import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/audio/audio_player_service.dart';
import 'package:kids_learning/audio/ui_audio_key.dart';
import 'package:kids_learning/l10n/app_localizations.dart';
import 'package:kids_learning/routes/app_routes.dart';
import 'package:kids_learning/services/audio_service.dart';
import 'package:kids_learning/services/auth_service.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';
import 'package:kids_learning/services/locale_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SideMenuOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const SideMenuOverlay({super.key, required this.onClose});

  @override
  State<SideMenuOverlay> createState() => _SideMenuOverlayState();
}

class _SideMenuOverlayState extends State<SideMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  String _appVersion = '';
  double _volume = 0.05; // Default volume matches AudioService init

  final AuthService _authService = AuthService.instance;
  final DailyChallengeService _challengeService =
      DailyChallengeService.instance;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadAppVersion();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start animation when overlay is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = 'v${packageInfo.version}';
      });
    } catch (e) {
      setState(() {
        _appVersion = 'v1.0.0';
      });
    }
  }

  void _closeMenu() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  Future<void> _checkForUpdates() async {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Theme.of(context).primaryColor),
            SizedBox(height: 16.h),
            Text(
              AppLocalizations.of(context)?.checkingForUpdates ??
                  'Checking for updates...',
              style: GoogleFonts.bubblegumSans(fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pop(); // Close loading dialog

      // For now, show a simple message that no update is available
      // In production, you would check against a remote version
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            AppLocalizations.of(context)?.update ?? 'Update',
            style: GoogleFonts.bubblegumSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            AppLocalizations.of(context)?.youHaveLatestVersion ??
                'You have the latest version!',
            style: GoogleFonts.bubblegumSans(fontSize: 14.sp),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)?.ok ?? 'OK',
                style: GoogleFonts.bubblegumSans(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showLanguageDialog() {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);

    final currentLocale = LocaleService.getCurrentLocale(context);
    String? selectedLanguage = currentLocale.languageCode;

    showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF8B5A2B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        title: Text(
          AppLocalizations.of(context)?.chooseLanguage ?? 'Choose Language',
          style: GoogleFonts.bubblegumSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(
              context,
              'English',
              'en',
              selectedLanguage == 'en',
              () {
                selectedLanguage = 'en';
                Navigator.of(context).pop('en');
              },
            ),
            SizedBox(height: 12.h),
            _buildLanguageOption(
              context,
              'বাংলা (Bengali)',
              'bn',
              selectedLanguage == 'bn',
              () {
                selectedLanguage = 'bn';
                Navigator.of(context).pop('bn');
              },
            ),
          ],
        ),
      ),
    ).then((selectedLang) {
      if (selectedLang != null && mounted) {
        LocaleService.changeLanguage(context, selectedLang);
        AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
      }
    });
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String name,
    String code,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFD700)
                : Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected
                  ? const Color(0xFFFFD700)
                  : Colors.white.withValues(alpha: 0.6),
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              name,
              style: GoogleFonts.bubblegumSans(
                fontSize: 16.sp,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.8),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.couldNotOpenUrl ??
                  'Could not open URL',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          AppLocalizations.of(context)?.logout ?? 'Logout',
          style: GoogleFonts.bubblegumSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)?.confirmLogout ??
              'Are you sure you want to logout?',
          style: GoogleFonts.bubblegumSans(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppLocalizations.of(context)?.cancel ?? 'Cancel',
              style: GoogleFonts.bubblegumSans(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              AppLocalizations.of(context)?.logout ?? 'Logout',
              style: GoogleFonts.bubblegumSans(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _closeMenu();
      await _authService.signOut();
      // // Clear language preference on logout
      // await LocaleService.clearLanguagePreference();

      if (mounted) {
        // Navigate to language selection screen
        context.goNamed(Names.login);
      }
    }
  }

  User? get _user => _authService.currentUser;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Stack(
      children: [
        // Overlay - covers the app content (LEFT side only)
        Positioned(
          top: 0,
          left: 0,
          bottom: 0,
          right: 0.75.sw,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: _closeMenu,
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
          ),
        ),

        // Side menu panel - slides in from right
        Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              width: 0.75.sw,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF8B5A2B), Color(0xFF6B4423)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(-5, 0),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Header with close button
                    _buildHeader(l10n),

                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Column(
                          children: [
                            // User profile section
                            _buildUserProfile(),

                            SizedBox(height: 24.h),

                            // Stats section (Streak & Stars)
                            _buildStatsSection(),

                            SizedBox(height: 24.h),

                            // Volume control
                            _buildVolumeControl(l10n),

                            SizedBox(height: 24.h),

                            // Change Language
                            _buildMenuItem(
                              icon: Icons.language_rounded,
                              title: l10n?.chooseLanguage ?? 'Change Language',
                              onTap: () => _showLanguageDialog(),
                            ),

                            // Menu items
                            _buildMenuItem(
                              icon: Icons.privacy_tip_rounded,
                              title: l10n?.privacyPolicy ?? 'Privacy Policy',
                              onTap: () =>
                                  _launchUrl('https://your-app.com/privacy'),
                            ),

                            _buildMenuItem(
                              icon: Icons.description_rounded,
                              title:
                                  l10n?.termsConditions ?? 'Terms & Conditions',
                              onTap: () =>
                                  _launchUrl('https://your-app.com/terms'),
                            ),

                            _buildMenuItem(
                              icon: Icons.update_rounded,
                              title:
                                  l10n?.checkForUpdates ?? 'Check for Updates',
                              onTap: _checkForUpdates,
                            ),

                            SizedBox(height: 16.h),

                            // App version
                            Text(
                              _appVersion,
                              style: GoogleFonts.bubblegumSans(
                                fontSize: 12.sp,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),

                            SizedBox(height: 16.h),

                            // Logout button
                            _buildLogoutButton(l10n),

                            SizedBox(height: 20.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AppLocalizations? l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n?.menu ?? 'Menu',
            style: GoogleFonts.bubblegumSans(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          // Close button
          GestureDetector(
            onTap: _closeMenu,
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    final displayName = _user?.displayName ?? _user?.email ?? 'Guest User';
    final photoUrl = _user?.photoURL;
    final email = _user?.email;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile picture
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
              ),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.person_rounded,
                        size: 50.sp,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Icon(Icons.person_rounded, size: 50.sp, color: Colors.white),
          ),

          SizedBox(height: 16.h),

          // Display name
          Text(
            displayName,
            style: GoogleFonts.bubblegumSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          if (email != null && email != displayName) ...[
            SizedBox(height: 4.h),
            Text(
              email,
              style: GoogleFonts.bubblegumSans(
                fontSize: 12.sp,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final progress = _challengeService.progress;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Streak - clickable to open streak calendar
          InkWell(
            onTap: _openStreakCalendar,
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.all(8.r),
              child: Column(
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: const Color(0xFFFF6B35),
                    size: 32.sp,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${progress.currentStreak}',
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Streak',
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 12.sp,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Divider(height: 40.h, color: Colors.white.withValues(alpha: 0.3)),

          // Stars - clickable to open redeem products
          InkWell(
            onTap: _openRedeemProducts,
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.all(8.r),
              child: Column(
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: const Color(0xFFFFD700),
                    size: 32.sp,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${progress.totalStars}',
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Stars',
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 12.sp,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openStreakCalendar() {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    _closeMenu();
    context.pushNamed(
      Names.streakCalendar,
      extra: {
        'completedDates': _challengeService.completedDates,
        'currentStreak': _challengeService.progress.currentStreak,
        'longestStreak': _challengeService.progress.longestStreak,
        'totalStars': _challengeService.progress.totalStars,
      },
    );
  }

  void _openRedeemProducts() {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    _closeMenu();
    context.pushNamed(Names.redeemProducts);
  }

  Widget _buildVolumeControl(AppLocalizations? l10n) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.music_note_rounded,
                color: const Color(0xFFFFD700),
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                l10n?.musicVolume ?? 'Music Volume',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          Row(
            children: [
              Icon(
                _volume == 0
                    ? Icons.volume_off_rounded
                    : _volume < 0.5
                    ? Icons.volume_down_rounded
                    : Icons.volume_up_rounded,
                color: const Color(0xFFFFD700),
                size: 20.sp,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: const Color(0xFFFFD700),
                    inactiveTrackColor: const Color(
                      0xFFFFD700,
                    ).withValues(alpha: 0.3),
                    thumbColor: const Color(0xFFFFD700),
                    overlayColor: const Color(
                      0xFFFFD700,
                    ).withValues(alpha: 0.2),
                    trackHeight: 8.h,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12,
                    ),
                  ),
                  child: Slider(
                    value: _volume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    onChanged: (value) {
                      setState(() {
                        _volume = value;
                      });
                      // Update background music volume
                      AudioService().setMusicVolume(value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24.sp),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 16.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(AppLocalizations? l10n) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _logout,
          borderRadius: BorderRadius.circular(16.r),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Colors.white, size: 24.sp),
              SizedBox(width: 12.w),
              Text(
                l10n?.logout ?? 'Logout',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
