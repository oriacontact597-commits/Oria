# 🎨 DESIGN UI/UX ACTUEL — ORIA Mobile (Hackaton AI4GOOD)

> **Objectif** : fournir à ChatGPT un panorama exhaustif du design présent pour identifier les axes d'amélioration écran par écran.
> **Date** : 2026-07-26
> **Stack** : Flutter 3.x + Material 3 (useMaterial3: true)
> **État** : App **fonctionnelle** (backend UP, 136 tests verts), mais travail front de polish/amélioration à prévoir pour le hackaton.

---

## 0. 📚 Présentation du projet

### 0.1 Qu'est-ce qu'ORIA ?

**ORIA** est une application mobile d'**orientation scolaire et professionnelle** destinée aux élèves du Togo (et plus largement de l'Afrique de l'Ouest francophone). Elle aide un collégien, lycéen, bachelier, étudiant ou même un professionnel en reconversion à :

- **Explorer** les séries, filières, formations, universités, métiers qui correspondent à son profil
- **Passer un diagnostic** (quiz d'orientation + analyse de bulletins)
- **Dialoguer avec ORIA**, un assistant IA qui répond aux questions sur l'orientation
- **Recevoir des recommandations proactives** quand sa situation évolue (notes qui baissent, nouvelle compétence, bac qui approche, etc.)
- **Échanger avec un conseiller** d'orientation formé au contexte togolais

### 0.2 Origine

ORIA est un **rebrand mobile** de **Activ EDUCATION**, plateforme plus large développée dans le cadre d'un stage à **HubCity/Woélab** (Lomé, Togo). Le rebrand est fait **uniquement pour la participation au hackaton AI4GOOD** — l'app mobile est présentée sous le nom ORIA, pas Activ.

### 0.3 Contexte hackaton

**Hackaton AI4GOOD** : événement tech au Togo visant à montrer que l'IA peut servir l'intérêt général. ORIA est la contribution "orientation scolaire + IA" du projet.

L'objectif hackaton est de montrer :
1. Une **plateforme d'orientation IA concrète** pour le Togo
2. Un **assistant conversationnel** (ORIA chat) qui répond aux questions sur les universités, séries, métiers
3. Un **moteur proactif** (EventEngine) qui détecte des événements dans le parcours de l'élève
4. Une **base de données riche** : 117 universités togolaises + établissements scolaires, séries, filières

### 0.4 Stack technique

| Couche | Tech | Détail |
|---|---|---|
| **Mobile** | Flutter 3.x + Dart | `setState` (pas de state management), singletons `BaseService` |
| **Backend** | Spring Boot 4.0.5 + Java 21 + Maven | Package by Feature, 30+ packages |
| **DB** | PostgreSQL 16 + pgvector (indispo) | 363 établissements TG, 117 universités en `.md` |
| **Cache** | Redis 7 | Cache SEP (Student Evolution Profile) |
| **IA** | Ollama local (`qwen2:0.5b`) | OpenAI révoqué, Groq fallback |
| **Stockage** | MinIO (3 buckets : images, videos, documents) | Max 500 MB / fichier |
| **CI/CD** | 3 GitHub Actions | backend / backoffice / flutter |
| **Backoffice** | React 19 + TS 6 + Vite + Tailwind v4 | **HORS périmètre hackaton** |

### 0.5 Périmètre STRICT du hackaton

**À MODIFIER** (côté mobile uniquement) :
- `oria-fronted-main/oria_education/` → app Flutter
- `oria-backend-main/src/main/java/.../evolution/` → moteurs IA
- `oria-backend-main/src/main/java/.../referentiel/` → multi-pays
- `oria-backend-main/src/main/java/.../shared/cache/` → Redis
- `oria-backend-main/src/main/java/.../shared/i18n/` → FR/EN/PT
- `oria-backend-main/src/main/resources/db/migration/` → V1, V2, V3, V4
- `oria-fronted-main/schools/` → page web écoles

**NE PAS TOUCHER** :
- `backoffice/` (React admin)
- `profil/`, `diagnostic/`, `accompagnement/`, `bibliotheque/` (sauf P1.1)
- `seed/` (data sources)

### 0.6 Modules backend déjà livrés (avant la phase UI)

| Phase | Module | Description |
|---|---|---|
| 3.3 | EventEngine | 7 événements proactifs (PROGRESSION, REGRESSION, BAC_APPROCHE, INACTIVITE, NOUVELLE_FORCE, NOUVELLE_FAIBLESSE, PALIER_ATTEINT) |
| 3.4 | UI Flutter Banner | Affichage proactif des events |
| 3.5 | Login 500→401 fix | Bug critique corrigé |
| 4.1 | SchoolController | Endpoint bulletins pour les écoles |
| 4.2 | Page web écoles | `/schools/bulletins.html` pour les lycées |
| 4.3 | Référentiel multi-pays | TG, BJ, CI + séries A, C, D, G |
| 4.4 | Bibliothèques + country_code | 363 établissements filtrables par pays |
| 4.5 | i18n FR/EN/PT | Bundles 11 clés |
| 4.6 | Parental consent | Service (backend OK, UI à faire) |
| 6.2 | Cache Redis SEP | `@Cacheable` sur `StudentEvolutionService` |

### 0.7 Personas cibles

| Persona | Type | Usage principal |
|---|---|---|
| **Élève collège** | COLLEGIEN, 12-15 ans | Découvrir les séries du lycée, explorer |
| **Lycéen** | LYCEEN, 15-18 ans | Préparer le bac, choisir série, simuler parcours |
| **Bachelier** | BAC, 18-20 ans | Trouver université / métier, entretien ORIA |
| **Étudiant** | ETUDIANT, 18-25 ans | Réorientation, portfolio, recommandations |
| **Professionnel** | PROFESSIONNEL, 25+ | Reconversion, datahub, badges |
| **Décrocheur** | AUTRE | Reprise d'études, simulateur parcours |
| **Parent** | PARENT | Suivi enfants, conseiller, dashboard dédié |
| **Conseiller** | CONSEILLER | Dashboard pro, RDV, messagerie |

### 0.8 Chiffres clés

- **117** universités togolaises seedées (`.md`)
- **363** établissements (universités + écoles) en DB
- **30+** packages backend Java
- **44** routes Flutter (38 écrans auth + 6 publics)
- **22** dossiers d'écrans Flutter
- **136** tests JUnit verts (1 skipped)
- **16 s** de démarrage backend
- **9 moteurs** d'évolution (academic, activities, behaviour, career, confidence, event, interest, riasec, skills, university)
- **7 événements** proactifs détectés par EventEngine
- **3 langues** supportées (FR/EN/PT) côté backend
- **3 pays** référentiel (TG, BJ, CI) + 4 séries TG (A, C, D, G)
- **8** polices (Inter × 5 poids + Poppins × 5 poids)

### 0.9 Démarrage pour tester

```bash
# Backend (déjà UP en ce moment)
cd /home/grace/hackaton/oria-backend-main
DB_HOST=localhost DB_PORT=5433 DB_NAME=oria_education \
DB_USER=postgres DB_PASSWORD=abalakata \
SPRING_DATASOURCE_URL='jdbc:postgresql://localhost:5433/oria_education?sslmode=disable' \
java -jar target/activEducation-0.0.1-SNAPSHOT.jar > /tmp/oria-backend.log 2>&1 &

# Mobile
cd /home/grace/hackaton/oria-fronted-main/oria_education
flutter pub get
flutter run
# adb reverse tcp:8080 tcp:8080  # Android

# Comptes démo
# admin@activeducation.tg / admin123
# eleve1@oria.com / admin123
# superadmin@oria.com / admin123
```

### 0.10 Phase actuelle et suivantes

**FAIT (côté backend)** :
- ✅ Pipeline complet : login → /eleves → compute → orchestrate → events
- ✅ 136 tests verts
- ✅ Hackaton-ready : ORIA central, EventEngine, multi-pays, i18n, cache

**À FAIRE (priorité actuelle)** :
- 🔴 **Améliorer l'UI Flutter** pour la démo hackaton
- 🟡 Consentement parental (UI Flutter, backend prêt)
- 🟡 Multi-pays : ajouter universités BJ/CI

**Long terme** :
- 🟢 P3.1 Langues locales (Ewe, Kabye, Moore, Wolof, Bambara)
- 🟢 P3.2 Vrai E2E MockMvc + JWT signé
- 🟢 P3.3 Push notifications FCM/APNs
- 🟢 P3.4 Rapport Terminale PDF

---

## 1. 📦 Identité visuelle

### 1.1 Palette de couleurs

Centralisée dans `lib/theme/app_theme.dart` → classe `AppColors`.

| Rôle | Hex | Nom | Usage |
|---|---|---|---|
| **Primary** | `#1300C8` | Bleu-violet profond | App bar, boutons primaires, liens actifs, badges |
| **Primary Dark** | `#0F00A0` | Variant sombre | Dégradé bouton primaire (hover/pressed) |
| **Primary Light** | `#4A3DFF` | Variant clair | CTA secondaires, surbrillance |
| **Accent** | `#FFA800` | Orange vif | Niveau/promotion, callouts, ORIA |
| **Accent Light** | `#FFD166` | Orange clair | États disabled, fonds atténués |
| **Background** | `#FCF8FF` | Blanc cassé mauve | Fond global des écrans |
| **Background Grey** | `#F4F0FA` | Gris-mauve très clair | Cartes, zones secondaires, fond bottom nav |
| **Background Blue** | `#1300C8` | Bleu primaire | Hero, header plein écran |
| **Text Dark** | `#1A1A2E` | Noir bleuté | Titres, valeurs importantes |
| **Text Medium** | `#454556` | Gris foncé | Corps de texte |
| **Text Light** | `#B0B7C3` | Gris clair | Hints, captions, icônes inactives |
| **Text White** | `#FFFFFF` | Blanc | Sur bleu/orange |
| **Success** | `#10B981` | Vert | Validations, badges positifs |
| **Error** | `#EF4444` | Rouge | Erreurs, badges non-lus |
| **Warning** | `#F59E0B` | Ambre | Alertes |
| **Card Border** | `#E5E7EB` | Gris border | Bordures de cartes |
| **Selected Card** | `#1300C8` | Primary | Carte sélectionnée |

### 1.2 Typographie

**Polices chargées** (assets/fonts/) :
- **Inter** (Regular, Medium, SemiBold, Bold, ExtraBold) — corps
- **Poppins** (Regular, Medium, SemiBold, Bold, ExtraBold) — titres

**Échelle typographique** (`AppTextStyles`) :

| Style | Famille | Taille | Poids | Usage |
|---|---|---|---|---|
| `displayLarge` | Poppins | 28 | 800 | Titre principal splash |
| `displayMedium` | Poppins | 24 | 800 | Titres écrans |
| `headingLarge` | Poppins | 20 | 700 | Sous-titres |
| `headingMedium` | Poppins | 17 | 700 | Sections cards |
| `headingSmall` | Poppins | 15 | 700 | Cards titres |
| `bodyLarge` | Inter | 15 | 400 | Paragraphe principal |
| `bodyMedium` | Inter | 14 | 400 | Texte courant |
| `label` | Inter | 13 | 600 | Labels, tags |
| `caption` | Inter | 12 | 400 | Légendes, hints |
| `buttonText` | Inter | 16 | 700 | Boutons |

### 1.3 Composants Material 3 configurés (theme global)

- **ElevatedButton** : fond accent (orange), 54 px de hauteur, `BorderRadius(14)`, sans elevation
- **OutlinedButton** : border primary 1.5 px, 54 px de hauteur, `BorderRadius(14)`
- **InputDecoration** : 12 px radius, sans fill, border grise 1.5 px → primary 2 px focus
- **AppBar** : fond `background`, sans elevation, titre primary 17/w700
- **Scaffold** : fond `background`

### 1.4 Assets

- `assets/images/logo.jpeg` et `logo2.jpeg` : ronds, fond bleu/violet, lettre "O" stylisée (probablement)
- Polices `.ttf` Inter + Poppins variantes

---

## 2. 🧭 Architecture navigation

### 2.1 Splash → Onboarding → Login → Home (MainScaffold)

```
SplashScreen (2.8s anim logo)
  └─ si token valide → MainScaffold
  └─ sinon → OnboardingScreen (3 pages swipe)
                  └─ ProfileSetupScreen (étape 1)
                  └─ RegisterScreen (form 2)
                  └─ RegisterPreferencesScreen (préférences 3)
                  └─ LoginScreen
```

### 2.2 MainScaffold — Bottom navigation

`lib/screens/main_scaffold.dart` — gère 5 onglets (rôle élève) ou 4 (rôle parent) :

**Défaut (élève/conseiller) :**
- [0] **Accueil** (home_rounded)
- [1] **Explorer** (explore_rounded)
- [2] **Diagnostic** (quiz_rounded)
- [3] **Messages** (chat_bubble_rounded)
- [4] **Profil** (person_rounded)

**Parent (4 onglets) :**
- [0] Accueil
- [1] Explorer
- [2] Messages
- [3] Profil

**FAB flottant** : petit bouton rond `Color(0xFF3133DD)` avec icône `auto_awesome` → ouvre l'écran **ORIA chat** (superposé à la nav).

**Différenciation de dashboard** : `MainScaffold._buildDashboard()` sélectionne :
- `DashboardConseiller` si `role == CONSEILLER`
- `DashboardParent` si `role == PARENT`
- `DashboardReconversion` si `typeApprenant == PROFESSIONNEL`
- `DashboardDecrocheur` si `typeApprenant == AUTRE`
- `DashboardBachelier` par défaut (élève/collégien/lycéen)

### 2.3 Bottom nav (BottomNav widget)

`lib/widgets/bottom_nav.dart` — barre blanche, ombre portée subtile vers le haut :
- Items en `Expanded` avec `GestureDetector` (PAS de `BottomNavigationBar` Material)
- Item actif : fond `primary @ 10%`, icône filled, couleur primary, label w700
- Item inactif : icône outlined, `textLight`, label w400
- Animation 200 ms

---

## 3. 📱 Pages clés (écran par écran)

### 3.1 Splash (`splash_screen.dart` — 232 lignes)

**Layout** : `Stack` plein écran, fond blanc, centré.
- **Logo** : image `assets/images/logo2.jpeg` 110×110, `ClipOval`, `FadeTransition` + `ScaleTransition` (elasticOut)
- **Titre "ORIA"** : `displayLarge` 30 px, primary, w800
- **Sous-titre** : "Trouve ta voie, construis ton avenir" — primary 75% opacity, 15 px
- **Barre de progression** : 3 px de haut, primary, arrondi 4 px, en bas
- **Status text** : "INITIALISATION" → "CHARGEMENT DES DONNÉES" → "PRESQUE PRÊT..." (changement selon progression anim)
- **Footer** : "Lomé, Togo" petit, primary 35% opacity

**Animations** : 2.8 s total. Vérifie JWT valide en parallèle.

### 3.2 Onboarding (`onboarding_screen.dart` — 571 lignes)

**Layout** : `PageView` swipe 3 pages. Bottom fixe : `DotIndicator` (3 dots) + bouton Primary "Suivant" / "Commencer" + lien "Passer" / "J'ai déjà un compte Se connecter".

**Page 1 — "Découvre ta voie"** : `CustomPainter` dessin vectoriel à main levée : 3 branches divergentes depuis un point central (bleu + orange), 3 cercles terminaux (1 orange central, 2 bleus latéraux). Titre `displayMedium`, sous-texte "Explore les séries, filières et métiers qui te correspondent vraiment".

**Page 2 — "Un diagnostic fait pour toi"** : mockup téléphone vectorisé en `Stack` (170×200 px gris arrondi contenant 3 options mockup), avec 3 badges flottants (étoile jaune, analytics bleu, école blanc). Sous-texte "Quiz d'orientation intelligent + analyse de tes notes. Des recommandations réelles basées sur le système togolais."

**Page 3 — "Un conseiller près de toi"** : illustration vectorielle personne (avatar circulaire orange + silhouette bleue), 3 bulles flottantes (chat bleu, caméra orange, téléphone blanc). Sous-texte "Pose tes questions, prends rendez-vous. Des conseillers formés au contexte togolais répondent sous 48h."

### 3.3 Login (`login_screen.dart` — 213 lignes)

**Layout** : `Scaffold` background `AppColors.background`, `SingleChildScrollView`, padding 24 px.

**Ordre vertical** :
- Logo rond 56×56 (`logo2.jpeg`) centré
- Titre "Bon retour !" `displayMedium`
- Sous-titre "Connecte-toi avec ton email" `bodyLarge`
- Champ email (`Icons.email_outlined`, hint "ex: prenom@email.com")
- Champ password (`Icons.lock_outlined`, `obscurePassword` toggle, hint "Mot de passe")
- Lien aligné droite "Mot de passe oublié ?"
- **PrimaryButton** orange "Se connecter" (54 px)
- Texte "Pas encore de compte ?"
- OutlinedButton primary "Créer mon compte" (54 px)

**États** : loading spinner sur le bouton, snackbar erreur en cas d'échec.

### 3.4 Register (`register_screen.dart` — 384 lignes)

**Layout** : Similaire login mais avec sélecteur de pays en haut (liste locale 5+ pays avec drapeau emoji + code dial + nom), champs étendus, bouton "Continuer".

### 3.5 Profile Setup (`profile_setup_screen.dart` — 345 lignes)

**Layout** : Form multi-étapes "On te connaît" : champs nom, prénom, niveau (chips), centres d'intérêt, photo optionnelle.

### 3.6 Dashboard Bachelier (`dashboard_bachelier.dart` — 724 lignes) ⭐ **PAGE D'ACCUEIL**

C'est la **page d'accueil par défaut** (rôle élève) et la **page prioritaire du hackaton**.

**Layout** : `Scaffold` background `BackgroundGrey`, `SafeArea`, `RefreshIndicator`, `SingleChildScrollView` padding 20 px.

**Ordre vertical (de haut en bas)** :

#### A. Header (ligne)
- **Gauche** : "Bonjour {prenom} !" Inter 22 w800 + badge pill `Accent` (orange) avec `niveauEtude` (ex: "LYCEE_2ND") 10 px blanc
- **Sous-titre** : `TextMedium` 14 w500 — "LYCEEN — LYCEE_2ND — série D"
- **Droite** : icône search (carré 38×38 blanc ombré) + avatar circulaire 48×48 avec border primary 2 px (initiale ou photo Network)

#### B. ⭐ **ORIA Callout — pièce maîtresse du hackaton**
Grande carte 22 px padding, gradient diagonal `#3133DD` → `#6A3DE8`, `BorderRadius(24)`, ombre bleue 30% alpha 20 px blur.

Contenu :
- **Ligne 1** : Avatar rond 44×44 blanc 18% "O" gras 22 px + Titre "ORIA" blanc 20 w900 + sous-titre "Ton assistant d'orientation IA" blanc 70% 13 px + icône `auto_awesome` blanc
- **Ligne 2** : phrase blanche 14 px : "Filières, universités, métiers… pose ta question, je te réponds avec des infos concrètes du Togo 🇹🇬"
- **Ligne 3** : Input factice arrondi 14 px (fond blanc 15% + border blanc 35%) avec icône chat blanc 70% + texte "Discuter avec ORIA…" + bouton carré blanc 44 px avec flèche bleu primary

**Tap global** → `Navigator.pushNamed(oria)`.

#### C. OriaProactiveBanner (component autonome)
Bannière conditionnelle si événements `EventEngine` détectés (ex: INACTIVITE, PROGRESSION). 1-2 lignes dans carte gradient léger.

#### D. Carte "Ma recommandation" (si IA dispo)
Gradient `primary` → `primaryDark`, `BorderRadius(16)`, padding 20 px.
- Row : icône `auto_awesome` + "Ma recommandation" label 16 w700
- Texte blanc 70% sur 3 lignes (extrait 120 char)
- Lien "Voir la recommandation complète →"
- Pill secondaire "Tester la v2 (3 signaux)" avec icône `auto_graph`

#### E. CTA Explorer
Carte gradient orange accent (15% → 5%), border accent 20% 1.5 px, `BorderRadius(20)`.
- "Explorer les filières" 16 w700
- "Découvre toutes les formations disponibles" caption
- Bouton carré orange 44 px à droite (sans icône visible dans le code, placeholder)

#### F. Carte "Besoin d'aide ?"
Carte blanche 20 px padding, `BorderRadius(20)`, border `cardBorder`.
- Titre "Besoin d'aide ?" 18 w700
- Sous-texte "Consultez notre foire aux questions ou contactez l'assistance."
- Row 2 actions : `_HelpAction` icône + label (FAQ, Support), fond `BackgroundGrey`, `BorderRadius(12)`.

### 3.7 ORIA Chat (`oria_screen.dart` — 473 lignes) ⭐ **ÉCRAN PHARE**

**Layout** : `Scaffold`, `SafeArea`, `Column`.

**Header** : Row — bouton retour, avatar O, titre "ORIA", sous-titre "Assistant d'orientation IA", menu ⋮ (clear session, toggle auto-speak).

**Body** : `ListView` messages. Bulles :
- **Assistant** : fond `BackgroundGrey` ou gradient bleu, arrondi 16 px, padding 14 px, max 85% largeur
- **User** : fond primary, texte blanc, aligné droite, arrondi 16 px (coins différents asymétriques)

**Footer** : Row — bouton micro (toggle `_isRecording`), TextField arrondi, bouton send (icône avion primary).

**États** : typing indicator (3 dots animés), session ID persisté en secure storage, voice input via `VoiceService`.

### 3.8 Explorer (`explorer_screen.dart` — 790 lignes)

**Layout** : Tabs horizontales (Filière, Métier, Établissement, Série), champ recherche, grille de cartes.

### 3.9 Quiz Diagnostic (`quiz_screen.dart` — 932 lignes)

**Layout** : Header progression (barre 0-100%), question centrale `displayMedium`, 4 options en cartes (sélectionnable → primary border), bouton "Suivant".

### 3.10 Messages (`messages_list_screen.dart` — 762 lignes)

**Layout** : ListView de conversations. Item = avatar + nom + dernier message + timestamp + badge non-lus rouge.

### 3.11 Profile (`profile_screen.dart` — 1367 lignes)

**Layout** : Header gradient bleu avec avatar + nom + email, sections ListTiles (Mes infos, Sécurité, Confidentialité, Langue, Déconnexion).

---

## 4. 🧩 Composants transverses

### 4.1 `widgets/common_widgets.dart`
- `PrimaryButton` : bouton orange 54 px, accepte `isLoading` (spinner)
- `DotIndicator` : pagination dots
- `OriaBadge` (mention)

### 4.2 `widgets/oria_proactive_banner.dart`
Carte affichant les events `EventEngine` (1-2 events), animation slide-in.

### 4.3 `widgets/skeleton_widget.dart`
Shimmer pendant chargement (`SkeletonDashboard`).

### 4.4 `widgets/recommendations_section.dart`
Carrousel horizontal de fiches.

### 4.5 `widgets/bottom_nav.dart`
Barre bottom custom (déjà décrite §2.3).

---

## 5. 🎯 Spécificités hackaton AI4GOOD

### 5.1 Périmètre strict
- **Modifié** : `lib/screens/home/dashboard_bachelier.dart` (ORIA callout central), `lib/screens/chat/oria_screen.dart` (chat ORIA), `lib/widgets/oria_proactive_banner.dart` (nouveau)
- **Non touché** : backoffice React, profil/, diagnostic/, accompagnement/, bibliotheque/

### 5.2 Fonctionnalités visibles
- **ORIA Callout** gradient bleu/violet → écran chat ORIA
- **FAB flottant** (small, primary) → écran chat ORIA
- **EventEngine banner** (proactif) → sur dashboard
- **Pas de saisie manuelle notes / OCR** côté mobile (volontairement)

### 5.3 Branded "ORIA"
- Logo "O" bleu-violet
- Nom "ORIA" en grandes lettres
- Sous-titre "Ton assistant d'orientation IA"
- Référence "Lomé, Togo" sur splash

---

## 6. 📊 État technique & dette

### 6.1 Forces
- Architecture Thema AppColors / AppTextStyles centralisée : **facile de rebrand**
- Composants réutilisables (`PrimaryButton`, `DotIndicator`)
- Backend **stable** (136 tests, 16 s démarrage)
- 30+ écrans fonctionnels
- Multi-langue préparé (i18n FR/EN/PT côté backend, pas encore câblé Flutter)

### 6.2 Faiblesses observées
- **Dashboard bachelier 724 lignes** : mélange fetch + rendu, à refactoriser
- **CTA Explorer** : bouton orange sans icône visible (placeholder)
- **Pas de page d'accueil dédiée ORIA** : ORIA est "inséré" dans le dashboard existant plutôt qu'une page d'entrée propre
- **Bouton retour/sauvegarde** : pas toujours visible dans les flows secondaires
- **Hiérarchie visuelle** : plusieurs cartes pleines largeurs, parfois trop denses
- **Onboarding** : `CustomPainter` fait main — beau mais peu de polish
- **Aucune animation de transition** entre écrans (juste le push Material)
- **Pas de mode sombre**
- **Pas de skeleton** sur la majorité des pages (seulement dashboard)
- **Logo** : image JPEG 56×56 / 110×110, pas de variantes hires

### 6.3 À valider avec ChatGPT
1. **Page d'accueil** : ORIA est "au milieu" du dashboard. Veux-tu une vraie page d'accueil ORIA-first ?
2. **Hiérarchie** : trop de cards empilées ? Besoin de sectionning ?
3. **Couleur primaire** : `#1300C8` violet-bleu — OK pour hackaton ou alternative ?
4. **Callout ORIA** : copy ("pose ta question, je te réponds avec des infos concrètes du Togo 🇹🇬") — pertinent ?
5. **FAB** : petit bouton rond bleu, slight hors-spec Material — acceptable ?
6. **Bottom nav** : 5 onglets, dense — réduire à 4 ?
7. **Illustrations onboarding** : flat 2D codées en `CustomPainter` — remplacer par Lottie / images plus "modernes" ?

---

## 7. 🗺️ Toutes les routes

`lib/theme/app_routes.dart` — table de routage centralisée dans `main.dart`.

| Route | Écran | Public |
|---|---|---|
| `/splash` | SplashScreen | ✓ |
| `/onboarding` | OnboardingScreen | ✓ |
| `/profileSetup` | ProfileSetupScreen | ✓ |
| `/register` | RegisterScreen | ✓ |
| `/registerPreferences` | RegisterPreferencesScreen | ✓ |
| `/login` | LoginScreen | ✓ |
| `/forgotPassword` | ForgotPasswordScreen | ✓ |
| `/otp` | OtpScreen | ✓ |
| `/resetPassword` | ResetPasswordScreen | ✓ |
| `/totpSetup` | TotpSetupScreen | auth |
| `/totpVerify` | TotpVerifyScreen | ✓ |
| `/home` | MainScaffold | auth |
| `/dashboard` | MainScaffold | auth |
| `/quiz` | QuizScreen | auth |
| `/resultats` | ResultatsScreen | auth |
| `/explorer` | ExplorerScreen | auth |
| `/messages` | MessagesListScreen | auth |
| `/chat` | ChatScreen | auth |
| `/rdv` | RdvScreen | auth |
| `/notifications` | NotificationsScreen | auth |
| `/favorites` | FavoritesScreen | auth |
| `/ficheDetail` | FicheDetailScreen | auth |
| `/search` | GlobalSearchScreen | auth |
| `/support` | SupportScreen | auth |
| `/faq` | FaqScreen | auth |
| `/conseillers` | ConseillersScreen | auth |
| `/enfantSuivi` | EnfantSuiviScreen | auth |
| `/rdvList` | RdvListScreen | auth |
| `/profile` | ProfileScreen | auth |
| `/etablissementsMap` | EtablissementsMapScreen | auth |
| `/recommandationIA` | RecommandationIAScreen | auth |
| `/selectionNiveau` | SelectionNiveauScreen | auth |
| `/bulletinsHistorique` | BulletinsHistoriqueScreen | auth |
| `/recommandation3Signaux` | Recommandation3SignauxScreen | auth |
| `/oria` | OriaScreen | auth |
| `/simulateur` | SimulateurParcoursScreen | auth |
| `/scenariosTypes` | ScenariosTypesScreen | auth |
| `/portfolio` | PortfolioScreen | auth |
| `/datahub` | DataHubScreen | auth |
| `/entretien` | EntretienScreen | auth |
| `/reseau` | ReseauScreen | auth |
| `/badges` | BadgeScreen | auth |
| `/temoignages` | TemoignageScreen | auth |
| `/evolution` | OrchestrationResultScreen | auth |
| `/notFound` | NotFoundScreen | ✓ |
| `/networkError` | NetworkErrorScreen | ✓ |

**44 routes**, 38 écrans authentifiés.

---

## 8. 📁 Structure fichiers

```
lib/
├── main.dart              (~225 lignes, table de routes)
├── theme/
│   ├── app_theme.dart     (palette + typo + Material 3 theme)
│   └── app_routes.dart    (constantes de routes + routeObserver)
├── models/                (DTOs Dart)
├── services/
│   ├── api_service.dart   (Dio + interceptors)
│   ├── base_service.dart  (refresh token lock)
│   ├── voice_service.dart (micro + TTS)
│   └── evolution_service.dart
├── utils/image_utils.dart
├── widgets/
│   ├── bottom_nav.dart
│   ├── common_widgets.dart (PrimaryButton, DotIndicator)
│   ├── oria_proactive_banner.dart
│   ├── recommendations_section.dart
│   └── skeleton_widget.dart
└── screens/
    ├── splash/
    ├── onboarding/
    ├── auth/                  (login, register, totp, otp, reset)
    ├── home/                  (dashboard_bachelier, dashboard_conseiller, etc.)
    ├── explorer/
    ├── search/
    ├── diagnostic/
    ├── chat/                  (ORIA screen)
    ├── messages/
    ├── conseillers/
    ├── profil/                (sic - profil pas profile)
    ├── orientation/
    ├── simulateur/
    ├── evolution/
    ├── reseau/
    ├── badge/
    ├── temoignage/
    ├── portfolio/
    ├── datahub/
    ├── entretien/
    ├── historique/
    └── errors/
```

**22 dossiers d'écrans**, 44 routes, 1367 lignes pour la plus grosse page (profile).

---

## 9. 🔧 Axes d'amélioration suggérés (à valider avec ChatGPT)

### 9.1 UX/Navigation
- Page d'accueil ORIA-first (au lieu de l'insérer dans le dashboard existant)
- Réduire bottom nav à 4 onglets (Accueil, Explorer, ORIA, Profil) — fusionner Messages dans ORIA ou dans Profil
- Ajouter bouton retour partout
- Bottom sheet au lieu de push fullscreen pour les détails

### 9.2 Visuel
- Refactor `DashboardBachelier` (724 lignes) en widgets
- Skeleton sur toutes les pages
- Animations de transition (hero, fade)
- Mode sombre
- Logo en SVG/PNG transparent multi-tailles

### 9.3 Contenu
- Vraie page dédiée ORIA (comme ChatGPT landing)
- Empty states illustrés
- Tooltips sur les features
- Onboarding animé (Lottie) ou vidéo

### 9.4 Hiérarchie
- Sections claires (mes infos / mes actions / mes outils)
- Section header sticky
- Cards full-width → grille 2 colonnes

### 9.5 Accessibilité
- Contraste WCAG (textLight sur blanc : vérifier)
- Touch targets ≥ 44 px
- Sémantique ARIA Flutter

---

## 10. 📸 Captures

**Note** : ce fichier décrit l'UI mais n'inclut pas de captures. Pour générer des captures, utiliser `flutter run` côté émulateur/device + screenshot. Backend ORIA est UP (port 8080) donc :

```bash
cd /home/grace/hackaton/oria-fronted-main/oria_education
flutter pub get
flutter run  # pour iOS/Android
# Capturer Splash → Login → Dashboard → ORIA
```

Login démo : `admin@activeducation.tg` / `admin123`
ou `eleve1@oria.com` / `admin123`

---

*Fin de la description. À fournir à ChatGPT pour identifier les axes d'amélioration prioritaires pour le hackaton AI4GOOD.*
