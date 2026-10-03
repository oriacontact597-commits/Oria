import 'package:flutter/material.dart';
import '../../services/evolution_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_routes.dart';

class OrchestrationResultScreen extends StatefulWidget {
  const OrchestrationResultScreen({super.key});

  @override
  State<OrchestrationResultScreen> createState() => _OrchestrationResultScreenState();
}

class _OrchestrationResultScreenState extends State<OrchestrationResultScreen> {
  final _service = EvolutionService();
  Map<String, dynamic>? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final studentId = await ApiService().getTrackingId();
      if (studentId == null) {
        setState(() { _error = 'Utilisateur non identifié.'; _loading = false; });
        return;
      }
      _result = await _service.orchestrate(studentId);
    } catch (e) {
      _error = 'Erreur : $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommandation ORIA'),
        backgroundColor: const Color(0xFF3133DD),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildResult(),
    );
  }

  Widget _buildResult() {
    if (_result == null) return const SizedBox();
    final score = (_result!['overallScore'] as num?)?.toDouble() ?? 0;
    final engines = (_result!['details']?['engines'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final explain = _result!['explainability'] as Map<String, dynamic>?;
    final summary = explain?['details']?['summary'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScoreCard(score),
          const SizedBox(height: 16),
          if (summary != null) _buildSummaryCard(summary),
          const SizedBox(height: 16),
          const Text('Moteurs évalués',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...engines.map(_buildEngineCard),
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.oria),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Discuter avec ORIA'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(double score) {
    final pct = (score * 100).round();
    final color = score >= 0.7
        ? Colors.green
        : score >= 0.4
            ? Colors.orange
            : Colors.red;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score,
                    strokeWidth: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                  Text('$pct%',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Score global',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    _labelForScore(score),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String summary) {
    return Card(
      color: const Color(0xFFF0F0FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, size: 18, color: Color(0xFF3133DD)),
                SizedBox(width: 8),
                Text('Analyse multi-dimensions',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(summary, style: const TextStyle(fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineCard(Map<String, dynamic> engine) {
    final name = engine['name'] as String? ?? '';
    final score = (engine['score'] as num?)?.toDouble() ?? 0;
    final weight = (engine['weight'] as num?)?.toDouble() ?? 0;
    final explanation = engine['explanation'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_engineLabel(name),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(explanation,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${(score * 100).round()}%',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: score >= 0.7 ? Colors.green : Colors.orange)),
                Text('poids ${(weight * 100).round()}%',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _labelForScore(double score) {
    if (score >= 0.8) return 'Profil solide — bonne orientation en vue.';
    if (score >= 0.6) return 'Profil encourageant — quelques axes à travailler.';
    if (score >= 0.4) return 'Profil en construction — continuer les efforts.';
    return 'Profil à développer — plus de données nécessaires.';
  }

  String _engineLabel(String name) {
    const labels = {
      'academic': 'Académique',
      'interest': 'Centres d\'intérêt',
      'riasec': 'RIASEC',
      'skills': 'Compétences',
      'behaviour': 'Comportement',
      'activities': 'Activités',
      'career': 'Matching métier',
      'university': 'Matching université',
      'confidence': 'Fiabilité',
    };
    return labels[name] ?? name;
  }
}
