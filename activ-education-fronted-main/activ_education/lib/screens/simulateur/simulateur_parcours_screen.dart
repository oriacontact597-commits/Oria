import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import '../../services/bulletin_service.dart';
import '../../models/bulletin_models.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_routes.dart';
import 'simulateur_resultat_screen.dart';

class SimulateurParcoursScreen extends StatefulWidget {
  const SimulateurParcoursScreen({super.key});

  @override
  State<SimulateurParcoursScreen> createState() =>
      _SimulateurParcoursScreenState();
}

class _BulletinEntry {
  String fileName;
  String slotLabel;
  List<NoteExtraiteModel> notes;

  _BulletinEntry({
    required this.fileName,
    required this.slotLabel,
    required this.notes,
  });
}

class _SimulateurParcoursScreenState extends State<SimulateurParcoursScreen> {
  final _api = ApiService();
  final _bulletinService = BulletinService();
  final _titreController = TextEditingController(text: 'Mon scénario');
  final _metierController = TextEditingController();

  String? _selectedSerieId;
  String _selectedNiveau = 'Terminale';
  String _selectedVille = '';
  bool _isLoadingSeries = true;
  bool _isExploring = false;

  List<Map<String, dynamic>> _series = [];
  final List<String> _niveaux = [
    'Troisième',
    'Seconde',
    'Première',
    'Terminale',
    'Bac+1',
    'Bac+2',
    'Bac+3',
    'Bac+5'
  ];

  bool get _isNiveauLycee =>
      _selectedNiveau == 'Première' || _selectedNiveau == 'Terminale';

  List<_BulletinEntry> get _b {
    // DDC hot‑reload peut laisser le backing field undefined → fallback
    try {
      return _bulletins ?? [];
    } catch (_) {
      return [];
    }
  }

  List<_BulletinEntry>? _bulletins;
  int? _analyzingIndex;

  @override
  void initState() {
    super.initState();
    _bulletins = [];
    _loadSeries();
  }

  List<String> _slotsPourNiveau(String niveau) {
    switch (niveau) {
      case 'Troisième':
        return ['Bulletin 3e'];
      case 'Seconde':
        return ['Bulletin 2nde'];
      case 'Première':
        return ['Bulletin 2nde', 'Bulletin 1ère'];
      case 'Terminale':
        return ['Bulletin 2nde', 'Relevé 1ère', 'Bulletin Tale'];
      case 'Bac+1':
        return ['Relevé Bac', 'Relevé Bac+1'];
      case 'Bac+2':
        return ['Relevé Bac', 'Relevé Bac+1', 'Relevé Bac+2'];
      case 'Bac+3':
        return ['Relevé Bac', 'Relevé Bac+1', 'Relevé Bac+2', 'Relevé Bac+3'];
      case 'Bac+5':
        return [
          'Relevé Bac',
          'Relevé Bac+1',
          'Relevé Bac+2',
          'Relevé Bac+3',
          'Relevé Bac+4',
          'Relevé Bac+5'
        ];
      default:
        return ['Bulletin actuel'];
    }
  }

  List<String> get _slots => _slotsPourNiveau(_selectedNiveau);

  Map<String, double> get _aggregatedNotes {
    final notes = <String, List<double>>{};
    for (final b in _b) {
      for (final n in b.notes) {
        notes.putIfAbsent(n.matiere, () => []).add(n.note);
      }
    }
    return notes
        .map((k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));
  }

  void _onNiveauChanged(String? nouveau) {
    if (nouveau == null) return;
    setState(() {
      _selectedNiveau = nouveau;
      if (!_isNiveauLycee) _selectedSerieId = null;
      // safe clear — DDC peut laisser _bulletins undefined après hot reload
      final safe = _b;
      _bulletins = safe;
      _bulletins!.clear();
    });
  }

  Future<void> _loadSeries() async {
    try {
      final res = await _api.dio.get('/api/v1/bibliotheque/series');
      final data = res.data;
      List<Map<String, dynamic>> series;
      if (data is List) {
        series = data.cast<Map<String, dynamic>>();
      } else if (data is Map && data.containsKey('content')) {
        series = (data['content'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      } else {
        series = [];
      }
      if (mounted) {
        setState(() {
          _series = series;
          _isLoadingSeries = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSeries = false);
    }
  }

  Future<void> _explorer() async {
    if (_isExploring) return;
    setState(() => _isExploring = true);

    try {
      final body = <String, dynamic>{
        'titre': _titreController.text.trim().isEmpty
            ? 'Mon scénario'
            : _titreController.text.trim(),
        if (_selectedSerieId != null) 'serieTrackingId': _selectedSerieId,
        'niveau': _selectedNiveau,
        if (_selectedVille.isNotEmpty) 'ville': _selectedVille,
        if (_metierController.text.trim().isNotEmpty)
          'motCleMetier': _metierController.text.trim(),
        if (_aggregatedNotes.isNotEmpty) 'notesSimulees': _aggregatedNotes,
      };

      final res =
          await _api.dio.post('/api/v1/simulateur/explorer', data: body);
      final data = res.data as Map<String, dynamic>? ?? {};

      if (mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SimulateurResultatScreen(resultat: data),
            ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExploring = false);
    }
  }

  Future<void> _addBulletin(int slotIndex) async {
    // DDC safe: réinitialise si undefined (hot reload)
    _bulletins ??= [];

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (!kIsWeb && file.path == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fichier non accessible')),
          );
        }
        return;
      }

      setState(() => _analyzingIndex = slotIndex);

      final eleveTrackingId = await _api.getTrackingId();
      if (eleveTrackingId == null) {
        if (mounted) setState(() => _analyzingIndex = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Utilisateur non connecté')),
          );
        }
        return;
      }

      final now = DateTime.now();
      final anneeScolaire = now.month >= 9
          ? '${now.year}-${now.year + 1}'
          : '${now.year - 1}-$now.year';
      final preview = await _bulletinService.preview(
        eleveTrackingId: eleveTrackingId,
        file: file,
        anneeScolaire: anneeScolaire,
        periode: 'FIN',
        typePeriode: 'TRIMESTRE',
        numeroPeriode: slotIndex + 1,
      );

      if (!mounted) return;

      final entry = _BulletinEntry(
        fileName: file.name,
        slotLabel: _slots[slotIndex],
        notes: preview.notesExtraites,
      );

      setState(() {
        if (slotIndex < _bulletins!.length) {
          _bulletins![slotIndex] = entry;
        } else {
          _bulletins!.add(entry);
        }
        _analyzingIndex = null;
      });

      if (preview.notesExtraites.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${file.name}" : aucune note extraite')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${preview.notesExtraites.length} note(s) extraites de "${file.name}"')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _analyzingIndex = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur OCR: ${e.toString()}')),
        );
      }
    }
  }

  void _removeBulletin(int index) {
    if (_bulletins == null) return;
    setState(() => _bulletins!.removeAt(index));
  }

  void _updateNote(int bulletinIndex, int noteIndex, double nouvelleNote) {
    if (_bulletins == null ||
        bulletinIndex < 0 ||
        bulletinIndex >= _bulletins!.length) {
      return;
    }
    final b = _bulletins![bulletinIndex];
    if (noteIndex < 0 || noteIndex >= b.notes.length) return;
    final ancienne = b.notes[noteIndex];
    b.notes[noteIndex] = NoteExtraiteModel(
      matiere: ancienne.matiere,
      note: nouvelleNote.clamp(0, 20),
      coefficient: ancienne.coefficient,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulateur de parcours'),
      ),
      body: _isLoadingSeries
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Construis ton scénario',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                      'Ajoute tes bulletins et découvre les meilleures filières pour toi.',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 20),
                  _buildSection('Titre du scénario', [
                    TextField(
                      controller: _titreController,
                      decoration: const InputDecoration(
                        hintText: 'Ex: Si je choisis Série C',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ]),
                  _buildSection('Niveau actuel', [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedNiveau,
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                      items: _niveaux
                          .map(
                              (n) => DropdownMenuItem(value: n, child: Text(n)))
                          .toList(),
                      onChanged: _onNiveauChanged,
                    ),
                  ]),
                  if (_isNiveauLycee)
                    _buildSection('Série scolaire', [
                      _series.isEmpty
                          ? const Text('Aucune série disponible')
                          : DropdownButtonFormField<String>(
                              initialValue: _selectedSerieId,
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder()),
                              hint: const Text('Choisis une série'),
                              items: _series
                                  .map((s) => DropdownMenuItem(
                                        value: s['trackingId'] as String?,
                                        child:
                                            Text(s['titre'] as String? ?? ''),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedSerieId = v),
                            ),
                    ]),
                  _buildSection('Métier souhaité (optionnel)', [
                    TextField(
                      controller: _metierController,
                      decoration: const InputDecoration(
                        hintText: 'Ex: Médecin, Architecte...',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ]),
                  _buildSection('Ville / Région (optionnel)', [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Ex: Lomé, Kara...',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (v) => _selectedVille = v.trim(),
                    ),
                  ]),
                  _buildSection('Mes bulletins', [
                    ..._slots.asMap().entries.map((slot) {
                      final i = slot.key;
                      final label = slot.value;
                      final existing = i < _b.length ? _b[i] : null;
                      final isAnalyzing = _analyzingIndex == i;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: existing != null
                                          ? AppColors.primary
                                              .withValues(alpha: 0.1)
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: existing != null
                                              ? AppColors.primary
                                              : Colors.grey[600],
                                        )),
                                  ),
                                  const Spacer(),
                                  if (existing != null)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 20),
                                      onPressed: () => _removeBulletin(i),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                ],
                              ),
                              if (isAnalyzing)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2)),
                                        SizedBox(height: 8),
                                        Text('Extraction OCR…',
                                            style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                )
                              else if (existing != null) ...[
                                const Divider(height: 12),
                                Text(existing.fileName,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 6),
                                ...existing.notes.asMap().entries.map((ne) {
                                  final j = ne.key;
                                  final note = ne.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            flex: 3,
                                            child: Text(note.matiere,
                                                style: const TextStyle(
                                                    fontSize: 13))),
                                        SizedBox(
                                          width: 64,
                                          child: TextField(
                                            controller: TextEditingController(
                                                text: note.note
                                                    .toStringAsFixed(1))
                                              ..selection =
                                                  TextSelection.fromPosition(
                                                      const TextPosition(offset: 4)),
                                            keyboardType: const TextInputType
                                                .numberWithOptions(
                                                decimal: true),
                                            textAlign: TextAlign.center,
                                            style:
                                                const TextStyle(fontSize: 13),
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 4),
                                              border: OutlineInputBorder(),
                                            ),
                                            onSubmitted: (v) {
                                              final val = double.tryParse(
                                                  v.replaceAll(',', '.'));
                                              if (val != null) {
                                                _updateNote(i, j, val);
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                            '×${note.coefficient.toStringAsFixed(0)}',
                                            style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 11)),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: () => _addBulletin(i),
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Remplacer',
                                        style: TextStyle(fontSize: 12)),
                                    style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact),
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _addBulletin(i),
                                    icon:
                                        const Icon(Icons.upload_file, size: 18),
                                    label: Text('Ajouter $label',
                                        style: const TextStyle(fontSize: 13)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ]),
                  if (_b.isNotEmpty) ...[
                    _buildSection('Aperçu des notes moyennes', [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: _aggregatedNotes.entries
                              .map((e) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        Expanded(
                                            flex: 3,
                                            child: Text(e.key,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w500))),
                                        Text(
                                            '${e.value.toStringAsFixed(1)} / 20',
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: e.value >= 10
                                                    ? Colors.green[700]
                                                    : Colors.red[700])),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isExploring ? null : _explorer,
                      icon: _isExploring
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.explore),
                      label: Text(_isExploring
                          ? 'Exploration...'
                          : 'Explorer mon scénario'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SimulateurComparaisonScreen(),
                          )),
                      icon: const Icon(Icons.compare_arrows),
                      label: const Text('Comparer plusieurs scénarios'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                          context, AppRoutes.scenariosTypes),
                      icon: const Icon(Icons.collections_bookmark),
                      label: const Text('Ou explore un scénario type'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class SimulateurComparaisonScreen extends StatefulWidget {
  const SimulateurComparaisonScreen({super.key});

  @override
  State<SimulateurComparaisonScreen> createState() =>
      _SimulateurComparaisonScreenState();
}

class _SimulateurComparaisonScreenState
    extends State<SimulateurComparaisonScreen> {
  final _api = ApiService();
  final _scenarios = <Map<String, dynamic>>[];
  bool _isComparing = false;

  void _ajouterScenario() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SimulateurParcoursScreen(),
        )).then((_) {
      // User would come back with scenarios saved
    });
  }

  Future<void> _comparer() async {
    if (_scenarios.length < 2) return;
    setState(() => _isComparing = true);
    try {
      final res =
          await _api.dio.post('/api/v1/simulateur/comparer', data: _scenarios);
      final data = res.data as List? ?? [];
      if (mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SimulateurResultatScreen(
                  resultats: data.cast<Map<String, dynamic>>(),
                  isComparaison: true),
            ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isComparing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comparer des scénarios')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: _scenarios.isEmpty
                  ? const Center(
                      child:
                          Text('Ajoute au moins 2 scénarios pour les comparer'))
                  : ListView.builder(
                      itemCount: _scenarios.length,
                      itemBuilder: (_, i) => Card(
                        child: ListTile(
                          title: Text(_scenarios[i]['titre'] as String? ??
                              'Scénario ${i + 1}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                setState(() => _scenarios.removeAt(i)),
                          ),
                        ),
                      ),
                    ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _ajouterScenario,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un scénario'),
              ),
            ),
            if (_scenarios.length >= 2) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isComparing ? null : _comparer,
                  icon: const Icon(Icons.compare_arrows),
                  label: Text(_isComparing
                      ? 'Comparaison...'
                      : 'Comparer (${_scenarios.length} scénarios)'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
