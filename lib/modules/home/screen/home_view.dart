import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kids_learning/modules/home/screen/widgets/friend_greeting_widget.dart';
import 'package:kids_learning/modules/home/screen/widgets/sun_menu_widget.dart';
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
            // Background image
            Image.asset(Assets.imagesHomeBg, fit: BoxFit.cover, height: 100.sh),

            // Friend greeting widget (replaces the old hardcoded chiku)
            const FriendGreetingWidget(),

            // Sun menu in top right
            SunMenuWidget(),
          ],
        ),
      ),
    );
  }
}
