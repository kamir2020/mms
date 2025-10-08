// ScreenLogin.dart
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:app_mms/user-marine/push-data-marine-insitu.dart';
import 'package:app_mms/user-marine/push-data-marine-study.dart';
import 'package:app_mms/user-marine/push-data-marine-tarball.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'screen-forgot-password.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'db_helper.dart';
import 'screen-register.dart';
import 'user-dashboard.dart';
import 'package:http_parser/http_parser.dart';

import 'user-river/push-data-river-manual-sample.dart';

class ScreenLogin extends StatefulWidget {
  @override
  _ScreenLogin createState() => _ScreenLogin();
}

class _ScreenLogin extends State<ScreenLogin> {
  final _formKey = GlobalKey<FormState>();
  late String _fullname = '', _username = '', _password = '';
  final ct_username = TextEditingController();
  final ct_password = TextEditingController();

  bool _isErrorLogin = false;
  bool _isErrorNRID = false;
  bool _isErrorPassword = false;
  bool _isBtnLogin = true;
  bool _passwordObsecure = true;

  /// "Remember Me" (stores email/password in Hive)
  bool isChecked = false;

  /// "Keep me logged in" (auto-skip login screen next launch)
  bool keepMeLoggedIn = false;

  late Box box1;

  final db = DBHelper();
  List<dynamic> data = [];

  // Services
  final _log = <String>[];
  final _service = MarineTarballService();

  final _log1 = <String>[];
  final _service1 = MarineInSituService();

  final _log2 = <String>[];
  final _service2 = MarineStudySampleService();

  final _log3 = <String>[];
  final _service3 = RiverManualSampleService();

  @override
  void initState() {
    super.initState();
    fetchData();
    createBox();
    _autoLogin(); // skip screen if keep_login=true
  }

  Future<void> createBox() async {
    final box = await Hive.openBox('logindata');
    if (!mounted) return;
    box1 = box;
    await getData();
  }

  Future<void> getData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      isChecked = prefs.getBool('remember_me') ?? false;
      keepMeLoggedIn = prefs.getBool('keep_login') ?? false; // restore toggle state
    });

    if (isChecked) {
      final email = box1.get('email');
      final pass = box1.get('password');
      if (email != null) ct_username.text = email;
      if (pass != null) ct_password.text = pass;
    }
  }

  Future<void> fetchData() async {
    final users = await DBHelper.getData();
    for (var user in users) {
      log('Name: ${user['fullname']}');
    }
  }

  Future<void> saveSession(
      String username,
      String userID,
      String levelID,
      String departID,
      String fullName,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', username);
    await prefs.setString('fullName', fullName);
    await prefs.setString('auth_id', userID);
    await prefs.setString('auth_levelID', levelID);
    await prefs.setString('auth_departID', departID);

    // Persist current Remember Me preference
    await prefs.setBool('remember_me', isChecked);

    // keep_login follows the checkbox, not forced true
    await prefs.setBool('keep_login', keepMeLoggedIn);
  }

  Future<bool> isConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // ---------- LOAD MASTER DATA TO SQLITE ----------
  Future<void> fetchAndSaveSampler() async {
    final url = Uri.parse(
        'https://mmsv2.pstw.com.my/api/api-get.php?action=load-tbl-sampler&username=$_username');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      List<dynamic> samplers = jsonDecode(response.body);
      for (var sampler in samplers) {
        db.insertSampler({
          "id": sampler['id'],
          "fullname": sampler['fullname'],
          "email": sampler['username'],
          "userID": sampler['userID'],
        });
      }
      log('data sampler saved in sqlite');
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> fetchAndSaveCategory() async {
    final url = Uri.parse(
        'https://mmsv2.pstw.com.my/api/api-get.php?action=load-tbl-category');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      List<dynamic> categories = jsonDecode(response.body);
      for (var category in categories) {
        db.insertCategory({
          "id": category['id'],
          "categoryID": category['categoryID'],
          "categoryName": category['categoryName'],
        });
      }
      log('data category saved in sqlite');
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> fetchAndSaveState() async {
    final url = Uri.parse(
        'https://mmsv2.pstw.com.my/api/api-get.php?action=load-tbl-state');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      List<dynamic> states = jsonDecode(response.body);
      for (var state in states) {
        db.insertState({
          "id": state['id'],
          "stateID": state['stateID'],
          "stateName": state['stateName'],
        });
      }
      log('data state saved in sqlite');
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> fetchAndSaveMarineStation() async {
    final url = Uri.parse(
        'https://mmsv2.pstw.com.my/api/api-get.php?action=load-tbl-marine-station');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      List<dynamic> stations = jsonDecode(response.body);
      for (var station in stations) {
        db.insertMarineStation({
          "id": station['id'],
          "stationID": station['stationID'],
          "stateID": station['stateID'],
          "categoryID": station['categoryID'],
          "locationName": station['locationName'],
          "latitude": station['latitude'],
          "longitude": station['longitude'],
        });
      }
      log('data marine station saved in sqlite');
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> fetchAndSaveTarballStation() async {
    final url = Uri.parse(
        'https://mmsv2.pstw.com.my/api/api-get.php?action=load-tbl-tarball-station');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      List<dynamic> stations = jsonDecode(response.body);
      for (var station in stations) {
        db.insertTarballStation({
          "id": station['id'],
          "stationID": station['stationID'],
          "stateID": station['stateID'],
          "categoryID": station['categoryID'],
          "locationName": station['locationName'],
          "longitude": station['longitude'],
          "latitude": station['latitude'],
        });
      }
      log('data tarball station saved in sqlite');
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> fetchAndSaveAirStation() async {
    final url = Uri.parse(
        'https://mmsv2.pstw.com.my/api/api-get.php?action=load-tbl-air-station');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      List<dynamic> stations = jsonDecode(response.body);
      for (var station in stations) {
        db.insertAirStation({
          "id": station['id'],
          "stationID": station['stationID'],
          "stateID": station['stateID'],
          "categoryID": station['categoryID'],
          "locationName": station['locationName'],
          "longitude": station['longitude'],
          "latitude": station['latitude'],
        });
      }
      log('data air station saved in sqlite');
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> fetchAndSaveRiverStation() async {
    final url = Uri.parse(
        'https://mmsv2.pstw.com.my/api/api-get.php?action=load-tbl-river-station');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      List<dynamic> stations = jsonDecode(response.body);
      for (var station in stations) {
        db.insertRiverStation({
          "id": station['id'],
          "stationID": station['stationID'],
          "stateID": station['stateID'],
          "basinName": station['basinName'],
          "riverName": station['riverName'],
          "latitude": station['latitude'],
          "longitude": station['longitude'],
        });
      }
      log('data river station saved in sqlite');
    } else {
      throw Exception('Failed to load data');
    }
  }

  // ---------- PUSH LOCAL DATA (safe log callbacks) ----------
  Future<void> _pushDataTarball() async {
    final result = await _service.pushDataTarballToMySQL(
      log: (m) {
        if (!mounted) return;
        setState(() => _log.add(m));
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pushed tarball ${result.rowsPushed} row(s), uploaded ${result.imagesUploaded} image(s).',
        ),
      ),
    );
  }

  Future<void> _pushDataInSitu() async {
    final result = await _service1.pushDataInSituToMySQL(
      log: (m) {
        if (!mounted) return;
        setState(() => _log1.add(m));
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pushed insitu ${result.rowsPushed} row(s), uploaded ${result.imagesUploaded} image(s).',
        ),
      ),
    );
  }

  Future<void> _pushDataStudySample() async {
    final result = await _service2.pushDataStudySampleToMySQL(
      log: (m) {
        if (!mounted) return;
        setState(() => _log2.add(m));
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pushed study sample ${result.rowsPushed} row(s), uploaded ${result.imagesUploaded} image(s).',
        ),
      ),
    );
  }

  Future<void> _pushDataRiverManualSample() async {
    final result = await _service3.pushDataRiverManualSampleToMySQL(
      log: (m) {
        if (!mounted) return;
        setState(() => _log3.add(m));
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pushed river manual sample ${result.rowsPushed} row(s), uploaded ${result.imagesUploaded} image(s).',
        ),
      ),
    );
  }

  // ---------- LOGIN FLOW ----------
  Future<void> _login() async {
    if ((_username != "") && (_password != "")) {
      if (mounted) setState(() => _isBtnLogin = false);

      // Remember Me → persist creds in Hive
      if (isChecked) {
        box1.put('email', ct_username.text);
        box1.put('password', ct_password.text);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', true);
      }

      if (await isConnected()) {
        // ONLINE LOGIN
        final response = await http.post(
          Uri.parse('https://mmsv2.pstw.com.my/api/api-post.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "action": "login-user",
            "username": _username,
            "password": _password
          }),
        );

        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          await db.insertUser({
            'fullName': data['fullName'],
            'email': _username,
            'password': _password,
            'userID': data['userID'],
            'levelID': data['levelID'],
            'departID': data['departID']
          });

          await saveSession(
            _username,
            data['userID'],
            data['levelID'],
            data['departID'],
            data['fullName'],
          );

          // Load masters first
          await Future.wait([
            fetchAndSaveSampler(),
            fetchAndSaveCategory(),
            fetchAndSaveState(),
            fetchAndSaveMarineStation(),
            fetchAndSaveTarballStation(),
            fetchAndSaveAirStation(),
            fetchAndSaveRiverStation(),
          ]);

          // Push local → server (await to avoid post-dispose callbacks)
          await Future.wait([
            _pushDataTarball(),
            _pushDataInSitu(),
            _pushDataStudySample(),
            _pushDataRiverManualSample(),
          ]);

          if (!mounted) return;
          setState(() => _isBtnLogin = true); // set before navigation
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => UserDashboard()),
          );
        } else {
          _handleInvalidLogin();
        }
      } else {
        // OFFLINE LOGIN
        final user = await db.getUser(_username, _password);
        if (user != null) {
          await saveSession(
            _username,
            user['userID'],
            user['levelID'],
            user['departID'],
            user['fullName'],
          );

          if (!mounted) return;
          setState(() => _isBtnLogin = true); // set before navigation
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => UserDashboard()),
          );
        } else {
          _handleInvalidLogin();
        }
      }
    } else {
      if (mounted) setState(() => _isErrorLogin = true);
    }
  }

  void _handleInvalidLogin() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid username and password!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        _isBtnLogin = true;
        _isErrorLogin = true;
        _isErrorNRID = false;
        _isErrorPassword = false;

        ct_username.clear();
        ct_password.clear();
      });
    }
  }

  // ---------- AUTO LOGIN ----------
  Future<void> _autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final keep = prefs.getBool('keep_login') ?? false;
    if (!keep) {
      if (!mounted) return;
      setState(() {
        isChecked = prefs.getBool('remember_me') ?? false;
        keepMeLoggedIn = prefs.getBool('keep_login') ?? false;
      });
      return;
    }

    final authId = prefs.getString('auth_id');
    if (authId != null && authId.isNotEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UserDashboard()),
      );
    }
  }

  // ---------- LOGOUT (call from UserDashboard) ----------
  static Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keep_login', false); // end session, preserve remember_me
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => ScreenLogin()),
          (_) => false,
    );
  }

  @override
  void dispose() {
    ct_username.dispose();
    ct_password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          alignment: Alignment.center,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 55.0,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage('images/icon4.png'),
                    radius: 50.0,
                  ),
                ),
                const Text(
                  'Integrated Environmental\nSolution',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                if (_isErrorLogin) ...[
                  const SizedBox(height: 5),
                  const Text(
                    'Email and password is not match',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 20),

                // ------------- FORM -------------
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // USERNAME
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: TextFormField(
                              controller: ct_username,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Username',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  setState(() => _isErrorNRID = true);
                                  return 'Enter your username';
                                }
                                setState(() => _isErrorNRID = false);
                                return null;
                              },
                              onSaved: (value) =>
                                  setState(() => _username = value!.trim()),
                            ),
                          ),
                        ),
                      ),
                      if (_isErrorNRID)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 45),
                          child: Text(
                            'Enter your username',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // PASSWORD
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: TextFormField(
                              controller: ct_password,
                              obscureText: _passwordObsecure,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Password',
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() =>
                                    _passwordObsecure = !_passwordObsecure);
                                  },
                                  icon: Icon(_passwordObsecure
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  setState(() => _isErrorPassword = true);
                                  return 'Enter your password';
                                }
                                setState(() => _isErrorPassword = false);
                                return null;
                              },
                              onSaved: (value) =>
                                  setState(() => _password = value!),
                            ),
                          ),
                        ),
                      ),
                      if (_isErrorPassword)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 45),
                          child: Text(
                            'Enter your password',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // LOGIN BUTTON
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: _isBtnLogin
                            ? ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              _login();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Login',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 15),
                              ),
                            ),
                          ),
                        )
                            : const Center(
                          child: CircularProgressIndicator(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // KEEP ME LOGGED IN (toggle)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Keep me logged in',
                        style: TextStyle(color: Colors.black)),
                    Checkbox(
                      value: keepMeLoggedIn,
                      onChanged: (value) async {
                        if (!mounted) return;
                        setState(() => keepMeLoggedIn = value ?? false);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('keep_login', keepMeLoggedIn);
                      },
                    ),
                  ],
                ),

                // REGISTER
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ScreenRegister()),
                        );
                      },
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'New user? Register now',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.supervised_user_circle),
                  ],
                ),

                const SizedBox(height: 10),

                // FORGOT PASSWORD
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ScreenForgotPassword()),
                        );
                      },
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.password),
                  ],
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
