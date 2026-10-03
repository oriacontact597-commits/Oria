import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_section_header.dart';
import 'quiz_screen.dart';

/// Page d'introduction au Diagnostic RIASEC.
/// Affiche les 6 dimensions RIASEC sous forme de cartes colorées.
/// L'utilisateur choisit par où commencer.
class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  final List<QuizIntro> _quizz = const [
    QuizIntro(
      code: 'R',
      label: 'Réaliste',
      tagline: 'Pratique, concret, manuel',
      icon: Icons.handyman_outlined,
      color: AppColors.success,
      progress: 0.0,
    ),
    QuizIntro(
      code: 'I',
      label: 'Investigateur',
      tagline: 'Curieux, analytique, recherche',
      icon: Icons.science_outlined,
      color: AppColors.primary,
      progress: 0.45,
    ),
    QuizIntro(
      code: 'A',
      label: 'Artistique',
      tagline: 'Créatif, expressif, original',
      icon: Icons.palette_outlined,
      color: AppColors.accent,
      progress: 0.0,
    ),
    QuizIntro(
      code: 'S',
      label: 'Social',
      tagline: 'Aide les autres, empathique',
      icon: Icons.favorite_border,
      color: Color(0xFFEC4899),
      progress: 0.20,
    ),
    QuizIntro(
      code: 'E',
      label: 'Entreprenant',
      tagline: 'Leader, décideur, ambitieux',
      icon: Icons.rocket_launch_outlined,
      color: Color(0xFF8B5CF6),
      progress: 0.0,
    ),
    QuizIntro(
      code: 'C',
      label: 'Conventionnel',
      tagline: 'Organisé, structuré, rigoureux',
      icon: Icons.fact_check_outlined,
      color: AppColors.warning,
      progress: 0.0,
    ),
  ];

  int get _completed => _quizz.where((q) => q.progress >= 1.0).length;
  int get _started => _quizz.where((q) => q.progress > 0).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Diagnostic RIASEC'),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero : progression
          SliverToBoxAdapter(child: _buildHero()),
          // Section "Ta progression"
          SliverToBoxAdapter(
            child: AppSectionHeader(
              title: 'Ta progression',
              actionLabel: '$_started/${_quizz.length} démarrés',
            ),
          ),
          SliverToBoxAdapter(child: _buildStatsRow()),
          SliverToBoxAdapter(
            child: AppSectionHeader(
              title: 'Les 6 dimensions',
              actionLabel: null,
            ),
          ),
          // Grille des 6 quiz
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, i) => _buildQuizCard(_quizz[i]),
                childCount: _quizz.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
      ),
    );
  }

  // ─── Hero ────────────────────────────────────────────────────────────
  Widget _buildHero() {
    final pct = _completed / _quizz.length;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AppCard(
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.psychology_alt_rounded,
                color: Colors.white, size: 32),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Découvre ton profil RIASEC',
              style: TextStyle(
                fontFamily: AppTextStyles.headingFontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '6 quiz rapides pour cerner tes forces, tes affinités, ton orientation idéale.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Barre de progression
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.25),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$_completed/${_quizz.length} dimensions complétées',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Stats row (très simple) ─────────────────────────────────────────
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Text('$_started', style: AppTextStyles.displayMedium),
                  Text('démarrés', style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Text('$_completed',
                      style: AppTextStyles.displayMedium
                          .copyWith(color: AppColors.success)),
                  Text('terminés', style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Text('${_quizz.length - _started}',
                      style: AppTextStyles.displayMedium
                          .copyWith(color: AppColors.accent)),
                  Text('à faire', style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Carte 6 quiz ───────────────────────────────────────────────────
  Widget _buildQuizCard(QuizIntro q) {
    final status = q.progress >= 1.0
        ? _QuizStatus.done
        : (q.progress > 0 ? _QuizStatus.inProgress : _QuizStatus.todo);
    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QuizScreen()),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: q.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(q.icon, color: q.color, size: 20),
              ),
              if (status == _QuizStatus.done)
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 18),
              if (status == _QuizStatus.inProgress)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    value: q.progress,
                    strokeWidth: 2,
                    color: q.color,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            q.label,
            style: AppTextStyles.headingMedium,
          ),
          const SizedBox(height: 2),
          Text(
            q.tagline,
            style: AppTextStyles.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

enum _QuizStatus { todo, inProgress, done }

class QuizIntro {
  final String code;
  final String label;
  final String tagline;
  final IconData icon;
  final Color color;
  final double progress;

  const QuizIntro({
    required this.code,
    required this.label,
    required this.tagline,
    required this.icon,
    required this.color,
    required this.progress,
  });
}
