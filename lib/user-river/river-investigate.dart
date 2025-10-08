import 'package:flutter/material.dart';
import 'investigate/form-river-investigate-data-log.dart';
import 'investigate/form-river-investigate-image-request.dart';
import 'investigate/form-river-investigate-sample.dart';
import 'dart:math';

class UserRiverInvestigate extends StatefulWidget {
  @override
  _UserRiverInvestigate createState() => _UserRiverInvestigate();
}

class _UserRiverInvestigate extends State<UserRiverInvestigate> with TickerProviderStateMixin {
  bool isDisplay = true;
  late Widget _containerRiver;

  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _containerRiver = _buildMenu();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget page) {
    setState(() {
      isDisplay = false;
      _containerRiver = page;
    });
  }

  Widget _buildMenu() {
    final List<Map<String, dynamic>> sections = [
      {
        'icon': Icons.water_drop_outlined,
        'title': 'RIVER: Sampling',
        'items': [
          {'label': 'Sampling Data', 'action': () => _navigateTo(SFormRiverISSample())},
        ],
      },
      {
        'icon': Icons.receipt_long_outlined,
        'title': 'RIVER: Report',
        'items': [
          {'label': 'NPE-1', 'action': () {}},
          {'label': 'NPE-2', 'action': () {}},
        ],
      },
      {
        'icon': Icons.analytics_outlined,
        'title': 'RIVER: Triennial',
        'items': [
          {'label': 'Report Data', 'action': () {}},
        ],
      },
      {
        'icon': Icons.bar_chart_outlined,
        'title': 'RIVER: Data Log',
        'items': [
          {'label': 'Data Log Report', 'action': () => _navigateTo(SFormRiverISDataLog())},
        ],
      },
      {
        'icon': Icons.image_outlined,
        'title': 'RIVER: Image Request',
        'items': [
          {'label': 'Image Request', 'action': () => _navigateTo(SFormRiverISImageRequest())},
        ],
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final int columns = screenWidth < 600 ? 1 : screenWidth < 1000 ? 2 : 3;
        final double itemMaxWidth = min(screenWidth / columns - 24, 300);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sections.map((section) {
            final indexOffset = sections.indexOf(section) * 10;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _animatedTitle(section['icon'], section['title']),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: List.generate(section['items'].length, (i) {
                    final item = section['items'][i];
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: itemMaxWidth),
                      child: _animatedButton(
                        item['label'],
                        item['action'],
                        indexOffset + i,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                const Divider(),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _animatedTitle(IconData icon, String title) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _fadeController,
        curve: Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _animatedButton(String label, VoidCallback onPressed, int index) {
    final delay = min(index * 0.05, 0.6);

    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        final progress = (_fadeController.value - delay).clamp(0.0, 1.0);
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: ElevatedButton.icon(
        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          alignment: Alignment.centerLeft,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 2,
          shadowColor: Colors.grey.shade200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: SingleChildScrollView(
          key: ValueKey(isDisplay),
          padding: const EdgeInsets.all(16),
          child: _containerRiver,
        ),
      ),
      floatingActionButton: !isDisplay
          ? FloatingActionButton(
        backgroundColor: Colors.green,
        tooltip: 'Back to Investigate Menu',
        onPressed: () {
          setState(() {
            isDisplay = true;
            _fadeController.reset();
            _fadeController.forward();
            _containerRiver = _buildMenu();
          });
        },
        child: const Icon(Icons.arrow_back),
      )
          : null,
    );
  }
}
