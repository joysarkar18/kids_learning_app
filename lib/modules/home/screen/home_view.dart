import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_learning/modules/home/screen/widgets/friend_greeting_widget.dart';
import 'package:kids_learning/modules/home/screen/widgets/sun_menu_widget.dart';
import 'package:kids_learning/routes/app_routes.dart';
import 'package:kids_learning/utils/assets.dart';
import 'package:kids_learning/widgets/gaming_image_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: 1.sh,
        width: 1.sw,
        child: Stack(
          children: [
            // Background image
            Image.asset(Assets.imagesHomeBg, fit: BoxFit.cover, height: 1.sh),

            // Friend greeting widget
            const FriendGreetingWidget(),

            // Sun menu in top right
            SunMenuWidget(),

            // Bottom menu with subject buttons
            Align(
              alignment: AlignmentGeometry.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 10.w,
                  right: 10.w,
                  bottom: 140.h,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // First row: Bengali, English, GK
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GamingImageButton(
                          imagePath: Assets.imagesBengaliIcon,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.bornomala);
                          },
                        ),
                        GamingImageButton(
                          imagePath: Assets.imagesEnglishIcon,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.alphabate);
                          },
                        ),
                        GamingImageButton(
                          imagePath: Assets.imagesGkIcon,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.sothikUttor);
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 30.h),

                    // Second row: Math, Chora, Drawing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GamingImageButton(
                          imagePath: Assets.imagesBanglaSonkha,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.banglaSonkha);
                          },
                        ),

                        GamingImageButton(
                          imagePath: Assets.imagesChoraIcon,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.chora);
                          },
                        ),
                        GamingImageButton(
                          imagePath: Assets.imagesDrawingIcon,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.drawing);
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 30.h),

                    // Second row: Math, Chora, Drawing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GamingImageButton(
                          imagePath: Assets.imagesEngrejiSonkha,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.englishSonkha);
                          },
                        ),
                        GamingImageButton(
                          imagePath: Assets.imagesGonit,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.ganitPlay);
                          },
                        ),
                        GamingImageButton(
                          imagePath: Assets.imagesNamota,
                          width: 0.3.sw,
                          onPressed: () {
                            context.pushNamed(Names.namota);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
