import 'package:flutter_test/flutter_test.dart';
import 'package:oria_education/services/auth_service.dart';
import 'package:oria_education/services/base_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile data', () {
    test('saveUserData persists photo and university', () async {
      await AuthService().saveUserData(
        trackingId: 'abc123',
        role: 'ELEVE',
        nom: 'AKO',
        prenom: 'Grace',
        email: 'grace@example.com',
        niveauEtude: 'Terminale',
        filiere: 'Sciences',
        metierSouhaite: 'Médecin',
        etablissementActuel: 'Université de Lomé',
        photoUrl: 'https://example.com/avatar.jpg',
      );

      expect(await BaseService.readSecure('user_etablissement_actuel'),
          'Université de Lomé');
      expect(await BaseService.readSecure('user_photo_url'),
          'https://example.com/avatar.jpg');
    });
  });
}
