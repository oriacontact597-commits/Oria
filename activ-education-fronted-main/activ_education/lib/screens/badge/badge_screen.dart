import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class BadgeScreen extends StatefulWidget {
  final String eleveTrackingId;
  const BadgeScreen({super.key, required this.eleveTrackingId});

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> {
  final _api = ApiService();
  List<BadgeResponse> _badges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    try {
      final data = await _api.badge.getBadges(widget.eleveTrackingId);
      if (mounted) setState(() { _badges = data; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_api.handleError(e))),
        );
      }
    }
  }

  Future<void> _verifierBadges() async {
    try {
      final nouveaux = await _api.badge.verifierEtAttribuer(widget.eleveTrackingId);
      await _loadBadges();
      if (nouveaux.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${nouveaux.length} nouveau(x) badge(s) débloqué(s) !'),
              backgroundColor: Colors.green),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun nouveau badge pour le moment')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_api.handleError(e))),
        );
      }
    }
  }

  IconData _badgeIcon(String? icone) {
    switch (icone) {
      case 'quiz': return Icons.quiz_outlined;
      case 'explore': return Icons.explore_outlined;
      case 'language': return Icons.language;
      case 'star': return Icons.star_outline;
      case 'group': return Icons.group_outlined;
      case 'mic': return Icons.mic_outlined;
      case 'search': return Icons.search_outlined;
      case 'skill': return Icons.auto_awesome_outlined;
      default: return Icons.emoji_events_outlined;
    }
  }

  Color _categorieColor(String? categorie) {
    switch (categorie) {
      case 'Quiz': return Colors.purple;
      case 'Découverte': return Colors.blue;
      case 'Portfolio': return Colors.green;
      case 'Profil': return Colors.orange;
      case 'Social': return Colors.teal;
      case 'Entretien': return Colors.indigo;
      case 'Exploration': return Colors.cyan;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final obtenus = _badges.where((b) => b.estObtenu).length;
    final total = _badges.length;
    final progress = total > 0 ? obtenus / total : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passeport de badges'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Comment ça fonctionne',
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('🎯 Badges'),
                content: const SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Les badges récompensent ton parcours sur la plateforme !'),
                      SizedBox(height: 12),
                      Text('🔓 Comment les débloquer ?',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('• Passe des quiz d\'orientation'),
                      Text('• Explore les fiches métiers et formations'),
                      Text('• Complète ton profil'),
                      Text('• Participe aux entretiens simulés'),
                      Text('• Sois actif sur la plateforme'),
                      SizedBox(height: 12),
                      Text('👀 Les badges verrouillés (gris) montrent'),
                      Text('ce que tu dois faire pour les obtenir.'),
                      SizedBox(height: 12),
                      Text('🔄 Appuie sur le bouton de rafraîchissement'),
                      Text('pour vérifier si tu as débloqué de nouveaux badges.'),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Compris !'),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Vérifier les badges',
            onPressed: _verifierBadges,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _badges.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Aucun badge disponible',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildProgressCard(obtenus, total, progress),
                    const SizedBox(height: 16),
                    ..._badges.map((b) => _buildBadgeCard(b)),
                  ],
                ),
    );
  }

  Widget _buildProgressCard(int obtenus, int total, double progress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, size: 36, color: Colors.amber),
                const SizedBox(width: 12),
                Text('$obtenus / $total',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),
            const SizedBox(height: 8),
            Text('${(progress * 100).toStringAsFixed(0)}% du parcours accompli',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCard(BadgeResponse badge) {
    final color = _categorieColor(badge.categorie);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: badge.estObtenu ? 1.0 : 0.4,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: badge.estObtenu ? color.withValues(alpha: 0.15) : Colors.grey[100],
            child: Icon(
              badge.estObtenu ? _badgeIcon(badge.icone) : Icons.lock_outline,
              color: badge.estObtenu ? color : Colors.grey[400],
            ),
          ),
          title: Text(badge.nom,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: badge.estObtenu ? Colors.black87 : Colors.grey[500],
              )),
          subtitle: Text(
            badge.estObtenu
                ? (badge.description ?? badge.conditionExplication ?? '')
                : (badge.conditionExplication ?? 'À débloquer'),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          trailing: badge.estObtenu
              ? const Icon(Icons.check_circle, color: Colors.green, size: 22)
              : Icon(Icons.circle_outlined, color: Colors.grey[300], size: 22),
        ),
      ),
    );
  }
}
