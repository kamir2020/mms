import 'dart:io';
import 'package:archive/archive.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

class MarineInSituFtpMedia {

  static String _safeBase(String s) {
    final underscored = s.replaceAll(' ', '_').trim();
    final cleaned = underscored.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '');
    return cleaned.isEmpty ? 'FILE' : cleaned;
  }

  // Safe extension: keep the dot only if valid alnum content follows.
  static String _safeExt(String ext) {
    if (ext.isEmpty) return '';
    final noDot = ext.startsWith('.') ? ext.substring(1) : ext;
    final cleaned = noDot.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return cleaned.isEmpty ? '' : '.${cleaned.toLowerCase()}';
  }

  /// Zip all provided images and upload only the ZIP:
  /// Final name: <stationID>_<YYYYMMDDHHMMSS>_img.zip
  static Future<String> zipAndUploadImages({
    required List<File?> images,   // e.g. [ _image1File, ..., _image8File ]
    required String stationID,     // e.g. "6QBLG002"
    required String timestamp,     // e.g. "2025-08-15 20:25:13"

    // ---- FTP config (ftpconnect v1.x) ----
    String host = '219.92.7.61',
    int port = 21,
    String user = 'mmseqmp',
    String pass = 'mmseqmp',

    // ---- Options ----
    String remoteDir = '/marine/in_situ',  // auto-created (nested OK)
    bool showLog = true,
    int timeoutSeconds = 120,      // int (seconds) for v1.x
    bool createRemoteDirIfMissing = true,
    bool deleteLocalZipAfterUpload = true,
  }) async {
    FTPConnect? ftp;
    File? zipFile;

    try {
      // 1) Build timestamp part → YYYYMMDDHHmmss
      DateTime dt;
      try {
        dt = DateTime.parse(timestamp.replaceAll(' ', 'T'));
      } catch (_) {
        dt = DateTime.now(); // fallback if parsing fails
      }
      final tsPart = DateFormat('yyyyMMddHHmmss').format(dt);

      // 2) ZIP base name (with _img suffix)
      final zipBase = _safeBase('${stationID}_${tsPart}_img');
      final zipPath = p.join(Directory.systemTemp.path, '$zipBase.zip');

      // 3) Build ZIP manually (more robust than ZipFileEncoder.addFile)
      final archive = Archive();
      int added = 0;

      for (int i = 0; i < images.length; i++) {
        final f = images[i];
        if (f == null) continue;
        if (!await f.exists()) continue;

        final label = 'optional${i + 1}';
        final entryBase = _safeBase('${stationID}_${tsPart}_$label');
        final entryExt  = _safeExt(p.extension(f.path)); // ".jpg" / ".png" / ""
        final entryName = '$entryBase$entryExt';         // final entry name

        final bytes = await f.readAsBytes();
        archive.addFile(ArchiveFile(entryName, bytes.length, bytes));
        added++;
      }

      if (added == 0) {
        return 'ℹ️ No images to zip. Nothing uploaded.';
      }

      final zipData = ZipEncoder().encode(archive)!;
      zipFile = File(zipPath)..writeAsBytesSync(zipData);

      // 4) FTP connect (v1.x signature: timeout is INT, flag is showLog)
      ftp = FTPConnect(
        host,
        port: port,
        user: user,
        pass: pass,
        showLog: showLog,
        timeout: timeoutSeconds,
        // isSecured: false, // enable if your server needs FTPS (check your server)
      );

      await ftp.connect();

      // 5) Ensure remoteDir exists (supports nested, e.g. "/upload/images/2025/08")
      if (createRemoteDirIfMissing) {
        await _ensureRemoteDir(ftp, remoteDir);
      } else {
        if (!await ftp.changeDirectory(remoteDir)) {
          return '❌ Remote directory not found: $remoteDir';
        }
      }

      // 6) Upload the ZIP with the exact name
      final ok = await ftp.uploadFile(zipFile, sRemoteName: '$zipBase.zip');

      return ok
          ? '✅ Uploaded $zipBase.zip to $remoteDir'
          : '❌ Upload failed for $zipBase.zip';
    } catch (e) {
      return '❌ ZIP/FTP error: $e';
    } finally {
      try { await ftp?.disconnect(); } catch (_) {}
      if (deleteLocalZipAfterUpload) {
        try { await zipFile?.delete(); } catch (_) {}
      }
    }
  }

  // Create nested remote path and cd into it (v1.x-friendly)
  static Future<void> _ensureRemoteDir(FTPConnect ftp, String remoteDir) async {
    await ftp.changeDirectory('/');
    final parts = remoteDir.split('/').where((s) => s.isNotEmpty);
    for (final part in parts) {
      if (!await ftp.changeDirectory(part)) {
        await ftp.makeDirectory(part);
        await ftp.changeDirectory(part);
      }
    }
  }
}
