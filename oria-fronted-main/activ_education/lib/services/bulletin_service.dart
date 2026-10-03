// lib/services/bulletin_service.dart

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'base_service.dart';

class BulletinService extends BaseService {
  static final BulletinService _instance = BulletinService._internal();
  factory BulletinService() => _instance;
  BulletinService._internal();

  /// Crée la pièce multipart adaptée à chaque plateforme.
  /// Sur le Web, file_picker ne fournit pas de chemin de fichier : il faut
  /// transmettre les octets retournés par le navigateur.
  Future<MultipartFile> _toMultipartFile(PlatformFile file) async {
    if (kIsWeb) {
      final bytes = file.bytes;
      if (bytes == null) {
        throw ArgumentError('Les données du fichier sont indisponibles.');
      }
      return MultipartFile.fromBytes(bytes, filename: file.name);
    }

    final filePath = file.path;
    if (filePath == null) {
      throw ArgumentError('Le chemin du fichier est indisponible.');
    }
    return MultipartFile.fromFile(filePath, filename: file.name);
  }

  // ─── Preview (OCR sans sauvegarde) ─────────────────────────────────

  /// POST /api/v1/eleves/{eleveTrackingId}/bulletins/preview
  Future<PreviewBulletinResponseModel> preview({
    required String eleveTrackingId,
    required PlatformFile file,
    required String anneeScolaire,
    required String periode,
    required String typePeriode,
    required int numeroPeriode,
  }) async {
    final formData = FormData.fromMap({
      'file': await _toMultipartFile(file),
      'anneeScolaire': anneeScolaire,
      'periode': periode,
      'typePeriode': typePeriode,
      'numeroPeriode': numeroPeriode,
    });
    final res = await dio.post(
      '/api/v1/eleves/$eleveTrackingId/bulletins/preview',
      data: formData,
    );
    return PreviewBulletinResponseModel.fromJson(
      res.data as Map<String, dynamic>,
    );
  }

  // ─── Confirm (sauvegarder les notes validées) ──────────────────────

  /// POST /api/v1/eleves/{eleveTrackingId}/bulletins/confirm
  Future<BulletinUploadResponseModel> confirm({
    required String eleveTrackingId,
    required String documentTrackingId,
    required String anneeScolaire,
    required String periode,
    required String semestreOuTrimestre,
    required List<Map<String, dynamic>> notesValidees,
  }) async {
    final res = await dio.post(
      '/api/v1/eleves/$eleveTrackingId/bulletins/confirm',
      queryParameters: {
        'documentTrackingId': documentTrackingId,
        'anneeScolaire': anneeScolaire,
        'periode': periode,
        'semestreOuTrimestre': semestreOuTrimestre,
      },
      data: notesValidees,
    );
    return BulletinUploadResponseModel.fromJson(
      res.data as Map<String, dynamic>,
    );
  }

  // ─── Upload mono ───────────────────────────────────────────────────

  Future<BulletinUploadResponseModel> uploadBulletin({
    required String eleveTrackingId,
    required PlatformFile file,
    required String anneeScolaire,
    required String periode,
    required String typePeriode,
    required int numeroPeriode,
  }) async {
    final formData = FormData.fromMap({
      'file': await _toMultipartFile(file),
      'anneeScolaire': anneeScolaire,
      'periode': periode,
      'typePeriode': typePeriode,
      'numeroPeriode': numeroPeriode,
    });
    final res = await dio.post(
      '/api/v1/eleves/$eleveTrackingId/bulletins',
      data: formData,
    );
    return BulletinUploadResponseModel.fromJson(
      res.data as Map<String, dynamic>,
    );
  }

  // ─── Upload batch (1..3 bulletins) ────────────────────────────────

  Future<List<BulletinUploadResponseModel>> uploadBatch({
    required String eleveTrackingId,
    required List<PlatformFile> files,
    required List<String> annees,
    required List<String> periodes,
    required List<String> types,
    required List<int> numeros,
  }) async {
    final n = files.length;
    if (annees.length != n ||
        periodes.length != n ||
        types.length != n ||
        numeros.length != n) {
      throw ArgumentError(
        'Tailles incohérentes : files=$n, annees=${annees.length}, '
        'periodes=${periodes.length}, types=${types.length}, '
        'numeros=${numeros.length}.',
      );
    }
    final formData = FormData();
    for (var i = 0; i < files.length; i++) {
      formData.files.add(
        MapEntry(
          'files',
          await _toMultipartFile(files[i]),
        ),
      );
    }
    for (final a in annees) {
      formData.fields.add(MapEntry('anneeScolaire', a));
    }
    for (final p in periodes) {
      formData.fields.add(MapEntry('periode', p));
    }
    for (final t in types) {
      formData.fields.add(MapEntry('typePeriode', t));
    }
    for (final num in numeros) {
      formData.fields.add(MapEntry('numeroPeriode', num.toString()));
    }
    final res = await dio.post(
      '/api/v1/eleves/$eleveTrackingId/bulletins/batch',
      data: formData,
    );
    return ((res.data as List<dynamic>?) ?? [])
        .whereType<Map<String, dynamic>>()
        .map(BulletinUploadResponseModel.fromJson)
        .toList();
  }
}
