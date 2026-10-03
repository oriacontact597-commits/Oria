import 'package:flutter_test/flutter_test.dart';
import 'package:oria_education/models/models.dart';

void main() {
  group('TokenResponse', () {
    test('fromJson parses correctly', () {
      final json = {
        'accessToken': 'abc123',
        'refreshToken': 'def456',
        'trackingId': 'track-1',
        'typeUtilisateur': 'ELEVE',
        'roles': ['ROLE_USER'],
        'expiresInMs': 86400000,
      };
      final token = TokenResponse.fromJson(json);
      expect(token.accessToken, 'abc123');
      expect(token.refreshToken, 'def456');
      expect(token.trackingId, 'track-1');
      expect(token.typeUtilisateur, 'ELEVE');
      expect(token.roles, ['ROLE_USER']);
      expect(token.expiresInMs, 86400000);
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};
      final token = TokenResponse.fromJson(json);
      expect(token.accessToken, '');
      expect(token.refreshToken, '');
      expect(token.trackingId, '');
      expect(token.typeUtilisateur, '');
      expect(token.roles, []);
      expect(token.expiresInMs, 0);
    });
  });

  group('EleveRequest', () {
    test('toJson includes all fields', () {
      final request = EleveRequest(
        nom: 'Doe',
        prenom: 'John',
        email: 'john@test.com',
        telephone: '+22800000000',
        motDePasse: 'pass1234',
        niveauEtude: 'Terminale',
        typeApprenant: TypeApprenant.LYCEEN,
        etablissementActuel: 'Lycée Test',
        matieresPreferees: ['Maths', 'SVT'],
        styleApprentissage: 'videos',
      );
      final json = request.toJson();
      expect(json['nom'], 'Doe');
      expect(json['email'], 'john@test.com');
      expect(json['telephone'], '+22800000000');
      expect(json['typeApprenant'], 'LYCEEN');
      expect(json['matieresPreferees'], ['Maths', 'SVT']);
      expect(json['styleApprentissage'], 'videos');
    });

    test('toJson excludes null fields', () {
      final request = EleveRequest(
        nom: 'Doe',
        prenom: 'John',
        email: 'john@test.com',
        motDePasse: 'pass1234',
        typeApprenant: TypeApprenant.AUTRE,
      );
      final json = request.toJson();
      expect(json.containsKey('telephone'), false);
      expect(json.containsKey('niveauEtude'), false);
      expect(json.containsKey('matieresPreferees'), false);
      expect(json.containsKey('styleApprentissage'), false);
    });
  });


}
