import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_routes.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/option_card.dart';
import '../../models/models.dart';
import '../../models/serie.dart';
import '../../services/api_service.dart';

/// Stepper linéaire d'inscription en 4 étapes.
/// Remplace les anciens profile_setup_screen + register_screen + register_preferences_screen.
///
///   1. Identité      (Prénom / Nom / Email / Téléphone / Pays)
///   2. Scolarité     (Rôle / Classe / Série)
///   3. Objectif      (Métier / Filière visé)
///   4. Centres d'intérêt (Matières + Style d'apprentissage)
///
/// Hackaton AI4GOOD : scope réduit à Lycéen / Étudiant, pas de photo de profil.
class SignupStepperScreen extends StatefulWidget {
  const SignupStepperScreen({super.key});

  @override
  State<SignupStepperScreen> createState() => _SignupStepperScreenState();
}

class _SignupStepperScreenState extends State<SignupStepperScreen> {
  final _api = ApiService();
  final _pageController = PageController();
  int _currentStep = 0;

  // ── Étape 1 : Identité ────────────────────────────────────────────────────
  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _selectedCountryCode = 'TG';
  String _dialCode = '+228';

  // ── Étape 2 : Scolarité ───────────────────────────────────────────────────
  _UserRole? _role;
  String? _selectedClasse;
  SerieLycee? _selectedSerie;

  // ── Étape 3 : Objectif ────────────────────────────────────────────────────
  final _objectifCtrl = TextEditingController();

  // ── Étape 4 : Centres d'intérêt ───────────────────────────────────────────
  final Set<String> _selectedMatieres = {};
  String? _selectedStyle;

  // ── Soumission ────────────────────────────────────────────────────────────
  bool _isLoading = false;

  // ── Liste pays extraite de l'ancien register_screen.dart ──────────────────
  static const _countryList = [
    ('TG', '🇹🇬', '+228', 'Togo'),
    ('BJ', '🇧🇯', '+229', 'Bénin'),
    ('BF', '🇧🇫', '+226', 'Burkina Faso'),
    ('CI', '🇨🇮', '+225', "Côte d'Ivoire"),
    ('SN', '🇸🇳', '+221', 'Sénégal'),
    ('ML', '🇲🇱', '+223', 'Mali'),
    ('NE', '🇳🇪', '+227', 'Niger'),
    ('GH', '🇬🇭', '+233', 'Ghana'),
    ('NG', '🇳🇬', '+234', 'Nigeria'),
    ('CM', '🇨🇲', '+237', 'Cameroun'),
    ('CG', '🇨🇬', '+242', 'Congo'),
    ('CD', '🇨🇩', '+243', 'RDC'),
    ('GA', '🇬🇦', '+241', 'Gabon'),
    ('FR', '🇫🇷', '+33', 'France'),
    ('BE', '🇧🇪', '+32', 'Belgique'),
    ('CH', '🇨🇭', '+41', 'Suisse'),
    ('CA', '🇨🇦', '+1', 'Canada'),
    ('US', '🇺🇸', '+1', 'États-Unis'),
  ];

  static const _matieres = [
    'Maths',
    'SVT',
    'Physique',
    'Français',
    'Histoire-Géo',
    'Anglais',
    'Philosophie',
    'Économie',
  ];

  static const _styles = [
    ('textes', 'Par les textes', Icons.menu_book_outlined),
    ('videos', 'Par les vidéos', Icons.play_circle_outline_rounded),
    ('both', 'Les deux', Icons.star_outline_rounded),
  ];

  static const _lyceeClasses = ['Seconde', 'Première', 'Terminale'];

  @override
  void dispose() {
    _pageController.dispose();
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _objectifCtrl.dispose();
    super.dispose();
  }

  // ── Validations par étape ─────────────────────────────────────────────────

  bool get _step1Valid =>
      _prenomCtrl.text.trim().isNotEmpty &&
      _nomCtrl.text.trim().isNotEmpty &&
      _validateEmail(_emailCtrl.text) == null &&
      _passwordCtrl.text.length >= 8 &&
      _phoneCtrl.text.trim().isNotEmpty;

  bool get _step2Valid {
    if (_role == null) return false;
    if (_role == _UserRole.lyceen) {
      if (_selectedClasse == null) return false;
      // Série obligatoire si lycée en Première/Terminale
      if ((_selectedClasse == 'Première' || _selectedClasse == 'Terminale') &&
          _selectedSerie == null) {
        return false;
      }
    }
    return true;
  }

  bool get _step3Valid => _objectifCtrl.text.trim().length >= 2;

  bool get _step4Valid => _selectedStyle != null; // matières restent optionnelles

  bool get _canContinue {
    switch (_currentStep) {
      case 0:
        return _step1Valid;
      case 1:
        return _step2Valid;
      case 2:
        return _step3Valid;
      case 3:
        return _step4Valid;
      default:
        return false;
    }
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email requis';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(v)) return 'Email invalide';
    return null;
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _next() {
    if (!_canContinue) return;
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  // ── Soumission finale ─────────────────────────────────────────────────────

  Future<void> _finish() async {
    setState(() => _isLoading = true);

    try {
      TypeApprenant typeApprenant;

      // Hackaton AI4GOOD : scope limité à Lycéen / Étudiant.
      switch (_role!) {
        case _UserRole.lyceen:
          typeApprenant = TypeApprenant.LYCEEN;
          break;
        case _UserRole.etudiant:
          typeApprenant = TypeApprenant.ETUDIANT;
          break;
      }

      final request = EleveRequest(
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        telephone: '$_dialCode${_phoneCtrl.text.trim()}',
        motDePasse: _passwordCtrl.text,
        // Le backend attend une String libre pour niveauEtude.
        niveauEtude: _selectedClasse ?? _role!.label,
        etablissementActuel: _selectedCountryCode,
        filiere: _objectifCtrl.text.trim(),
        metierSouhaite: _objectifCtrl.text.trim(),
        typeApprenant: typeApprenant,
        matieresPreferees: _selectedMatieres.toList(),
        styleApprentissage: _selectedStyle,
      );
      final response = await _api.auth.inscrireEleve(request);

      await _api.auth.saveEleveProfile(response);

      // Auto-login avec JWT après inscription
      try {
        final token = await _api.auth.login(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
        await _api.auth.saveToken(token.accessToken);
        await _api.auth.saveRefreshToken(token.refreshToken);
        await _api.auth.saveUserData(
          trackingId: token.trackingId,
          role: token.typeUtilisateur,
          nom: response.nom,
          prenom: response.prenom,
          email: response.email,
          niveauEtude: response.niveauEtude,
          filiere: response.filiere,
          metierSouhaite: response.metierSouhaite,
        );
      } catch (_) {
        // Non bloquant : le trackingId est déjà sauvegardé
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final is401 = e is DioException && e.response?.statusCode == 401;
        final message = _api.handleError(e);
        if (is401) {
          _showRegisterUnavailable();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $message')),
          );
        }
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
            const SizedBox(width: 10),
            Flexible(
              child: Text('Inscription réussie !', style: AppTextStyles.headingMedium),
            ),
          ],
        ),
        content: const Text(
          "Votre compte est créé. Bienvenue sur ORIA !",
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.home, (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text("C'est parti !",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  void _showRegisterUnavailable() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 28),
            SizedBox(width: 10),
            Expanded(child: Text('Inscription indisponible', style: AppTextStyles.headingMedium)),
          ],
        ),
        content: const Text(
          "L'inscription élève n'est pas disponible pour le moment. Réessayez plus tard.",
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StepProgressBar(totalSteps: 4, currentStep: _currentStep + 1),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _StepIdentity(),
                  _StepSchooling(),
                  _StepGoal(),
                  _StepInterests(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _prev,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textDark, size: 16),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Étape ${_currentStep + 1} sur 4',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLast = _currentStep == 3;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlineButton(
                label: 'Précédent',
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: _currentStep > 0 ? 1 : 2,
            child: PrimaryButton(
              label: isLast ? "C'est parti !" : 'Continuer',
              isLoading: _isLoading,
              onPressed: _canContinue ? _next : null,
              trailingIcon: isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers (state exposed to child pages) ───────────────────────────────

  void setCountry(String code, String dial) {
    setState(() {
      _selectedCountryCode = code;
      _dialCode = dial;
    });
  }

  void setRole(_UserRole? role) {
    setState(() {
      _role = role;
      // Reset classe + série si le rôle change
      _selectedClasse = null;
      _selectedSerie = null;
    });
  }

  void setClasse(String? classe) {
    setState(() {
      _selectedClasse = classe;
      // Reset série si on quitte Première/Terminale
      if (classe != 'Première' && classe != 'Terminale') {
        _selectedSerie = null;
      }
    });
  }

  void setSerie(SerieLycee? serie) => setState(() => _selectedSerie = serie);

  void toggleMatiere(String m) {
    setState(() {
      if (_selectedMatieres.contains(m)) {
        _selectedMatieres.remove(m);
      } else {
        _selectedMatieres.add(m);
      }
    });
  }

  void setStyle(String? s) => setState(() => _selectedStyle = s);

  /// Permet aux pages enfants de demander un rebuild (remplace `state.setState()`
  /// qui est marqué protected par le linter).
  void rebuild() => setState(() {});
}

// ── Rôle enum (scope hackaton : Lycéen + Étudiant) ──────────────────────────
enum _UserRole {
  lyceen('Lycéen(ne)', Icons.menu_book_outlined),
  etudiant('Étudiant(e)', Icons.account_balance_outlined);

  final String label;
  final IconData icon;
  const _UserRole(this.label, this.icon);
}

// ════════════════════════════════════════════════════════════════════════════
// ÉTAPE 1 — Identité
// ════════════════════════════════════════════════════════════════════════════
class _StepIdentity extends StatelessWidget {
  const _StepIdentity();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_SignupStepperScreenState>()!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('Faisons connaissance', style: AppTextStyles.displayMedium),
          const SizedBox(height: 6),
          const Text(
            'On aura besoin de ces infos pour créer ton compte',
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Prénom',
            hint: 'Kofi',
            controller: state._prenomCtrl,
            onChanged: (_) => state.rebuild(),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Nom',
            hint: 'Adjovi',
            controller: state._nomCtrl,
            onChanged: (_) => state.rebuild(),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Email',
            hint: 'kofi@email.com',
            controller: state._emailCtrl,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => state.rebuild(),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Mot de passe',
            hint: '••••••••',
            controller: state._passwordCtrl,
            isPassword: true,
            onChanged: (_) => state.rebuild(),
          ),
          const SizedBox(height: 20),
          const Text('Pays', style: AppTextStyles.label),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _openCountryPicker(context, state),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder, width: 1.5),
              ),
              child: Row(
                children: [
                  Text(
                    _SignupStepperScreenState._countryList
                        .firstWhere((e) => e.$1 == state._selectedCountryCode,
                            orElse: () => _SignupStepperScreenState._countryList[0])
                        .$2,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _SignupStepperScreenState._countryList
                        .firstWhere((e) => e.$1 == state._selectedCountryCode,
                            orElse: () => _SignupStepperScreenState._countryList[0])
                        .$4,
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textDark),
                  ),
                  const Spacer(),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Téléphone',
            hint: '00 00 00 00',
            controller: state._phoneCtrl,
            keyboardType: TextInputType.phone,
            prefixText: '${state._dialCode} ',
            onChanged: (_) => state.rebuild(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _openCountryPicker(BuildContext context, _SignupStepperScreenState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Choisir un pays', style: AppTextStyles.displayMedium),
            const SizedBox(height: 12),
            const Divider(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _SignupStepperScreenState._countryList.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final (code, flag, dial, name) =
                      _SignupStepperScreenState._countryList[i];
                  final selected = code == state._selectedCountryCode;
                  return ListTile(
                    leading: Text(flag, style: const TextStyle(fontSize: 28)),
                    title: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Text(dial,
                        style: const TextStyle(color: AppColors.textMedium)),
                    selected: selected,
                    selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                    onTap: () {
                      state.setCountry(code, dial);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ÉTAPE 2 — Scolarité
// ════════════════════════════════════════════════════════════════════════════
class _StepSchooling extends StatelessWidget {
  const _StepSchooling();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_SignupStepperScreenState>()!;
    // Hackaton AI4GOOD : on demande la classe uniquement pour le lycée.
    final showClasse = state._role == _UserRole.lyceen;
    final classes = _SignupStepperScreenState._lyceeClasses;
    final showSerie = state._role == _UserRole.lyceen &&
        (state._selectedClasse == 'Première' || state._selectedClasse == 'Terminale');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('Ta scolarité', style: AppTextStyles.displayMedium),
          const SizedBox(height: 6),
          const Text(
            'Quelques infos pour personnaliser tes recommandations',
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: 24),
          const Text('Je suis...', style: AppTextStyles.label),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.4,
            children: _UserRole.values.map((r) {
              return OptionCard(
                icon: r.icon,
                label: r.label,
                isSelected: state._role == r,
                onTap: () => state.setRole(r),
              );
            }).toList(),
          ),
          if (showClasse) ...[
            const SizedBox(height: 24),
            const Text('Classe actuelle', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder, width: 1.5),
              ),
              child: DropdownButtonFormField<String>(
                initialValue: state._selectedClasse,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                hint: Text('Sélectionner une classe',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight)),
                items: classes
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: state.setClasse,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMedium),
              ),
            ),
          ],
          if (showSerie) ...[
            const SizedBox(height: 24),
            const Text('Série', style: AppTextStyles.label),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: SerieLycee.values.map((s) {
                return OptionCard(
                  label: s.code,
                  sublabel: s.label,
                  isSelected: state._selectedSerie == s,
                  onTap: () => state.setSerie(s),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ÉTAPE 3 — Objectif
// ════════════════════════════════════════════════════════════════════════════
class _StepGoal extends StatelessWidget {
  const _StepGoal();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_SignupStepperScreenState>()!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('Ton objectif', style: AppTextStyles.displayMedium),
          const SizedBox(height: 6),
          const Text(
            'Décris en un mot ou deux le métier ou la filière que tu vises',
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Métier ou filière visé(e)',
            hint: 'Médecin, Ingénieur logiciel, Professeur…',
            controller: state._objectifCtrl,
            onChanged: (_) => state.rebuild(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Tu pourras modifier ton objectif à tout moment dans ton profil.",
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ÉTAPE 4 — Centres d'intérêt
// ════════════════════════════════════════════════════════════════════════════
class _StepInterests extends StatelessWidget {
  const _StepInterests();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_SignupStepperScreenState>()!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('Tes centres d\'intérêt', style: AppTextStyles.displayMedium),
          const SizedBox(height: 6),
          const Text(
            'Ces infos nous aident à personnaliser tes recommandations',
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Flexible(
                child: Text('Matières préférées', style: AppTextStyles.headingMedium),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'OPTIONNEL',
                  style: AppTextStyles.caption.copyWith(fontSize: 10, letterSpacing: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _SignupStepperScreenState._matieres.map((m) {
              final selected = state._selectedMatieres.contains(m);
              return GestureDetector(
                onTap: () => state.toggleMatiere(m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.cardBorder,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    m,
                    style: AppTextStyles.label.copyWith(
                      color: selected ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          const Text(
            'Comment tu préfères apprendre ?',
            style: AppTextStyles.headingMedium,
          ),
          const SizedBox(height: 12),
          ..._SignupStepperScreenState._styles.map((s) {
            final (key, label, icon) = s;
            final selected = state._selectedStyle == key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OptionCard(
                icon: icon,
                label: label,
                isSelected: selected,
                onTap: () => state.setStyle(key),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
