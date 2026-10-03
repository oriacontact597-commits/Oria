// lib/screens/orientation/bulletins_historique_screen.dart
//
// Écran "Ajoute tes 3 derniers bulletins" — Phase 4 du Module Prédiction.
// Formulaire 3 sections (3 années consécutives), chacune avec :
//   - 1 ligne "Moyenne générale" obligatoire (source du moteur de trajectoire
//     Phase 3)
//   - 0..N lignes supplémentaires "par matière" (facultatif)
//
// Bouton "Voir mes recommandations" → Recommandation3SignauxScreen.

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_routes.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class BulletinsHistoriqueScreen extends StatefulWidget {
  /// Optionnels : passés par SelectionNiveauScreen pour pré-remplir
  /// l'en-tête. Si null, l'utilisateur peut quand même saisir.
  final String? niveauCode;
  final String? niveauLabel;

  const BulletinsHistoriqueScreen({
    super.key,
    this.niveauCode,
    this.niveauLabel,
  });

  @override
  State<BulletinsHistoriqueScreen> createState() =>
      _BulletinsHistoriqueScreenState();
}

/// Une ligne de matière dans une année donnée.
class _NoteEntry {
  final TextEditingController matiere;
  final TextEditingController note;
  bool estMoyenneGenerale;

  _NoteEntry({String? matiereInit, this.estMoyenneGenerale = false})
      : matiere = TextEditingController(text: matiereInit ?? ''),
        note = TextEditingController();

  void dispose() {
    matiere.dispose();
    note.dispose();
  }
}

/// Une année scolaire avec ses matières.
class _AnneeEntry {
  final TextEditingController anneeScolaire;
  final TextEditingController classe;
  final List<_NoteEntry> notes = [];

  _AnneeEntry({required String annee, required String classeDefaut})
      : anneeScolaire = TextEditingController(text: annee),
        classe = TextEditingController(text: classeDefaut);

  void dispose() {
    anneeScolaire.dispose();
    classe.dispose();
    for (final n in notes) {
      n.dispose();
    }
  }
}

class _BulletinsHistoriqueScreenState extends State<BulletinsHistoriqueScreen> {
  final _api = ApiService();

  late List<_AnneeEntry> _annees;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  String? _eleveId;

  /// Classes par défaut selon le niveau (heuristique simple).
  String _classeParDefaut() {
    final code = widget.niveauCode;
    if (code == null) return '';
    if (code == 'COLLEGE') return '3ème';
    if (code == 'LYCEE_2ND') return 'Seconde';
    if (code == 'LYCEE_1ERE') return 'Première';
    if (code == 'LYCEE_TLE') return 'Terminale';
    if (code == 'BAC_1') return 'Licence 1';
    if (code == 'BAC_2') return 'Licence 2';
    if (code == 'BAC_3') return 'Licence 3';
    return '';
  }

  /// Génère les 3 dernières années scolaires (ex. 2025-2026, 2024-2025, 2023-2024).
  List<String> _troisDernieresAnnees() {
    final now = DateTime.now();
    final currentYear = now.month >= 9 ? now.year : now.year - 1;
    return [
      '$currentYear-${currentYear + 1}',
      '${currentYear - 1}-$currentYear',
      '${currentYear - 2}-${currentYear - 1}',
    ];
  }

  @override
  void initState() {
    super.initState();
    _annees = [];
    _load();
  }

  @override
  void dispose() {
    for (final a in _annees) {
      a.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final id = await _api.getTrackingId();
      if (!mounted) return;
      if (id == null) {
        setState(() {
          _error = 'Vous devez être connecté';
          _isLoading = false;
        });
        return;
      }
      _eleveId = id;

      // 1) Charger l'historique existant
      final existantes =
          await _api.prediction.getHistoriqueComplet(id);

      // 2) Initialiser 3 années pré-remplies
      final annees = _troisDernieresAnnees();
      final classeDefaut = _classeParDefaut();
      _annees = annees
          .map((a) => _AnneeEntry(annee: a, classeDefaut: classeDefaut))
          .toList();

      // 3) Pour chaque année, pré-remplir avec l'existant
      // (on matche par annee_scolaire). La 1ère ligne ajoutée est forcée
      // "moyenne générale" si la liste est vide.
      for (var i = 0; i < _annees.length; i++) {
        final anneeCible = annees[i];
        final lignesPourAnnee =
            existantes.where((n) => n.anneeScolaire == anneeCible).toList();

        if (lignesPourAnnee.isEmpty) {
          // On ajoute une ligne "Moyenne générale" vide par défaut
          _annees[i].notes.add(
                _NoteEntry(matiereInit: 'Moyenne générale', estMoyenneGenerale: true),
              );
        } else {
          // On remplit avec l'existant
          for (final n in lignesPourAnnee) {
            _annees[i].notes.add(
              _NoteEntry(
                matiereInit: n.matiere ?? 'Moyenne générale',
                estMoyenneGenerale: n.estMoyenneGenerale,
              )..note.text = n.moyenne.toStringAsFixed(1),
            );
            if (lignesPourAnnee.first == n && n.classe.isNotEmpty) {
              _annees[i].classe.text = n.classe;
            }
          }
        }
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _api.handleError(e);
        _isLoading = false;
      });
    }
  }

  /// Ajoute une ligne matière à l'année `i` (la ligne "Moyenne générale"
  /// reste en tête).
  void _ajouterNote(int anneeIndex) {
    setState(() {
      _annees[anneeIndex].notes.add(_NoteEntry());
    });
  }

  void _supprimerNote(int anneeIndex, int noteIndex) {
    setState(() {
      // On empêche de supprimer la seule ligne "Moyenne générale" d'une année
      final entry = _annees[anneeIndex].notes[noteIndex];
      if (entry.estMoyenneGenerale &&
          _annees[anneeIndex]
              .notes
              .where((n) => n.estMoyenneGenerale)
              .length ==
              1) {
        return;
      }
      entry.dispose();
      _annees[anneeIndex].notes.removeAt(noteIndex);
    });
  }

  /// Vérifie la validité et envoie toutes les lignes au backend.
  /// On envoie TOUT (même les partiels) ; le backend upsert par
  /// (eleve_id, annee_scolaire, matiere) — l'idempotence est gérée côté
  /// service Phase 2.
  Future<void> _valider() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      if (_eleveId == null) {
        setState(() {
          _error = 'Vous devez être connecté';
          _isSubmitting = false;
        });
        return;
      }

      // Pré-valide côté client
      int nbLignes = 0;
      for (final a in _annees) {
        for (final n in a.notes) {
          final noteVal = double.tryParse(n.note.text.replaceAll(',', '.'));
          if (noteVal != null && n.matiere.text.trim().isNotEmpty) {
            nbLignes++;
          }
        }
      }
      if (nbLignes == 0) {
        setState(() {
          _error =
              'Renseigne au moins une moyenne (la moyenne générale d\'une année) pour pouvoir calculer ta trajectoire.';
          _isSubmitting = false;
        });
        return;
      }

      // POST séquentiel (volumétrie faible : 3-15 lignes max)
      for (final a in _annees) {
        for (final n in a.notes) {
          final noteVal = double.tryParse(n.note.text.replaceAll(',', '.'));
          if (noteVal == null) continue;
          if (n.matiere.text.trim().isEmpty) continue;
          await _api.prediction.ajouterNoteHistorique(
            _eleveId!,
            NoteHistoriqueRequest(
              anneeScolaire: a.anneeScolaire.text.trim(),
              classe: a.classe.text.trim().isEmpty
                  ? _classeParDefaut()
                  : a.classe.text.trim(),
              niveau: widget.niveauCode,
              matiere: n.estMoyenneGenerale
                  ? null
                  : n.matiere.text.trim(),
              moyenne: noteVal,
              estPartielle: false,
              estMoyenneGenerale: n.estMoyenneGenerale,
            ),
          );
        }
      }

      if (!mounted) return;
      // Enchaîne sur la recommandation 3 signaux
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.recommandation3Signaux,
      );
    } catch (e) {
      setState(() {
        _error = _api.handleError(e);
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes bulletins'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _isLoading
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
            Text(_error!,
                style: AppTextStyles.bodyLarge, textAlign: TextAlign.center),
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
        if (widget.niveauLabel != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.backgroundGrey,
            child: Row(
              children: [
                const Icon(Icons.school, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Niveau : ${widget.niveauLabel}',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textDark),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _annees.length,
            itemBuilder: (context, i) => _buildAnneeCard(i),
          ),
        ),
        if (_error != null && !_isSubmitting)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(_error!,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.error),
                textAlign: TextAlign.center),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                PrimaryButton(
                  label: _isSubmitting
                      ? 'Enregistrement…'
                      : 'Voir mes recommandations',
                  onPressed: _isSubmitting ? null : _valider,
                  isLoading: _isSubmitting,
                  trailingIcon: Icons.auto_awesome,
                ),
                const SizedBox(height: 8),
                OutlineButton(
                  label: 'Passer cette étape',
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.recommandation3Signaux,
                          );
                        },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnneeCard(int anneeIndex) {
    final annee = _annees[anneeIndex];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Année ${anneeIndex + 1}',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: annee.anneeScolaire,
                  decoration: const InputDecoration(
                    labelText: 'Année scolaire',
                    hintText: '2024-2025',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: annee.classe,
            decoration: const InputDecoration(
              labelText: 'Classe',
              hintText: 'Terminale C, Licence 2 Info, ...',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          ...annee.notes.asMap().entries.map((e) {
            return _buildNoteRow(anneeIndex, e.key, e.value);
          }),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _ajouterNote(anneeIndex),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Ajouter une matière'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteRow(int anneeIndex, int noteIndex, _NoteEntry entry) {
    final isMg = entry.estMoyenneGenerale;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMg ? AppColors.backgroundGrey : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: entry.matiere,
              enabled: !isMg,
              decoration: InputDecoration(
                labelText: isMg ? 'Moyenne générale' : 'Matière',
                isDense: true,
                border: isMg ? InputBorder.none : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: entry.note,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Note /20',
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.textLight),
            onPressed: () => _supprimerNote(anneeIndex, noteIndex),
            tooltip: 'Supprimer cette ligne',
          ),
        ],
      ),
    );
  }
}
