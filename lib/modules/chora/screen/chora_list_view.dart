import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/modules/chora/data/models/chora_model.dart';
import 'package:kids_learning/routes/app_routes.dart';
import 'package:kids_learning/services/audio_service.dart';
import 'package:kids_learning/utils/assets.dart';
import 'package:kids_learning/utils/themes/app_colors.dart';
import 'package:kids_learning/widgets/gaming_image_button.dart';

import '../bloc/chora_bloc.dart';
import '../bloc/chora_event.dart';
import '../bloc/chora_state.dart';

class ChoraListScreen extends StatefulWidget {
  const ChoraListScreen({super.key});

  @override
  State<ChoraListScreen> createState() => _ChoraListScreenState();
}

class _ChoraListScreenState extends State<ChoraListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    AudioService().pause();
    context.read<ChoraBloc>().add(ChoraInit());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ChoraBloc>().add(ChoraLoadMore());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    AudioService().resume();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SizedBox(
          height: 1.sh,
          width: 1.sw,
          child: Stack(
            children: [
              // Background
              Image.asset(
                Assets.imagesChoraBg,
                fit: BoxFit.cover,
                height: 1.sh,
                width: 1.sw,
              ),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: .17.sh),

                    // Title

                    // Grid content
                    Expanded(
                      child: BlocBuilder<ChoraBloc, ChoraState>(
                        builder: (context, state) {
                          if (state is ChoraLoading) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            );
                          }

                          if (state is ChoraError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 60.sp,
                                    color: Colors.red,
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    'কিছু ভুল হয়েছে',
                                    style: GoogleFonts.hindSiliguri(
                                      fontSize: 18.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 20.h),
                                  ElevatedButton(
                                    onPressed: () {
                                      context.read<ChoraBloc>().add(
                                        ChoraInit(),
                                      );
                                    },
                                    child: const Text('আবার চেষ্টা করো'),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (state is ChoraLoaded && state.choras.isEmpty) {
                            return Center(
                              child: Text(
                                'কোনো ছড়া পাওয়া যায়নি',
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 18.sp,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }

                          final choras = state.choras;
                          final hasMore = state is ChoraLoaded && state.hasMore;

                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5.w),
                            child: GridView.builder(
                              controller: _scrollController,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16.w,
                                    mainAxisSpacing: 16.h,
                                    childAspectRatio: 0.85,
                                  ),
                              itemCount: hasMore
                                  ? choras.length + 2
                                  : choras.length,
                              itemBuilder: (context, index) {
                                if (index >= choras.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }
                                return _ChoraCard(
                                  chora: choras[index],
                                  onTap: () {
                                    context.pushNamed(
                                      Names.choraPlayer,
                                      extra: {'choras': choras, 'index': index},
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 0.11.sh),
                  ],
                ),
              ),

              // Close button
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(left: 10.w, top: 15.h, bottom: 12),
                  child: GamingImageButton(
                    width: 0.28.sw,
                    imagePath: Assets.imagesCrossIcon,
                    onPressed: () {
                      context.read<ChoraBloc>().add(ChoraStop());
                      context.pop();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoraCard extends StatelessWidget {
  final ChoraModel chora;
  final VoidCallback onTap;

  const _ChoraCard({required this.chora, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Thumbnail content with padding for the frame
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                left: 12.w,
                top: 12.h,
                right: 12.w,
                bottom: 18.h,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thumbnail
                    CachedNetworkImage(
                      imageUrl: chora.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.primary1.withValues(alpha: 0.3),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                            color: AppColors.primary2,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary2.withValues(alpha: 0.6),
                              AppColors.primary1.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 50.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Play icon overlay
                    Center(
                      child: Container(
                        width: 50.w,
                        height: 50.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 28.sp,
                          color: AppColors.primary2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Wooden frame overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Image.asset(Assets.imagesChoraFrame, fit: BoxFit.fill),
            ),
          ),
        ],
      ),
    );
  }
}
