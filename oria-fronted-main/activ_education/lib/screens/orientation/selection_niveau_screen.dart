// lib/screens/orientation/selection_niveau_screen.dart
//
// Écran "sélection du niveau actuel" — Phase 4 du Module Prédiction.
// Affiche les 7 niveaux canoniques (récupérés via GET /api/v1/niveaux)
// sous forme de grille de cartes. Au tap, l'écran PUT le niveau sur
// l'élève (PUT /api/v1/eleves/{id}) puis redirige vers la saisie des
// bulletins (3 années).

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_routes.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class SelectionNiveauScreen extends StatefulWidget {
  const SelectionNiveauScreen({super.key});

  @override
  State<SelectionNiveauScreen> createState() => _SelectionNiveauScreenState();
}

class _SelectionNiveauScreenState extends State<SelectionNiveauScreen> {
  final _api = ApiService();

  List<NiveauModel> _niveaux = [];
  String? _selectedCode;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final niveaux = await _api.prediction.listerNiveaux();
      setState(() {
        _niveaux = niveaux;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = _api.handleError(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _valider() async {
    if (_selectedCode == null) {
      setState(() => _error = 'Veuillez sélectionner ton niveau actuel.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final trackingId = await _api.getTrackingId();
      if (trackingId == null) {
        setState(() {
          _error = 'Vous devez être connecté';
          _isSubmitting = false;
        });
        return;
      }
      await _api.prediction.majNiveauEleve(trackingId, _selectedCode!);

      // Récupère le libellé humain pour le passer à l'écran suivant
      final selected = _niveaux.firstWhere(
        (n) => n.code == _selectedCode,
        orElse: () => NiveauModel(
          code: _selectedCode!,
          label: _selectedCode!,
          categorie: '',
          codeCourt: '',
        ),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.bulletinsHistorique,
        arguments: {
          'niveauCode': selected.code,
          'niveauLabel': selected.label,
        },
      );
    } catch (e) {
      setState(() {
        _error = _api.handleError(e);
        _isSubmitting = false;
      });
    }
  }

  IconData _iconForCategorie(String categorie) {
    switch (categorie) {
      case 'college':
        return Icons.school;
      case 'secondaire':
        return Icons.menu_book;
      case 'superieur':
        return Icons.workspace_premium;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ton niveau actuel'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 24),
            Text(_error!, style: AppTextStyles.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Réessayer', onPressed: _load),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Bandeau d'explication
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: AppColors.backgroundGrey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              const SizedBox(height: 8),
              Text(
                'Cette information permet de te proposer des filières adaptées à ton parcours.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMedium),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemCount: _niveaux.length,
            itemBuilder: (context, i) {
              final n = _niveaux[i];
              final isSelected = n.code == _selectedCode;
              return _NiveauCard(
                niveau: n,
                icon: _iconForCategorie(n.categorie),
                isSelected: isSelected,
                onTap: () => setState(() => _selectedCode = n.code),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                if (_error != null && _selectedCode != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_error!,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.error)),
                  ),
                PrimaryButton(
                  label: _isSubmitting
                      ? 'Enregistrement…'
                      : 'Continuer',
                  onPressed: _isSubmitting ? null : _valider,
                  isLoading: _isSubmitting,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NiveauCard extends StatelessWidget {
  final NiveauModel niveau;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NiveauCard({
    required this.niveau,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 36,
                color: isSelected ? Colors.white : AppColors.primary),
            const SizedBox(height: 12),
            Text(
              niveau.label,
              style: AppTextStyles.headingMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                niveau.codeCourt,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? Colors.white : AppColors.textMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
