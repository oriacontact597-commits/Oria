import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class DataHubScreen extends StatefulWidget {
  const DataHubScreen({super.key});

  @override
  State<DataHubScreen> createState() => _DataHubScreenState();
}

class _DataHubScreenState extends State<DataHubScreen> {
  final _api = ApiService();
  DataHubResponse? _data;
  bool _isLoading = true;
  bool _useMapView = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await _api.datahub.getDataHub();
      if (mounted) setState(() { _data = data; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_api.handleError(e))),
        );
      }
    }
  }

  Color _heatColor(double value, double max) {
    if (max == 0) return Colors.grey.shade200;
    final ratio = value / max;
    if (ratio > 0.7) return Colors.red.shade700;
    if (ratio > 0.4) return Colors.orange.shade600;
    if (ratio > 0.2) return Colors.amber.shade500;
    return Colors.blue.shade300;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte thermique'),
        actions: [
          IconButton(
            icon: Icon(_useMapView ? Icons.list : Icons.map),
            tooltip: _useMapView ? 'Vue liste' : 'Vue carte',
            onPressed: () => setState(() => _useMapView = !_useMapView),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('Impossible de charger les données'))
              : _useMapView ? _buildMapView() : _buildListView(),
    );
  }

  Widget _buildMapView() {
    final regions = _data!.regions.where((r) => r.nom != 'Autres').toList();
    final maxEtab = regions.fold(0.0, (max, r) => r.densite > max ? r.densite : max);

    if (regions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Aucune donnée régionale disponible',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(8.6195, 0.8248),
        initialZoom: 7.0,
        minZoom: 6.0,
        maxZoom: 9.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'tg.edtch.activEducation',
        ),
        MarkerLayer(
          markers: regions.map((r) {
            final radius = max(20.0, min(60.0, r.densite / maxEtab * 50 + 20));
            return Marker(
              point: LatLng(r.latitude, r.longitude),
              width: radius * 2 + 20,
              height: radius * 2 + 30,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: radius * 2,
                    height: radius * 2,
                    decoration: BoxDecoration(
                      color: _heatColor(r.densite, maxEtab).withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6)],
                    ),
                    child: Center(
                      child: Text('${r.nombreEtablissements}',
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(r.nom, style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11,
                      shadows: [Shadow(color: Colors.white, blurRadius: 3)])),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildListView() {
    final regions = _data!.regions;
    final maxEtab = regions.fold(0.0, (max, r) => r.densite > max ? r.densite : max);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          const Text('Régions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...regions.map((r) => _buildRegionTile(r, maxEtab)),
          const SizedBox(height: 24),
          const Text('Répartition par type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ..._data!.repartitionTypeEtablissement.entries.map((e) => _buildTypeTile(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final d = _data!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text('${d.totalEtablissements}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Établissements', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            Container(width: 1, height: 40, color: Colors.grey[300]),
            Expanded(
              child: Column(
                children: [
                  Text('${d.totalFilieres}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Filières', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            Container(width: 1, height: 40, color: Colors.grey[300]),
            Expanded(
              child: Column(
                children: [
                  Text('${d.regions.length}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Régions', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionTile(RegionStat r, double maxEtab) {
    final color = _heatColor(r.densite, maxEtab);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text('${r.nombreEtablissements}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        title: Text(r.nomComplet, style: const TextStyle(fontSize: 14)),
        subtitle: Text(r.etablissementsParType.entries.map((e) =>
            '${_typeLabel(e.key)}: ${e.value}').join(' · '),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: SizedBox(
          width: 60,
          child: LinearProgressIndicator(
            value: maxEtab > 0 ? r.densite / maxEtab : 0,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTile(String type, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(_typeIcon(type), size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(_typeLabel(type), style: const TextStyle(fontSize: 13))),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'UNIVERSITE': return 'Université';
      case 'ECOLE_SUPERIEURE': return 'École supérieure';
      case 'LYCEE': return 'Lycée';
      case 'COLLEGE': return 'Collège';
      case 'CENTRE_FORMATION_PROFESSIONNELLE': return 'CFP';
      case 'GRANDE_ECOLE': return 'Grande école';
      default: return type;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'UNIVERSITE': return Icons.school;
      case 'ECOLE_SUPERIEURE': return Icons.account_balance;
      case 'LYCEE': return Icons.school_outlined;
      case 'COLLEGE': return Icons.menu_book;
      case 'CENTRE_FORMATION_PROFESSIONNELLE': return Icons.build;
      case 'GRANDE_ECOLE': return Icons.star;
      default: return Icons.business;
    }
  }
}
