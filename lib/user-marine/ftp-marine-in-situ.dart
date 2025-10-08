import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class MarineManualInSituFTP {
  static Future<String> sendToFTP({
    required Map<String, dynamic> payload,

    // FTP config
    String host = '219.92.7.61',
    int port = 21,
    String user = 'mmseqmp',
    String pass = 'mmseqmp',

    // Options
    String remoteDir = '/marine/in_situ',
    bool passive = true,
    bool showLog = true,
    int timeoutSeconds = 25,
  }) async {
    try {
      // ✅ station_id
      final stationID = payload["station_id"]?.toString() ?? "UNKNOWN";

      // ✅ timestamp → "2025-08-15 20:25:13"
      final tsRaw = payload["timestamp"].toString();
      final dt = DateTime.parse(tsRaw.replaceAll(" ", "T"));
      final tsPart = DateFormat("yyyyMMddHHmmss").format(dt);

      // ✅ Final fileName: stationID_YYYYMMDDHHMMSS
      final fileName = '${stationID}_$tsPart';

      // 1) Save JSON
      final dir = await getApplicationDocumentsDirectory();
      final jsonPath = '${dir.path}/$fileName.json';
      final jsonFile = File(jsonPath);
      await jsonFile.writeAsString(jsonEncode(payload));

      // 2) Zip it
      final zipPath = '${dir.path}/$fileName.zip';
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      encoder.addFile(jsonFile);
      encoder.close();

      // 3) FTP upload
      final ftp = FTPConnect(
        host,
        port: port,
        user: user,
        pass: pass,
        timeout: 120,
      );

      await ftp.connect();

      // ✅ Ensure remoteDir exists (auto-create if not)
      if (!await ftp.changeDirectory(remoteDir)) {
        await ftp.makeDirectory(remoteDir);
        await ftp.changeDirectory(remoteDir);
      }

      final ok = await ftp.uploadFile(File(zipPath), sRemoteName: '$fileName.zip');
      await ftp.disconnect();

      // ✅ Cleanup local temp files (optional)
      await jsonFile.delete();
      await File(zipPath).delete();

      return ok
          ? '✅ Uploaded $fileName.zip to $remoteDir'
          : '❌ Upload failed';
    } catch (e) {
      return '❌ FTP upload failed: $e';
    }
  }
}
