import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SimulateurResultatScreen extends StatelessWidget {
  final Map<String, dynamic>? resultat;
  final List<Map<String, dynamic>>? resultats;
  final bool isComparaison;

  const SimulateurResultatScreen({
    super.key,
    this.resultat,
    this.resultats,
    this.isComparaison = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isComparaison && resultats != null) {
      return _buildComparaison(context);
    }
    return _buildResultatUnique(context);
  }

  Widget _buildResultatUnique(BuildContext context) {
    final data = resultat!;
    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    final filieres = (data['filieres'] as List? ?? []).cast<Map<String, dynamic>>();
    final metiers = (data['metiers'] as List? ?? []).cast<Map<String, dynamic>>();
    final etablissements = (data['etablissements'] as List? ?? []).cast<Map<String, dynamic>>();
    final serieTitre = data['serieTitre'] as String? ?? '';
    final titre = data['titre'] as String? ?? 'Mon scénario';

    return Scaffold(
      appBar: AppBar(title: Text(titre)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(stats, serieTitre),
            const SizedBox(height: 16),
            _buildSection(context, 'Filières accessibles', Icons.school, filieres, (f) => [
              ListTile(
                title: Text(f['titre'] as String? ?? ''),
                subtitle: Text(f['resume'] as String? ?? ''),
                trailing: _buildScoreBadge(f['scoreCompatibilite'] as double? ?? 0),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildChip('${f['domaine'] ?? ""}', Colors.blue),
                    if (f['duree'] != null) _buildChip(f['duree'] as String, Colors.green),
                    if (f['niveauRequis'] != null) _buildChip(f['niveauRequis'] as String, Colors.orange),
                  ],
                ),
              ),
              const Divider(),
            ]),
            const SizedBox(height: 16),
            _buildSection(context, 'Métiers possibles', Icons.work, metiers, (m) => [
              ListTile(
                title: Text(m['titre'] as String? ?? ''),
                subtitle: Text(m['resume'] as String? ?? ''),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (m['secteur'] != null) _buildChip(m['secteur'] as String, Colors.purple),
                    if (m['fourchetteSalaire'] != null)
                      _buildChip(m['fourchetteSalaire'] as String, Colors.teal),
                  ],
                ),
              ),
              const Divider(),
            ]),
            const SizedBox(height: 16),
            if (etablissements.isNotEmpty)
              _buildSection(context, 'Établissements', Icons.location_city, etablissements, (e) => [
                ListTile(
                  title: Text(e['titre'] as String? ?? ''),
                  subtitle: Text(e['ville'] as String? ?? ''),
                  trailing: e['estPublic'] == true
                      ? const Chip(label: Text('Public', style: TextStyle(fontSize: 11)), backgroundColor: Colors.green)
                      : const Chip(label: Text('Privé', style: TextStyle(fontSize: 11)), backgroundColor: Colors.amber),
                ),
                const Divider(),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> stats, String serieTitre) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(serieTitre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(Icons.school, '${stats['totalFilieres'] ?? 0}', 'Filières'),
                _buildStat(Icons.work, '${stats['totalMetiers'] ?? 0}', 'Métiers'),
                _buildStat(Icons.location_city, '${stats['totalEtablissements'] ?? 0}', 'Établissements'),
              ],
            ),
            const SizedBox(height: 8),
            Text('Score moyen : ${stats['scoreMoyenCompatibilite'] ?? "—"}%',
                style: const TextStyle(fontWeight: FontWeight.w500)),
            if (stats['dureeMin'] != null && stats['dureeMax'] != null)
              Text('Durée : ${(stats['dureeMin'] as num).toInt()} - ${(stats['dureeMax'] as num).toInt()} ans',
                  style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildScoreBadge(double score) {
    Color color;
    if (score >= 80) {
      color = Colors.green;
    } else if (score >= 60) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text('${score.toStringAsFixed(0)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 4),
      child: Chip(
        label: Text(text, style: const TextStyle(fontSize: 11)),
        backgroundColor: color.withValues(alpha: 0.1),
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon,
      List<Map<String, dynamic>> items, List<Widget> Function(Map<String, dynamic>) builder) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Text('${items.length}', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
          const Divider(),
          ...items.expand((item) => builder(item)),
        ],
      ),
    );
  }

  Widget _buildComparaison(BuildContext context) {
    final scenarios = resultats!;
    return Scaffold(
      appBar: AppBar(title: const Text('Comparaison')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: scenarios.length,
        itemBuilder: (_, i) {
          final s = scenarios[i];
          final stats = s['stats'] as Map<String, dynamic>? ?? {};
          return Card(
            child: ListTile(
              title: Text(s['titre'] as String? ?? 'Scénario ${i + 1}'),
              subtitle: Text(
                '${stats['totalFilieres'] ?? 0} filières · ${stats['totalMetiers'] ?? 0} métiers · '
                'Score: ${stats['scoreMoyenCompatibilite'] ?? "—"}%',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => SimulateurResultatScreen(resultat: s),
              )),
            ),
          );
        },
      ),
    );
  }
}
