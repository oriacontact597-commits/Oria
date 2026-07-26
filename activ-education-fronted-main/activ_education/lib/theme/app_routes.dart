// lib/theme/app_routes.dart
import 'package:flutter/material.dart';

class AppRoutes {
  static final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
  // Auth & Onboarding
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String profileSetup = '/profile-setup';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String otp = '/otp';
  static const String resetPassword = '/reset-password';

  // Main
  static const String home = '/home';
  static const String dashboard = '/dashboard';

  // Modules
  static const String profile = '/profile';
  static const String explorer = '/explorer';
  static const String diagnostic = '/diagnostic';
  static const String quiz = '/diagnostic';
  static const String resultats = '/resultats';
  static const String support = '/support';
  static const String faq = '/faq';
  static const String messages = '/messages';
  static const String chat = '/chat';
  static const String notifications = '/notifications';
  static const String rdv = '/rdv';
  static const String enfantSuivi = '/enfant-suivi';

  static const String rdvList = '/rdv-list';
  static const String recommandationIA = '/recommandation-ia';

  // Prédiction & Recommandation IA (Phase 4)
  static const String selectionNiveau = '/selection-niveau';
  static const String bulletinsHistorique = '/bulletins-historique';
  static const String recommandation3Signaux = '/recommandation-3-signaux';

  // Utilitaires
  static const String ficheDetail = '/fiche-detail';
  static const String favorites = '/favorites';
  static const String search = '/search';
  static const String conseillers = '/conseillers';
  static const String etablissementsMap = '/etablissements-map';

  // IA Chat
  static const String oria = '/oria';

  // Simulateur
  static const String simulateur = '/simulateur';
  static const String scenariosTypes = '/scenarios-types';

  // Portfolio
  static const String portfolio = '/portfolio';
  static const String portfolioAnalyse = '/portfolio-analyse';

  // DataHub / Heatmap
  static const String datahub = '/datahub';

  // Entretien IA
  static const String entretien = '/entretien';

  // Réseau social
  static const String reseau = '/reseau';

  // Badges
  static const String badges = '/badges';

  // Témoignages
  static const String temoignages = '/temoignages';

  // Evolution / Recommandation (Phase 3)
  static const String evolution = '/evolution';

  // 2FA / TOTP
  static const String totpSetup = '/totp-setup';
  static const String totpVerify = '/totp-verify';

  // États
  static const String notFound = '/404';
  static const String networkError = '/network-error';
}
