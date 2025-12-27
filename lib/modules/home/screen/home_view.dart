import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kids_learning/utils/assets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: 100.sh,
        width: 100.sw,
        child: Stack(
          children: [
            Image.asset(Assets.imagesHomeBg, fit: BoxFit.cover, height: 100.sh),
            Align(
              alignment: AlignmentGeometry.topLeft,
              child: Padding(
                padding: EdgeInsets.only(top: 40, left: 16),
                child: Image.asset(Assets.imagesGajrajPop, width: 100.w),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
