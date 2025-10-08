import 'dart:ui' as ui;
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:app_mms/object-class/local-object-location-river.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:usb_serial/usb_serial.dart';
import '../../bluetooth/bluetooth_manager.dart';
import '../../bluetooth/widget/bluetooth_device_list_dialog.dart';
import '../../db_helper.dart';
import '../../object-class/local-object-state.dart';
import '../../object-class/local-object-user.dart';
import '../../object-state.dart';
import 'package:app_mms/object-station-river.dart';
import 'dart:typed_data';
import 'package:path/path.dart' as path;

import '../../serial/global-state.dart';
import '../../serial/serial_manager.dart';
import '../../serial/widget/serial_port_list_dialog.dart';

class SFormRiverISSample extends StatefulWidget {
  _SFormRiverISSample createState() => _SFormRiverISSample();
}

class _SFormRiverISSample extends State<SFormRiverISSample> {

  bool _isLocation = false;

  TextEditingController _stationID = TextEditingController();
  TextEditingController _sampleDate = TextEditingController();
  TextEditingController _sampleTime = TextEditingController();
  TextEditingController _basinName = TextEditingController();
  TextEditingController _riverName = TextEditingController();
  TextEditingController _latitude = TextEditingController();
  TextEditingController _longitude = TextEditingController();
  TextEditingController _barcode = TextEditingController();

  TextEditingController _currentLatitude = TextEditingController();
  TextEditingController _currentLongitude = TextEditingController();

  final TextEditingController _dateCapture = TextEditingController();
  final TextEditingController _timeCapture = TextEditingController();

  final TextEditingController _firstSamplerName = TextEditingController();
  final TextEditingController _secondSamplerName = TextEditingController();

  TextEditingController _reportID = TextEditingController();
  TextEditingController _uuidData = TextEditingController();
  TextEditingController _doData1 = TextEditingController();
  TextEditingController _doData2 = TextEditingController();
  TextEditingController _phData = TextEditingController();
  TextEditingController _ecData = TextEditingController();
  TextEditingController _sanilityData = TextEditingController();
  TextEditingController _tempData = TextEditingController();
  TextEditingController _turbidityData = TextEditingController();

  TextEditingController _flowRate = TextEditingController();
  TextEditingController _dissolvedSolid = TextEditingController();
  TextEditingController _suspendedSolid = TextEditingController();

  TextEditingController _batteryData = TextEditingController();

  double _distanceDevice = 0;
  late String? stationID;
  late String? selectedStateName;
  late String? firstSamplerName, secondSamplerName;
  late String? sampleDate, sampleTime;
  late String? dateCapture, timeCapture;
  late String? riverName, basinName;

  late String? _selectedStateName,_selectedCategoryName;
  late String? latitude, longitude;
  late String? getLatitude, getLongitude;
  late String? barcode;
  late String _type = '';
  late String _weather = '';
  late String result = '';
  late String? eventRemark, labRemark;
  late String? timestampResult1,timestampResult2;

  bool _form1 = true;
  bool _form2 = false;
  bool _form3 = false;
  bool _form4 = false;

  final _formRiverSample1 = GlobalKey<FormState>();
  final _formRiverSample2 = GlobalKey<FormState>();
  final _formRiverSample3 = GlobalKey<FormState>();
  final _formRiverSample4 = GlobalKey<FormState>();

  // Sensor data variables
  late String sondeID = '';
  late String doValue1 = "--"; // Oxygen concentration
  late String doValue2 = "--"; // Oxygen saturation
  late String pH = "--";
  late String ec = "--"; // Electrical conductivity
  late String salinity = "--";
  late String temperature = "--";
  late String flowRate = "--";
  late String totalDissolve = "--";
  late String totalSuspended = "--";
  late String tds = "--";
  late String turbidity = "--";
  late String tss = "--";
  late String battery = "--";

  String? stateID;
  StationRiver? selectedStation;
  States? selectedState;

  bool _isDisplay = false;
  bool _isDeviceUSB = false;
  bool _isDeviceBluetooth = false;

  UsbPort? port;
  bool isConnected = false;
  StreamSubscription<Uint8List>? inputStreamSubscription;
  late String rawData = "";

  final BluetoothManager _bluetoothManager = BluetoothManager();
  bool _isLoadingBluetooth = false;
  Map<String, double> _latestReadingsBluetooth = {};

  bool connectionStatus = true;
  final db = DBHelper();

  @override
  void initState() {
    super.initState();
    _getProfile();
    _loadSampler();
    _loadState();
    _checkInternet();

    _reportID.text = getRandomString(10);


    _uuidData.text = 'A123';
    _doData1.text = '10';
    _doData2.text = '15';
    _phData.text = '15';
    _sanilityData.text = '15';
    _ecData.text = '15';
    _tempData.text = '15';
    _turbidityData.text = '15';
    _flowRate.text = '10';
    _dissolvedSolid.text = '20';
    _suspendedSolid.text = '10';
    _batteryData.text = '20';

    var now = DateTime.now();
    var formatter = DateFormat('yyyy-MM-dd');
    String formattedDate = formatter.format(now);
    String formattedTime = DateFormat('HH:mm:ss').format(now);


    _sampleDate.text = formattedDate;
    _dateCapture.text = formattedDate;

    _sampleTime.text = formattedTime;
    _timeCapture.text = formattedTime;

    int timestamp = DateTime.now().millisecondsSinceEpoch;
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String result1 = DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
    String result2 = DateFormat('yyyyMMdd_HHmmss').format(date);

    setState(() {
      timestampResult1 = result1;
      timestampResult2 = result2;
    });

  }

  List<localUser> sampler1 = [];
  localUser? selectedLocalSampler;

  Future<void> _loadSampler() async {
    final data = await DBHelper.getSampler();
    setState(() {
      sampler1 = data;
    });
  }

  List<localState> state1 = [];
  localState? selectedLocalState;

  Future<void> _loadState() async {
    final data = await DBHelper.getState();
    setState(() {
      state1 = data;
    });
  }

  List<localRiverLocation> location1 = [];
  localRiverLocation? selectedLocalLocation;

  Future<void> _loadLocation(String? stateID) async {
    final data = await DBHelper.getLocationRiver(stateID);
    setState(() {
      _isLocation = true;
      location1 = data;
    });
  }

  static const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  Future<void> _getProfile() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _firstSamplerName.text = prefs.getString("fullName").toString();
    });

  }

  List<String> emailList = [];

  Future<void> fetchEmails() async {
    print('Email list');
    final response = await http.get(Uri.parse('https://mmsv2.pstw.com.my/api/river/api-get-river.php?action=river-email'));

    if (response.statusCode == 200) {
      final List<dynamic> emails = jsonDecode(response.body);
      setState(() {
        emailList = emails.cast<String>();
      });
      print(emailList);
    } else {
      print('Failed to fetch emails');
    }
  }

  Future<void> _checkInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        connectionStatus = false;
      });
      return;
    }

    // Check actual internet access
    try {
      final result = await http.get(Uri.parse('https://google.com')).timeout(Duration(seconds: 5));
      if (result.statusCode == 200) {
        setState(() {
          fetchEmails();
          connectionStatus = true;
        });
      } else {
        setState(() {
          connectionStatus = false;
        });
      }
    } catch (e) {
      setState(() {
        connectionStatus = false;
      });
    }
  }

  Future<void> _checkPermissionsAndFetchLocation(BuildContext context) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {

      }
    }

    if (permission == LocationPermission.deniedForever) {

    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentLatitude.text = position.latitude.toString();
      _currentLongitude.text = position.longitude.toString();

      // set latitude & longitude
      //_latitude.text = position.latitude.toString();
      //_longitude.text = position.longitude.toString();

    });

    double result = calculateDistance(double.parse(_latitude.text),double.parse(_longitude.text),double.parse(_currentLatitude.text),double.parse(_currentLongitude.text));

    setState(() {
      _distanceDevice = result;
    });
    _showDistance(context, result.toString());

    print("Latitude: ${position.latitude}, Longitude: ${position.longitude}");
  }

  void _showDistance(BuildContext context, String result) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.place_rounded,
                      size: 50, color: Colors.blueAccent),
                  const SizedBox(height: 15),
                  Text(
                    'Distance',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'The distance between the two locations is $result KM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: CurvedAnimation(
                parent: anim1, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
    );
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371; // Radius of the Earth in km

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // Distance in km
  }

  double _degreesToRadians(double degree) {
    return degree * pi / 180;
  }

  final ImagePicker _picker1 = ImagePicker();
  File? _image1;
  late String _img1='';
  bool isLoadingImg1 = false;

  Future<void> _takePicture1() async {
    try {
      final XFile? photo = await _picker1.pickImage(
        source: ImageSource.camera,
        maxWidth: 500,
        maxHeight: 200,
        imageQuality: 80,
      );

      if (photo != null) {

        final bytes = await photo.readAsBytes();
        final decodedImage = img.decodeImage(bytes);

        // drawing text
        img.Image? originalImage = img.decodeImage(bytes);

        if (decodedImage != null && decodedImage.width > decodedImage.height) {

          // save string
          img.drawString(originalImage!, img.arial_14, 2, 12, timestampResult1!);

          // Save string to file
          final tempDir = await getTemporaryDirectory();
          final filePath = path.join(tempDir.path, 'edited_${path.basename(photo.path)}');
          final editedFile = File(filePath)..writeAsBytesSync(img.encodeJpg(originalImage));

          setState(() {
            _img1 = '';
            _image1 = editedFile;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Please take a picture in landscape (horizontal) image.")),
          );
        }

      }
    } catch (e) {
      print("Error while capturing image: $e");
    }
  }

  Future<void> _takePicture1a(ImageSource source) async {
    try {
      final XFile? photo = await _picker1.pickImage(source: source,
        maxWidth: 500,
        maxHeight: 200,
        imageQuality: 80,
      );

      if (photo != null) {

        final bytes = await photo.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final uiImage = frame.image;

        if (uiImage.width <= uiImage.height) {

          setState(() {
            isLoadingImg1 = false;
          });

          print("Only landscape images are allowed.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Only landscape images are allowed.")),
          );
          return;
        }

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, ui.Rect.fromLTWH(0, 0, uiImage.width.toDouble(), uiImage.height.toDouble()));
        final paint = Paint();

        // Draw the image
        canvas.drawImage(uiImage, Offset.zero, paint);
        // Draw the text
        final textStyle = TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        );

        final textSpan = TextSpan(text: timestampResult1!, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: ui.TextDirection.ltr,
        )..layout();

        textPainter.paint(canvas, Offset(10, 15));

        final picture = recorder.endRecording();
        final finalImage = await picture.toImage(uiImage.width, uiImage.height);
        final pngBytes = await finalImage.toByteData(format: ui.ImageByteFormat.png);


        // Save string to file
        final tempDir = await getTemporaryDirectory();
        final filePath = path.join(
            tempDir.path, 'edited_${path.basename(photo.path)}');
        final editedFile = File(filePath)..writeAsBytesSync(pngBytes!.buffer.asUint8List());

        setState(() {
          _img1 = '';
          isLoadingImg1 = false;
          _image1 = editedFile;
        });

      }
    } catch (e) {
      print("Error while capturing image: $e");
    }
  }

  // Function to delete the picture
  Future<void> _deletePicture1() async {
    if (_image1 != null) {
      try {
        await _image1!.delete();
        setState(() {
          _image1 = null; // Reset the image state
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Picture deleted successfully!")),
        );
      } catch (e) {
        print("Error while deleting the picture: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete picture!")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No picture to delete!")),
      );
    }
  }

  final ImagePicker _picker2 = ImagePicker();
  File? _image2;
  late String _img2='';
  bool isLoadingImg2 = false;

  Future<void> _takePicture2() async {
    try {
      final XFile? photo = await _picker2.pickImage(
        source: ImageSource.camera,
        maxWidth: 500,
        maxHeight: 200,
        imageQuality: 80,
      );

      if (photo != null) {

        final bytes = await photo.readAsBytes();
        final decodedImage = img.decodeImage(bytes);

        // drawing text
        img.Image? originalImage = img.decodeImage(bytes);

        if (decodedImage != null && decodedImage.width > decodedImage.height) {

          // save string
          img.drawString(originalImage!, img.arial_14, 2, 12, timestampResult1!);

          // Save string to file
          final tempDir = await getTemporaryDirectory();
          final filePath = path.join(tempDir.path, 'edited_${path.basename(photo.path)}');
          final editedFile = File(filePath)..writeAsBytesSync(img.encodeJpg(originalImage));

          setState(() {
            _img2 = '';
            _image2 = editedFile;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Please take a picture in landscape (horizontal) image.")),
          );
        }

      }
    } catch (e) {
      print("Error while capturing image: $e");
    }
  }

  Future<void> _takePicture2a(ImageSource source) async {
    try {
      final XFile? photo = await _picker2.pickImage(source: source,
        maxWidth: 500,
        maxHeight: 200,
        imageQuality: 80,
      );

      if (photo != null) {

        final bytes = await photo.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final uiImage = frame.image;

        if (uiImage.width <= uiImage.height) {

          setState(() {
            isLoadingImg2 = false;
          });

          print("Only landscape images are allowed.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Only landscape images are allowed.")),
          );
          return;
        }

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, ui.Rect.fromLTWH(0, 0, uiImage.width.toDouble(), uiImage.height.toDouble()));
        final paint = Paint();

        // Draw the image
        canvas.drawImage(uiImage, Offset.zero, paint);
        // Draw the text
        final textStyle = TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        );

        final textSpan = TextSpan(text: timestampResult1!, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: ui.TextDirection.ltr,
        )..layout();

        textPainter.paint(canvas, Offset(10, 15));

        final picture = recorder.endRecording();
        final finalImage = await picture.toImage(uiImage.width, uiImage.height);
        final pngBytes = await finalImage.toByteData(format: ui.ImageByteFormat.png);


        // Save string to file
        final tempDir = await getTemporaryDirectory();
        final filePath = path.join(
            tempDir.path, 'edited_${path.basename(photo.path)}');
        final editedFile = File(filePath)..writeAsBytesSync(pngBytes!.buffer.asUint8List());

        setState(() {
          _img2 = '';
          isLoadingImg2 = false;
          _image2 = editedFile;
        });

      }
    } catch (e) {
      print("Error while capturing image: $e");
    }
  }

  // Function to delete the picture
  Future<void> _deletePicture2() async {
    if (_image2 != null) {
      try {
        await _image2!.delete();
        setState(() {
          _image2 = null; // Reset the image state
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Picture deleted successfully!")),
        );
      } catch (e) {
        print("Error while deleting the picture: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete picture!")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No picture to delete!")),
      );
    }
  }

  final ImagePicker _picker3 = ImagePicker();
  File? _image3;
  late String _img3='';
  bool isLoadingImg3 = false;

  Future<void> _takePicture3() async {
    try {
      final XFile? photo = await _picker3.pickImage(
        source: ImageSource.camera,
        maxWidth: 500,
        maxHeight: 200,
        imageQuality: 80,
      );

      if (photo != null) {

        final bytes = await photo.readAsBytes();
        final decodedImage = img.decodeImage(bytes);

        // drawing text
        img.Image? originalImage = img.decodeImage(bytes);

        if (decodedImage != null && decodedImage.width > decodedImage.height) {

          // save string
          img.drawString(originalImage!, img.arial_14, 2, 12, timestampResult1!);

          // Save string to file
          final tempDir = await getTemporaryDirectory();
          final filePath = path.join(tempDir.path, 'edited_${path.basename(photo.path)}');
          final editedFile = File(filePath)..writeAsBytesSync(img.encodeJpg(originalImage));

          setState(() {
            _img3 = '';
            _image3 = editedFile;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Please take a picture in landscape (horizontal) image.")),
          );
        }

      }
    } catch (e) {
      print("Error while capturing image: $e");
    }
  }

  Future<void> _takePicture3a(ImageSource source) async {
    try {
      final XFile? photo = await _picker3.pickImage(source: source,
        maxWidth: 500,
        maxHeight: 200,
        imageQuality: 80,
      );

      if (photo != null) {

        final bytes = await photo.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final uiImage = frame.image;

        if (uiImage.width <= uiImage.height) {

          setState(() {
            isLoadingImg3 = false;
          });

          print("Only landscape images are allowed.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Only landscape images are allowed.")),
          );
          return;
        }

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, ui.Rect.fromLTWH(0, 0, uiImage.width.toDouble(), uiImage.height.toDouble()));
        final paint = Paint();

        // Draw the image
        canvas.drawImage(uiImage, Offset.zero, paint);
        // Draw the text
        final textStyle = TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        );

        final textSpan = TextSpan(text: timestampResult1!, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: ui.TextDirection.ltr,
        )..layout();

        textPainter.paint(canvas, Offset(10, 15));

        final picture = recorder.endRecording();
        final finalImage = await picture.toImage(uiImage.width, uiImage.height);
        final pngBytes = await finalImage.toByteData(format: ui.ImageByteFormat.png);


        // Save string to file
        final tempDir = await getTemporaryDirectory();
        final filePath = path.join(
            tempDir.path, 'edited_${path.basename(photo.path)}');
        final editedFile = File(filePath)..writeAsBytesSync(pngBytes!.buffer.asUint8List());

        setState(() {
          _img3 = '';
          isLoadingImg3 = false;
          _image3 = editedFile;
        });

      }
    } catch (e) {
      print("Error while capturing image: $e");
    }
  }

  // Function to delete the picture
  Future<void> _deletePicture3() async {
    if (_image3 != null) {
      try {
        await _image3!.delete();
        setState(() {
          _image3 = null; // Reset the image state
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Picture deleted successfully!")),
        );
      } catch (e) {
        print("Error while deleting the picture: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete picture!")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No picture to delete!")),
      );
    }
  }

  final ImagePicker _picker4 = ImagePicker();
  File? _image4;
  late String _img4='';
  bool isLoadingImg4 = false;

  Future<void> _takePicture4() async {
    try {
      final XFile? photo = await _picker4.pickImage(
        source: ImageSource.camera,
        maxWidth: 500,
        maxHeight: 200,
        imageQuality: 80,
      );

      if (photo != null) {

        final bytes = await photo.readAsBytes();
        final decodedImage = img.decodeImage(bytes);

        // drawing text
        img.Image? originalImage = img.decodeImage(bytes);

        if (decodedImage != null && decodedImage.width > decodedImage.height) {

          // save string
          img.drawString(originalImage!, img.arial_14, 2, 12, timestampResult1!);

          // Save string to file
          final tempDir = await getTemporaryDirectory();
          final filePath = path.join(tempDir.path, 'edited_${path.basename(photo.path)}');
          final editedFile = File(filePath)..writeAsBytesSync(img.encodeJpg(originalImage));

          setState(() {
            _img4 = '';
            _image4 = editedFile;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Please take a picture in landscape (horizontal) image.")),
          );
        }

      }
    } catch (e) {
      print("Error while capturing image: $e");
    }
  }

  Future<void> _takePicture4a(ImageSource source) async {
    try {
      final XFile? photo = await _picker4.pickImage(source: source,
        maxWidth: 500,
        maxHeight: 200,
        imageQuality: 80,
      );

      if (photo != null) {

        final bytes = await photo.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final uiImage = frame.image;

        if (uiImage.width <= uiImage.height) {

          setState(() {
            isLoadingImg4 = false;
          });

          print("Only landscape images are allowed.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Only landscape images are allowed.")),
          );
          return;
        }

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, ui.Rect.fromLTWH(0, 0, uiImage.width.toDouble(), uiImage.height.toDouble()));
        final paint = Paint();

        // Draw the image
        canvas.drawImage(uiImage, Offset.zero, paint);
        // Draw the text
        final textStyle = TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        );

        final textSpan = TextSpan(text: timestampResult1!, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: ui.TextDirection.ltr,
        )..layout();

        textPainter.paint(canvas, Offset(10, 15));

        final picture = recorder.endRecording();
        final finalImage = await picture.toImage(uiImage.width, uiImage.height);
        final pngBytes = await finalImage.toByteData(format: ui.ImageByteFormat.png);


        // Save string to file
        final tempDir = await getTemporaryDirectory();
        final filePath = path.join(
            tempDir.path, 'edited_${path.basename(photo.path)}');
        final editedFile = File(filePath)..writeAsBytesSync(pngBytes!.buffer.asUint8List());

        setState(() {
          _img4 = '';
          isLoadingImg4 = false;
          _image4 = editedFile;
        });

      }
    } catch (e) {
      print("Error while capturing image: $e");
    }
  }

  // Function to delete the picture
  Future<void> _deletePicture4() async {
    if (_image4 != null) {
      try {
        await _image4!.delete();
        setState(() {
          _image4 = null; // Reset the image state
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Picture deleted successfully!")),
        );
      } catch (e) {
        print("Error while deleting the picture: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete picture!")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No picture to delete!")),
      );
    }
  }

  final ImagePicker _picker5 = ImagePicker();
  File? _image5;
  bool isLoadingImg5 = false;

  Future<void> _takePicture5() async {
    try {
      final XFile? photo = await _picker5.pickImage(
        source: ImageSource.camera,
        maxWidth: 500,
        maxHeight: 200,
        imageQuality: 80,
      );

      if (photo != null) {

        final bytes = await photo.readAsBytes();
        final decodedImage = img.decodeImage(bytes);

        // drawing text
        img.Image? originalImage = img.decodeImage(bytes);

        if (decodedImage != null && decodedImage.width > decodedImage.height) {

          // save string
          img.drawString(originalImage!, img.arial_14, 2, 12, timestampResult1!);

          // Save string to file
          final tempDir = await getTemporaryDirectory();
          final filePath = path.join(tempDir.path, 'edited_${path.basename(photo.path)}');
          final editedFile = File(filePath)..writeAsBytesSync(img.encodeJpg(originalImage));

          setState(() {
            _image5 = editedFile;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Please take a picture in landscape (horizontal) image.")),
          );
        }

      }
    } catch (e) {
      print("Error while capturing image: $e");
    }
  }

  Future<void> _takePicture5a(ImageSource source) async {
    try {
      final XFile? photo = await _picker5.pickImage(source: source,
        maxWidth: 500,
        maxHeight: 200,
        imageQuality: 80,
      );

      if (photo != null) {

        final bytes = await photo.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final uiImage = frame.image;

        if (uiImage.width <= uiImage.height) {

          setState(() {
            isLoadingImg5 = false;
          });

          print("Only landscape images are allowed.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Only landscape images are allowed.")),
          );
          return;
        }

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, ui.Rect.fromLTWH(0, 0, uiImage.width.toDouble(), uiImage.height.toDouble()));
        final paint = Paint();

        // Draw the image
        canvas.drawImage(uiImage, Offset.zero, paint);
        // Draw the text
        final textStyle = TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        );

        final textSpan = TextSpan(text: timestampResult1!, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: ui.TextDirection.ltr,
        )..layout();

        textPainter.paint(canvas, Offset(10, 15));

        final picture = recorder.endRecording();
        final finalImage = await picture.toImage(uiImage.width, uiImage.height);
        final pngBytes = await finalImage.toByteData(format: ui.ImageByteFormat.png);


        // Save string to file
        final tempDir = await getTemporaryDirectory();
        final filePath = path.join(
            tempDir.path, 'edited_${path.basename(photo.path)}');
        final editedFile = File(filePath)..writeAsBytesSync(pngBytes!.buffer.asUint8List());

        setState(() {
          isLoadingImg5 = false;
          _image5 = editedFile;
        });

      }
    } catch (e) {
      print("Error while capturing image: $e");
    }
  }

  // Function to delete the picture
  Future<void> _deletePicture5() async {
    if (_image5 != null) {
      try {
        await _image5!.delete();
        setState(() {
          _image5 = null; // Reset the image state
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Picture deleted successfully!")),
        );
      } catch (e) {
        print("Error while deleting the picture: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete picture!")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No picture to delete!")),
      );
    }
  }

  final ImagePicker _picker6 = ImagePicker();
  File? _image6;
  bool isLoadingImg6 = false;

  Future<void> _takePicture6() async {
    try {
      final XFile? photo = await _picker6.pickImage(
        source: ImageSource.camera,
        maxWidth: 500,
        maxHeight: 200,
        imageQuality: 80,
      );

      if (photo != null) {

        final bytes = await photo.readAsBytes();
        final decodedImage = img.decodeImage(bytes);

        // drawing text
        img.Image? originalImage = img.decodeImage(bytes);

        if (decodedImage != null && decodedImage.width > decodedImage.height) {

          // save string
          img.drawString(originalImage!, img.arial_14, 2, 12, timestampResult1!);

          // Save string to file
          final tempDir = await getTemporaryDirectory();
          final filePath = path.join(tempDir.path, 'edited_${path.basename(photo.path)}');
          final editedFile = File(filePath)..writeAsBytesSync(img.encodeJpg(originalImage));

          setState(() {
            _image6 = editedFile;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Please take a picture in landscape (horizontal) image.")),
          );
        }

      }
    } catch (e) {
      print("Error while capturing image: $e");
    }
  }

  Future<void> _takePicture6a(ImageSource source) async {
    try {
      final XFile? photo = await _picker6.pickImage(source: source,
        maxWidth: 500,
        maxHeight: 200,
        imageQuality: 80,
      );

      if (photo != null) {

        final bytes = await photo.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final uiImage = frame.image;

        if (uiImage.width <= uiImage.height) {

          setState(() {
            isLoadingImg6 = false;
          });

          print("Only landscape images are allowed.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Only landscape images are allowed.")),
          );
          return;
        }

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, ui.Rect.fromLTWH(0, 0, uiImage.width.toDouble(), uiImage.height.toDouble()));
        final paint = Paint();

        // Draw the image
        canvas.drawImage(uiImage, Offset.zero, paint);
        // Draw the text
        final textStyle = TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        );

        final textSpan = TextSpan(text: timestampResult1!, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: ui.TextDirection.ltr,
        )..layout();

        textPainter.paint(canvas, Offset(10, 15));

        final picture = recorder.endRecording();
        final finalImage = await picture.toImage(uiImage.width, uiImage.height);
        final pngBytes = await finalImage.toByteData(format: ui.ImageByteFormat.png);


        // Save string to file
        final tempDir = await getTemporaryDirectory();
        final filePath = path.join(
            tempDir.path, 'edited_${path.basename(photo.path)}');
        final editedFile = File(filePath)..writeAsBytesSync(pngBytes!.buffer.asUint8List());

        setState(() {
          isLoadingImg6 = false;
          _image6 = editedFile;
        });

      }
    } catch (e) {
      print("Error while capturing image: $e");
    }
  }

  // Function to delete the picture
  Future<void> _deletePicture6() async {
    if (_image6 != null) {
      try {
        await _image6!.delete();
        setState(() {
          _image6 = null; // Reset the image state
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Picture deleted successfully!")),
        );
      } catch (e) {
        print("Error while deleting the picture: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete picture!")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No picture to delete!")),
      );
    }
  }

  final ImagePicker _picker7 = ImagePicker();
  File? _image7;
  bool isLoadingImg7 = false;

  Future<void> _takePicture7() async {
    try {
      final XFile? photo = await _picker7.pickImage(
        source: ImageSource.camera,
        maxWidth: 500,
        maxHeight: 200,
        imageQuality: 80,
      );

      if (photo != null) {

        final bytes = await photo.readAsBytes();
        final decodedImage = img.decodeImage(bytes);

        // drawing text
        img.Image? originalImage = img.decodeImage(bytes);

        if (decodedImage != null && decodedImage.width > decodedImage.height) {

          // save string
          img.drawString(originalImage!, img.arial_14, 2, 12, timestampResult1!);

          // Save string to file
          final tempDir = await getTemporaryDirectory();
          final filePath = path.join(tempDir.path, 'edited_${path.basename(photo.path)}');
          final editedFile = File(filePath)..writeAsBytesSync(img.encodeJpg(originalImage));

          setState(() {
            _image7 = editedFile;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Please take a picture in landscape (horizontal) image.")),
          );
        }

      }
    } catch (e) {
      print("Error while capturing image: $e");
    }
  }

  Future<void> _takePicture7a(ImageSource source) async {
    try {
      final XFile? photo = await _picker7.pickImage(source: source,
        maxWidth: 500,
        maxHeight: 200,
        imageQuality: 80,
      );

      if (photo != null) {

        final bytes = await photo.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final uiImage = frame.image;

        if (uiImage.width <= uiImage.height) {

          setState(() {
            isLoadingImg7 = false;
          });

          print("Only landscape images are allowed.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Only landscape images are allowed.")),
          );
          return;
        }

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, ui.Rect.fromLTWH(0, 0, uiImage.width.toDouble(), uiImage.height.toDouble()));
        final paint = Paint();

        // Draw the image
        canvas.drawImage(uiImage, Offset.zero, paint);
        // Draw the text
        final textStyle = TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        );

        final textSpan = TextSpan(text: timestampResult1!, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: ui.TextDirection.ltr,
        )..layout();

        textPainter.paint(canvas, Offset(10, 15));

        final picture = recorder.endRecording();
        final finalImage = await picture.toImage(uiImage.width, uiImage.height);
        final pngBytes = await finalImage.toByteData(format: ui.ImageByteFormat.png);


        // Save string to file
        final tempDir = await getTemporaryDirectory();
        final filePath = path.join(
            tempDir.path, 'edited_${path.basename(photo.path)}');
        final editedFile = File(filePath)..writeAsBytesSync(pngBytes!.buffer.asUint8List());

        setState(() {
          isLoadingImg7 = false;
          _image7 = editedFile;
        });

      }
    } catch (e) {
      print("Error while capturing image: $e");
    }
  }

  // Function to delete the picture
  Future<void> _deletePicture7() async {
    if (_image7 != null) {
      try {
        await _image7!.delete();
        setState(() {
          _image7 = null; // Reset the image state
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Picture deleted successfully!")),
        );
      } catch (e) {
        print("Error while deleting the picture: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete picture!")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No picture to delete!")),
      );
    }
  }

  final ImagePicker _picker8 = ImagePicker();
  File? _image8;
  bool isLoadingImg8 = false;

  Future<void> _takePicture8() async {
    try {
      final XFile? photo = await _picker8.pickImage(
        source: ImageSource.camera,
        maxWidth: 500,
        maxHeight: 200,
        imageQuality: 80,
      );

      if (photo != null) {

        final bytes = await photo.readAsBytes();
        final decodedImage = img.decodeImage(bytes);

        // drawing text
        img.Image? originalImage = img.decodeImage(bytes);

        if (decodedImage != null && decodedImage.width > decodedImage.height) {

          // save string
          img.drawString(originalImage!, img.arial_14, 2, 12, timestampResult1!);

          // Save string to file
          final tempDir = await getTemporaryDirectory();
          final filePath = path.join(tempDir.path, 'edited_${path.basename(photo.path)}');
          final editedFile = File(filePath)..writeAsBytesSync(img.encodeJpg(originalImage));

          setState(() {
            _image8 = editedFile;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Please take a picture in landscape (horizontal) image.")),
          );
        }

      }
    } catch (e) {
      print("Error while capturing image: $e");
    }
  }

  Future<void> _takePicture8a(ImageSource source) async {
    try {
      final XFile? photo = await _picker8.pickImage(source: source,
        maxWidth: 500,
        maxHeight: 200,
        imageQuality: 80,
      );

      if (photo != null) {

        final bytes = await photo.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final uiImage = frame.image;

        if (uiImage.width <= uiImage.height) {

          setState(() {
            isLoadingImg6 = false;
          });

          print("Only landscape images are allowed.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Only landscape images are allowed.")),
          );
          return;
        }

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder, ui.Rect.fromLTWH(0, 0, uiImage.width.toDouble(), uiImage.height.toDouble()));
        final paint = Paint();

        // Draw the image
        canvas.drawImage(uiImage, Offset.zero, paint);
        // Draw the text
        final textStyle = TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        );

        final textSpan = TextSpan(text: timestampResult1!, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: ui.TextDirection.ltr,
        )..layout();

        textPainter.paint(canvas, Offset(10, 15));

        final picture = recorder.endRecording();
        final finalImage = await picture.toImage(uiImage.width, uiImage.height);
        final pngBytes = await finalImage.toByteData(format: ui.ImageByteFormat.png);


        // Save string to file
        final tempDir = await getTemporaryDirectory();
        final filePath = path.join(
            tempDir.path, 'edited_${path.basename(photo.path)}');
        final editedFile = File(filePath)..writeAsBytesSync(pngBytes!.buffer.asUint8List());

        setState(() {
          isLoadingImg8 = false;
          _image8 = editedFile;
        });

      }
    } catch (e) {
      print("Error while capturing image: $e");
    }
  }

  // Function to delete the picture
  Future<void> _deletePicture8() async {
    if (_image8 != null) {
      try {
        await _image8!.delete();
        setState(() {
          _image8 = null; // Reset the image state
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Picture deleted successfully!")),
        );
      } catch (e) {
        print("Error while deleting the picture: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete picture!")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No picture to delete!")),
      );
    }
  }

  Widget _buildForm1() {
    return Form(
      key: _formRiverSample1,
      child: Column(
        children: [
          Divider(),
          Center(
            child: Text(':: Information Details :: ',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
          ),
          Divider(),
          SizedBox(height: 10.0,),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  controller: _firstSamplerName,
                  decoration: InputDecoration(
                    labelText: '1st Sampler',
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => setState(() => firstSamplerName = value!),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return '1st Sampler';
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 10.0,),
          Row(
            children: [
              Expanded(
                child: DropdownSearch<localUser>(
                  items: sampler1,
                  selectedItem: selectedLocalSampler,
                  itemAsString: (localUser u) => "${u.fullname}", // optional
                  popupProps: PopupProps.menu(showSearchBox: true),
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Choose 2nd sampler",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  validator: (value) {
                    if (value == null) return 'Please select the 2nd sampler';
                    if (secondSamplerName != null && secondSamplerName == _firstSamplerName.text) {
                      return '2nd sampler must be different from 1st sampler';
                    }
                    return null;
                  },
                  onChanged: (localUser? value) {
                    setState(() {
                      selectedLocalSampler = value;
                      _secondSamplerName.text = selectedLocalSampler!.fullname;
                      //secondSamplerName = selectedLocalSampler!.fullname;
                    });
                    if (value != null) {
                      print("Name: ${value.fullname}");
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 10.0,),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _secondSamplerName,
                  decoration: InputDecoration(
                    labelText: '2nd Sampler',
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => setState(() => secondSamplerName = value!),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return '2nd Sampler';
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 10.0,),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _sampleDate,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => setState(() => sampleDate = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.0,),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  controller: _sampleTime,
                  decoration: InputDecoration(
                    labelText: 'Time',
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => setState(() => sampleTime = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.0,),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField(
                  decoration: InputDecoration(
                    labelText: 'Type',
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  value: _type.isNotEmpty ? _type : null,
                  items: <String>['Schedule', 'Triennial']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _type = value.toString();
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Type is required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 10.0,),
          Row(
            children: [
              Expanded(
                child: DropdownSearch<localState>(
                  items: state1,
                  selectedItem: selectedLocalState,
                  itemAsString: (localState u) => "${u.stateName}", // optional
                  popupProps: PopupProps.menu(showSearchBox: true),
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Select state",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  validator: (value) {
                    if (value == null) return 'Please select state';
                    return null;
                  },
                  onChanged: (localState? value) {
                    setState(() {
                      selectedLocalState = value;
                      stateID = selectedLocalState!.stateID;
                      _selectedStateName = selectedLocalState!.stateName;

                      selectedStation = null;
                      _isLocation = true;
                      _loadLocation(stateID);
                    });
                    if (value != null) {
                      print("Selected ID: ${value.stateID}, Name: ${value.stateName}");
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 10.0,),
          _isLocation ? Column(
            children: [
              SizedBox(
                height: 0,
              ),
              Row(
                children: [
                  Expanded(
                    child: DropdownSearch<localRiverLocation>(
                      items: location1,
                      selectedItem: selectedLocalLocation,
                      itemAsString: (localRiverLocation u) => "${u.stationID} - ${u.riverName}", // optional
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        emptyBuilder: (context, searchEntry) => Center(
                          child: Text("No records found"),
                        ),
                      ),
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: "Select location",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      validator: (value) {
                        if (value == null) return 'Please select location';
                        return null;
                      },
                      onChanged: (localRiverLocation? value) {
                        setState(() {
                          selectedLocalLocation = value;
                        });
                        if (value != null) {
                          print("Name: ${value.riverName}");

                          _basinName.text = selectedLocalLocation!.basinName;
                          _riverName.text = selectedLocalLocation!.riverName;
                          _latitude.text = selectedLocalLocation!.latitude;
                          _longitude.text = selectedLocalLocation!.longitude;
                          _stationID.text = selectedLocalLocation!.stationID;

                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ) : SizedBox(),
          SizedBox(height: 0.0,),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  controller: _basinName,
                  decoration: InputDecoration(
                    labelText: 'Basin',
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => setState(() => basinName = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.0,),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  readOnly: true,
                  controller: _riverName,
                  decoration: InputDecoration(
                    labelText: 'River',
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => setState(() => riverName = value!),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 10.0,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    TextFormField(
                      readOnly: true,
                      controller: _latitude,
                      decoration: InputDecoration(
                        labelText: 'Latitude',
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (value) => setState(() => latitude = value!),
                    ),
                    SizedBox(height: 10.0,),
                    TextFormField(
                      controller: _longitude,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Longitude',
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (value) => setState(() => longitude = value!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: 5.0,
          ),
          SizedBox(
            height: 5,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _currentLatitude,
                      decoration: InputDecoration(
                        labelText: 'Current Latitude',
                        filled: true,
                        fillColor: Colors.yellow[100],
                        contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Current Latitude is required';
                        }
                        // If you want to validate numeric format:
                        final num? lat = num.tryParse(value);
                        if (lat == null) {
                          return 'Latitude must be a number';
                        }
                        if (lat < -90 || lat > 90) {
                          return 'Latitude must be between -90 and 90';
                        }
                        return null;
                      },
                      onSaved: (value) => setState(() => getLatitude = value!),
                    ),
                    SizedBox(height: 10.0,),
                    TextFormField(
                      controller: _currentLongitude,
                      decoration: InputDecoration(
                        labelText: 'Current Longitude',
                        filled: true,
                        fillColor: Colors.yellow[100],
                        contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Current Longitude is required';
                        }
                        final num? lng = num.tryParse(value);
                        if (lng == null) {
                          return 'Longitude must be a number';
                        }
                        if (lng < -180 || lng > 180) {
                          return 'Longitude must be between -180 and 180';
                        }
                        return null;
                      },
                      onSaved: (value) => setState(() => getLongitude = value!),
                    ),
                    TextButton(
                      onPressed: () => _checkPermissionsAndFetchLocation(context),
                      child: Text('>> Get location'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.0,),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        readOnly: true,
                        controller: _barcode,
                        decoration: InputDecoration(
                          labelText: 'Barcode',
                          contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Barcode is required';
                          }
                          if (value.length < 5) {
                            return 'Barcode must be at least 5 characters';
                          }
                          // Optional: allow only numbers
                          if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                            return 'Barcode must contain only digits';
                          }
                          return null;
                        },
                        onSaved: (value) => setState(() => barcode = value!),
                      ),
                      TextButton(
                        onPressed: () async {
                          String? res = await SimpleBarcodeScanner.scanBarcode(
                            context,
                            barcodeAppBar: const BarcodeAppBar(
                              appBarTitle: 'Test',
                              centerTitle: false,
                              enableBackButton: true,
                              backButtonIcon: Icon(Icons.arrow_back_ios),
                            ),
                            isShowFlashIcon: true,
                            delayMillis: 500,
                            cameraFace: CameraFace.back,
                            scanFormat: ScanFormat.ONLY_BARCODE,
                          );

                          // Avoid capturing -1 when user cancels
                          if (res != null && res != "-1") {
                            setState(() {
                              result = res;
                              _barcode.text = result;
                            });
                          } else {
                            // Optional: clear or ignore if canceled
                            debugPrint("Scan canceled, no barcode captured.");
                          }
                        },
                        child: const Text('>> Scan Barcode'),
                      ),
                    ],
                  )
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue
                  ),
                  onPressed: () {
                    if (_formRiverSample1.currentState!.validate()) {
                      _formRiverSample1.currentState!.save();

                      setState(() {
                        _form1 = false;
                        _form2 = true;
                        _form3 = false;
                        _form4 = false;
                      });
                    }
                  },
                  child: Text('Proceed',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
                ),
              ),
            ],
          ),
          SizedBox(height: 50,),
        ],
      ),
    );
  }

  Widget _buildForm2() {
    return Form(
      key: _formRiverSample2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(':: Manual Info',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Weather'),
              ),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField(
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  value: _weather.isNotEmpty ? _weather : null,
                  items: <String>['Clear', 'Cloudy', 'Rainy']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _weather = value.toString();
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Choose weather';
                    }
                    return null; // no error
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 5,),
          _image1 == null ? Text(_img1,style: TextStyle(color: Colors.red,fontWeight: FontWeight.bold),)
              : SizedBox(width: 1.0,),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text('Photo (Left)'),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: _takePicture1,
                        icon: Icon(
                          size: 30,
                          Icons.picture_in_picture,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () {
                          _takePicture1a(ImageSource.gallery);
                        },
                        icon: Icon(
                          size: 30,
                          Icons.collections,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          isLoadingImg1 ? Center(
            child: CircularProgressIndicator(),
          ) : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _image1 != null
                  ? Column(
                children: [
                  SingleChildScrollView(
                    //scrollDirection: Axis.horizontal,
                    child: Container(
                      alignment: Alignment.center,
                      child: Center(
                        child: Image.file(
                          _image1!,
                          width: 300,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: IconButton(
                          onPressed: _deletePicture1,
                          icon: Icon(
                            size: 40,
                            color: Colors.red,
                            Icons.delete_forever_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
                  : Text("--No image captured yet--",style: TextStyle(fontSize: 12,color: Colors.red),),
            ],
          ),
          SizedBox(height: 5,),

          _image1 == null ? Text(_img1,style: TextStyle(color: Colors.red,fontWeight: FontWeight.bold),)
              : SizedBox(width: 1.0,),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text('Photo (Right)'),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: _takePicture2,
                        icon: Icon(
                          size: 30,
                          Icons.picture_in_picture,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () {
                          _takePicture2a(ImageSource.gallery);
                        },
                        icon: Icon(
                          size: 30,
                          Icons.collections,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          isLoadingImg2 ? Center(
            child: CircularProgressIndicator(),
          ) : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _image2 != null
                  ? Column(
                children: [
                  SingleChildScrollView(
                    //scrollDirection: Axis.horizontal,
                    child: Container(
                      alignment: Alignment.center,
                      child: Center(
                        child: Image.file(
                          _image2!,
                          width: 300,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: IconButton(
                          onPressed: _deletePicture2,
                          icon: Icon(
                            size: 40,
                            color: Colors.red,
                            Icons.delete_forever_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
                  : Text("--No image captured yet--",style: TextStyle(fontSize: 12,color: Colors.red),),
            ],
          ),
          SizedBox(height: 5,),

          _image3 == null ? Text(_img3,style: TextStyle(color: Colors.red,fontWeight: FontWeight.bold),)
              : SizedBox(width: 1.0,),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text('Photo (Bottom)'),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: _takePicture3,
                        icon: Icon(
                          size: 30,
                          Icons.picture_in_picture,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () {
                          _takePicture3a(ImageSource.gallery);
                        },
                        icon: Icon(
                          size: 30,
                          Icons.collections,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          isLoadingImg3 ? Center(
            child: CircularProgressIndicator(),
          ) : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _image3 != null
                  ? Column(
                children: [
                  SingleChildScrollView(
                    //scrollDirection: Axis.horizontal,
                    child: Container(
                      alignment: Alignment.center,
                      child: Center(
                        child: Image.file(
                          _image3!,
                          width: 300,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: IconButton(
                          onPressed: _deletePicture3,
                          icon: Icon(
                            size: 40,
                            color: Colors.red,
                            Icons.delete_forever_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
                  : Text("--No image captured yet--",style: TextStyle(fontSize: 12,color: Colors.red),),
            ],
          ),
          SizedBox(height: 5,),

          _image4 == null ? Text(_img4,style: TextStyle(color: Colors.red,fontWeight: FontWeight.bold),)
              : SizedBox(width: 1.0,),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text('Photo (Front)'),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: _takePicture4,
                        icon: Icon(
                          size: 30,
                          Icons.picture_in_picture,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () {
                          _takePicture4a(ImageSource.gallery);
                        },
                        icon: Icon(
                          size: 30,
                          Icons.collections,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          isLoadingImg4 ? Center(
            child: CircularProgressIndicator(),
          ) : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _image4 != null
                  ? Column(
                children: [
                  SingleChildScrollView(
                    //scrollDirection: Axis.horizontal,
                    child: Container(
                      alignment: Alignment.center,
                      child: Center(
                        child: Image.file(
                          _image4!,
                          width: 300,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: IconButton(
                          onPressed: _deletePicture4,
                          icon: Icon(
                            size: 40,
                            color: Colors.red,
                            Icons.delete_forever_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
                  : Text("--No image captured yet--",style: TextStyle(fontSize: 12,color: Colors.red),),
            ],
          ),
          SizedBox(height: 5,),

          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text('Photo (Optional 1)'),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: _takePicture5,
                        icon: Icon(
                          size: 30,
                          Icons.picture_in_picture,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () {
                          _takePicture5a(ImageSource.gallery);
                        },
                        icon: Icon(
                          size: 30,
                          Icons.collections,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          isLoadingImg5 ? Center(
            child: CircularProgressIndicator(),
          ) : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _image5 != null
                  ? Column(
                children: [
                  SingleChildScrollView(
                    //scrollDirection: Axis.horizontal,
                    child: Container(
                      alignment: Alignment.center,
                      child: Center(
                        child: Image.file(
                          _image5!,
                          width: 300,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: IconButton(
                          onPressed: _deletePicture5,
                          icon: Icon(
                            size: 40,
                            color: Colors.red,
                            Icons.delete_forever_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
                  : Text("--No image captured yet--",style: TextStyle(fontSize: 12,color: Colors.red),),
            ],
          ),
          SizedBox(height: 5,),

          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text('Photo (Optional 2)'),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: _takePicture6,
                        icon: Icon(
                          size: 30,
                          Icons.picture_in_picture,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () {
                          _takePicture6a(ImageSource.gallery);
                        },
                        icon: Icon(
                          size: 30,
                          Icons.collections,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          isLoadingImg6 ? Center(
            child: CircularProgressIndicator(),
          ) : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _image6 != null
                  ? Column(
                children: [
                  SingleChildScrollView(
                    //scrollDirection: Axis.horizontal,
                    child: Container(
                      alignment: Alignment.center,
                      child: Center(
                        child: Image.file(
                          _image6!,
                          width: 300,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: IconButton(
                          onPressed: _deletePicture6,
                          icon: Icon(
                            size: 40,
                            color: Colors.red,
                            Icons.delete_forever_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
                  : Text("--No image captured yet--",style: TextStyle(fontSize: 12,color: Colors.red),),
            ],
          ),
          SizedBox(height: 5,),

          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text('Photo (Optional 3)'),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: _takePicture7,
                        icon: Icon(
                          size: 30,
                          Icons.picture_in_picture,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () {
                          _takePicture7a(ImageSource.gallery);
                        },
                        icon: Icon(
                          size: 30,
                          Icons.collections,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          isLoadingImg7 ? Center(
            child: CircularProgressIndicator(),
          ) : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _image7 != null
                  ? Column(
                children: [
                  SingleChildScrollView(
                    //scrollDirection: Axis.horizontal,
                    child: Container(
                      alignment: Alignment.center,
                      child: Center(
                        child: Image.file(
                          _image7!,
                          width: 300,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: IconButton(
                          onPressed: _deletePicture7,
                          icon: Icon(
                            size: 40,
                            color: Colors.red,
                            Icons.delete_forever_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
                  : Text("--No image captured yet--",style: TextStyle(fontSize: 12,color: Colors.red),),
            ],
          ),
          SizedBox(height: 5,),

          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text('Photo (Optional 4)'),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: _takePicture8,
                        icon: Icon(
                          size: 30,
                          Icons.picture_in_picture,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () {
                          _takePicture8a(ImageSource.gallery);
                        },
                        icon: Icon(
                          size: 30,
                          Icons.collections,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          isLoadingImg8 ? Center(
            child: CircularProgressIndicator(),
          ) : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _image8 != null
                  ? Column(
                children: [
                  SingleChildScrollView(
                    //scrollDirection: Axis.horizontal,
                    child: Container(
                      alignment: Alignment.center,
                      child: Center(
                        child: Image.file(
                          _image8!,
                          width: 300,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: IconButton(
                          onPressed: _deletePicture8,
                          icon: Icon(
                            size: 40,
                            color: Colors.red,
                            Icons.delete_forever_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
                  : Text("--No image captured yet--",style: TextStyle(fontSize: 12,color: Colors.red),),
            ],
          ),
          SizedBox(height: 5,),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Event remarks'),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.yellow[100],
                    contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
                  ),
                  onSaved: (value) => setState(() => eventRemark = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 5,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Lab remarks'),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.yellow[100],
                    contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
                  ),
                  onSaved: (value) => setState(() => labRemark = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey
                  ),
                  onPressed: () {
                    setState(() {
                      _form1 = true;
                      _form2 = false;
                      _form3 = false;
                      _form4 = false;
                    });
                  },
                  child: Text('Cancel'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue
                  ),
                  onPressed: () {
                    if (_formRiverSample2.currentState!.validate()) {
                      _formRiverSample2.currentState!.save();

                      if (_image1==null) {
                        setState(() {
                          _img1 = 'IMAGE IS REQUIRED?';
                        });
                      }

                      if (_image2==null) {
                        setState(() {
                          _img2 = 'IMAGE IS REQUIRED?';
                        });
                      }

                      if (_image3==null) {
                        setState(() {
                          _img3 = 'IMAGE IS REQUIRED?';
                        });
                      }

                      if (_image4==null) {
                        setState(() {
                          _img4 = 'IMAGE IS REQUIRED?';
                        });
                      }

                      else {
                        setState(() {
                          _form1 = false;
                          _form2 = false;
                          _form3 = true;
                          _form4 = false;
                        });
                      }
                    }
                  },
                  child: Text('Proceed'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForm3() {
    return Form(
      key: _formRiverSample3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 5.0,),
          Text(':: Station Info',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Station ID'),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _stationID,
                  readOnly: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[300],
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => setState(() => stationID = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Name'),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _riverName,
                  readOnly: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[300],
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => setState(() => riverName = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Latitude'),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  readOnly: true,
                  controller: _currentLatitude,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[300],
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => setState(() => latitude = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Longitude'),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _currentLongitude,
                  readOnly: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[300],
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => setState(() => longitude = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.0,),
          Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              gradient: LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF007AFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                ':: DATA CAPTURE ::',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    _connectToSerial();
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [Color(0xFF4A90E2), Color(0xFF0050AC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4A90E2).withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.usb_rounded, color: Colors.white, size: 28),
                        SizedBox(height: 8),
                        Text(
                          'Serial Communication',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    _onRequestBluetooth();
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [Color(0xFF00BFA6), Color(0xFF00796B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF00BFA6).withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bluetooth_rounded, color: Colors.white, size: 28),
                        SizedBox(height: 8),
                        Text(
                          'Bluetooth Communication',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.0,),

          _isDeviceUSB ? Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    SizedBox(height: 8),
                    //Text("Available Devices:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text("Connect to Sonde via Serial", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    ValueListenableBuilder<SerialConnectionState>(
                      valueListenable: _serialManager.connectionState,
                      builder: (context, state, child) {
                        Color statusColor = Colors.red;
                        String statusText = "Disconnected";
                        if (state == SerialConnectionState.connected) {
                          statusColor = Colors.green;
                          statusText = "Connected to ${_serialManager.connectedDeviceName}";
                        } else if (state == SerialConnectionState.connecting) {
                          statusColor = Colors.orange;
                          statusText = "Connecting...";
                        }
                        return Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16));
                      },
                    ),
                    SizedBox(height: 5),
                    Text(_statusMessageSerial, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    SizedBox(height: 5),
                    _isLoadingSerial
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                      icon: const Icon(Icons.usb),
                      label: Text(_serialManager.connectionState.value == SerialConnectionState.connected ? 'Disconnect' : 'Connect to Serial Device'),
                      onPressed: () {
                        if (_serialManager.connectionState.value == SerialConnectionState.connected) {
                          _serialManager.disconnect();
                          setState(() {
                            _statusMessageSerial = 'Disconnected';
                          });
                        } else {
                          _connectToDevice();
                        }
                      },
                    ),
                    SizedBox(height: 5,),
                  ],
                ),
              ),
            ],
          ) : SizedBox(width: 0.0,),

          _isDeviceBluetooth ? Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Connect to Sonde via Bluetooth", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ValueListenableBuilder<BluetoothConnectionState>(
                  valueListenable: _bluetoothManager.connectionState,
                  builder: (context, state, child) {
                    Color statusColor = Colors.red;
                    String statusText = "Disconnected";
                    if (state == BluetoothConnectionState.connected) {
                      statusColor = Colors.green;
                      statusText = "Connected to ${_bluetoothManager.connectedDeviceName}";

                      List<String> words = statusText.split(" ");
                      String lastWord = words.last;
                      _uuidData.text = lastWord;


                    } else if (state == BluetoothConnectionState.connecting) {
                      statusColor = Colors.orange;
                      statusText = "Connecting...";
                    }
                    return Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16));
                  },
                ),
                SizedBox(height: 5),
                _isLoadingBluetooth
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                  icon: const Icon(Icons.bluetooth_searching),
                  label: Text(_bluetoothManager.connectionState.value == BluetoothConnectionState.connected ? 'Disconnect' : 'Connect to Bluetooth Device'),
                  onPressed: () {
                    if (_bluetoothManager.connectionState.value == BluetoothConnectionState.connected) {
                      _bluetoothManager.disconnect();
                    } else {
                      _connectToBluetooth();
                    }
                  },
                ),
                SizedBox(height: 5.0,),
              ],
            ),
          ) : SizedBox(width: 1.0,),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Sonde ID'),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  readOnly: true,
                  controller: _uuidData,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Required"; // Error shown below field
                    }
                    return null; // No error
                  },
                  onSaved: (value) => setState(() => sondeID = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Date'),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  readOnly: true,
                  controller: _dateCapture,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => setState(() => dateCapture = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Time'),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  readOnly: true,
                  controller: _timeCapture,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => setState(() => timeCapture = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Container(
            width: MediaQuery.of(context).size.width,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            child: Text('Parameters',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),),
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Oxygen concentration (mg/L)'),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  readOnly: true,
                  controller: _doData1,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Required"; // Error shown below field
                    }
                    return null; // No error
                  },
                  onSaved: (value) => setState(() => doValue1 = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Oxygen saturation (% Sat)'),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  readOnly: true,
                  controller: _doData2,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Required"; // Error shown below field
                    }
                    return null; // No error
                  },
                  onSaved: (value) => setState(() => doValue2 = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('pH'),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  readOnly: true,
                  controller: _phData,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Required"; // Error shown below field
                    }
                    return null; // No error
                  },
                  onSaved: (value) => setState(() => pH = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Conductivity (us/cm)'),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  readOnly: true,
                  controller: _ecData,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Required"; // Error shown below field
                    }
                    return null; // No error
                  },
                  onSaved: (value) => setState(() => ec = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Salinity (ppt)'),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  readOnly: true,
                  controller: _sanilityData,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Required"; // Error shown below field
                    }
                    return null; // No error
                  },
                  onSaved: (value) => setState(() => salinity = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Temperature'),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  readOnly: true,
                  controller: _tempData,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Required"; // Error shown below field
                    }
                    return null; // No error
                  },
                  onSaved: (value) => setState(() => temperature = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Turbidity (NTU)'),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  readOnly: true,
                  controller: _turbidityData,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Required"; // Error shown below field
                    }
                    return null; // No error
                  },
                  onSaved: (value) => setState(() => turbidity = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Flowrate (m/s)'),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  readOnly: true,
                  controller: _flowRate,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Required"; // Error shown below field
                    }
                    return null; // No error
                  },
                  onSaved: (value) => setState(() => flowRate = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Total Dissolve Solid'),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  readOnly: true,
                  controller: _dissolvedSolid,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Required"; // Error shown below field
                    }
                    return null; // No error
                  },
                  onSaved: (value) => setState(() => totalDissolve = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Total Suspended Solid'),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  readOnly: true,
                  controller: _suspendedSolid,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Required"; // Error shown below field
                    }
                    return null; // No error
                  },
                  onSaved: (value) => setState(() => totalSuspended = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Battery status'),
              ),
              Expanded(
                flex: 3,
                child: TextFormField(
                  readOnly: true,
                  controller: _batteryData,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 20.0, 10.0),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Required"; // Error shown below field
                    }
                    return null; // No error
                  },
                  onSaved: (value) => setState(() => battery = value!),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey
                  ),
                  onPressed: () {
                    setState(() {
                      _form1 = false;
                      _form2 = true;
                      _form3 = false;
                      _form4 = false;
                    });
                  },
                  child: Text('Cancel'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue
                  ),
                  onPressed: () {
                    if(_formRiverSample3.currentState!.validate()) {
                      _formRiverSample3.currentState!.save();

                      setState(() {
                        _form1 = false;
                        _form2 = false;
                        _form3 = false;
                        _form4 = true;
                      });
                    }
                  },
                  child: Text('Proceed',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildForm4() {
    return Form(
      key: _formRiverSample4,
      child: Column(
        children: [
          Container(
            height: 50,
            child: Center(
              child: Text(':: REPORT SUMMARY ::',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
            ),
          ),
          Divider(),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Report'),
              ),
              Expanded(
                flex: 3,
                child: Text(_reportID.text),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('1st Sampler'),
              ),
              Expanded(
                flex: 3,
                child: Text(firstSamplerName!),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('2nd Sampler'),
              ),
              Expanded(
                flex: 3,
                child: Text(secondSamplerName!),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Date'),
              ),
              Expanded(
                flex: 3,
                child: Text(sampleDate!),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Time'),
              ),
              Expanded(
                flex: 3,
                child: Text(sampleTime!),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Sampling type'),
              ),
              Expanded(
                flex: 3,
                child: Text(_type),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('State'),
              ),
              Expanded(
                flex: 3,
                child: Text(_selectedStateName!),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Station ID & Name'),
              ),
              Expanded(
                flex: 3,
                child: Text(stationID! +' - '+ riverName!),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Location'),
              ),
              Expanded(
                flex: 3,
                child: Text(latitude!+","+longitude!),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Current location'),
              ),
              Expanded(
                flex: 3,
                child: Text(getLatitude!+","+getLongitude!),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Barcode'),
              ),
              Expanded(
                flex: 3,
                child: Text(barcode!),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Container(
            width: MediaQuery.of(context).size.width,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            child: Text('Parameters',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),),
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text('Oxygen concentration (mg/L)'),
              ),
              Expanded(
                flex: 2,
                child: Text(doValue1),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text('Oxygen saturation (% Sat)'),
              ),
              Expanded(
                flex: 2,
                child: Text(doValue2),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text('pH'),
              ),
              Expanded(
                flex: 2,
                child: Text(pH),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text('Conductivity'),
              ),
              Expanded(
                flex: 2,
                child: Text(ec),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text('Salinity (ppt)'),
              ),
              Expanded(
                flex: 2,
                child: Text(salinity),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text('Temparature'),
              ),
              Expanded(
                flex: 2,
                child: Text(temperature),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text('Tubidity (NTU)'),
              ),
              Expanded(
                flex: 2,
                child: Text(turbidity),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text('Flowrate (m/s)'),
              ),
              Expanded(
                flex: 2,
                child: Text(flowRate),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text('Total Dissolve Solid'),
              ),
              Expanded(
                flex: 2,
                child: Text(totalDissolve),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text('Total Suspended Solid'),
              ),
              Expanded(
                flex: 2,
                child: Text(totalSuspended),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text('Battery Status'),
              ),
              Expanded(
                flex: 2,
                child: Text(battery),
              ),
            ],
          ),
          SizedBox(height: 5.0,),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue
                  ),
                  onPressed: () {
                    setState(() {
                      _form1 = false;
                      _form2 = false;
                      _form3 = true;
                      _form4 = false;
                    });
                  },
                  child: Text('Cancel',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
                ),
              ),
              SizedBox(width: 5.0,),
              Expanded(
                child: connectionStatus ? ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue
                  ),
                  onPressed: () {
                    if (_formRiverSample4.currentState!.validate()) {
                      _formRiverSample4.currentState!.save();
                      _sendDataServer();
                    }
                  },
                  child: Text('Send PSTW',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
                ) :
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue
                  ),
                  onPressed: () {
                    _sendDataLocalStorage();
                  },
                  child: Text('Local Storage',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
                ),
              ),
            ],
          ),
          SizedBox(height: 30,)
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isDisplay ? Container(
      height: MediaQuery.of(context).size.height,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          Text('Data transferred in progress...please wait')
        ],
      ),
    )
        : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('River: Schedule Sampling',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),),
        SizedBox(height: 10,),
        if (_form1 == true) ... [
          _buildForm1(),
        ]
        else if (_form2 == true) ... [
          _buildForm2(),
        ]
        else if (_form3 == true) ... [
            _buildForm3(),
          ]
          else if (_form4 == true) ... [
              _buildForm4(),
            ]
      ],
    );
  }

  void _onRequestBluetooth() {

    _requestPermissions().then((_) => _scanBluetooth());
    // bluetooth connection
  }

  void _scanBluetooth() {

    setState(() {
      _isDeviceUSB = false;
      _isDeviceBluetooth = true;
    });

    _bluetoothManager.connectionState.addListener(() {
      if (mounted) setState(() {});
    });

    // Listen for incoming data and store it in our "mailbox".
    _bluetoothManager.dataStream.listen((Map<String, double> readings) {
      if (mounted) {
        setState(() {

          _latestReadingsBluetooth = readings;

          _doData1.text = (readings['Optical Dissolved Oxygen: Compensated mg/L'] ?? 0.0).toStringAsFixed(2);
          _doData2.text = (readings['Optical Dissolved Oxygen: Compensated % Saturation'] ?? 0.0).toStringAsFixed(2);
          _phData.text = (readings['PH: PH units'] ?? 0.0).toStringAsFixed(2);
          _tempData.text = (readings['External Temp: Degrees Celcius'] ?? 0.0).toStringAsFixed(2);
          _ecData.text = (readings['Conductivity: us/cm'] ?? 0.0).toStringAsFixed(2);
          _sanilityData.text = (readings['Conductivity: Salinity'] ?? 0.0).toStringAsFixed(2);
          _turbidityData.text = (readings['Turbidity: FNU'] ?? 0.0).toStringAsFixed(2);
          _dissolvedSolid.text = (readings['Conductivity:TDS mg/L'] ?? 0.0).toStringAsFixed(2);
          _suspendedSolid.text = (readings['Turbidity: TSS'] ?? 0.0).toStringAsFixed(2);
          _batteryData.text = (readings['Sonde: Battery Voltage'] ?? 0.0).toStringAsFixed(2);

          //_uuidData.text = (readings['EXO1 - 4 port Sonde']?.toInt() ?? 0).toString();

        });
      }
    });

  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  void _connectToBluetooth() async {
    setState(() => _isLoadingBluetooth = true);
    // Get the list of paired devices.
    final devices = await _bluetoothManager.getPairedDevices();

    if (devices.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No paired usb devices found.")));
      setState(() => _isLoadingBluetooth = false);
      return;
    }

    // Show the selection dialog.
    final selectedDevice = await showBluetoothDeviceListDialog(context: context, devices: devices);

    if (selectedDevice != null) {
      // If a device is selected, connect to it.
      await _bluetoothManager.connect(selectedDevice);
      // If connection is successful, start the auto-refresh.
      if (_bluetoothManager.connectionState.value == BluetoothConnectionState.connected) {
        _bluetoothManager.startAutoReading(interval: const Duration(seconds: 5));
      }
    }
    setState(() => _isLoadingBluetooth = false);
  }

  // connect to serial
  final SerialManager _serialManager = SerialManager();
  bool _isLoadingSerial = false;
  String _statusMessageSerial = 'Please connect to a device.';
  Map<String, double> _latestReadingsSerial = {};
  Timer? _dataTimeoutTimer;
  static const platform = MethodChannel('com.example.app_mms/usb');


  void _connectToSerial() {
    setState(() {
      _isDeviceUSB = true;
      _isDeviceBluetooth = false;
    });

    _serialManager.connectionState.addListener(() {
      if (mounted) setState(() {});
    });

    _serialManager.dataStream.listen((Map<String, double> readings1) {
      _dataTimeoutTimer?.cancel();

      if (mounted) {

        setState(() {

          _latestReadingsSerial = readings1;
          _statusMessageSerial = 'Data received at ${TimeOfDay.now().format(context)}';

          _doData1.text = (readings1['Optical Dissolved Oxygen: Compensated mg/L'] ?? 0.0).toStringAsFixed(2);
          _doData2.text = (readings1['Optical Dissolved Oxygen: Compensated % Saturation'] ?? 0.0).toStringAsFixed(2);
          _phData.text = (readings1['PH: PH units'] ?? 0.0).toStringAsFixed(2);
          _tempData.text = (readings1['External Temp: Degrees Celcius'] ?? 0.0).toStringAsFixed(2);
          _ecData.text = (readings1['Conductivity: us/cm'] ?? 0.0).toStringAsFixed(2);
          _sanilityData.text = (readings1['Conductivity: Salinity'] ?? 0.0).toStringAsFixed(2);
          _turbidityData.text = (readings1['Turbidity: FNU'] ?? 0.0).toStringAsFixed(2);
          _flowRate.text = (readings1['Velocity (m/s)'] ?? 0.0).toStringAsFixed(2);
          _dissolvedSolid.text = (readings1['Conductivity:TDS mg/L'] ?? 0.0).toStringAsFixed(2);
          _suspendedSolid.text = (readings1['Turbidity: TSS'] ?? 0.0).toStringAsFixed(2);
          _batteryData.text = (readings1['Sonde: Battery Voltage'] ?? 0.0).toStringAsFixed(2);
          _uuidData.text = GlobalState().serialNumber.toString();

        });

        _dataTimeoutTimer = Timer(const Duration(seconds: 6), () {
          if (mounted) {
            print("Data timeout: No new data for 6 seconds. Clearing view.");
            setState(() {
              _latestReadingsSerial.clear();
              _statusMessageSerial = "Awaiting next data refresh...";
            });
          }
        });
      }
    });
  }

  Future<bool> requestUsbPermission(UsbDevice device) async {
    try {
      final result = await platform.invokeMethod('requestUsbPermission', {
        'deviceName': device.productName ?? 'Unknown Device',
        'vid': device.vid,
        'pid': device.pid,
      });
      print("Permission requested for ${device.productName}: $result");
      if (mounted) {
        setState(() {
          _statusMessageSerial = 'Permission requested for ${device.productName}';
          print('Testing...' + device.vid.toString());

          //_uuidData.text = device.serial.toString();
        });
      }
      return result == true;
    } on PlatformException catch (e) {
      print("Failed to request USB permission: ${e.message}");
      if (mounted) {
        setState(() {
          _statusMessageSerial = 'Failed to request permission: ${e.message}';
        });
      }
      return false;
    }
  }

  void _connectToDevice() async {
    // FIX: Show loading indicator and initial status message immediately
    setState(() {
      _isLoadingSerial = true;
      _statusMessageSerial = 'Searching for devices...';
    });

    // Use a short delay to allow the UI to update before starting heavy work
    await Future.delayed(const Duration(milliseconds: 100));

    final devices = await _serialManager.getAvailableDevices();
    if (devices.isEmpty && mounted) {
      setState(() {
        _statusMessageSerial = 'No serial devices found';
        _isLoadingSerial = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No serial devices found.")));
      return;
    }

    final selectedDevice = await showSerialPortListDialog(context: context, devices: devices);
    if (selectedDevice == null && mounted) {
      setState(() {
        _isLoadingSerial = false;
        _statusMessageSerial = 'Device selection canceled.';
      });
      return;
    }

    if (selectedDevice != null) {
      // FIX: Update status before requesting permission
      setState(() {
        _statusMessageSerial = 'Requesting permission for ${selectedDevice.productName}...';
      });
      await Future.delayed(const Duration(milliseconds: 100));

      bool permissionGranted = await requestUsbPermission(selectedDevice);
      if (permissionGranted) {

        setState(() {
          _statusMessageSerial = 'Permission granted. Connecting...';
        });
        await Future.delayed(const Duration(milliseconds: 100));

        try {
          await _serialManager.connect(selectedDevice);

          if (_serialManager.connectionState.value == SerialConnectionState.connected && mounted) {

            setState(() {
              _statusMessageSerial = 'Connected to ${selectedDevice.productName}';
              _isLoadingSerial = false; // Turn off loading indicator on success
            });

            //_uuidData.text = selectedDevice.serial.toString();
            _serialManager.startAutoReading(interval: const Duration(seconds: 5));

            print("_serialManager.dataStream type: ${_serialManager.dataStream.runtimeType}");

            // get data from sonde
            _serialManager.dataStream.listen((Map<String, double> data) {
              print("Parsed sensor map: $data");
              //_uuidData.text = "abc" + data.toString();
              //_statusMessageSerial = data.toString();
            });


          } else if(mounted) {
            setState(() {
              _statusMessageSerial = 'Connection failed after permission grant.';
              _isLoadingSerial = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _statusMessageSerial = 'Connection failed: $e';
              _isLoadingSerial = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _statusMessageSerial = 'Permission not granted for ${selectedDevice.productName}';
            _isLoadingSerial = false;
          });
        }
      }
    }
  }

  void _sendDataServer() async {

    setState(() {
      _isDisplay = true;
    });

    final response = await http.post(
      Uri.parse('https://mmsv2.pstw.com.my/api/river/api-post-river.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "action": "river-is-sampling",
        "reportID": _reportID.text.toString(),"firstSampler": firstSamplerName!,
        "secondSampler": secondSamplerName!,
        "dateController": sampleDate!,"timeController": sampleTime!,"type":_type,
        "stationName": riverName!,"sampleCode": barcode!,
        "latitude": getLatitude!,"longitude": getLongitude!,
        "distance":_distanceDevice.toString(),
        "weather": _weather,
        "eventRemark":eventRemark!,"labRemark":labRemark!,
        "sondeID":sondeID,"dateCapture":dateCapture,"timeCapture":timeCapture,
        "oxygen1":doValue1,"oxygen2":doValue2,
        "pH":pH,"ec":ec,"salinity":salinity,"temp":temperature,
        "turbidity":turbidity,"flowrate":flowRate,
        "totalDissolve":totalDissolve,"totalSuspended":totalSuspended,
        "battery":battery, "stationID":stationID!,
        "timestamp":timestampResult1!
      }),
    );
    var data = json.decode(response.body);


    if (data['statusCode']==201) {

      if (_distanceDevice > 50) {

        final smtpServer = gmail('pstwitdept@gmail.com', 'orfovnkgysytzseo'); // Use an App Password

        for (String email in emailList) {
          final message = Message()
            ..from = Address('pstwitdept@gmail.com', 'Notification : ')
            ..recipients.add(email)
            ..subject = 'MMS: Monitoring distance'
            ..text = '1st Sampler Name : ' + firstSamplerName.toString() +
                '\n2nd Sampler : ' + secondSamplerName.toString() +
                '\nStation ID : ' + stationID! +
                '\nLocation Name : ' + riverName! +
                '\nDistance : ' + _distanceDevice.toString();

          try {
            final sendReport = await send(message, smtpServer);
            print('Email sent to $email: ' + sendReport.toString());
          } catch (e) {
            print('Error sending email to $email: $e');
          }
        }

      }

      // upload picture
      if (_image1 != null) { // upload image 1
        final uri = Uri.parse("https://mmsv2.pstw.com.my/upload-image.php?action=river_is_sampling&id="+stationID!+"&timestamp="+timestampResult2!+"&description=left_side");
        var request = http.MultipartRequest('POST', uri);
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _image1!.path,
          filename: path.basename(_image1!.path),
        ));

        var response1 = await request.send();
      }

      // upload picture
      if (_image2 != null) { // upload image 2
        final uri = Uri.parse("https://mmsv2.pstw.com.my/upload-image.php?action=river_is_sampling&id="+stationID!+"&timestamp="+timestampResult2!+"&description=right_side");
        var request = http.MultipartRequest('POST', uri);
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _image2!.path,
          filename: path.basename(_image2!.path),
        ));

        var response1 = await request.send();
      }

      // upload picture
      if (_image3 != null) { // upload image 3
        final uri = Uri.parse("https://mmsv2.pstw.com.my/upload-image.php?action=river_is_sampling&id="+stationID!+"&timestamp="+timestampResult2!+"&description=bottom_side");
        var request = http.MultipartRequest('POST', uri);
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _image3!.path,
          filename: path.basename(_image3!.path),
        ));

        var response1 = await request.send();
      }

      // upload picture
      if (_image4 != null) { // upload image 4
        final uri = Uri.parse("https://mmsv2.pstw.com.my/upload-image.php?action=river_is_sampling&id="+stationID!+"&timestamp="+timestampResult2!+"&description=front_side");
        var request = http.MultipartRequest('POST', uri);
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _image4!.path,
          filename: path.basename(_image4!.path),
        ));

        var response1 = await request.send();
      }

      // upload picture
      if (_image5 != null) { // upload image 5
        final uri = Uri.parse("https://mmsv2.pstw.com.my/upload-image.php?action=river_is_sampling&id="+stationID!+"&timestamp="+timestampResult2!+"&description=optional1");
        var request = http.MultipartRequest('POST', uri);
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _image5!.path,
          filename: path.basename(_image5!.path),
        ));

        var response1 = await request.send();
      }

      // upload picture
      if (_image6 != null) { // upload image 6
        final uri = Uri.parse("https://mmsv2.pstw.com.my/upload-image.php?action=river_is_sampling&id="+stationID!+"&timestamp="+timestampResult2!+"&description=optional2");
        var request = http.MultipartRequest('POST', uri);
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _image6!.path,
          filename: path.basename(_image6!.path),
        ));

        var response1 = await request.send();
      }

      // upload picture
      if (_image7 != null) { // upload image 7
        final uri = Uri.parse("https://mmsv2.pstw.com.my/upload-image.php?action=river_is_sampling&id="+stationID!+"&timestamp="+timestampResult2!+"&description=optional3");
        var request = http.MultipartRequest('POST', uri);
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _image7!.path,
          filename: path.basename(_image7!.path),
        ));

        var response1 = await request.send();
      }

      // upload picture
      if (_image8 != null) { // upload image 8
        final uri = Uri.parse("https://mmsv2.pstw.com.my/upload-image.php?action=river_is_sampling&id="+stationID!+"&timestamp="+timestampResult2!+"&description=optional4");
        var request = http.MultipartRequest('POST', uri);
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _image8!.path,
          filename: path.basename(_image8!.path),
        ));

        var response1 = await request.send();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Data has been saved!",
          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),backgroundColor: Colors.black,),
      );

      setState(() {

        firstSamplerName = '';
        secondSamplerName = '';
        selectedLocalSampler = null;

        _latitude.clear();
        _longitude.clear();
        _currentLatitude.clear();
        _currentLongitude.clear();
        _type = "";
        _weather = "";
        _barcode.clear();

        _basinName.clear();
        _riverName.clear();
        _latitude.clear();
        _longitude.clear();
        _stationID.clear();
        _latitude.clear();
        _longitude.clear();

        selectedLocalState = null;
        _isDisplay = false;
        _isLocation = false;

        _form1 = true;
        _form2 = false;
        _form3 = false;
        _form4 = false;
      });

    }
    else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Data failed to save",
          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),backgroundColor: Colors.red,),
      );

      setState(() {

        firstSamplerName = '';
        secondSamplerName = '';
        selectedLocalSampler = null;

        _latitude.clear();
        _longitude.clear();
        _currentLatitude.clear();
        _currentLongitude.clear();
        _type = "";
        _weather = "";
        _barcode.clear();

        _basinName.clear();
        _riverName.clear();
        _latitude.clear();
        _longitude.clear();
        _stationID.clear();
        _latitude.clear();
        _longitude.clear();

        selectedLocalState = null;
        _isDisplay = false;
        _isLocation = false;

        _form1 = true;
        _form2 = false;
        _form3 = false;
        _form4 = false;

      });

    }
  }

  void _sendDataLocalStorage() async {

    setState(() {
      _isDisplay = true;
    });

    bool success = await db.insertDataRiverISSample(
      tableName: 'tbl_river_is_sampling',
      values: {
        'reportID': _reportID.text.toString(),
        'firstSampler': firstSamplerName!,
        'secondSampler': secondSamplerName!,
        'dateController': sampleDate!,
        'timeController': sampleTime!,
        'type': _type,
        'stationName': riverName!,
        'sampleCode': barcode!,
        'latitude': getLatitude!,
        'longitude': getLongitude!,
        'distance':_distanceDevice.toString(),
        'weather': _weather,
        'eventRemark': eventRemark!,
        'labRemark': labRemark!,
        'sondeID': sondeID,
        'dateCapture': dateCapture,
        'timeCapture': timeCapture,
        'oxygen1': doValue1,
        'oxygen2': doValue2,
        'pH': pH,
        'ec': ec,
        'sanility': salinity,
        'temp': temperature,
        'turbidity': turbidity,
        'flowrate': flowRate,
        'totalDissolve':totalDissolve,
        'totalSuspended': totalSuspended,
        'battery': battery,
        'stationID': stationID!,
        'timestamp': timestampResult1!
      },
    );

    if (success == true) {

      // upload image
      if (_image1 != null) { // upload image 1

        File? _savedImage;
        File imageFile = File(_image1!.path);

        // Get app directory
        Directory appDir = await getApplicationDocumentsDirectory();

        // Create custom folder
        String folderName = "is_sample/"+stationID!;
        Directory customDir = Directory('${appDir.path}/$folderName');
        if (!await customDir.exists()) {
          await customDir.create(recursive: true);
        }

        // Create full image path
        //String fileName = path.basename(_image1!.path);
        String fileExtension = path.extension(_image1!.path);
        String fileName = stationID!+'_'+timestampResult2!+'_left_side'+fileExtension;
        String savedPath = '${customDir.path}/$fileName';

        // Save image
        final savedImage = await imageFile.copy(savedPath);

        setState(() {
          _savedImage = savedImage;
        });

        print("Image saved to: $savedPath");

      }

      // upload image
      if (_image2 != null) { // upload image 2

        File? _savedImage;
        File imageFile = File(_image2!.path);

        // Get app directory
        Directory appDir = await getApplicationDocumentsDirectory();

        // Create custom folder
        String folderName = "is_sample/"+stationID!;
        Directory customDir = Directory('${appDir.path}/$folderName');
        if (!await customDir.exists()) {
          await customDir.create(recursive: true);
        }

        // Create full image path
        //String fileName = path.basename(_image1!.path);
        String fileExtension = path.extension(_image2!.path);
        String fileName = stationID!+'_'+timestampResult2!+'_right_side'+fileExtension;
        String savedPath = '${customDir.path}/$fileName';

        // Save image
        final savedImage = await imageFile.copy(savedPath);

        setState(() {
          _savedImage = savedImage;
        });

        print("Image saved to: $savedPath");

      }

      // upload image
      if (_image3 != null) { // upload image 3

        File? _savedImage;
        File imageFile = File(_image3!.path);

        // Get app directory
        Directory appDir = await getApplicationDocumentsDirectory();

        // Create custom folder
        String folderName = "is_sample/"+stationID!;
        Directory customDir = Directory('${appDir.path}/$folderName');
        if (!await customDir.exists()) {
          await customDir.create(recursive: true);
        }

        // Create full image path
        //String fileName = path.basename(_image1!.path);
        String fileExtension = path.extension(_image3!.path);
        String fileName = stationID!+'_'+timestampResult2!+'_bottom_side'+fileExtension;
        String savedPath = '${customDir.path}/$fileName';

        // Save image
        final savedImage = await imageFile.copy(savedPath);

        setState(() {
          _savedImage = savedImage;
        });

        print("Image saved to: $savedPath");

      }

      // upload image
      if (_image4 != null) { // upload image 4

        File? _savedImage;
        File imageFile = File(_image4!.path);

        // Get app directory
        Directory appDir = await getApplicationDocumentsDirectory();

        // Create custom folder
        String folderName = "is_sample/"+stationID!;
        Directory customDir = Directory('${appDir.path}/$folderName');
        if (!await customDir.exists()) {
          await customDir.create(recursive: true);
        }

        // Create full image path
        //String fileName = path.basename(_image1!.path);
        String fileExtension = path.extension(_image4!.path);
        String fileName = stationID!+'_'+timestampResult2!+'_front_side'+fileExtension;
        String savedPath = '${customDir.path}/$fileName';

        // Save image
        final savedImage = await imageFile.copy(savedPath);

        setState(() {
          _savedImage = savedImage;
        });

        print("Image saved to: $savedPath");

      }

      // upload image
      if (_image5 != null) { // upload image 5

        File? _savedImage;
        File imageFile = File(_image5!.path);

        // Get app directory
        Directory appDir = await getApplicationDocumentsDirectory();

        // Create custom folder
        String folderName = "is_sample/"+stationID!;
        Directory customDir = Directory('${appDir.path}/$folderName');
        if (!await customDir.exists()) {
          await customDir.create(recursive: true);
        }

        // Create full image path
        //String fileName = path.basename(_image1!.path);
        String fileExtension = path.extension(_image5!.path);
        String fileName = stationID!+'_'+timestampResult2!+'_optional1'+fileExtension;
        String savedPath = '${customDir.path}/$fileName';

        // Save image
        final savedImage = await imageFile.copy(savedPath);

        setState(() {
          _savedImage = savedImage;
        });

        print("Image saved to: $savedPath");

      }

      // upload image
      if (_image6 != null) { // upload image 6

        File? _savedImage;
        File imageFile = File(_image6!.path);

        // Get app directory
        Directory appDir = await getApplicationDocumentsDirectory();

        // Create custom folder
        String folderName = "is_sample/"+stationID!;
        Directory customDir = Directory('${appDir.path}/$folderName');
        if (!await customDir.exists()) {
          await customDir.create(recursive: true);
        }

        // Create full image path
        //String fileName = path.basename(_image1!.path);
        String fileExtension = path.extension(_image6!.path);
        String fileName = stationID!+'_'+timestampResult2!+'_optional2'+fileExtension;
        String savedPath = '${customDir.path}/$fileName';

        // Save image
        final savedImage = await imageFile.copy(savedPath);

        setState(() {
          _savedImage = savedImage;
        });

        print("Image saved to: $savedPath");

      }

      // upload image
      if (_image7 != null) { // upload image 7

        File? _savedImage;
        File imageFile = File(_image7!.path);

        // Get app directory
        Directory appDir = await getApplicationDocumentsDirectory();

        // Create custom folder
        String folderName = "is_sample/"+stationID!;
        Directory customDir = Directory('${appDir.path}/$folderName');
        if (!await customDir.exists()) {
          await customDir.create(recursive: true);
        }

        // Create full image path
        //String fileName = path.basename(_image1!.path);
        String fileExtension = path.extension(_image7!.path);
        String fileName = stationID!+'_'+timestampResult2!+'_optional3'+fileExtension;
        String savedPath = '${customDir.path}/$fileName';

        // Save image
        final savedImage = await imageFile.copy(savedPath);

        setState(() {
          _savedImage = savedImage;
        });

        print("Image saved to: $savedPath");

      }

      // upload image
      if (_image8 != null) { // upload image 8

        File? _savedImage;
        File imageFile = File(_image8!.path);

        // Get app directory
        Directory appDir = await getApplicationDocumentsDirectory();

        // Create custom folder
        String folderName = "is_sample/"+stationID!;
        Directory customDir = Directory('${appDir.path}/$folderName');
        if (!await customDir.exists()) {
          await customDir.create(recursive: true);
        }

        // Create full image path
        //String fileName = path.basename(_image1!.path);
        String fileExtension = path.extension(_image8!.path);
        String fileName = stationID!+'_'+timestampResult2!+'_optional4'+fileExtension;
        String savedPath = '${customDir.path}/$fileName';

        // Save image
        final savedImage = await imageFile.copy(savedPath);

        setState(() {
          _savedImage = savedImage;
        });

        print("Image saved to: $savedPath");

      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Data has been saved!",
          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),backgroundColor: Colors.black,),
      );

      setState(() {

        firstSamplerName = '';
        secondSamplerName = '';
        selectedLocalSampler = null;

        _latitude.clear();
        _longitude.clear();
        _currentLatitude.clear();
        _currentLongitude.clear();
        _type = "";
        _weather = "";
        _barcode.clear();

        _basinName.clear();
        _riverName.clear();
        _latitude.clear();
        _longitude.clear();
        _stationID.clear();
        _latitude.clear();
        _longitude.clear();

        selectedLocalState = null;
        _isDisplay = false;
        _isLocation = false;

        _form1 = true;
        _form2 = false;
        _form3 = false;
        _form4 = false;

      });
    }

    else {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Data failed to save",
          style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),backgroundColor: Colors.red,),
      );

      setState(() {

        firstSamplerName = '';
        secondSamplerName = '';
        selectedLocalSampler = null;

        _latitude.clear();
        _longitude.clear();
        _currentLatitude.clear();
        _currentLongitude.clear();
        _type = "";
        _weather = "";
        _barcode.clear();

        _basinName.clear();
        _riverName.clear();
        _latitude.clear();
        _longitude.clear();
        _stationID.clear();
        _latitude.clear();
        _longitude.clear();

        selectedLocalState = null;
        _isDisplay = false;
        _isLocation = false;

        _form1 = true;
        _form2 = false;
        _form3 = false;
        _form4 = false;

      });

    }

  }

}