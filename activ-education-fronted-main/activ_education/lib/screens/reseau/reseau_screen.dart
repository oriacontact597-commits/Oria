import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class ReseauScreen extends StatefulWidget {
  final String utilisateurId;
  final String nomUtilisateur;
  const ReseauScreen({super.key, required this.utilisateurId, required this.nomUtilisateur});

  @override
  State<ReseauScreen> createState() => _ReseauScreenState();
}

class _ReseauScreenState extends State<ReseauScreen> {
  final _api = ApiService();
  final _postCtrl = TextEditingController();
  List<PublicationResponse> _publications = [];
  bool _isLoading = true;
  bool _isPosting = false;
  String _selectedTab = 'feed';

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  @override
  void dispose() {
    _postCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFeed() async {
    try {
      final data = _selectedTab == 'tendances'
          ? await _api.reseau.getTendances()
          : await _api.reseau.getFeed(widget.utilisateurId);
      if (mounted) setState(() { _publications = data; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_api.handleError(e))),
        );
      }
    }
  }

  Future<void> _publier() async {
    if (_postCtrl.text.trim().isEmpty) return;
    setState(() => _isPosting = true);
    try {
      await _api.reseau.publier(widget.utilisateurId, widget.nomUtilisateur, _postCtrl.text.trim());
      _postCtrl.clear();
      if (mounted) setState(() => _isPosting = false);
      await _loadFeed();
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_api.handleError(e))),
        );
      }
    }
  }

  Future<void> _reactionner(PublicationResponse pub) async {
    try {
      await _api.reseau.reactionner(pub.trackingId, widget.utilisateurId);
      await _loadFeed();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_api.handleError(e))),
        );
      }
    }
  }

  Future<void> _supprimer(PublicationResponse pub) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer'),
        content: const Text('Supprimer cette publication ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _api.reseau.supprimerPublication(pub.trackingId, widget.utilisateurId);
        await _loadFeed();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_api.handleError(e))),
          );
        }
      }
    }
  }

  void _showCommentaires(PublicationResponse pub) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CommentaireSheet(
        publicationTrackingId: pub.trackingId,
        utilisateurId: widget.utilisateurId,
        nomUtilisateur: widget.nomUtilisateur,
        onCommentAdded: _loadFeed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réseau'),
        actions: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'feed', label: Text('Fil', style: TextStyle(fontSize: 12))),
              ButtonSegment(value: 'tendances', label: Text('Tendances', style: TextStyle(fontSize: 12))),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (v) => setState(() { _selectedTab = v.first; _isLoading = true; _loadFeed(); }),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  child: Text(widget.nomUtilisateur.isNotEmpty
                      ? widget.nomUtilisateur[0].toUpperCase() : '?'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _postCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Partagez votre expérience...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    maxLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _publier(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isPosting
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  onPressed: _isPosting ? null : _publier,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _publications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.group, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('Aucune publication',
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadFeed,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _publications.length,
                          itemBuilder: (_, i) => _buildPublicationCard(_publications[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicationCard(PublicationResponse pub) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              child: Text(pub.auteurNom != null && pub.auteurNom!.isNotEmpty
                  ? pub.auteurNom![0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 14)),
            ),
            title: Text(pub.auteurNom ?? 'Anonyme', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(pub.auteurRole ?? '', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            trailing: pub.estAuteur
                ? IconButton(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onPressed: () => _supprimer(pub),
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(pub.contenu, style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
          if (pub.tags != null && pub.tags!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                spacing: 4,
                children: pub.tags!.split(',').map((t) => Chip(
                  label: Text(t.trim(), style: const TextStyle(fontSize: 10)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.favorite_outline, size: 18, color: Colors.grey[600]),
                  onPressed: () => _reactionner(pub),
                ),
                Text('${pub.nombreReactions}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.comment_outlined, size: 18, color: Colors.grey[600]),
                  onPressed: () => _showCommentaires(pub),
                ),
                Text('${pub.nombreCommentaires}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const Spacer(),
                Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(_formatDate(pub.createdAt), style: TextStyle(color: Colors.grey[400], fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}j';
    } catch (_) {
      return '';
    }
  }
}

class _CommentaireSheet extends StatefulWidget {
  final String publicationTrackingId;
  final String utilisateurId;
  final String nomUtilisateur;
  final VoidCallback onCommentAdded;

  const _CommentaireSheet({
    required this.publicationTrackingId,
    required this.utilisateurId,
    required this.nomUtilisateur,
    required this.onCommentAdded,
  });

  @override
  State<_CommentaireSheet> createState() => _CommentaireSheetState();
}

class _CommentaireSheetState extends State<_CommentaireSheet> {
  final _api = ApiService();
  final _commentCtrl = TextEditingController();
  List<CommentaireResponse> _commentaires = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadCommentaires();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCommentaires() async {
    try {
      final data = await _api.reseau.getCommentaires(widget.publicationTrackingId);
      if (mounted) setState(() { _commentaires = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _commenter() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    setState(() => _isSending = true);
    try {
      await _api.reseau.commenter(
        widget.publicationTrackingId,
        widget.utilisateurId,
        widget.nomUtilisateur,
        _commentCtrl.text.trim(),
      );
      _commentCtrl.clear();
      if (mounted) setState(() => _isSending = false);
      widget.onCommentAdded();
      await _loadCommentaires();
    } catch (e) {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: 400,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  const Text('Commentaires', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _commentaires.isEmpty
                      ? Center(child: Text('Aucun commentaire', style: TextStyle(color: Colors.grey[600])))
                      : ListView.builder(
                          itemCount: _commentaires.length,
                          itemBuilder: (_, i) => ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              child: Text(
                                _commentaires[i].auteurNom?.isNotEmpty == true
                                    ? _commentaires[i].auteurNom![0].toUpperCase()
                                    : '?',
                                style: const TextStyle(fontSize: 12)),
                            ),
                            title: Text(_commentaires[i].auteurNom ?? 'Anonyme',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            subtitle: Text(_commentaires[i].contenu,
                                style: const TextStyle(fontSize: 12)),
                          ),
                        ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Écrire un commentaire...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _commenter(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isSending
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    onPressed: _isSending ? null : _commenter,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
