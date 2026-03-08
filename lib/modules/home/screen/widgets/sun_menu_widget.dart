import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kids_learning/modules/home/screen/widgets/side_menu_overlay.dart';

/// Sun icon button that opens the side menu overlay when tapped.
class SunMenuWidget extends StatefulWidget {
  const SunMenuWidget({super.key});

  @override
  State<SunMenuWidget> createState() => _SunMenuWidgetState();
}

class _SunMenuWidgetState extends State<SunMenuWidget> {
  bool _isMenuOpen = false;

  void _openMenu() {
    setState(() {
      _isMenuOpen = true;
    });
  }

  void _closeMenu() {
    setState(() {
      _isMenuOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Sun button - always visible
        Positioned(
          top: 40.h,
          right: 16.w,
          child: GestureDetector(
            onTap: _openMenu,
            child: Image.asset(
              'assets/images/sun_menu.png',
              width: 100.w,
              height: 100.w,
              fit: BoxFit.contain,
            ),
          ),
        ),
        // Side menu overlay - only when open
        if (_isMenuOpen) SideMenuOverlay(onClose: _closeMenu),
      ],
    );
  }
}
