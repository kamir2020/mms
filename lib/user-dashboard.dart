import 'package:app_mms/user-marine/marine-investigate.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screen-password.dart';
import 'screen-login.dart';
import 'user-main.dart';
import 'user-air/air-sample.dart';
import 'user-marine/marine-manual.dart';
import 'user-marine/marine-continuos.dart';
import 'user-river/river-manual.dart';
import 'user-river/river-investigate.dart';
import 'my-drawer-header.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: UserDashboard(),
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.indigo,
    ),
  ));
}

class UserDashboard extends StatefulWidget {
  @override
  _UserDashboard createState() => _UserDashboard();
}

class _UserDashboard extends State<UserDashboard> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  String _name = 'Dashboard';
  Widget _container = UserMain();

  @override
  void initState() {
    super.initState();
    getSession();
  }

  Future<void> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    // print session if needed
    // print(prefs.getString('auth_id').toString());
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  void switchScreen(String title, Widget screen) {
    setState(() {
      _name = title;
      _container = screen;
    });
    Navigator.pop(context); // close drawer
  }

  Widget buildDrawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }

  // --- BLOCK BACK BUTTON EXIT HERE ---
  Future<bool> _onWillPop() async {
    // 1) If drawer open, close it.
    if (scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
      return false;
    }

    // 2) If not on Dashboard, go back to Dashboard.
    final bool onDashboard = _name == 'Dashboard';
    if (!onDashboard) {
      setState(() {
        _name = 'Dashboard';
        _container = UserMain();
      });
      return false;
    }

    // 3) Otherwise, block exit and hint the user.
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Use Logout from the menu to exit.'),
        duration: Duration(seconds: 2),
      ),
    );
    return false; // prevent popping the route (no app exit)
  }
  // -----------------------------------

  @override
  Widget build(BuildContext context) {
    return WillPopScope( // <-- wrap Scaffold
      onWillPop: _onWillPop,
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          iconTheme: const IconThemeData(color: Colors.indigo),
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _name,
              key: ValueKey(_name),
              style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              MyHeaderDrawer(),
              buildDrawerItem(Icons.dashboard, 'Dashboard', () {
                switchScreen('Dashboard', UserMain());
              }),
              ExpansionTile(
                title: const Text('Marine'),
                leading: const Icon(Icons.sailing, color: Colors.indigo),
                childrenPadding: const EdgeInsets.only(left: 30),
                children: [
                  buildDrawerItem(Icons.timeline, 'Continuous', () {
                    switchScreen('MARINE - Continuous', MarineContinuos());
                  }),
                  buildDrawerItem(Icons.assignment, 'Manual', () {
                    switchScreen('MARINE - Manual', UserMarineManual());
                  }),
                  buildDrawerItem(Icons.science, 'Investigative Study', () {
                    switchScreen('MARINE - Investigative Study', MarineInvestigate());
                  }),
                ],
              ),
              ExpansionTile(
                title: const Text('River'),
                leading: const Icon(Icons.water, color: Colors.indigo),
                childrenPadding: const EdgeInsets.only(left: 30),
                children: [
                  buildDrawerItem(Icons.opacity, 'Manual Sampling', () {
                    switchScreen('RIVER - Manual Sampling', UserRiverSample());
                  }),
                  buildDrawerItem(Icons.search, 'Investigative Sampling', () {
                    switchScreen('RIVER - Investigative Sampling', UserRiverInvestigate());
                  }),
                ],
              ),
              ExpansionTile(
                title: const Text('Air'),
                leading: const Icon(Icons.air, color: Colors.indigo),
                childrenPadding: const EdgeInsets.only(left: 30),
                children: [
                  buildDrawerItem(Icons.cloud, 'Manual Sampling', () {
                    switchScreen('AIR - Manual Sampling', UserAirSample());
                  }),
                  buildDrawerItem(Icons.timeline, 'Continuous', () {
                    switchScreen('AIR - Manual Sampling', UserAirSample()); // Placeholder
                  }),
                  buildDrawerItem(Icons.science, 'Investigative Sampling', () {
                    switchScreen('AIR - Manual Sampling', UserAirSample()); // Placeholder
                  }),
                ],
              ),
              const Divider(),
              buildDrawerItem(Icons.settings, 'Change Password', () {
                switchScreen('Change Password', ScreenPassword());
              }),
              buildDrawerItem(Icons.logout, 'Logout', () async {
                await clearSession();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ScreenLogin()),
                );
              }),
            ],
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation);

            return SlideTransition(
              position: offset,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: _container,
        ),
      ),
    );
  }
}
