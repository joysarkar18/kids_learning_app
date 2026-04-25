import 'dart:io';
import 'dart:math';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_learning/l10n/app_localizations.dart';
import 'package:kids_learning/routes/app_routes.dart';
import 'package:kids_learning/services/auth_service.dart';
import 'package:kids_learning/services/logger_service.dart';
import 'package:kids_learning/services/snackbar_service.dart';
import 'package:kids_learning/services/user_service.dart';
import 'package:kids_learning/utils/assets.dart';
import 'package:kids_learning/widgets/gaming_button.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fireflyController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  bool get _isLoading => _isGoogleLoading || _isAppleLoading;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fireflyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fireflyController.dispose();
    super.dispose();
  }

  Future<void> _handleSignInSuccess(dynamic user) async {
    if (user != null) {
      FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
      UserService.instance.saveUserData(user);
      if (mounted) {
        context.goNamed(Names.onboarding);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isGoogleLoading = true);

    try {
      final user = await AuthService.instance.signInWithGoogle();
      await _handleSignInSuccess(user);
    } catch (e) {
      LoggerService.logError('Login failed: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackbarService().showError(
          message: l10n?.somethingWentWrong ?? 'Something went wrong!',
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_isLoading) return;
    setState(() => _isAppleLoading = true);

    try {
      final user = await AuthService.instance.signInWithApple();
      await _handleSignInSuccess(user);
    } catch (e) {
      LoggerService.logError('Apple login failed: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackbarService().showError(
          message: l10n?.somethingWentWrong ?? 'Something went wrong!',
        );
      }
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Static jungle background
          CustomPaint(size: Size.infinite, painter: _JunglePainter()),

          // Animated fireflies layer
          AnimatedBuilder(
            animation: _fireflyController,
            builder: (context, _) => CustomPaint(
              size: Size.infinite,
              painter: _FireflyPainter(_fireflyController.value),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28.w),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      const Spacer(flex: 5),

                      // Welcome text with glow
                      Text(
                        l10n?.welcome ?? 'Welcome!',
                        style: GoogleFonts.bubblegumSans(
                          fontSize: 46.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: const Color(
                                0xFF7CFF6B,
                              ).withValues(alpha: 0.6),
                              blurRadius: 20,
                            ),
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              offset: const Offset(2, 3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 6.h),

                      Text(
                        l10n?.signInToStart ?? 'Sign in to start learning!',
                        style: GoogleFonts.bubblegumSans(
                          fontSize: 17.sp,
                          color: const Color(0xFFD4FFD0),
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              offset: const Offset(1, 1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 36.h),

                      // Google Sign-In Button
                      _buildGoogleButton(l10n),

                      // Apple Sign-In Button (iOS only)
                      if (Platform.isIOS) ...[
                        SizedBox(height: 14.h),
                        _buildAppleButton(l10n),
                      ],

                      SizedBox(height: 28.h),

                      // Privacy & Terms
                      _buildLegalText(l10n),

                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton(AppLocalizations? l10n) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.15),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: UniversalGamingButton(
          onPressed: _handleGoogleSignIn,
          width: 300.w,
          height: 56,
          loading: _isGoogleLoading,
          enabled: !_isLoading,
          backgroundColor: Colors.white,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          borderRadius: 30,
          loadingWidget: _BouncingDotsLoader(color: const Color(0xFFEA4335)),
          iconWidget: _isGoogleLoading
              ? null
              : SvgPicture.asset(Assets.iconsGoogle, width: 24.w, height: 24.h),
          text: l10n?.signInWithGoogle ?? 'Sign in with Google',
          textStyle: GoogleFonts.bubblegumSans(
            color: const Color(0xFF333333),
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAppleButton(AppLocalizations? l10n) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: UniversalGamingButton(
        onPressed: _handleAppleSignIn,
        width: 300.w,
        height: 56,
        loading: _isAppleLoading,
        enabled: !_isLoading,
        backgroundColor: const Color(0xFF1A1A2E),
        shadowColor: Colors.black.withValues(alpha: 0.5),
        borderRadius: 30,
        loadingWidget: const _BouncingDotsLoader(color: Colors.white),
        iconWidget: _isAppleLoading
            ? null
            : Icon(Icons.apple, color: Colors.white, size: 26.sp),
        text: l10n?.signInWithApple ?? 'Sign in with Apple',
        textStyle: GoogleFonts.bubblegumSans(
          color: Colors.white,
          fontSize: 17.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLegalText(AppLocalizations? l10n) {
    final style = GoogleFonts.bubblegumSans(
      fontSize: 12.sp,
      color: const Color(0xFF9ECDA0),
    );
    final linkStyle = GoogleFonts.bubblegumSans(
      fontSize: 12.sp,
      height: 1.7,
      color: const Color(0xFFE0FFD6),
      decoration: TextDecoration.underline,
      decorationColor: const Color(0xFFE0FFD6),
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: l10n?.agreeText ?? 'By continuing, you agree to our'),
          const TextSpan(text: '\n'),
          TextSpan(
            text: l10n?.privacyPolicy ?? 'Privacy Policy',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _openUrl('https://byteberggames.com/privacy'),
          ),
          TextSpan(text: ' ${l10n?.andText ?? 'and'} '),
          TextSpan(
            text: l10n?.termsConditions ?? 'Terms & Conditions',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _openUrl('https://byteberggames.com/terms'),
          ),
        ],
      ),
    );
  }
}

// ─── Animated firefly overlay ────────────────────────────────────────
class _FireflyPainter extends CustomPainter {
  final double t;
  _FireflyPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(99);
    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    for (int i = 0; i < 18; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height * 0.55;
      final drift = sin((t * pi * 2) + i * 0.7) * 6;
      final x = baseX + drift;
      final y = baseY + cos((t * pi * 2) + i * 1.1) * 4;
      final pulse = 0.3 + 0.7 * ((sin((t * pi * 2) + i * 1.3) + 1) / 2);
      final radius = (1.5 + rng.nextDouble() * 2.0) * pulse;

      glowPaint.color = Color.fromRGBO(180, 255, 80, 0.25 * pulse);
      canvas.drawCircle(Offset(x, y), radius + 6, glowPaint);

      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = Color.fromRGBO(255, 255, 200, 0.5 * pulse),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FireflyPainter old) => true;
}

// ─── Static jungle background ────────────────────────────────────────
class _JunglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Night sky gradient — deep indigo to dark jungle green
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFF0A1628),
          Color(0xFF0D2137),
          Color(0xFF0B3328),
          Color(0xFF0E4A2A),
          Color(0xFF0A3318),
        ],
        stops: const [0.0, 0.2, 0.45, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // Moon glow
    canvas.drawCircle(
      Offset(w * 0.75, h * 0.1),
      w * 0.25,
      Paint()
        ..color = const Color(0xFFFFF8E1).withValues(alpha: 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50),
    );
    canvas.drawCircle(
      Offset(w * 0.75, h * 0.1),
      w * 0.12,
      Paint()
        ..color = const Color(0xFFFFF8E1).withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
    );

    // Crescent moon
    final moonCenter = Offset(w * 0.75, h * 0.1);
    final moonR = w * 0.055;
    final moonPath = Path()
      ..addOval(Rect.fromCircle(center: moonCenter, radius: moonR));
    final moonCut = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(
            moonCenter.dx + moonR * 0.45,
            moonCenter.dy - moonR * 0.25,
          ),
          radius: moonR * 0.85,
        ),
      );
    final crescent = Path.combine(PathOperation.difference, moonPath, moonCut);
    canvas.drawPath(crescent, Paint()..color = const Color(0xFFFFF9C4));
    canvas.drawPath(
      crescent,
      Paint()
        ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Stars
    final rng = Random(7);
    final starPaint = Paint();
    for (int i = 0; i < 35; i++) {
      final x = rng.nextDouble() * w;
      final y = rng.nextDouble() * h * 0.30;
      final r = 0.5 + rng.nextDouble() * 1.5;
      final a = 0.3 + rng.nextDouble() * 0.5;
      starPaint.color = Color.fromRGBO(255, 255, 230, a);
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }

    // Far background trees (silhouettes)
    _drawFarTrees(canvas, w, h);

    // Left thick tree
    _drawThickTree(canvas, w * 0.02, h * 0.05, h, w * 0.10, true);
    // Right thick tree
    _drawThickTree(canvas, w * 0.92, h * 0.03, h, w * 0.11, false);

    // Hanging vines
    _drawVine(canvas, w * 0.18, h * 0.08, h * 0.40, true);
    _drawVine(canvas, w * 0.07, h * 0.22, h * 0.48, false);
    _drawVine(canvas, w * 0.84, h * 0.06, h * 0.38, false);
    _drawVine(canvas, w * 0.95, h * 0.20, h * 0.45, true);

    // Ground layers
    _drawGround(canvas, w, h);

    // Mushrooms & flowers
    _drawMushroom(
      canvas,
      Offset(w * 0.12, h * 0.86),
      14,
      const Color(0xFFFF6B6B),
    );
    _drawMushroom(
      canvas,
      Offset(w * 0.85, h * 0.87),
      11,
      const Color(0xFFFFAB40),
    );
    _drawMushroom(
      canvas,
      Offset(w * 0.62, h * 0.85),
      9,
      const Color(0xFFE040FB),
    );
    _drawFlower(canvas, Offset(w * 0.30, h * 0.86), 8, const Color(0xFFFF80AB));
    _drawFlower(canvas, Offset(w * 0.72, h * 0.86), 7, const Color(0xFFFFEB3B));
    _drawFlower(canvas, Offset(w * 0.48, h * 0.87), 6, const Color(0xFF80D8FF));

    // Foreground grass tufts
    _drawGrassTuft(canvas, w * 0.05, h * 0.88, 18);
    _drawGrassTuft(canvas, w * 0.22, h * 0.86, 14);
    _drawGrassTuft(canvas, w * 0.40, h * 0.87, 16);
    _drawGrassTuft(canvas, w * 0.58, h * 0.85, 15);
    _drawGrassTuft(canvas, w * 0.78, h * 0.87, 17);
    _drawGrassTuft(canvas, w * 0.93, h * 0.86, 13);

    // Bottom dark overlay for text readability
    final overlayPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF0A1628).withValues(alpha: 0.4),
          const Color(0xFF0A1628).withValues(alpha: 0.85),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, h * 0.45, w, h * 0.55));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.45, w, h * 0.55), overlayPaint);
  }

  void _drawFarTrees(Canvas canvas, double w, double h) {
    final paint = Paint();
    final rng = Random(13);
    for (int i = 0; i < 8; i++) {
      final x = w * (i / 8.0) + rng.nextDouble() * w * 0.1;
      final treeH = h * (0.15 + rng.nextDouble() * 0.12);
      final treeW = w * (0.06 + rng.nextDouble() * 0.04);
      final baseY = h * 0.40;

      // Trunk
      paint.color = const Color(0xFF0C2E1A);
      canvas.drawRect(
        Rect.fromLTWH(
          x - treeW * 0.15,
          baseY - treeH * 0.4,
          treeW * 0.3,
          treeH * 0.5,
        ),
        paint,
      );

      // Canopy (triangle)
      final canopyPath = Path();
      canopyPath.moveTo(x, baseY - treeH);
      canopyPath.lineTo(x - treeW, baseY - treeH * 0.3);
      canopyPath.lineTo(x + treeW, baseY - treeH * 0.3);
      canopyPath.close();
      paint.color = Color.fromRGBO(
        10 + rng.nextInt(20),
        50 + rng.nextInt(30),
        20 + rng.nextInt(20),
        0.7,
      );
      canvas.drawPath(canopyPath, paint);
    }
  }

  void _drawThickTree(
    Canvas canvas,
    double x,
    double top,
    double bottom,
    double width,
    bool isLeft,
  ) {
    // Main trunk
    final trunkPath = Path();
    final lean = isLeft ? width * 0.15 : -width * 0.15;
    trunkPath.moveTo(x + lean, top);
    trunkPath.cubicTo(
      x - width * 0.3,
      top + (bottom - top) * 0.3,
      x - width * 0.4,
      top + (bottom - top) * 0.7,
      x - width * 0.3,
      bottom,
    );
    trunkPath.lineTo(x + width * 0.5, bottom);
    trunkPath.cubicTo(
      x + width * 0.5,
      top + (bottom - top) * 0.7,
      x + width * 0.4,
      top + (bottom - top) * 0.3,
      x + lean + width * 0.5,
      top,
    );
    trunkPath.close();

    // Trunk gradient
    canvas.drawPath(
      trunkPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFF2D1810),
            Color(0xFF4A3228),
            Color(0xFF2D1810),
          ],
        ).createShader(Rect.fromLTWH(x - width, top, width * 2, bottom - top)),
    );

    // Bark texture
    final barkPaint = Paint()
      ..color = const Color(0xFF1E0F08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final rng = Random(isLeft ? 1 : 2);
    for (
      double y = top + 40;
      y < bottom - 30;
      y += 18 + rng.nextDouble() * 12
    ) {
      final startX = x - width * 0.1 + rng.nextDouble() * width * 0.3;
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + width * 0.2, y + 5),
        barkPaint,
      );
    }

    // Branch stubs
    _drawBranch(
      canvas,
      Offset(
        x + (isLeft ? width * 0.3 : -width * 0.1),
        top + (bottom - top) * 0.2,
      ),
      isLeft,
      width * 0.6,
    );
    _drawBranch(
      canvas,
      Offset(x + (isLeft ? width * 0.2 : 0), top + (bottom - top) * 0.35),
      !isLeft,
      width * 0.4,
    );

    // Foliage
    final foliageColor1 = const Color(0xFF1B7A40);
    final foliageColor2 = const Color(0xFF28A060);
    final foliageColor3 = const Color(0xFF15602F);

    _drawCanopy(
      canvas,
      Offset(x + lean * 0.5, top - width * 0.2),
      width * 1.2,
      foliageColor3,
    );
    _drawCanopy(
      canvas,
      Offset(x + lean, top + width * 0.1),
      width * 0.9,
      foliageColor1,
    );
    _drawCanopy(
      canvas,
      Offset(x + (isLeft ? -width * 0.3 : width * 0.5), top + width * 0.3),
      width * 0.8,
      foliageColor2,
    );
    _drawCanopy(
      canvas,
      Offset(x + (isLeft ? width * 0.5 : -width * 0.3), top - width * 0.1),
      width * 0.7,
      foliageColor1,
    );
  }

  void _drawBranch(Canvas canvas, Offset start, bool goRight, double length) {
    final path = Path();
    final dir = goRight ? 1.0 : -1.0;
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(
      start.dx + length * 0.5 * dir,
      start.dy - length * 0.15,
      start.dx + length * dir,
      start.dy - length * 0.05,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF3D2B1F)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawCanopy(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()..color = color;
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.4, center.dy + radius * 0.3),
      radius * 0.75,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.45, center.dy + radius * 0.25),
      radius * 0.65,
      paint,
    );
    // Highlight
    canvas.drawCircle(
      Offset(center.dx - radius * 0.15, center.dy - radius * 0.2),
      radius * 0.45,
      Paint()
        ..color = Color.fromRGBO(
          color.r.toInt(),
          (color.g * 255 + 30).clamp(0, 255).toInt(),
          color.b.toInt(),
          0.4,
        ),
    );
  }

  void _drawVine(
    Canvas canvas,
    double startX,
    double startY,
    double endY,
    bool curveRight,
  ) {
    final path = Path();
    path.moveTo(startX, startY);
    final dir = curveRight ? 1.0 : -1.0;
    final len = endY - startY;
    path.cubicTo(
      startX + 20 * dir,
      startY + len * 0.3,
      startX - 10 * dir,
      startY + len * 0.6,
      startX + 8 * dir,
      endY,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF2D7A3E)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Small leaves along vine
    for (double t = 0.2; t <= 0.85; t += 0.22) {
      final y = startY + len * t;
      final x = startX + dir * 10 * sin(t * pi * 2);
      _drawSmallLeaf(canvas, Offset(x, y), curveRight);
    }
  }

  void _drawSmallLeaf(Canvas canvas, Offset pos, bool flipX) {
    final path = Path();
    final dir = flipX ? 1.0 : -1.0;
    path.moveTo(pos.dx, pos.dy);
    path.quadraticBezierTo(
      pos.dx + 10 * dir,
      pos.dy - 6,
      pos.dx + 14 * dir,
      pos.dy + 2,
    );
    path.quadraticBezierTo(pos.dx + 10 * dir, pos.dy + 7, pos.dx, pos.dy);
    canvas.drawPath(path, Paint()..color = const Color(0xFF3DA55B));
  }

  void _drawGround(Canvas canvas, double w, double h) {
    // Back ground layer (darkest)
    final bg = Path()
      ..moveTo(0, h * 0.90)
      ..quadraticBezierTo(w * 0.15, h * 0.86, w * 0.3, h * 0.89)
      ..quadraticBezierTo(w * 0.5, h * 0.92, w * 0.7, h * 0.87)
      ..quadraticBezierTo(w * 0.85, h * 0.85, w, h * 0.88)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(bg, Paint()..color = const Color(0xFF082210));

    // Mid ground (slightly lighter)
    final mg = Path()
      ..moveTo(0, h * 0.91)
      ..quadraticBezierTo(w * 0.2, h * 0.88, w * 0.35, h * 0.90)
      ..quadraticBezierTo(w * 0.55, h * 0.93, w * 0.75, h * 0.89)
      ..quadraticBezierTo(w * 0.9, h * 0.87, w, h * 0.90)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(mg, Paint()..color = const Color(0xFF0D3818));

    // Foreground (richest green)
    final fg = Path()
      ..moveTo(0, h * 0.93)
      ..quadraticBezierTo(w * 0.25, h * 0.90, w * 0.4, h * 0.92)
      ..quadraticBezierTo(w * 0.6, h * 0.95, w * 0.8, h * 0.91)
      ..quadraticBezierTo(w * 0.95, h * 0.89, w, h * 0.92)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(fg, Paint()..color = const Color(0xFF104A22));
  }

  void _drawMushroom(Canvas canvas, Offset base, double size, Color capColor) {
    // Stem
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(base.dx, base.dy - size * 0.3),
          width: size * 0.35,
          height: size * 0.7,
        ),
        Radius.circular(size * 0.1),
      ),
      Paint()..color = const Color(0xFFF5E6D0),
    );

    // Cap
    final capPath = Path();
    capPath.moveTo(base.dx - size * 0.6, base.dy - size * 0.5);
    capPath.quadraticBezierTo(
      base.dx,
      base.dy - size * 1.4,
      base.dx + size * 0.6,
      base.dy - size * 0.5,
    );
    capPath.close();
    canvas.drawPath(capPath, Paint()..color = capColor);

    // Cap spots
    final spotPaint = Paint()..color = Colors.white.withValues(alpha: 0.7);
    canvas.drawCircle(
      Offset(base.dx - size * 0.15, base.dy - size * 0.85),
      size * 0.08,
      spotPaint,
    );
    canvas.drawCircle(
      Offset(base.dx + size * 0.2, base.dy - size * 0.75),
      size * 0.06,
      spotPaint,
    );
    canvas.drawCircle(
      Offset(base.dx, base.dy - size * 0.65),
      size * 0.05,
      spotPaint,
    );

    // Cap glow
    canvas.drawPath(
      capPath,
      Paint()
        ..color = capColor.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  void _drawFlower(Canvas canvas, Offset center, double size, Color color) {
    // Stem
    canvas.drawLine(
      center,
      Offset(center.dx, center.dy - size * 1.5),
      Paint()
        ..color = const Color(0xFF2D7A3E)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // Petals
    final petalCenter = Offset(center.dx, center.dy - size * 1.5);
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72) * pi / 180;
      final petalPath = Path();
      final px = petalCenter.dx + cos(angle) * size * 0.6;
      final py = petalCenter.dy + sin(angle) * size * 0.6;
      petalPath.addOval(
        Rect.fromCenter(
          center: Offset(px, py),
          width: size * 0.55,
          height: size * 0.35,
        ),
      );
      canvas.drawPath(petalPath, Paint()..color = color);
    }

    // Center
    canvas.drawCircle(
      petalCenter,
      size * 0.2,
      Paint()..color = const Color(0xFFFFEB3B),
    );
  }

  void _drawGrassTuft(Canvas canvas, double x, double baseY, double height) {
    final paint = Paint()
      ..color = const Color(0xFF2D8A45)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = -2; i <= 2; i++) {
      final path = Path();
      path.moveTo(x, baseY);
      path.quadraticBezierTo(
        x + i * 5,
        baseY - height * 0.6,
        x + i * 8,
        baseY - height,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Bouncing dots loading animation ─────────────────────────────────
class _BouncingDotsLoader extends StatefulWidget {
  final Color color;
  const _BouncingDotsLoader({required this.color});

  @override
  State<_BouncingDotsLoader> createState() => _BouncingDotsLoaderState();
}

class _BouncingDotsLoaderState extends State<_BouncingDotsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Stagger each dot by 0.2 of the animation cycle
            final delay = i * 0.2;
            final t = (_controller.value - delay) % 1.0;
            // Bounce curve: peaks at t=0.3, returns to 0 by t=0.6
            final bounce = t < 0.5 ? sin(t * pi / 0.5) * 8 : 0.0;
            final scale = t < 0.5 ? 1.0 + sin(t * pi / 0.5) * 0.3 : 1.0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.translate(
                offset: Offset(0, -bounce),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
