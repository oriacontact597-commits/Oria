import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class TemoignageScreen extends StatefulWidget {
  const TemoignageScreen({super.key});

  @override
  State<TemoignageScreen> createState() => _TemoignageScreenState();
}

class _TemoignageScreenState extends State<TemoignageScreen> {
  final _api = ApiService();
  List<TemoignageResponse> _temoignages = [];
  List<TemoignageResponse> _vedettes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemoignages();
  }

  Future<void> _loadTemoignages() async {
    try {
      final results = await Future.wait([
        _api.temoignage.getPublies(),
        _api.temoignage.getVedettes(),
      ]);
      if (mounted) setState(() {
        _temoignages = results[0];
        _vedettes = results[1];
        _isLoading = false;
      });
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
      appBar: AppBar(
        title: const Text('Témoignages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Comment ça marche',
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.rate_review_outlined, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Témoignages'),
                  ],
                ),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Les témoignages sont des retours d\'expérience d\'anciens élèves comme toi.',
                      style: TextStyle(height: 1.5),
                    ),
                    SizedBox(height: 16),
                    Text('Comment ça fonctionne ?',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Text('• Découvre des parcours d\'étudiants et professionnels'),
                    Text("• Inspire-toi de leur expérience pour t'orienter"),
                    Text('• Partage ton propre témoignage depuis ton profil'),
                    SizedBox(height: 16),
                    Text('Les témoignages "À la une" sont mis en avant par notre équipe pour leur pertinence.',
                        style: TextStyle(height: 1.5)),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Compris'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTemoignages,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_vedettes.isNotEmpty) ...[
                    const Text('À la une', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    ..._vedettes.map((t) => _TemoignageCard(temoignage: t, vedette: true)),
                    const SizedBox(height: 24),
                  ],
                  const Text('Témoignages récents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (_temoignages.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text('Aucun témoignage pour le moment', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._temoignages.map((t) => _TemoignageCard(temoignage: t)),
                ],
              ),
            ),
    );
  }
}

class _TemoignageCard extends StatelessWidget {
  final TemoignageResponse temoignage;
  final bool vedette;

  const _TemoignageCard({required this.temoignage, this.vedette = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: vedette ? const BorderSide(color: AppColors.primary, width: 1.5) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: temoignage.auteurPhotoUrl != null
                      ? NetworkImage(temoignage.auteurPhotoUrl!) : null,
                  child: temoignage.auteurPhotoUrl == null
                      ? Text(temoignage.auteurNom.isNotEmpty
                          ? temoignage.auteurNom[0].toUpperCase() : '?')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(temoignage.auteurNom,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (temoignage.auteurTitre != null)
                        Text(temoignage.auteurTitre!,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                if (vedette)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('À la une',
                        style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(temoignage.contenu, style: const TextStyle(fontSize: 14, height: 1.4)),
            const SizedBox(height: 12),
            Row(
              children: [
                if (temoignage.metierNom != null) ...[
                  Icon(Icons.work_outline, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(temoignage.metierNom!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(width: 16),
                ],
                if (temoignage.filiereSuivie != null) ...[
                  Icon(Icons.school_outlined, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(temoignage.filiereSuivie!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
                const Spacer(),
                Icon(Icons.visibility_outlined, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('${temoignage.nbVues}', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
