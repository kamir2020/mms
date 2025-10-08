import 'package:flutter/material.dart';
import 'dart:math';
import 'manual/form-marine-manual-data-log.dart';
import 'manual/form-marine-manual-image-request.dart';
import 'manual/form-in-situ-sampling.dart';
import 'manual/form-info-centre.dart';
import 'manual/form-pre-sampling.dart';
import 'manual/form-report.dart';
import 'manual/form-tarball.dart';

class UserMarineManual extends StatefulWidget {
  @override
  _UserMarineManual createState() => _UserMarineManual();
}

class _UserMarineManual extends State<UserMarineManual> with TickerProviderStateMixin {
  bool isDisplay = true;
  late Widget _containerAir;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _containerAir = _listMenu();

    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Widget _sectionTitle({required IconData icon, required String title}) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: Colors.green),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(String title, VoidCallback onPressed, int index) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        final delay = min(index * 0.1, 0.5); // stagger delay
        final opacity = (_fadeController.value - delay).clamp(0.0, 1.0);
        final slideOffset = Offset(0, (1.0 - opacity) * 0.2);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: slideOffset * 20,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton.icon(
          icon: Icon(Icons.arrow_forward_ios_rounded, size: 16),
          label: Align(
            alignment: Alignment.centerLeft,
            child: Text(title, style: TextStyle(fontSize: 14)),
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: Size.fromHeight(50),
            alignment: Alignment.centerLeft,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 1,
            shadowColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _listMenu() {
    List<Map<String, dynamic>> sections = [
      {
        'title': 'Info Centre',
        'icon': Icons.science_outlined,
        'items': [
          {'label': 'Info Centre Document', 'onTap': () => _openSection(SFormInfoCentre())},
        ]
      },
      {
        'title': 'Pre-sampling',
        'icon': Icons.receipt_long,
        'items': [
          {'label': 'Process of Pre-Sampling', 'onTap': () => _openSection(SFormPreSampling())},
        ]
      },
      {
        'title': 'In Situ Sampling',
        'icon': Icons.bar_chart,
        'items': [
          {'label': 'Process of In Situ Sampling', 'onTap': () => _openSection(SFormInSituSample())},
        ]
      },
      {
        'title': 'Tarball Sampling',
        'icon': Icons.bar_chart,
        'items': [
          {'label': 'Process of Tarball Sampling', 'onTap': () => _openSection(SFormTarball())},
        ]
      },
      {
        'title': 'Report',
        'icon': Icons.image,
        'items': [
          {'label': 'Process of Reporting', 'onTap': () => _openSection(SFormReport())},
        ]
      },
      {
        'title': 'Data Status Log',
        'icon': Icons.image,
        'items': [
          {'label': 'Process of Reporting', 'onTap': () => _openSection(SFormMarineManualDataLog())},
        ]
      },
      {
        'title': 'Image Request',
        'icon': Icons.image,
        'items': [
          {'label': 'Process of Reporting', 'onTap': () => _openSection(SFormMarineManualImageRequest())},
        ]
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sections.asMap().entries.map((sectionEntry) {
            final sec = sectionEntry.value;
            final secIndex = sectionEntry.key;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle(icon: sec['icon'], title: sec['title']),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(sec['items'].length, (itemIndex) {
                    final totalIndex = secIndex * 3 + itemIndex; // for stagger animation
                    return SizedBox(
                      width: isWide ? (constraints.maxWidth / 2) - 20 : constraints.maxWidth,
                      child: _menuButton(
                        sec['items'][itemIndex]['label'],
                        sec['items'][itemIndex]['onTap'],
                        totalIndex,
                      ),
                    );
                  }),
                ),
                SizedBox(height: 20),
                Divider(),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  void _openSection(Widget widget) {
    setState(() {
      isDisplay = false;
      _containerAir = widget;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 400),
          child: _containerAir,
        ),
      ),
      floatingActionButton: !isDisplay
          ? FloatingActionButton(
        backgroundColor: Colors.green,
        tooltip: 'Back to Menu',
        onPressed: () {
          setState(() {
            isDisplay = true;
            _fadeController.reset();
            _fadeController.forward();
            _containerAir = _listMenu();
          });
        },
        child: const Icon(Icons.arrow_back),
      )
          : null,
    );
  }
}
