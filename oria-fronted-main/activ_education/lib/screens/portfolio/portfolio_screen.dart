import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class PortfolioScreen extends StatefulWidget {
  final String eleveTrackingId;
  const PortfolioScreen({super.key, required this.eleveTrackingId});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _api = ApiService();
  List<CompetenceResponse> _competences = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompetences();
  }

  Future<void> _loadCompetences() async {
    try {
      final data = await _api.portfolio.listerCompetences(widget.eleveTrackingId);
      if (mounted) setState(() { _competences = data; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_api.handleError(e))),
        );
      }
    }
  }

  String _categorieIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'scolaire': return '📚';
      case 'technique': return '🛠️';
      case 'langue': return '🌍';
      case 'sport': return '⚽';
      case 'artistique': return '🎨';
      case 'informatique': return '💻';
      case 'benevolat': return '🤝';
      case 'stage': return '💼';
      default: return '⭐';
    }
  }

  Color _niveauColor(int niveau) {
    switch (niveau) {
      case 1: return Colors.red.shade300;
      case 2: return Colors.orange.shade300;
      case 3: return Colors.amber.shade400;
      case 4: return Colors.lightGreen.shade400;
      case 5: return Colors.green.shade500;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<CompetenceResponse>>{};
    for (final c in _competences) {
      grouped.putIfAbsent(c.categorie, () => []).add(c);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Analyser mon profil',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => PortfolioAnalyseScreen(eleveTrackingId: widget.eleveTrackingId),
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Ajouter une compétence',
            onPressed: () => _showCompetenceDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _competences.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Aucune compétence renseignée',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter ma première compétence'),
                        onPressed: () => _showCompetenceDialog(),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCompetences,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildScoreCard(),
                      const SizedBox(height: 16),
                      ...grouped.entries.map((entry) => _buildCategorySection(entry.key, entry.value)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildScoreCard() {
    if (_competences.isEmpty) return const SizedBox.shrink();
    final total = _competences.length;
    final avg = _competences.map((c) => c.niveauEstime).reduce((a, b) => a + b) / total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$total compétences', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: avg / 5,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      avg >= 4 ? Colors.green : avg >= 3 ? Colors.amber : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Niveau moyen: ${avg.toStringAsFixed(1)}/5',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              icon: const Icon(Icons.analytics, size: 18),
              label: const Text('Analyser'),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PortfolioAnalyseScreen(eleveTrackingId: widget.eleveTrackingId),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String categorie, List<CompetenceResponse> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF2196F3).withValues(alpha: 0.08),
              child: Row(
                children: [
                  Text(_categorieIcon(categorie), style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(categorie, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Spacer(),
                  Text('${items.length}', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            ...items.map((c) => _buildCompetenceTile(c)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetenceTile(CompetenceResponse c) {
    return ListTile(
      dense: true,
      title: Text(c.titre, style: const TextStyle(fontSize: 14)),
      subtitle: c.description != null && c.description!.isNotEmpty
          ? Text(c.description!, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 12))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _niveauColor(c.niveauEstime).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('${c.niveauEstime}/5',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                    color: _niveauColor(c.niveauEstime))),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') _showCompetenceDialog(competence: c);
              if (v == 'delete') _confirmDelete(c);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Modifier')),
              const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showCompetenceDialog({CompetenceResponse? competence}) async {
    final titreCtrl = TextEditingController(text: competence?.titre ?? '');
    final descCtrl = TextEditingController(text: competence?.description ?? '');
    final sourceCtrl = TextEditingController(text: competence?.source ?? '');
    String categorie = competence?.categorie ?? 'Scolaire';
    int niveau = competence?.niveauEstime ?? 3;

    final categories = ['Scolaire', 'Technique', 'Langue', 'Sport', 'Artistique', 'Informatique', 'Bénévolat', 'Stage'];
    final isEditing = competence != null;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Modifier la compétence' : 'Nouvelle compétence'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titreCtrl,
                  decoration: const InputDecoration(labelText: 'Titre *', hintText: 'Ex: Python, Anglais, Dessin...'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description', hintText: 'Décrivez votre niveau...'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: categorie,
                  decoration: const InputDecoration(labelText: 'Catégorie *'),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => categorie = v!),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Niveau: '),
                    Expanded(
                      child: Slider(
                        value: niveau.toDouble(),
                        min: 1, max: 5, divisions: 4,
                        label: '$niveau/5',
                        onChanged: (v) => setDialogState(() => niveau = v.round()),
                      ),
                    ),
                    Text('$niveau/5', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                TextField(
                  controller: sourceCtrl,
                  decoration: const InputDecoration(labelText: 'Source', hintText: 'Ex: Lycée, Cours en ligne, Stage...'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                if (titreCtrl.text.trim().isEmpty) return;
                try {
                    if (isEditing) {
                    await _api.portfolio.modifierCompetence(
                      widget.eleveTrackingId,
                      competence.trackingId,
                      CompetenceRequest(
                        titre: titreCtrl.text.trim(),
                        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        categorie: categorie,
                        niveauEstime: niveau,
                        source: sourceCtrl.text.trim().isEmpty ? null : sourceCtrl.text.trim(),
                      ),
                    );
                  } else {
                    await _api.portfolio.ajouterCompetence(
                      widget.eleveTrackingId,
                      CompetenceRequest(
                        titre: titreCtrl.text.trim(),
                        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        categorie: categorie,
                        niveauEstime: niveau,
                        source: sourceCtrl.text.trim().isEmpty ? null : sourceCtrl.text.trim(),
                      ),
                    );
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _loadCompetences();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_api.handleError(e))),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Enregistrer' : 'Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(CompetenceResponse c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text('Supprimer "${c.titre}" du portfolio ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _api.portfolio.supprimerCompetence(widget.eleveTrackingId, c.trackingId);
        await _loadCompetences();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_api.handleError(e))),
          );
        }
      }
    }
  }
}

class PortfolioAnalyseScreen extends StatefulWidget {
  final String eleveTrackingId;
  const PortfolioAnalyseScreen({super.key, required this.eleveTrackingId});

  @override
  State<PortfolioAnalyseScreen> createState() => _PortfolioAnalyseScreenState();
}

class _PortfolioAnalyseScreenState extends State<PortfolioAnalyseScreen> {
  final _api = ApiService();
  AnalysePortfolioResponse? _analyse;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyse();
  }

  Future<void> _loadAnalyse() async {
    try {
      final data = await _api.portfolio.analyser(widget.eleveTrackingId);
      if (mounted) setState(() { _analyse = data; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_api.handleError(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analyse du profil')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analyse == null
              ? const Center(child: Text('Impossible de charger l\'analyse'))
              : RefreshIndicator(
                  onRefresh: _loadAnalyse,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildGlobalScore(),
                      const SizedBox(height: 16),
                      _buildRadarCategories(),
                      const SizedBox(height: 16),
                      _buildMetiersList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildGlobalScore() {
    final score = _analyse!.scoreGlobal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              width: 100, height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100, height: 100,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        score >= 70 ? Colors.green : score >= 40 ? Colors.amber : Colors.orange,
                      ),
                    ),
                  ),
                  Text('${score.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('${_analyse!.totalCompetences} compétences',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Text('Score global de compétences',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarCategories() {
    final data = _analyse!.repartitionParCategorie;
    if (data.isEmpty) return const SizedBox.shrink();

    final entries = data.entries.toList();
    final categories = entries.map((e) => e.key).toList();
    final values = entries.map((e) => e.value.toDouble()).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Répartition par catégorie',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: RadarChart(
                RadarChartData(
                  radarTouchData: RadarTouchData(enabled: false),
                  dataSets: [
                    RadarDataSet(
                      fillColor: const Color(0xFF2196F3).withValues(alpha: 0.2),
                      borderColor: const Color(0xFF2196F3),
                      borderWidth: 2,
                      entryRadius: 4,
                      dataEntries: values
                          .map((v) => RadarEntry(value: v))
                          .toList(),
                    ),
                  ],
                  tickCount: 4,
                  ticksTextStyle: const TextStyle(fontSize: 9, color: Colors.transparent),
                  tickBorderData: BorderSide(color: Colors.grey.shade200),
                  gridBorderData: BorderSide(color: Colors.grey.shade200),
                  titlePositionPercentageOffset: 0.15,
                  titleTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  getTitle: (i, _) => RadarChartTitle(text: categories[i]),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: entries.map((e) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('${e.key}: ${e.value}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetiersList() {
    final metiers = _analyse!.metiersRecommandes;
    if (metiers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Ajoutez des compétences pour obtenir des recommandations.',
              style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Métiers recommandés',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            ...metiers.map((m) => _buildMetierTile(m)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetierTile(RecommandationMetier m) {
    final pct = m.scoreCompatibilite;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(m.nomMetier,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: pct >= 70
                      ? Colors.green.shade100
                      : pct >= 40
                          ? Colors.amber.shade100
                          : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${pct.toStringAsFixed(0)}%',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: pct >= 70
                            ? Colors.green.shade800
                            : pct >= 40
                                ? Colors.amber.shade800
                                : Colors.red.shade800)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: Colors.grey[200],
              minHeight: 6,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 70 ? Colors.green : pct >= 40 ? Colors.amber : Colors.red,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('${m.competencesAcquises}/${m.competencesRequises} compétences',
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          if (m.competencesManquantes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Manque: ${m.competencesManquantes.join(", ")}',
                style: TextStyle(color: Colors.red.shade400, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}
