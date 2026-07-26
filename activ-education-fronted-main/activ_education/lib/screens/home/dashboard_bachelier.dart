// lib/screens/home/dashboard_bachelier.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_routes.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/skeleton_widget.dart';
import '../../widgets/oria_proactive_banner.dart';
import '../../utils/image_utils.dart';

class DashboardBachelier extends StatefulWidget {
  final String? typeApprenant;
  const DashboardBachelier({super.key, this.typeApprenant});

  @override
  State<DashboardBachelier> createState() => _DashboardBachelierState();
}

class _DashboardBachelierState extends State<DashboardBachelier> with RouteAware {
  final _api = ApiService();

  String? _userTrackingId;
  String? _userName;
  int _unreadMessagesCount = 0;
  ResultatDiagnosticResponse? _dernierResultat;
  EleveResponse? _userProfile;
  String? _iaRecommandation;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppRoutes.routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    AppRoutes.routeObserver.unsubscribe(this);
    super.dispose();
  }

  DateTime _lastLoad = DateTime(2000);

  @override
  void didPopNext() {
    if (DateTime.now().difference(_lastLoad).inSeconds > 30) {
      _loadDashboardData();
    }
  }

  @override
  void didPush() {
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);
      _userTrackingId = await _api.getTrackingId();
      if (_userTrackingId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 1. Chargement critique : profil
      await _api.getEleve(_userTrackingId!).then((p) {
        _userProfile = p;
        _userName = p.prenom;
      }).catchError((_) { _userName = 'Invité'; });
      _lastLoad = DateTime.now();
      if (mounted) setState(() => _isLoading = false);

      // 2. Chargement non-critique en arrière-plan
      await Future.wait([
        _api.getMessagesNonLus(_userTrackingId!).then((c) {
          _unreadMessagesCount = c;
        }).catchError((_) {}),
        _api.getResultatsEleve(_userTrackingId!, page: 0, size: 1).then((page) {
          if (page.content.isNotEmpty) {
            _dernierResultat = page.content.first;
          }
        }).catchError((_) {}),
      ]);
      try {
        final iaRes = await _api.getRecommandationIA(_userTrackingId!);
        _iaRecommandation = iaRes;
      } catch (_) {
        _iaRecommandation = _dernierResultat?.recommandation;
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Erreur chargement dashboard: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: SafeArea(
        child: _isLoading
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header avec salutation et notifications
                      _buildHeader(),

                      const SizedBox(height: 20),

                      // ════════════════════════════════════════════════════════
                      // Hackaton AI4GOOD : ORIA prend la place centrale
                      // (à la place du diagnostic, des actions rapides,
                      //  des modules d'orientation, des messages,
                      //  des conseillers et des rendez-vous)
                      // ════════════════════════════════════════════════════════
                      _buildOriaCallout(),

                      const SizedBox(height: 16),

                      // Événements proactifs (EventEngine backend)
                      if (_userTrackingId != null)
                        OriaProactiveBanner(studentTrackingId: _userTrackingId!),

                      const SizedBox(height: 24),

                      // Recommandation personnalisée IA
                      if (_iaRecommandation != null) ...[
                        _buildIaRecommandation(),
                        const SizedBox(height: 24),
                      ],

                      // Explorer CTA
                      _buildExplorerCta(),

                      const SizedBox(height: 24),

                      // Aide & FAQ
                      _buildHelpSection(),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Bonjour ${_userProfile?.prenom ?? "Bachelier"} !',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        fontFamily: 'Inter',
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (_userProfile?.niveauEtude != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _userProfile!.niveauEtude!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _buildHeaderSubtitle(),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.search),
          child: Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
              ],
            ),
            child: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
          ),
        ),
        Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.backgroundGrey,
                    image: _userProfile?.photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(resolveImageUrl(_userProfile!.photoUrl)!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _userProfile?.photoUrl == null
                      ? Center(
                          child: Text(
                            _userName != null && _userName!.isNotEmpty
                                ? _userName![0].toUpperCase()
                                : 'B',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
            if (_unreadMessagesCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _unreadMessagesCount > 9 ? '9+' : _unreadMessagesCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _buildHeaderSubtitle() {
    final p = _userProfile;
    if (p == null) return 'Nouveau Bachelier';
    final type = p.typeApprenant;
    final niveau = p.niveauEtude ?? '';
    final filiere = p.filiere ?? '';
    if (type == 'COLLEGIEN') {
      return niveau.isNotEmpty ? '$type — $niveau' : type;
    }
    if (type == 'LYCEEN') {
      final parts = [type];
      if (niveau.isNotEmpty) parts.add(niveau);
      if (filiere.isNotEmpty) parts.add('série $filiere');
      return parts.join(' — ');
    }
    if (type == 'ETUDIANT') {
      final parts = [type];
      if (niveau.isNotEmpty) parts.add(niveau);
      if (filiere.isNotEmpty) parts.add(filiere);
      return parts.join(' — ');
    }
    return type;
  }

  // ════════════════════════════════════════════════════════════════════
  // Hackaton AI4GOOD — ORIA au centre de l'accueil
  // Remplace l'ancien bloc "Action requise / Diagnostic".
  // ════════════════════════════════════════════════════════════════════
  Widget _buildOriaCallout() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.oria),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3133DD), Color(0xFF6A3DE8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3133DD).withValues(alpha: 0.30),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'O',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ORIA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Inter',
                        ),
                      ),
                      Text(
                        'Ton assistant d\'orientation IA',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Filières, universités, métiers… pose ta question, je te réponds avec des infos concrètes du Togo 🇹🇬',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            color: Colors.white70, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Discuter avec ORIA…',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF3133DD),
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Phase 4 — lance le parcours du moteur 3 signaux depuis le dashboard.
  /// Si l'élève n'a pas de niveau, on commence par `selection_niveau_screen`.
  /// Sinon on va directement à la saisie des bulletins.
  Future<void> _lancerParcours3Signaux() async {
    try {
      final trackingId = _userTrackingId;
      if (trackingId == null) return;
      final eleve = await _api.getEleve(trackingId);
      if (!mounted) return;
      if (eleve.niveauEtude == null || eleve.niveauEtude!.isEmpty) {
        Navigator.pushNamed(context, AppRoutes.selectionNiveau);
      } else {
        Navigator.pushNamed(
          context,
          AppRoutes.bulletinsHistorique,
          arguments: {
            'niveauCode': eleve.niveauEtude,
            'niveauLabel': eleve.niveauEtude,
          },
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.pushNamed(context, AppRoutes.bulletinsHistorique);
    }
  }

  Widget _buildIaRecommandation() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.recommandationIA),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Ma recommandation',
                        style: AppTextStyles.label.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _iaRecommandation != null && _iaRecommandation!.length > 120
                        ? '${_iaRecommandation!.substring(0, 120)}...'
                        : (_iaRecommandation ?? ''),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Voir la recommandation complète →',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Phase 4 — entrée alternative vers le moteur 3 signaux
                  GestureDetector(
                    onTap: _lancerParcours3Signaux,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.auto_graph, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Tester la v2 (3 signaux)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplorerCta() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.15),
            AppColors.accent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explorer les filières',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Découvre toutes les formations disponibles',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMedium),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.explorer),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Besoin d\'aide ?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Consultez notre foire aux questions ou contactez l\'assistance.',
            style: TextStyle(color: AppColors.textMedium),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HelpAction(
                  icon: Icons.help_outline_rounded,
                  label: 'FAQ',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.faq),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HelpAction(
                  icon: Icons.support_agent_rounded,
                  label: 'Support',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.messages),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _HelpAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HelpAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

