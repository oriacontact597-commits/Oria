import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_routes.dart';
import '../../widgets/common_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.profileSetup);
    }
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  _animController.reset();
                  _animController.forward();
                },
                children: const [
                  _OnboardingPage1(),
                  _OnboardingPage2(),
                  _OnboardingPage3(),
                ],
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  DotIndicator(count: 3, current: _currentPage),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: _currentPage < 2 ? 'Suivant' : 'Commencer',
                    onPressed: _nextPage,
                    trailingIcon: _currentPage < 2 ? null : Icons.arrow_forward_rounded,
                  ),
                  const SizedBox(height: 16),
                  if (_currentPage < 2)
                    GestureDetector(
                      onTap: _skip,
                      child: Text(
                        'Passer',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMedium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _skip,
                      child: RichText(
                        text: TextSpan(
                          text: "J'ai déjà un compte  ",
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMedium,
                          ),
                          children: [
                            TextSpan(
                              text: 'Se connecter',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page 1: Découvre ta voie ──────────────────────────────────────────────
class _OnboardingPage1 extends StatelessWidget {
  const _OnboardingPage1();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // Illustration — paths diagram
          SizedBox(
            height: 220,
            child: CustomPaint(
              painter: _PathDiagramPainter(),
              child: const SizedBox.expand(),
            ),
          ),
          const Spacer(flex: 2),
          const Text(
            'Découvre les filières adaptées à ton profil',
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Explore les séries, filières et métiers qui correspondent vraiment à ton profil',
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

// ─── Page 2: Universités ────────────────────────────────────────────────────
class _OnboardingPage2 extends StatelessWidget {
  const _OnboardingPage2();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // Illustration — campus / building
          SizedBox(
            height: 220,
            child: _CampusIllustration(),
          ),
          const Spacer(flex: 2),
          const Text(
            'Explore les universités et établissements',
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            "Découvre les universités togolaises, leurs programmes et leurs conditions d'admission.",
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

// ─── Page 3: ORIA assistant ─────────────────────────────────────────────────
class _OnboardingPage3 extends StatelessWidget {
  const _OnboardingPage3();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          SizedBox(
            height: 220,
            child: _OriaAssistantIllustration(),
          ),
          const Spacer(flex: 2),
          const Text(
            'Discute avec ORIA, ton assistant IA',
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            "Pose tes questions 24h/24. ORIA t'oriente en s'appuyant sur les données du système éducatif togolais.",
            style: AppTextStyles.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

// ─── Custom Painter: Path diagram (page 1) ─────────────────────────────────
class _PathDiagramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final paintBlue = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final paintOrange = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Center bottom dot
    canvas.drawCircle(
      Offset(cx, cy + 50),
      10,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.fill,
    );

    // Left branch (blue)
    final pathLeft = Path()
      ..moveTo(cx, cy + 50)
      ..cubicTo(cx - 20, cy, cx - 60, cy - 30, cx - 80, cy - 60);
    canvas.drawPath(pathLeft, paintBlue);

    // Right branch (blue)
    final pathRight = Path()
      ..moveTo(cx, cy + 50)
      ..cubicTo(cx + 20, cy, cx + 60, cy - 30, cx + 80, cy - 60);
    canvas.drawPath(pathRight, paintBlue);

    // Center branch (orange)
    final pathCenter = Path()
      ..moveTo(cx, cy + 50)
      ..lineTo(cx, cy - 60);
    canvas.drawPath(pathCenter, paintOrange);

    // Left circle
    canvas.drawCircle(
      Offset(cx - 80, cy - 60),
      28,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx - 80, cy - 60),
      28,
      paintBlue,
    );

    // Center circle (orange, larger)
    canvas.drawCircle(
      Offset(cx, cy - 70),
      32,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(Offset(cx, cy - 70), 32, paintOrange);

    // Right circle
    canvas.drawCircle(
      Offset(cx + 80, cy - 60),
      28,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(Offset(cx + 80, cy - 60), 28, paintBlue);

    // Icons inside circles (simplified)
    final iconPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    // graduation cap left
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 80, cy - 62), width: 18, height: 14),
        const Radius.circular(2),
      ),
      iconPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Campus Illustration (page 2) ───────────────────────────────────────────
class _CampusIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sun / sky background circle
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
          // Main building (center)
          Positioned(
            bottom: 30,
            child: Container(
              width: 110,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
              child: Stack(
                children: [
                  // Pillars
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          4,
                          (i) => Container(
                            width: 8,
                            height: 56,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Roof triangle accent
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Left smaller building
          Positioned(
            bottom: 30,
            left: 30,
            child: Container(
              width: 44,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    3,
                    (i) => Container(
                      width: double.infinity,
                      height: 8,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Right smaller building
          Positioned(
            bottom: 30,
            right: 30,
            child: Container(
              width: 44,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    4,
                    (i) => Container(
                      width: double.infinity,
                      height: 8,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Floating graduation cap (top-left)
          Positioned(
            top: 14,
            left: 24,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 22),
            ),
          ),
          // Floating map pin (top-right)
          Positioned(
            top: 20,
            right: 16,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
            ),
          ),
          // Ground line
          Positioned(
            bottom: 28,
            left: 20,
            right: 20,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ORIA Assistant Illustration (page 3) ──────────────────────────────────
class _OriaAssistantIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow halo
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
          // Phone mockup (center)
          Container(
            width: 120,
            height: 170,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder, width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 6)),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                // AI avatar bubble (received)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                        bottomLeft: Radius.circular(2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Container(width: 30, height: 6,
                            decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(3))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // User bubble (sent)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(2),
                      ),
                    ),
                    child: Container(
                      width: 40, height: 6,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // AI avatar bubble 2
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                        bottomLeft: Radius.circular(2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Container(width: 22, height: 6,
                            decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(3))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating star (top-left)
          Positioned(
            top: 12,
            left: 24,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
          ),
          // Floating chat (top-right)
          Positioned(
            top: 18,
            right: 20,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
            ),
          ),
          // Floating orb (bottom-left)
          Positioned(
            bottom: 24,
            left: 16,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.bolt_rounded, color: AppColors.accent, size: 18),
            ),
          ),
          // Floating heart (bottom-right)
          Positioned(
            bottom: 30,
            right: 12,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
