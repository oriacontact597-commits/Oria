import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class EntretienScreen extends StatefulWidget {
  final String eleveTrackingId;
  const EntretienScreen({super.key, required this.eleveTrackingId});

  @override
  State<EntretienScreen> createState() => _EntretienScreenState();
}

class _EntretienScreenState extends State<EntretienScreen> {
  final _api = ApiService();
  final _reponseCtrl = TextEditingController();
  final _metierCtrl = TextEditingController();

  EntretienResponse? _session;
  ResultatEntretienResponse? _resultat;
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void dispose() {
    _reponseCtrl.dispose();
    _metierCtrl.dispose();
    super.dispose();
  }

  Future<void> _startInterview() async {
    if (_metierCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final session = await _api.entretien.demarrerEntretien(
        StartEntretienRequest(
          metierTitre: _metierCtrl.text.trim(),
          eleveTrackingId: widget.eleveTrackingId,
        ),
      );
      if (mounted) setState(() { _session = session; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_api.handleError(e))),
        );
      }
    }
  }

  Future<void> _sendAnswer() async {
    if (_reponseCtrl.text.trim().isEmpty) return;
    setState(() => _isSending = true);
    final answer = _reponseCtrl.text.trim();
    _reponseCtrl.clear();
    try {
      final resp = await _api.entretien.repondre(_session!.sessionId, answer);
      if (mounted) {
        if (resp.statut == 'TERMINE') {
          final resultat = await _api.entretien.getResultat(_session!.sessionId);
          setState(() { _resultat = resultat; _isSending = false; _session = null; });
        } else {
          setState(() { _session = resp; _isSending = false; });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_api.handleError(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entretien simulé')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _resultat != null
              ? _buildResultat()
              : _session != null
                  ? _buildInterview()
                  : _buildStartForm(),
    );
  }

  Widget _buildStartForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.record_voice_over, size: 72, color: Colors.blue.shade300),
          const SizedBox(height: 24),
          const Text('Simulation d\'entretien',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Entraînez-vous avec un recruteur IA',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 32),
          TextField(
            controller: _metierCtrl,
            decoration: const InputDecoration(
              labelText: 'Métier visé *',
              hintText: 'Ex: Développeur web, Infirmier, Comptable...',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _startInterview(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Commencer l\'entretien'),
              onPressed: _startInterview,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterview() {
    final progress = _session!.questionNumero / _session!.totalQuestions;
    return Column(
      children: [
        LinearProgressIndicator(value: progress, minHeight: 4),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(_session!.metierTitre,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('Question ${_session!.questionNumero}/${_session!.totalQuestions}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_outline, color: Colors.blue.shade400),
                        const SizedBox(width: 8),
                        const Text('Recruteur',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(_session!.question ?? '',
                        style: const TextStyle(fontSize: 16, height: 1.5)),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _reponseCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Votre réponse...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      maxLines: 2,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _isSending ? null : (_) => _sendAnswer(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _isSending ? null : _sendAnswer,
                    child: _isSending
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Envoyer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultat() {
    final r = _resultat!;
    final pct = (r.scoreFinal / 100).clamp(0.0, 1.0);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
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
                            value: pct,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              pct >= 0.7 ? Colors.green : pct >= 0.4 ? Colors.amber : Colors.red,
                            ),
                          ),
                        ),
                        Text('${r.scoreFinal.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(r.appreciation, textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700], height: 1.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Détail des échanges',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ...r.echanges.map((e) => _buildEchangeCard(e)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Nouvel entretien'),
              onPressed: () => setState(() {
                _resultat = null;
                _session = null;
                _metierCtrl.clear();
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEchangeCard(EchangeDTO e) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Q${e.numero}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800, fontSize: 12)),
                ),
                const Spacer(),
                _buildScoreBadge(e.score),
              ],
            ),
            const SizedBox(height: 6),
            Text(e.question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(e.reponse, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
            if (e.evaluation.isNotEmpty && !e.evaluation.startsWith('{')) ...[
              const Divider(height: 12),
              Text(e.evaluation, style: TextStyle(color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBadge(double score) {
    final pct = score / 20;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: pct >= 0.7 ? Colors.green.shade100 : pct >= 0.4 ? Colors.amber.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('${score.toStringAsFixed(1)}/20',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11,
              color: pct >= 0.7 ? Colors.green.shade800 : pct >= 0.4 ? Colors.amber.shade800 : Colors.red.shade800)),
    );
  }
}
