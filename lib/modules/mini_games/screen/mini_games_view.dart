import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/l10n/app_localizations.dart';
import 'package:kids_learning/routes/app_routes.dart';
import 'package:kids_learning/utils/assets.dart';
import 'package:kids_learning/widgets/gaming_image_button.dart';

import '../bloc/mini_games_bloc.dart';
import '../bloc/mini_games_event.dart';
import '../bloc/mini_games_state.dart';
import '../data/models/mini_game_model.dart';

class MiniGamesScreen extends StatelessWidget {
  const MiniGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MiniGamesBloc()..add(const MiniGamesLoadEvent()),
      child: const _MiniGamesBody(),
    );
  }
}

class _MiniGamesBody extends StatefulWidget {
  const _MiniGamesBody();

  @override
  State<_MiniGamesBody> createState() => _MiniGamesBodyState();
}

class _MiniGamesBodyState extends State<_MiniGamesBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<MiniGamesBloc>().add(const MiniGamesLoadMoreEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        width: 1.sw,
        height: 1.sh,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
              Color(0xFF1A1A2E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar: cross button + title in same row
              Padding(
                padding: EdgeInsets.only(
                    left: 10.w, right: 16.w, top: 5.h, bottom: 5.h),
                child: Row(
                  children: [
                    GamingImageButton(
                      width: 0.15.sw,
                      imagePath: Assets.imagesCrossIcon,
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        l10n?.miniGames ?? 'Mini Games',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.bubblegumSans(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Spacer to balance the cross button width
                    SizedBox(width: 0.15.sw),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              // Games grid
              Expanded(
                child: BlocBuilder<MiniGamesBloc, MiniGamesState>(
                  builder: (context, state) {
                    if (state is MiniGamesLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white70,
                        ),
                      );
                    }

                    if (state is MiniGamesError) {
                      return _buildEmptyState(l10n);
                    }

                    if (state is MiniGamesLoaded) {
                      if (state.games.isEmpty) {
                        return _buildEmptyState(l10n);
                      }

                      return GridView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14.w,
                          mainAxisSpacing: 14.h,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: state.games.length +
                            (state.hasMore || state.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= state.games.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  color: Colors.white70,
                                ),
                              ),
                            );
                          }
                          return _GameCard(game: state.games[index]);
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations? l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_esports_rounded,
            size: 60.sp,
            color: Colors.white30,
          ),
          SizedBox(height: 12.h),
          Text(
            l10n?.noGamesFound ?? 'No games found',
            style: GoogleFonts.bubblegumSans(
              fontSize: 20.sp,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final MiniGameModel game;

  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.pushNamed(
          Names.miniGamePlay,
          extra: {'name': game.name, 'playUrl': game.playUrl},
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.18),
                  Colors.white.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // Image takes most of the card
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(18.r),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: game.icon,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                          color: Colors.white.withValues(alpha: 0.05),
                          child: Center(
                            child: Icon(
                              Icons.sports_esports_rounded,
                              size: 40.sp,
                              color: Colors.white24,
                            ),
                          ),
                        ),
                        errorWidget: (_, _, _) => Container(
                          color: Colors.white.withValues(alpha: 0.05),
                          child: Center(
                            child: Icon(
                              Icons.sports_esports_rounded,
                              size: 40.sp,
                              color: Colors.white24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Name at the bottom
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
                  child: Text(
                    game.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 15.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
