import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/audio/audio_player_service.dart';
import 'package:kids_learning/audio/ui_audio_key.dart';
import 'package:kids_learning/l10n/app_localizations.dart';
import 'package:kids_learning/modules/daily_challenge/screen/redeem_products_view.dart';
import 'package:kids_learning/routes/app_routes.dart';
import 'package:kids_learning/services/auth_service.dart';
import 'package:kids_learning/services/daily_challenge_service.dart';
import 'package:kids_learning/services/device_info_service.dart';
import 'package:kids_learning/utils/assets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

class SideMenuWidget extends StatefulWidget {
  const SideMenuWidget({super.key});

  @override
  State<SideMenuWidget> createState() => _SideMenuWidgetState();
}

class _SideMenuWidgetState extends State<SideMenuWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isOpen = false;
  String _appVersion = '';
  double _volume = 1.0;

  final AuthService _authService = AuthService.instance;
  final DailyChallengeService _challengeService = DailyChallengeService.instance;

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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
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

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
    });
    
    if (_isOpen) {
      _animationController.forward();
      AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    } else {
      _animationController.reverse();
    }
  }

  void _closeMenu() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
      });
      _animationController.reverse();
    }
  }

  Future<void> _checkForUpdates() async {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: 16.h),
            Text(
              AppLocalizations.of(context)?.checkingForUpdates ?? 'Checking for updates...',
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Text(
            AppLocalizations.of(context)?.update ?? 'Update',
            style: GoogleFonts.bubblegumSans(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          content: Text(
            AppLocalizations.of(context)?.youHaveLatestVersion ?? 'You have the latest version!',
            style: GoogleFonts.bubblegumSans(fontSize: 14.sp),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)?.ok ?? 'OK',
                style: GoogleFonts.bubblegumSans(color: Theme.of(context).primaryColor),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    AudioPlayerService.instance.playUi(key: UiAudioKey.button_press);
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.couldNotOpenUrl ?? 'Could not open URL'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          AppLocalizations.of(context)?.logout ?? 'Logout',
          style: GoogleFonts.bubblegumSans(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppLocalizations.of(context)?.confirmLogout ?? 'Are you sure you want to logout?',
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
      
      if (mounted) {
        context.goNamed(Names.onboarding);
      }
    }
  }

  User? get _user => _authService.currentUser;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isBn = Localizations.localeOf(context).languageCode == 'bn';

    return Stack(
      children: [
        // Overlay background when menu is open
        if (_isOpen)
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTap: _closeMenu,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),

        // Menu button (sun icon)
        Positioned(
          top: 40.h,
          right: 16.w,
          child: GestureDetector(
            onTap: _toggleMenu,
            child: Image.asset(
              Assets.imagesSunMenu,
              width: 100.w,
              height: 100.w,
              fit: BoxFit.contain,
            ),
          ),
        ),

        // Side menu panel
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
                  colors: [
                    Color(0xFFFFF8E1),
                    Color(0xFFFFECB3),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
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
                            
                            // Menu items
                            _buildMenuItem(
                              icon: Icons.privacy_tip_rounded,
                              title: l10n?.privacyPolicy ?? 'Privacy Policy',
                              onTap: () => _launchUrl('https://your-app.com/privacy'),
                            ),
                            
                            _buildMenuItem(
                              icon: Icons.description_rounded,
                              title: l10n?.termsAndConditions ?? 'Terms & Conditions',
                              onTap: () => _launchUrl('https://your-app.com/terms'),
                            ),
                            
                            _buildMenuItem(
                              icon: Icons.update_rounded,
                              title: l10n?.checkForUpdates ?? 'Check for Updates',
                              onTap: _checkForUpdates,
                            ),
                            
                            SizedBox(height: 16.h),
                            
                            // App version
                            Text(
                              _appVersion,
                              style: GoogleFonts.bubblegumSans(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
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
              color: const Color(0xFF5D4037),
            ),
          ),
          GestureDetector(
            onTap: _closeMenu,
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.close_rounded,
                color: const Color(0xFF5D4037),
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
        color: Colors.white.withValues(alpha: 0.7),
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
                : Icon(
                    Icons.person_rounded,
                    size: 50.sp,
                    color: Colors.white,
                  ),
          ),
          
          SizedBox(height: 16.h),
          
          // Display name
          Text(
            displayName,
            style: GoogleFonts.bubblegumSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5D4037),
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
                color: Colors.grey.shade600,
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
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Streak
          _buildStatItem(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFFF6B35),
            value: '${progress.currentStreak}',
            label: 'Streak',
          ),
          
          Divider(
            height: 40.h,
            color: Colors.grey.shade300,
          ),
          
          // Stars
          _buildStatItem(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFFFD700),
            value: '${progress.totalStars}',
            label: 'Stars',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 32.sp),
        SizedBox(height: 4.h),
        Text(
          value,
          style: GoogleFonts.bubblegumSans(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4037),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.bubblegumSans(
            fontSize: 12.sp,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeControl(AppLocalizations? l10n) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.music_note_rounded,
                color: const Color(0xFF9C27B0),
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                l10n?.musicVolume ?? 'Music Volume',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5D4037),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          Row(
            children: [
              Icon(
                _volume == 0 ? Icons.volume_off_rounded : 
                               _volume < 0.5 ? Icons.volume_down_rounded : 
                               Icons.volume_up_rounded,
                color: const Color(0xFF9C27B0),
                size: 20.sp,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: const Color(0xFF9C27B0),
                    inactiveTrackColor: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                    thumbColor: const Color(0xFF9C27B0),
                    overlayColor: const Color(0xFF9C27B0).withValues(alpha: 0.2),
                    trackHeight: 8.h,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
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
                      // TODO: Update global audio volume
                      // AudioPlayerService.instance.setVolume(value);
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
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                Icon(
                  icon,
                  color: const Color(0xFF5D4037),
                  size: 24.sp,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.bubblegumSans(
                      fontSize: 16.sp,
                      color: const Color(0xFF5D4037),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: const Color(0xFF5D4037),
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
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _logout,
          borderRadius: BorderRadius.circular(16.r),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.red.shade700,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                l10n?.logout ?? 'Logout',
                style: GoogleFonts.bubblegumSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
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
