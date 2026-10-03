import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/base_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_section_header.dart';
import '../explorer/explorer_screen.dart';
import '../diagnostic/quiz_list_screen.dart';
import '../profile/profile_screen.dart';
import '../chat/oria_screen.dart';

/// Page d'accueil ORIA-first.
/// Le callout gradient bleu/violet est l'élément central : il invite à parler à ORIA.
/// 3 chips de suggestions (pré-remplissent ORIA) + 2 cartes raccourcies.
class HomeOriaScreen extends StatefulWidget {
  const HomeOriaScreen({super.key});

  @override
  State<HomeOriaScreen> createState() => _HomeOriaScreenState();
}

class _HomeOriaScreenState extends State<HomeOriaScreen> {
  String _prenom = '';

  @override
  void initState() {
    super.initState();
    _loadPrenom();
  }

  Future<void> _loadPrenom() async {
    try {
      final prenom = await BaseService.readSecure('user_prenom');
      final nom = await BaseService.readSecure('user_nom');
      if (mounted && (prenom != null || nom != null)) {
        final first = (prenom ?? nom ?? '').trim();
        setState(() => _prenom = first.split(' ').first);
      }
    } catch (_) {
      // pas grave si pas chargé : reste vide
    }
  }

  void _openOriaWithPrompt(String prompt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OriaScreen(initialPrompt: prompt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildHeroTitle()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            SliverToBoxAdapter(child: _buildCallout()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            SliverToBoxAdapter(child: _buildSuggestionChips()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            SliverToBoxAdapter(
              child: AppSectionHeader(
                title: 'Découvrir',
                actionLabel: 'Voir tout',
                onAction: () {},
              ),
            ),
            SliverToBoxAdapter(child: _buildQuickCards()),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Avatar rond
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: AppShadows.card,
              ),
              alignment: Alignment.center,
              child: Text(
                _prenom.isNotEmpty ? _prenom[0].toUpperCase() : '✨',
                style: AppTextStyles.headingMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Spacer(),
          // Bouton ORIA discreet
          _RoundIconButton(
            icon: Icons.auto_awesome,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OriaScreen()),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _RoundIconButton(
            icon: Icons.notifications_none,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ─── Hero title ─────────────────────────────────────────────────────────
  Widget _buildHeroTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _prenom.isNotEmpty ? 'Bonjour, $_prenom 👋' : 'Bonjour 👋',
            style: AppTextStyles.displayLarge.copyWith(
              fontSize: 30,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Que veux-tu explorer aujourd\'hui ?',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMedium),
          ),
        ],
      ),
    );
  }

  // ─── Callout ORIA (gradient) ─────────────────────────────────────────────
  Widget _buildCallout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Hero(
        tag: 'oria-callout',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OriaScreen(),
              ),
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.gradientStart,
                    AppColors.gradientEnd,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gradientStart.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Demande à ORIA',
                          style: TextStyle(
                            fontFamily: AppTextStyles.headingFontFamily,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Orientation, métiers, établissements',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Chips suggestions ─────────────────────────────────────────────────
  Widget _buildSuggestionChips() {
    final suggestions = const [
      ('🎓', 'Je suis en Terminale'),
      ('💼', 'Je veux devenir ingénieur'),
      ('📊', 'Comparer 2 filières'),
      ('📍', 'Établissements à Lomé'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final (emoji, label) = suggestions[i];
          return GestureDetector(
            onTap: () => _openOriaWithPrompt(label),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Cartes raccourcies (Bibliothèque, Diagnostic) ──────────────────────
  Widget _buildQuickCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _ShortcutCard(
              icon: Icons.menu_book_rounded,
              title: 'Bibliothèque',
              subtitle: '363 fiches',
              gradient: const [AppColors.primary, AppColors.primaryLight],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExplorerScreen()),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _ShortcutCard(
              icon: Icons.psychology_alt_rounded,
              title: 'Diagnostic',
              subtitle: 'Découvrir mon profil',
              gradient: const [AppColors.accent, AppColors.accentLight],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuizListScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sous-widgets ──────────────────────────────────────────────────────────

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceSubtle,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Icon(icon, color: AppColors.textDark, size: 20),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.headingMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
