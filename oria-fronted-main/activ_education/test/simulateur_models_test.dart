// test/simulateur_models_test.dart
//
// Tests des modèles Dart du module simulateur (Chantiers A + B).
// Suit le pattern de model_test.dart (parsing JSON + valeurs par défaut).

import 'package:flutter_test/flutter_test.dart';
import 'package:oria_education/models/models.dart';

void main() {
  group('ScenarioTemplateModel', () {
    test('fromJson parses tous les champs', () {
      final json = {
        'trackingId': '11111111-1111-1111-1111-000000000001',
        'titre': 'Et si je montais ma moyenne de maths de 2 points ?',
        'description': 'Simulation de +2 points en maths.',
        'categorie': 'PROGRESSION_NOTES',
      };
      final t = ScenarioTemplateModel.fromJson(json);
      expect(t.trackingId, '11111111-1111-1111-1111-000000000001');
      expect(t.titre, contains('maths'));
      expect(t.description, contains('+2'));
      expect(t.categorie, CategorieTemplate.PROGRESSION_NOTES);
    });

    test('fromJson tolère une catégorie inconnue → PROGRESSION_NOTES', () {
      final json = {
        'trackingId': 'x',
        'titre': 't',
        'description': 'd',
        'categorie': 'BIZARRE',
      };
      final t = ScenarioTemplateModel.fromJson(json);
      expect(t.categorie, CategorieTemplate.PROGRESSION_NOTES);
    });

    test('fromJson tolère des champs manquants', () {
      final json = <String, dynamic>{};
      final t = ScenarioTemplateModel.fromJson(json);
      expect(t.trackingId, '');
      expect(t.titre, '');
      expect(t.description, '');
    });

    test('CategorieTemplate.label retourne un libellé non vide', () {
      for (final c in CategorieTemplate.values) {
        expect(c.label, isNotEmpty);
      }
    });
  });

  group('ScenarioResultModel', () {
    test('fromJson minimal (tout vide)', () {
      final json = <String, dynamic>{};
      final r = ScenarioResultModel.fromJson(json);
      expect(r.filieres, isEmpty);
      expect(r.metiers, isEmpty);
      expect(r.etablissements, isEmpty);
      expect(r.stats, isNull);
      expect(r.comparaison, isNull);
    });

    test('fromJson avec stats + filiere complète', () {
      final json = {
        'titre': 'Maths +2 points',
        'serieTitre': 'Série C',
        'stats': {
          'totalFilieres': 5,
          'totalMetiers': 12,
          'totalEtablissements': 3,
          'scoreMoyenCompatibilite': 78.5,
          'dureeMin': 2.0,
          'dureeMax': 5.0,
        },
        'filieres': [
          {
            'trackingId': 'f-1',
            'titre': 'Informatique',
            'resume': 'Filière info',
            'domaine': 'Sciences',
            'duree': '3 ans',
            'niveauRequis': 'Bac C',
            'scoreCompatibilite': 85.0,
            'seuilsValides': 4,
            'seuilsTotal': 5,
          },
        ],
        'metiers': [
          {
            'trackingId': 'm-1',
            'titre': 'Développeur',
            'resume': 'Dev web/mobile',
            'secteur': 'Tech',
            'fourchetteSalaire': '300k-800k',
          },
        ],
        'etablissements': [
          {
            'trackingId': 'e-1',
            'titre': 'Université de Lomé',
            'ville': 'Lomé',
            'type': 'Public',
            'niveau': 'Licence',
            'estPublic': true,
            'filieresProposeesTitres': ['Informatique', 'Maths'],
          },
        ],
      };
      final r = ScenarioResultModel.fromJson(json);
      expect(r.titre, 'Maths +2 points');
      expect(r.serieTitre, 'Série C');
      expect(r.stats, isNotNull);
      expect(r.stats!.totalFilieres, 5);
      expect(r.stats!.scoreMoyenCompatibilite, 78.5);
      expect(r.filieres.length, 1);
      expect(r.filieres.first.titre, 'Informatique');
      expect(r.filieres.first.scoreCompatibilite, 85.0);
      expect(r.metiers.first.secteur, 'Tech');
      expect(r.etablissements.first.estPublic, true);
      expect(r.etablissements.first.filieresProposeesTitres.length, 2);
    });

    test('fromJson avec comparaison (Chantier A)', () {
      final json = {
        'titre': 'Comparaison',
        'comparaison': {
          'meilleurScenario': 'Lomé',
          'pireScenario': 'Kara',
          'scoreMoyenMax': 80.0,
          'scoreMoyenMin': 60.0,
          'nombreFilieresCommunes': 3,
          'nombreScenarios': 2,
          'synthese': 'Lomé est 20% meilleur en moyenne.',
          'deltasParFiliere': {
            'Informatique': [
              {'scenarioTitre': 'Lomé', 'score': 80.0},
              {'scenarioTitre': 'Kara', 'score': 60.0},
            ],
          },
        },
      };
      final r = ScenarioResultModel.fromJson(json);
      expect(r.comparaison, isNotNull);
      expect(r.comparaison!.meilleurScenario, 'Lomé');
      expect(r.comparaison!.nombreFilieresCommunes, 3);
      expect(r.comparaison!.synthese, contains('Lomé'));
      expect(r.comparaison!.deltasParFiliere['Informatique']!.length, 2);
      expect(
          r.comparaison!.deltasParFiliere['Informatique']!.first.score, 80.0);
    });
  });

  group('StatsRecapModel / FiliereMatchModel', () {
    test('StatsRecap tolère des champs absents', () {
      final s = StatsRecapModel.fromJson(<String, dynamic>{});
      expect(s.totalFilieres, 0);
      expect(s.scoreMoyenCompatibilite, 0.0);
    });

    test('FiliereMatch.fromJson avec valeurs par défaut', () {
      final f = FiliereMatchModel.fromJson(<String, dynamic>{});
      expect(f.trackingId, '');
      expect(f.scoreCompatibilite, 0.0);
      expect(f.seuilsTotal, 0);
    });
  });
}
