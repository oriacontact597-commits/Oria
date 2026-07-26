// test/bulletin_models_test.dart
//
// Tests des modèles Dart du module bulletin (Chantier C).
// Suit le pattern de model_test.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:activ_education/models/models.dart';

void main() {
  group('NoteExtraiteModel', () {
    test('fromJson', () {
      final n = NoteExtraiteModel.fromJson({
        'matiere': 'Mathématiques',
        'note': 14.5,
        'coefficient': 2.0,
      });
      expect(n.matiere, 'Mathématiques');
      expect(n.note, 14.5);
      expect(n.coefficient, 2.0);
    });

    test('fromJson tolère des champs absents (défauts safe)', () {
      final n = NoteExtraiteModel.fromJson(<String, dynamic>{});
      expect(n.matiere, '');
      expect(n.note, 0.0);
      expect(n.coefficient, 1.0);
    });
  });

  group('NoteSaisiManuelResponseModel', () {
    test('fromJson complet', () {
      final n = NoteSaisiManuelResponseModel.fromJson({
        'trackingId': 'note-1',
        'matiere': 'Français',
        'note': 13.0,
        'coefficient': 3,
        'anneeScolaire': '2024-2025',
        'semestreOuTrimestre': 'Trimestre 2',
        'eleveTrackingId': 'eleve-1',
        'createdAt': '2025-03-15T10:30:00',
      });
      expect(n.trackingId, 'note-1');
      expect(n.matiere, 'Français');
      expect(n.note, 13.0);
      expect(n.coefficient, 3);
      expect(n.anneeScolaire, '2024-2025');
      expect(n.semestreOuTrimestre, 'Trimestre 2');
      expect(n.eleveTrackingId, 'eleve-1');
      expect(n.createdAt, isNotNull);
      expect(n.createdAt!.year, 2025);
    });

    test('fromJson tolère createdAt mal formé → null', () {
      final n = NoteSaisiManuelResponseModel.fromJson({
        'trackingId': 'note-2',
        'matiere': 'SVT',
        'note': 10.0,
        'eleveTrackingId': 'eleve-1',
        'createdAt': 'pas-une-date',
      });
      expect(n.createdAt, isNull);
    });
  });

  group('BulletinUploadResponseModel', () {
    test('fromJson complet avec notes + reco', () {
      final r = BulletinUploadResponseModel.fromJson({
        'trackingId': 'doc-1',
        'notesExtraites': [
          {'matiere': 'Maths', 'note': 14.0, 'coefficient': 2.0},
          {'matiere': 'Français', 'note': 12.0, 'coefficient': 3.0},
        ],
        'notesCrees': [
          {
            'trackingId': 'n-1',
            'matiere': 'Maths',
            'note': 14.0,
            'coefficient': 2,
            'anneeScolaire': '2024-2025',
            'semestreOuTrimestre': 'Trimestre 2',
            'eleveTrackingId': 'eleve-1',
          }
        ],
        'recommandation': {
          'eleveTrackingId': 'eleve-1',
          'top': [
            {
              'trackingId': 'f-1',
              'titre': 'Informatique',
              'domaine': 'Sciences',
              'duree': '3 ans',
              'scoreFinal': 0.85,
            }
          ],
          'poidsAspiration': 0.35,
          'poidsRealite': 0.50,
          'poidsEngagement': 0.15,
        },
        'periode': 'MILIEU',
        'anneeScolaire': '2024-2025',
        'semestreOuTrimestre': 'Trimestre 2',
        'message': 'Bulletin analysé : 1 note(s) extraite(s).',
      });
      expect(r.trackingId, 'doc-1');
      expect(r.notesExtraites.length, 2);
      expect(r.notesCrees.length, 1);
      expect(r.notesCrees.first.matiere, 'Maths');
      expect(r.recommandation, isNotNull);
      expect(r.recommandation!['top'], isA<List>());
      expect((r.recommandation!['top'] as List).length, 1);
      expect(r.periode, 'MILIEU');
      expect(r.anneeScolaire, '2024-2025');
      expect(r.semestreOuTrimestre, 'Trimestre 2');
      expect(r.message, contains('1 note'));
    });

    test('fromJson tolère recommandation null (0 filière)', () {
      final r = BulletinUploadResponseModel.fromJson({
        'trackingId': 'doc-2',
        'notesExtraites': [],
        'notesCrees': [],
        'recommandation': null,
      });
      expect(r.recommandation, isNull);
      expect(r.notesExtraites, isEmpty);
    });
  });
}
