import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

/// Événement proactif détecté par l'EventEngine backend.
class OriaEvent {
  final String type;
  final String severity; // HIGH / MEDIUM / LOW
  final String message;
  final DateTime detectedAt;

  OriaEvent({
    required this.type,
    required this.severity,
    required this.message,
    required this.detectedAt,
  });

  factory OriaEvent.fromJson(Map<String, dynamic> json) {
    return OriaEvent(
      type: json['type'] as String,
      severity: json['severity'] as String,
      message: json['message'] as String,
      detectedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['detectedAt'] as num).toInt(),
      ),
    );
  }

  Color get color {
    switch (severity) {
      case 'HIGH':
        return AppColors.error;
      case 'MEDIUM':
        return AppColors.primary;
      default:
        return AppColors.accent;
    }
  }

  IconData get icon {
    switch (type) {
      case 'PROGRESSION':
        return Icons.trending_up;
      case 'REGRESSION':
        return Icons.trending_down;
      case 'BAC_APPROCHE':
        return Icons.school;
      case 'INACTIVITE':
        return Icons.access_time;
      case 'NOUVELLE_FORCE':
        return Icons.star;
      case 'NOUVELLE_FAIBLESSE':
        return Icons.warning_amber;
      case 'PALIER_ATTEINT':
        return Icons.emoji_events;
      default:
        return Icons.notifications;
    }
  }
}

/// Bannière ORIA proactive qui affiche les événements détectés par l'EventEngine.
/// Lit /api/v1/evolution/{studentId}/events.
class OriaProactiveBanner extends StatefulWidget {
  final String studentTrackingId;
  const OriaProactiveBanner({super.key, required this.studentTrackingId});

  @override
  State<OriaProactiveBanner> createState() => _OriaProactiveBannerState();
}

class _OriaProactiveBannerState extends State<OriaProactiveBanner> {
  final ApiService _api = ApiService();
  List<OriaEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _api.getEvolutionEvents(widget.studentTrackingId);
      if (raw.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      // raw = { "score":..., "explanation":..., "details": { "events": [...] } }
      final details = raw['details'] as Map<String, dynamic>?;
      final eventsList = (details?['events'] as List?) ?? [];
      final list = eventsList
          .map((e) => OriaEvent.fromJson(e as Map<String, dynamic>))
          .toList();
      // Tri : HIGH > MEDIUM > LOW, puis plus récent d'abord
      list.sort((a, b) {
        final sevOrder = {'HIGH': 0, 'MEDIUM': 1, 'LOW': 2};
        final cmp = (sevOrder[a.severity] ?? 3)
            .compareTo(sevOrder[b.severity] ?? 3);
        if (cmp != 0) return cmp;
        return b.detectedAt.compareTo(a.detectedAt);
      });
      if (mounted) {
        setState(() {
          _events = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'ORIA te parle',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._events.take(3).map((e) => _EventCard(event: e)),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final OriaEvent event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: event.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: event.color, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(event.icon, color: event.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              event.message,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
