import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'screen-login.dart';
import 'screen-register-success.dart';
import 'screen-register-fail.dart';

class ScreenRegister extends StatefulWidget {
  @override
  _ScreenRegister createState() => _ScreenRegister();
}

class _ScreenRegister extends State<ScreenRegister> {
  final _formRegister = GlobalKey<FormState>();
  final TextEditingController _fullName = TextEditingController();

  String? fullName, email, password, selectGroupID, selectDepartID;
  bool btnRegister = false;
  bool showPassword = false;

  final List<DropdownItemGroup> _itemGroup = [
    DropdownItemGroup(id: 'L1', name: 'Management'),
    DropdownItemGroup(id: 'L2', name: 'Manager'),
    DropdownItemGroup(id: 'L3', name: 'Executive'),
    DropdownItemGroup(id: 'L4', name: 'Engineer'),
    DropdownItemGroup(id: 'L5', name: 'Technician'),
    DropdownItemGroup(id: 'L6', name: 'QAQC'),
    DropdownItemGroup(id: 'L7', name: 'Inventory Master'),
    DropdownItemGroup(id: 'L8', name: 'IT'),
  ];

  final List<DropdownItemDepart> _itemDepart = [
    DropdownItemDepart(id: 'D1', name: 'Air'),
    DropdownItemDepart(id: 'D2', name: 'River'),
    DropdownItemDepart(id: 'D3', name: 'Marine'),
    DropdownItemDepart(id: 'D4', name: 'IT'),
    DropdownItemDepart(id: 'D5', name: 'Management'),
  ];

  DropdownItemGroup? _selectedItemGroup;
  DropdownItemDepart? _selectedItemDepart;

  void _functionRegister() async {
    setState(() => btnRegister = true);

    final response = await http.post(
      Uri.parse('https://mmsv2.pstw.com.my/api/api-post.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "action": "register-user",
        "fullName": fullName,
        "username": email,
        "pwd": password,
        "levelID": selectGroupID,
        "departID": selectDepartID
      }),
    );

    final data = json.decode(response.body);

    if (data['statusCode'] == 200) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => ScreenRegisterSuccess(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        ),
      );
    } else {
      String errorMsg = data['message'] ?? 'Registration failed. Please try again.';
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => ScreenRegisterFail(error: errorMsg),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        ),
      );
    }

    setState(() => btnRegister = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade50,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.indigo),
          onPressed: () => Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              transitionDuration: Duration(milliseconds: 500),
              pageBuilder: (_, __, ___) => ScreenLogin(),
              transitionsBuilder: (_, anim, __, child) => SlideTransition(
                position: Tween<Offset>(begin: Offset(-1, 0), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
          ),
        ),
        title: Text('Register', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formRegister,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome 👋", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text("Create your account", style: TextStyle(fontSize: 16, color: Colors.grey[600])),

                SizedBox(height: 24),
                TextFormField(
                  controller: _fullName,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (value) {
                    _fullName.value = TextEditingValue(
                      text: value.toUpperCase(),
                      selection: _fullName.selection,
                    );
                  },
                  validator: validateName,
                  onSaved: (value) => fullName = value,
                ),

                SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: validateEmail,
                  onSaved: (value) => email = value,
                ),

                SizedBox(height: 12),
                TextFormField(
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => showPassword = !showPassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: validatePassword,
                  onSaved: (value) => password = value,
                ),

                SizedBox(height: 12),
                DropdownButtonFormField<DropdownItemGroup>(
                  value: _selectedItemGroup,
                  decoration: InputDecoration(
                    labelText: 'Select Position',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _itemGroup.map((item) {
                    return DropdownMenuItem(value: item, child: Text(item.name));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedItemGroup = value;
                      selectGroupID = value?.id;
                    });
                  },
                  validator: (value) => value == null ? 'Please choose your position' : null,
                ),

                SizedBox(height: 12),
                DropdownButtonFormField<DropdownItemDepart>(
                  value: _selectedItemDepart,
                  decoration: InputDecoration(
                    labelText: 'Select Department',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _itemDepart.map((item) {
                    return DropdownMenuItem(value: item, child: Text(item.name));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedItemDepart = value;
                      selectDepartID = value?.id;
                    });
                  },
                  validator: (value) => value == null ? 'Please choose your department' : null,
                ),

                SizedBox(height: 24),
                btnRegister
                    ? Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Registering...', style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                )
                    : ElevatedButton.icon(
                  icon: Icon(Icons.check,color: Colors.white,),
                  label: Text('Register', style: TextStyle(fontSize: 16,color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.fromHeight(50),
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (_formRegister.currentState!.validate()) {
                      _formRegister.currentState!.save();
                      _functionRegister();
                    }
                  },
                ),

                SizedBox(height: 16),
                Center(
                  child: TextButton(
                    child: Text("Already registered? Login here"),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          transitionDuration: Duration(milliseconds: 500),
                          pageBuilder: (_, __, ___) => ScreenLogin(),
                          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? validateEmail(String? email) {
    final gmailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@(transwater|pstw)\.[a-zA-Z]{2,}$');
    if (email == null || email.isEmpty) return 'Please enter an email';
    if (!gmailRegex.hasMatch(email)) return 'Only @transwater or @pstw allowed';
    return null;
  }

  String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Enter your name';
    return null;
  }

  String? validatePassword(String? password) {
    if (password == null || password.length < 8) return 'Password must be at least 8 characters';
    return null;
  }
}

class DropdownItemGroup {
  final String id;
  final String name;
  DropdownItemGroup({required this.id, required this.name});
  @override
  String toString() => name;
}

class DropdownItemDepart {
  final String id;
  final String name;
  DropdownItemDepart({required this.id, required this.name});
  @override
  String toString() => name;
}
