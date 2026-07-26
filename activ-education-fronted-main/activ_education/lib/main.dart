// lib/main.dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'models/models.dart';
import 'theme/app_routes.dart';
import 'services/api_service.dart';

// Auth & Onboarding
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/signup_stepper_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/totp_setup_screen.dart';
import 'screens/auth/totp_verify_screen.dart';

// Home & Modules
import 'screens/main_scaffold.dart';
import 'screens/explorer/explorer_screen.dart';
import 'screens/explorer/favorites_screen.dart';
import 'screens/explorer/fiche_detail_screen.dart';
import 'screens/explorer/etablissements_map_screen.dart';
import 'screens/search/global_search_screen.dart';
import 'screens/conseillers/conseillers_screen.dart';
import 'screens/diagnostic/quiz_screen.dart';
import 'screens/diagnostic/resultats_screen.dart';
import 'screens/messages/messages_list_screen.dart';
import 'screens/messages/chat_screen.dart';
import 'screens/messages/rdv_screen.dart';
import 'screens/home/notifications_screen.dart';
import 'screens/home/faq_screen.dart';
import 'screens/home/support_screen.dart';
import 'screens/home/enfant_suivi_screen.dart';
import 'screens/messages/rdv_list_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/errors/not_found_screen.dart';
import 'screens/errors/network_error_screen.dart';
import 'screens/home/recommandation_ia_screen.dart';
import 'screens/orientation/selection_niveau_screen.dart';
import 'screens/orientation/bulletins_historique_screen.dart';
import 'screens/orientation/recommandation_3_signaux_screen.dart';
import 'screens/chat/oria_screen.dart';
import 'screens/simulateur/simulateur_parcours_screen.dart';
import 'screens/simulateur/scenarios_types_screen.dart';
import 'screens/portfolio/portfolio_screen.dart';
import 'screens/datahub/datahub_screen.dart';
import 'screens/entretien/entretien_screen.dart';
import 'screens/reseau/reseau_screen.dart';
import 'screens/badge/badge_screen.dart';
import 'screens/temoignage/temoignage_screen.dart';
import 'screens/evolution/orchestration_result_screen.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  ApiService().init();
  await initializeDateFormatting('fr_FR', null);
  runApp(const OriaApp());
}

class OriaApp extends StatelessWidget {
  const OriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ORIA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      navigatorObservers: [AppRoutes.routeObserver],
      routes: {
        // Auth
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.onboarding: (_) => const OnboardingScreen(),
        AppRoutes.profileSetup: (_) => const SignupStepperScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
        AppRoutes.otp: (_) => const OtpScreen(),
        AppRoutes.resetPassword: (_) => const ResetPasswordScreen(),
        AppRoutes.totpSetup: (_) => const TotpSetupScreen(),
        AppRoutes.totpVerify: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final challengeToken = args?['challengeToken'] as String? ?? '';
          final email = args?['email'] as String? ?? '';
          return TotpVerifyScreen(challengeToken: challengeToken, email: email);
        },

        // Main Navigation
        AppRoutes.home: (_) => const MainScaffold(),
        AppRoutes.dashboard: (_) => const MainScaffold(),

        // Diagnostic
        AppRoutes.quiz: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final quizTrackingId = args?['quizTrackingId'] as String?;
          return QuizScreen(quizTrackingId: quizTrackingId);
        },
        AppRoutes.resultats: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final score = args?['score'] as double?;
          final profil = args?['profil'] as String?;
          final quizId = args?['quizId'] as String?;
          return ResultatsScreen(score: score, profil: profil, quizId: quizId);
        },
        // Autres
        AppRoutes.explorer: (_) => const ExplorerScreen(),
        AppRoutes.messages: (_) => const MessagesListScreen(),
        AppRoutes.chat: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final expediteurId = args?['expediteurId'] as String? ?? '';
          final expediteurNom = args?['expediteurNom'] as String? ?? '';
          return ChatScreen(
              expediteurId: expediteurId, expediteurNom: expediteurNom);
        },
        AppRoutes.rdv: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final conseillerId = args?['conseillerId'] as String?;
          final conseillerNom = args?['conseillerNom'] as String?;
          return RdvScreen(
              conseillerId: conseillerId, conseillerNom: conseillerNom);
        },
        AppRoutes.notifications: (_) => const NotificationsScreen(),
        AppRoutes.favorites: (_) => const FavoritesScreen(),
        AppRoutes.ficheDetail: (context) {
          final raw = ModalRoute.of(context)?.settings.arguments;
          if (raw is Map<String, dynamic>) {
            final fiche = raw['fiche'] as FicheBase?;
            if (fiche != null) {
              return FicheDetailScreen(fiche: fiche);
            }
          }
          return const Scaffold(
            body: Center(child: Text('Fiche non trouvée')),
          );
        },
        AppRoutes.search: (_) => const GlobalSearchScreen(),
        AppRoutes.support: (_) => const SupportScreen(),
        AppRoutes.faq: (_) => const FaqScreen(),
        AppRoutes.conseillers: (_) => const ConseillersScreen(),
        AppRoutes.enfantSuivi: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final enfantId = args?['enfantTrackingId'] as String?;
          if (enfantId == null) return const Scaffold(body: Center(child: Text('Élève non spécifié')));
          return EnfantSuiviScreen(enfantTrackingId: enfantId);
        },
        AppRoutes.rdvList: (_) => const RdvListScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.etablissementsMap: (_) => const EtablissementsMapScreen(),
        AppRoutes.recommandationIA: (_) => const RecommandationIAScreen(),
        AppRoutes.selectionNiveau: (_) => const SelectionNiveauScreen(),
        AppRoutes.bulletinsHistorique: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return BulletinsHistoriqueScreen(
            niveauCode: args?['niveauCode'] as String?,
            niveauLabel: args?['niveauLabel'] as String?,
          );
        },
        AppRoutes.recommandation3Signaux: (_) =>
            const Recommandation3SignauxScreen(),
        AppRoutes.oria: (_) => const OriaScreen(),
        AppRoutes.simulateur: (_) => const SimulateurParcoursScreen(),
        AppRoutes.scenariosTypes: (_) => const ScenariosTypesScreen(),
        AppRoutes.portfolio: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final eleveId = args?['eleveTrackingId'] as String?;
          if (eleveId == null) return const Scaffold(body: Center(child: Text('Élève non spécifié')));
          return PortfolioScreen(eleveTrackingId: eleveId);
        },
        AppRoutes.datahub: (_) => const DataHubScreen(),
        AppRoutes.entretien: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final eleveId = args?['eleveTrackingId'] as String?;
          if (eleveId == null) return const Scaffold(body: Center(child: Text('Élève non spécifié')));
          return EntretienScreen(eleveTrackingId: eleveId);
        },
        AppRoutes.reseau: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final userId = args?['utilisateurId'] as String?;
          final nom = args?['nomUtilisateur'] as String? ?? '';
          if (userId == null) return const Scaffold(body: Center(child: Text('Utilisateur non spécifié')));
          return ReseauScreen(utilisateurId: userId, nomUtilisateur: nom);
        },
        AppRoutes.badges: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final eleveId = args?['eleveTrackingId'] as String?;
          if (eleveId == null) return const Scaffold(body: Center(child: Text('Élève non spécifié')));
          return BadgeScreen(eleveTrackingId: eleveId);
        },
        AppRoutes.temoignages: (_) => const TemoignageScreen(),
        AppRoutes.evolution: (_) => const OrchestrationResultScreen(),

        // États
        AppRoutes.notFound: (_) => const NotFoundScreen(),
        AppRoutes.networkError: (_) => const NetworkErrorScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => NotFoundScreen(
            message: 'Route "${settings.name}" introuvable.',
          ),
        );
      },
    );
  }
}
