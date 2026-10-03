// lib/screens/home/dashboard_bachelier.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_routes.dart';
import '../../services/api_service.dart';
import '../../services/base_service.dart';
import '../../models/models.dart';
import '../../widgets/skeleton_widget.dart';
import '../../widgets/oria_proactive_banner.dart';
import '../../utils/image_utils.dart';
import '../../utils/profile_completion.dart';
import '../explorer/fiche_detail_screen.dart';
import '../documents/documents_screen.dart';

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
  int _unreadNotificationsCount = 0;
  ResultatDiagnosticResponse? _dernierResultat;
  EleveResponse? _userProfile;
  String? _iaRecommandation;
  double _profilCompletion = 0;
  bool _hasNotes = false;
  List<FicheEtablissementResponse> _etablissements = const [];

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
      final id = _userTrackingId!;

      // Prénom garanti : 1) stockage local (écrit à la connexion),
      // 2) /auth/me (tous types de comptes), 3) profil élève.
      try {
        final stored = await BaseService.readSecure('user_prenom');
        if (stored != null && stored.trim().isNotEmpty) {
          _userName = stored.trim();
        }
      } catch (_) {}
      if (_userName == null) {
        try {
          final me = await _api.auth.getMe();
          final prenom = (me['prenom'] as String?)?.trim();
          if (prenom != null && prenom.isNotEmpty) {
            _userName = prenom;
            await BaseService.writeSecure('user_prenom', prenom);
          }
        } catch (_) {}
      }

      try {
        final p = await _api.getEleve(id);
        _userProfile = p;
        if (p.prenom.isNotEmpty) _userName = p.prenom;
      } catch (_) {
        _userName ??= 'Invité';
      }
      _lastLoad = DateTime.now();
      if (mounted) setState(() => _isLoading = false);

      await Future.wait([
        _api.getMessagesNonLus(id).then((c) {
          _unreadMessagesCount = c;
        }).catchError((_) {}),
        _api.interaction.getNotificationsNonLusCount(id).then((c) {
          _unreadNotificationsCount = c;
        }).catchError((_) {}),
        _api.getResultatsEleve(id, page: 0, size: 1).then((page) {
          if (page.content.isNotEmpty) {
            _dernierResultat = page.content.first;
          }
        }).catchError((_) {}),
        _api.prediction.getMoyennesGenerales(id).then((notes) {
          _hasNotes = notes.isNotEmpty;
        }).catchError((_) {}),
        _api.explorer.listerEtablissements(
                page: 0, size: 10, useCache: false)
            .then((page) {
          _etablissements = page.content;
        }).catchError((_) {}),
      ]);

      _profilCompletion = calculateProfileCompletion(
        telephone: _userProfile?.telephone,
        etablissementActuel: _userProfile?.etablissementActuel,
        filiere: _userProfile?.filiere,
        matieresPreferees: _userProfile?.matieresPreferees,
        hasNotes: _hasNotes,
        hasDiagnostic: _dernierResultat != null,
      );

      try {
        final iaRes = await _api.getRecommandationIA(id);
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
      backgroundColor: const Color(0xFFF8FAFC), // fond du design V2 (#F8FAFC)
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
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildProfileProgress(),
                      const SizedBox(height: 24),
                      _buildQuickServices(),
                      const SizedBox(height: 32),
                      if (_userTrackingId != null) ...[
                        OriaProactiveBanner(studentTrackingId: _userTrackingId!),
                        const SizedBox(height: 24),
                      ],
                      if (_iaRecommandation != null) ...[
                        _buildIaRecommandation(),
                        const SizedBox(height: 24),
                      ],
                      _buildEstablishmentCarousel(),
                      const SizedBox(height: 24),
                      _buildExplorerCta(),
                      const SizedBox(height: 24),
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
    final prenom = (_userProfile?.prenom.isNotEmpty ?? false)
        ? _userProfile!.prenom
        : (_userName ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
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
                  image: _userProfile?.photoUrl != null &&
                          resolveImageUrl(_userProfile!.photoUrl) != null
                      ? DecorationImage(
                          image: NetworkImage(
                              resolveImageUrl(_userProfile!.photoUrl)!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _userProfile?.photoUrl == null
                    ? Center(
                        child: prenom.isNotEmpty
                            ? Text(
                                prenom[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : const Icon(Icons.person_rounded,
                                color: AppColors.primary, size: 24),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        prenom.isNotEmpty ? 'Salut, $prenom !' : 'Salut !',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          fontFamily: 'Inter',
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.waving_hand_rounded,
                        size: 18, color: AppColors.accent),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Prêt(e) pour ton avenir ?',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.notifications),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.notifications_none_rounded,
                        size: 20, color: AppColors.textDark),
                  ),
                ),
              ),
              if (_unreadNotificationsCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileProgress() {
    final pct = _profilCompletion.round();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.track_changes_rounded,
              size: 22, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Profil complété à $pct%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 96,
              height: 8,
              child: LinearProgressIndicator(
                value: _profilCompletion / 100,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickServices() {
    // Couleurs Tailwind (blue/orange/green/pink-100) du design.
    final services = <_QuickService>[
      _QuickService(
        icon: Icons.chat_bubble_rounded,
        iconColor: const Color(0xFF2563EB),
        label: 'Chat avec ORIA',
        color: const Color(0xFFDBEAFE),
        badge: _unreadMessagesCount,
        onTap: () => Navigator.pushNamed(context, AppRoutes.oria),
      ),
      _QuickService(
        icon: Icons.description_rounded,
        iconColor: const Color(0xFFEA580C),
        label: 'Mes Documents',
        color: const Color(0xFFFFEDD5),
        onTap: () {
          final id = _userTrackingId;
          if (id == null) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DocumentsScreen(trackingId: id)),
          );
        },
      ),
      _QuickService(
        icon: Icons.calendar_month_rounded,
        iconColor: const Color(0xFF16A34A),
        label: 'Calendrier',
        color: const Color(0xFFDCFCE7),
        onTap: () => Navigator.pushNamed(context, AppRoutes.rdvList),
      ),
      _QuickService(
        icon: Icons.star_rounded,
        iconColor: const Color(0xFFDB2777),
        label: 'Favoris',
        color: const Color(0xFFFCE7F3),
        onTap: () => Navigator.pushNamed(context, AppRoutes.favorites),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mes Services',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.45,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final s = services[index];
            return GestureDetector(
              onTap: s.onTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: s.color,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Icon(s.icon, color: s.iconColor, size: 26),
                        ),
                        if (s.badge > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: Text(
                                s.badge > 9 ? '9+' : '${s.badge}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.label,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textDark),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildIaRecommandation() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.recommandationIA),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFFC026D3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 12, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'ANALYSE IA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Ton parcours idéal a été généré !',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _iaRecommandation != null && _iaRecommandation!.length > 120
                  ? '${_iaRecommandation!.substring(0, 120)}...'
                  : (_iaRecommandation ?? 'L\'IA analyse ton profil pour te proposer la meilleure orientation.'),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Découvrir mon parcours idéal',
                    style: TextStyle(
                      color: Color(0xFF4F46E5),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Color(0xFF4F46E5), size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Score de correspondance local (profil élève vs contenu de l'établissement).
  /// L'API n'expose pas de "% match" : on le calcule à partir des centres
  /// d'intérêt réels de l'élève (filière, métier souhaité, matières préférées).
  int _matchScore(FicheEtablissementResponse etab) {
    final profilParts = <String>[
      if (_userProfile?.filiere != null) _userProfile!.filiere!,
      if (_userProfile?.metierSouhaite != null) _userProfile!.metierSouhaite!,
      ...?_userProfile?.matieresPreferees,
    ];
    final profil = profilParts.join(' ').toLowerCase();
    final tokens = profil
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length > 3)
        .toSet()
        .toList();
    if (tokens.isEmpty) return 70;

    final cible = '${etab.titre} ${etab.offreFormation ?? ''} '
            '${etab.resume} ${etab.typeEtablissement ?? ''} ${etab.niveau ?? ''}'
        .toLowerCase();
    final hits = tokens.where(cible.contains).length;
    return (60 + hits * 12).clamp(50, 97);
  }

  Widget _buildEstablishmentCarousel() {
    // Fallback visuel (données de démo) si l'API est vide ou injoignable.
    final real = _etablissements.isNotEmpty;
    final schools = _etablissements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Établissements suggérés',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
                  ),
                  Text(
                    'Basé sur ton profil et tes notes',
                    style: TextStyle(fontSize: 12, color: AppColors.textMedium),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.explorer),
              child: const Text('Voir tout', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!real && _isLoading)
          const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
        else if (!real)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Text(
              'Aucun établissement suggéré pour le moment. Explore le catalogue pour en découvrir !',
              style: TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.4),
              textAlign: TextAlign.center,
            ),
          )
        else
          SizedBox(
            height: 175,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: schools.length,
              itemBuilder: (context, index) {
                final etab = schools[index];
                return _EstablishmentCard(
                  etablissement: etab,
                  match: _matchScore(etab),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FicheDetailScreen(fiche: etab)),
                  ),
                );
              },
            ),
          ),
      ],
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
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 22),
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

class _QuickService {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color color;
  final int badge;
  final VoidCallback onTap;

  const _QuickService({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge = 0,
  });
}

class _EstablishmentCard extends StatelessWidget {
  final FicheEtablissementResponse etablissement;
  final int match;
  final VoidCallback onTap;

  const _EstablishmentCard({
    required this.etablissement,
    required this.match,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final etab = etablissement;
    final photo = resolveImageUrl(etab.imageUrl);
    final sousTitre = [
      if ((etab.offreFormation ?? '').isNotEmpty) etab.offreFormation,
      if ((etab.ville ?? '').isNotEmpty) etab.ville,
    ].whereType<String>().join(' • ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: photo != null
                        ? Image.network(
                            photo,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const _EtabEmojiBox(),
                          )
                        : const _EtabEmojiBox(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$match% Match',
                    style: const TextStyle(
                      color: Color(0xFF15803D),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              etab.titre.isNotEmpty ? etab.titre : 'Sans nom',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              sousTitre.isNotEmpty ? sousTitre : (etab.typeEtablissement ?? 'Établissement'),
              style: const TextStyle(fontSize: 11, color: AppColors.textMedium),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9FAFB),
                  foregroundColor: AppColors.textDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                ),
                child: const Text('Voir détails',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EtabEmojiBox extends StatelessWidget {
  const _EtabEmojiBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE0E7FF),
      alignment: Alignment.center,
      child: const Icon(Icons.school_rounded, size: 24, color: Color(0xFF4338CA)),
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
