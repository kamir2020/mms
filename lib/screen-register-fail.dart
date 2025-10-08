import 'package:flutter/material.dart';
import 'screen-register.dart';

class ScreenRegisterFail extends StatelessWidget {
  final String error;

  ScreenRegisterFail({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 100, color: Colors.red),
              SizedBox(height: 20),
              Text("Registration Failed", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text(error, textAlign: TextAlign.center),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => ScreenRegister()),
                  );
                },
                child: Text("Try Again",style: TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: Size.fromHeight(45),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
