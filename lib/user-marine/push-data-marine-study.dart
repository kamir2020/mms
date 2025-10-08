// lib/services/marine_tarball_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class PushStudySample {
  final int rowsPushed;
  final int imagesUploaded;
  final List<String> logs;

  const PushStudySample({
    required this.rowsPushed,
    required this.imagesUploaded,
    required this.logs,
  });
}

typedef Logger = void Function(String message);

class MarineStudySampleService {
  // Config
  final String dbName;
  final Uri pushApiUrl;
  final Uri uploadApiUrl;

  // Allow injecting openDatabase / directory for testing if you want
  final Future<Database> Function()? _openDb;
  final Future<Directory> Function()? _getDocsDir;

  MarineStudySampleService({
    this.dbName = 'mms.db',
    Uri? pushApiUrl,
    Uri? uploadApiUrl,
    Future<Database> Function()? openDb,
    Future<Directory> Function()? getDocsDir,
  })  : pushApiUrl = pushApiUrl ??
      Uri.parse('https://mmsv2.pstw.com.my/api/marine/api-push-data.php'),
        uploadApiUrl = uploadApiUrl ??
            Uri.parse(
                'https://mmsv2.pstw.com.my/upload-image-local.php?image=marine_study_sample'),
        _openDb = openDb,
        _getDocsDir = getDocsDir;

  Future<Database> _openDatabaseInternal() async {
    if (_openDb != null) return _openDb!();
    return openDatabase(dbName);
  }

  Future<Directory> _docsDirInternal() async {
    if (_getDocsDir != null) return _getDocsDir!();
    return getApplicationDocumentsDirectory();
  }

  Future<PushStudySample> pushDataStudySampleToMySQL({Logger? log}) async {
    final _logs = <String>[];
    void addLog(String m) {
      _logs.add(m);
      if (log != null) log!(m);
    }

    int rowsPushed = 0;
    int imagesUploaded = 0;

    final db = await _openDatabaseInternal();

    // 1) Ensure table exists (optional sanity check)
    try {
      // If this throws, we’ll catch below and surface a helpful message
      await db.rawQuery('SELECT 1 FROM tbl_marine_study_sampling LIMIT 1');
    } on DatabaseException catch (e) {
      addLog("SQLite error: ${e.toString()}");
      addLog("Tip: Make sure 'tbl_marine_study_sampling' is created before pushing.");
      return PushStudySample(rowsPushed: 0, imagesUploaded: 0, logs: _logs);
    }

    // 2) Count & fetch
    final result =
    await db.rawQuery('SELECT COUNT(*) as count FROM tbl_marine_study_sampling');
    final count = Sqflite.firstIntValue(result) ?? 0;

    if (count == 0) {
      addLog('No record in tbl_marine_study_sampling.');
      return PushStudySample(rowsPushed: 0, imagesUploaded: 0, logs: _logs);
    }

    final records = await db.query('tbl_marine_study_sampling');
    addLog('Found $count row(s), sending to server…');

    // 3) Push rows
    try {
      final response = await http.post(
        pushApiUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': 'push-marine-study-sample', 'data': records}),
      );

      if (response.statusCode == 200) {
        rowsPushed = count;
        addLog("Data pushed successfully. Server replied 200.");
      } else {
        addLog("Push failed. HTTP ${response.statusCode}: ${response.body}");
        return PushStudySample(
            rowsPushed: 0, imagesUploaded: 0, logs: _logs);
      }
    } catch (e) {
      addLog("Push error: $e");
      return PushStudySample(rowsPushed: 0, imagesUploaded: 0, logs: _logs);
    }

    // 4) Upload images under <appDocs>/tarball/<folder>/*.jpg|png and clean up
    try {
      final baseDir = await _docsDirInternal();
      final parentFolderPath = path.join(baseDir.path, 'manual_study_sampling');
      final parentDir = Directory(parentFolderPath);

      if (!await parentDir.exists()) {
        addLog('Images folder does not exist: $parentFolderPath (skip uploads)');
      } else {
        // Subfolders == one logical group per record or report
        final subfolders = parentDir
            .listSync()
            .whereType<Directory>()
            .toList(growable: false);

        for (final folder in subfolders) {
          final files = folder.listSync().whereType<File>();
          for (final file in files) {
            final ext = path.extension(file.path).toLowerCase();
            if (ext == '.jpg' || ext == '.jpeg' || ext == '.png') {
              final ok = await _uploadFile(
                file,
                folderName: path.basename(folder.path),
                addLog: addLog,
              );
              if (ok) {
                imagesUploaded++;
                // delete the file after successful upload
                try {
                  await file.delete();
                  addLog('${path.basename(file.path)} → deleted');
                } catch (e) {
                  addLog('Failed to delete ${file.path}: $e');
                }
              }
            }
          }

          // Remove empty folder
          try {
            if (folder.existsSync() && folder.listSync().isEmpty) {
              await folder.delete();
              addLog('Deleted empty folder: ${folder.path}');
            }
          } catch (e) {
            addLog('Failed to delete folder ${folder.path}: $e');
          }
        }
      }
    } catch (e) {
      addLog('Image upload pass failed: $e');
    }

    // 5) Clear table only after everything above succeeds
    try {
      await db.delete('tbl_marine_study_sampling');
      addLog("Table 'tbl_marine_study_sampling' emptied.");
    } catch (e) {
      addLog("Failed to clear 'tbl_marine_study_sampling': $e");
    }

    return PushStudySample(
      rowsPushed: rowsPushed,
      imagesUploaded: imagesUploaded,
      logs: _logs,
    );
  }

  Future<bool> _uploadFile(
      File file, {
        required String folderName,
        required void Function(String) addLog,
      }) async {
    final fileName = path.basename(file.path);

    try {
      final req = http.MultipartRequest('POST', uploadApiUrl);
      req.fields['folder'] = folderName;
      req.files.add(await http.MultipartFile.fromPath(
        'image',
        file.path,
        filename: fileName,
        contentType:
        MediaType.parse(lookupMimeType(file.path) ?? 'application/octet-stream'),
      ));

      final resp = await req.send();
      final body = await resp.stream.bytesToString();

      if (resp.statusCode == 200 && body.contains('Uploaded')) {
        addLog('$fileName → Uploaded');
        return true;
      } else {
        addLog('$fileName → Upload failed: [${"${resp.statusCode}"}] $body');
        return false;
      }
    } catch (e) {
      addLog('$fileName → Upload error: $e');
      return false;
    }
  }
}
