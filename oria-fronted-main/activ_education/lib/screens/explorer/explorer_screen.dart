import 'package:flutter/material.dart';

import '../../models/common.dart';
import '../../models/explorer_models.dart';
import '../../screens/explorer/fiche_detail_screen.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_filter_chip.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/app_section_header.dart';
import '../../widgets/skeleton_widget.dart';

/// Catalogue Bibliothèque — établissements.
/// Sticky search bar + chips filtres pays/type + grille 2 colonnes.
/// Style Notion : épuré, hiérarchie forte, skeleton au chargement.
class ExplorerScreen extends StatefulWidget {
  const ExplorerScreen({super.key});

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedPays = 'TG';
  bool _loading = true;
  List<dynamic> _items = const [];
  int _total = 0;

  static const _paysOpts = [
    ('TG', '🇹🇬 Togo'),
    ('BJ', '🇧🇯 Bénin'),
    ('CI', '🇨🇮 Côte d\'Ivoire'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ApiService();
      // Pas de cache : le catalogue doit refléter immédiatement la base.
      // size=1000 : les 3 pays (929 établissements) tiennent dans une réponse,
      // le filtrage pays se fait ensuite côté client.
      final PageResponse<FicheEtablissementResponse> res =
          await api.explorer.listerEtablissements(
              page: 0, size: 1000, useCache: false);

      final filtered = res.content
          .where((e) =>
              (e.countryCode ?? 'TG').toUpperCase() == _selectedPays)
          .toList();

      _total = filtered.length;
      _items = filtered;
    } catch (_) {
      _items = const [];
      _total = 0;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildPaysChips()),
            SliverToBoxAdapter(
              child: AppSectionHeader(
                title: _loading
                    ? 'Chargement…'
                    : '$_total établissements'
                        '${(_selectedPays.isNotEmpty) ? " en $_selectedPays" : ""}',
              ),
            ),
            if (_loading)
              const SliverToBoxAdapter(child: _SkeletonGrid())
            else if (_items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyState(
                  icon: Icons.travel_explore,
                  title: 'Aucun établissement trouvé',
                  subtitle: 'Essaie de changer de pays.',
                  actionLabel: 'Voir tous',
                  onAction: _load,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.xs,
                    crossAxisSpacing: AppSpacing.xs,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildCard(_items[i]),
                    childCount: _items.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text('Bibliothèque', style: AppTextStyles.headingLarge),
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.textDark),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: AppSearchBar(
        controller: _searchCtrl,
        hintText: 'Chercher une école, une filière…',
        onMicTap: () {},
      ),
    );
  }

  Widget _buildPaysChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        itemCount: _paysOpts.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final (code, label) = _paysOpts[i];
          return AppFilterChip(
            label: label,
            selected: _selectedPays == code,
            onTap: () {
              setState(() => _selectedPays = code);
              _load();
            },
          );
        },
      ),
    );
  }

  Widget _buildCard(dynamic e) {
    final FicheEtablissementResponse etab = e as FicheEtablissementResponse;
    final nom = etab.titre.isNotEmpty ? etab.titre : 'Sans nom';
    final ville = etab.ville ?? '';
    final type = etab.typeEtablissement ?? '';
    final photo = etab.imageUrls.isNotEmpty ? etab.imageUrls.first : null;

    return AppCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FicheDetailScreen(fiche: etab)),
        );
      },
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radius),
            ),
            child: SizedBox(
              height: 80,
              width: double.infinity,
              child: photo != null
                  ? Image.network(
                      photo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ville.isEmpty ? '—' : ville,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
                if (type.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      type,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceSubtle,
      child: const Center(
        child: Icon(Icons.school_rounded,
            color: AppColors.primary, size: 36),
      ),
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.xs,
        crossAxisSpacing: AppSpacing.xs,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.82,
        children: List.generate(
          6,
          (_) => const SkeletonWidget(height: 160),
        ),
      ),
    );
  }
}
