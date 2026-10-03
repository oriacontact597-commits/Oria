# Brief Design Premium ORIA — Style ChatGPT

> **Destinataires** : toi (donner ce fichier à ChatGPT) + moi (implémentation Flutter).
> **Périmètre** : ORIA mobile (Flutter) — uniquement les écrans les plus visibles.
> **Direction visuelle** : épurée, centrée, focus sur l'IA ORIA (style ChatGPT mobile).

---

## Section 0 — Pitch projet (à donner à ChatGPT pour contexte)

ORIA est une **plateforme d'orientation scolaire et professionnelle au Togo** (hackers à impact AI4GOOD). L'assistant central s'appelle **ORIA** (ex-Activ) : il aide un lycéen/bachelier/étudiant à choisir sa filière, école, métier.

**Cible utilisateur** : 16-25 ans, smartphone Android bas de gamme, connexion 3G, usage de jour (parfois nuit).

**Mission hackaton** : refaire l'UI mobile pour qu'elle soit au niveau **ChatGPT mobile / Notion / Headway**. Pas une refonte totale (59 écrans) — on cible 4 écrans clés + un design system partagé.

**Stack existante** : Flutter + Dart, `setState` (pas de state management), Dio (HTTP), `flutter_secure_storage` (token JWT), backend Spring Boot qui expose l'API sous `/api/v1/...`.

**Contraintes** :
- Pas de framework de state management (utiliser `setState` + `ValueNotifier` si besoin).
- Performance smartphone bas de gamme : limiter les rebuilds, animations < 200ms.
- Dark mode **désactivé** pour le MVP (luminosité plein écran, le Togo est ensoleillé).
- Budget illustrations : on reste sur des `CustomPainter` et `Icons` Material — pas d'assets externes.

---

## Section 1 — Design tokens (à modifier dans `lib/theme/app_theme.dart`)

### 1.1 Couleurs — déjà OK, mais ajouter nuances

| Token existant | Hex | Cible ChatGPT-like |
|---|---|---|
| `primary` | `#1300C8` | Conserver (logo ORIA) — c'est l'identité |
| `primaryDark` | `#0F00A0` | OK |
| `primaryLight` | `#4A3DFF` | OK |
| `accent` | `#FFA800` | OK |
| `accentLight` | `#FFD166` | OK |
| `background` | `#FCF8FF` | Trop chaud. **Cible** : `#FFFFFF` (ChatGPT) ou `#F9F9F9` (Notion). |
| `backgroundGrey` | `#F4F0FA` | Trop saturé. **Cible** : `#F4F4F5` (gris neutre). |
| `textDark` | `#1A1A2E` | OK |
| `textMedium` | `#454556` | OK |
| `textLight` | `#B0B7C3` | OK |

**Ajouts à introduire dans `AppColors`** :
```dart
// Neutres supplémentaires (style ChatGPT)
static const Color surfaceSubtle = Color(0xFFF7F7F8);   // Fond de carte alternative
static const Color borderSubtle = Color(0xFFEDEDEF);     // Bordure carte fine
static const Color overlay = Color(0x33000000);          // Voile modal
static const Color gradientStart = Color(0xFF3133DD);    // ChatGPT-like deep blue
static const Color gradientEnd = Color(0xFF6A3DE8);      // ChatGPT-like purple
static const Color messageBubbleUser = Color(0xFF3133DD); // Bulle user (chat)
static const Color messageBubbleAI = Color(0xFFF7F7F8);    // Bulle ORIA (chat)
```

### 1.2 Typographie — OK, mais affiner line-heights

| Style | Actuel | Cible ChatGPT |
|---|---|---|
| `displayLarge` | 28/w800, h:1.2 | OK |
| `displayMedium` | 24/w800, h:1.3 | OK |
| `headingLarge` | 20/w700 | OK |
| `bodyLarge` | 15/w400, h:1.5 | Ajouter `letterSpacing: -0.1` |
| `bodyMedium` | 14/w400 | Ajouter `height: 1.4` |
| `caption` | 12/w400, l:0.5 | OK |

**Garder** : Poppins (titres) + Inter (corps) — déjà chargé.

### 1.3 Spacing scale (nouveau, ajouter à `app_theme.dart`)

```dart
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double radius = 16;          // Border radius standard (cartes)
  static const double radiusLg = 24;        // Border radius grandes bulles (chat)
  static const double inputHeight = 54;     // Hauteur input (ChatGPT-like)
  static const double fabSize = 56;         // FAB ORIA
}
```

### 1.4 Shadows (nouveau, ajouter)

```dart
class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0D000000),  // 5% black
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x1A000000),  // 10% black
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
}
```

---

## Section 2 — Écran #1 : Accueil ORIA-first (PRIORITAIRE)

### 2.1 État actuel
**Fichier** : `lib/screens/home/dashboard_bachelier.dart` (724 lignes) + 4 autres dashboards (`conseiller`, `parent`, `decrocheur`, `reconversion`).
**Système** : `main_scaffold.dart` avec `IndexedStack` de 5 onglets (Accueil / Explorer / Diagnostic / Messages / Profil) + FAB ORIA (callout gradient bleu/violet, icon `auto_awesome`).
**Constat** : ORIA est un **FAB secondaire** dans le coin. Pas la star de l'écran. C'est exactement l'inverse de ce qu'on veut.

### 2.2 Cible UX ChatGPT-like

**Concept** : ORIA devient **la page d'accueil elle-même** (comme ChatGPT fait de la conversation la home). L'utilisateur arrive → il **parle à ORIA** → il explore les fiches en second rideau.

**Layout cible** (du haut vers le bas) :
1. **Header ultra-fin** (32px) : avatar rond 36px à gauche + bouton paramètres à droite. Pas de titre "Bonjour".
2. **Titre centré** : "Bonjour, [Prénom]" en `displayLarge` centré, fade-in 200ms.
3. **Callout gradient** (PRIORITÉ) : un grand bloc arrondi `radiusLg` (24px), `padding: 24`, gradient linéaire `gradientStart → gradientEnd`, hauteur ~140px. Au centre : icône `auto_awesome` (32px, blanc) + texte "**Demande à ORIA**" (Inter w600, blanc) + sous-titre "Orientation, métiers, écoles" (Inter w400, blanc 80%).
   - Tap → push direct sur `oria_screen.dart`.
   - Animation : `Hero` tag `oria-callout` pour transition fluide.
4. **Suggestions** (ChatGPT-like) : 3 chips horizontales scrollables ("Je suis en classe de Terminale", "Je veux devenir ingénieur", "Comparer 2 filières"). Tap → pré-remplir le champ texte ORIA.
5. **Cartes raccourcies** (sous le callout) : 2 grandes cartes 16:9 côte à côte :
   - "📚 Bibliothèque" → push `explorer_screen.dart`.
   - "🧠 Diagnostic" → push `quiz_screen.dart`.
6. Pas de bottom nav 5 onglets : **bottom nav simplifiée** = 3 items (Accueil / Bibliothèque / Profil). Le reste est dans "Plus".

### 2.3 Fichiers à modifier
- **Créer** : `lib/screens/home/home_oria.dart` (nouvelle home, ~200 lignes).
- **Modifier** : `lib/screens/main_scaffold.dart` — passer à 3 onglets, simple bottom nav.
- **Créer** : `lib/widgets/oria_callout.dart` (composant callout gradient réutilisable).
- **Créer** : `lib/widgets/suggestion_chips.dart` (chips horizontales).
- **Garder** : les 4 autres dashboards mais les rendre **secondaires** (page Profil → bouton "Changer de tableau de bord").

### 2.4 Actions concrètes à donner à ChatGPT
```
Génère le code Flutter complet de `ORIAHomeScreen` avec :
- AppBar minimaliste (avatar + paramètres)
- "Bonjour, [nom]" centré grand
- Callout gradient bleu/violet, hero animation vers ORIA screen
- 3 chips de suggestions cliquables (pré-remplissent l'input ORIA)
- 2 cartes raccourcies (Bibliothèque, Diagnostic)
- Bottom nav 3 items (Accueil / Bibliothèque / Profil)
Respecte les design tokens existants dans `lib/theme/app_theme.dart`.
Utilise setState (pas de Provider/Riverpod/BLoC).
```

---

## Section 3 — Écran #2 : Bibliothèque établissements (catalogue)

### 3.1 État actuel
**Fichier** : `lib/screens/explorer/explorer_screen.dart` (790 lignes) — top tabs (Établissements/Filières/Métiers/Séries/Favoris), grille de cartes, filtres sheet.
**Constat** : dense, animations absentes, cartes plates.

### 3.2 Cible UX ChatGPT-like

**Concept** : page de recherche propre, comme un Notion : barre de recherche en haut sticky, filtre chips horizontales scrollables, grille Masonry de cartes, chaque carte = 1 fiche + tap → bottom sheet de preview (puis push detail).

**Layout cible** :
1. **Sticky header** (60px) : search bar pill (radius 24, icône loupe à gauche, micro à droite).
2. **Chips filtres** : "Tous", "Togo", "Bénin", "Côte d'Ivoire" + "Privé", "Public" + "Université", "Lycée". Chips selected = fond `primary`, texte blanc.
3. **Compteur résultat** : "363 établissements en Togo" (caption, gris).
4. **Grille 2 colonnes** : cartes `radius 16`, ombre légère, 1 photo (16:9) en haut + nom (headingSmall) + ville + type (badge).
5. **Skeleton** : 6 cartes shimmering au chargement (`SkeletonWidget` existe déjà).
6. **Empty state** : illustration CustomPainter + "Aucun établissement ne correspond".

### 3.3 Fichiers à modifier
- **Refactor** : `explorer_screen.dart` (split en widgets).
- **Créer** : `lib/widgets/catalog/etablissement_card.dart`.
- **Créer** : `lib/widgets/catalog/filter_chips.dart`.
- **Créer** : `lib/widgets/catalog/preview_bottom_sheet.dart` (ChatGPT-style sheet : drag handle + image + titre + extrait + bouton "Voir la fiche").
- **Garder** : `lib/widgets/skeleton_widget.dart` (déjà OK).

### 3.4 Actions concrètes à donner à ChatGPT
```
Refactore `explorer_screen.dart` en composants réutilisables :
- Sticky search bar (pill radius 24)
- Chips horizontales filtres (selected = fond primary)
- Grille 2 colonnes de cartes établissement
- Bottom sheet preview (drag handle, image, titre, extrait)
- Empty state avec CustomPainter
- Skeleton au chargement (6 cartes)
Garde `setState` + le service `BibliothequeService` existant.
```

---

## Section 4 — Écran #3 : ORIA Chat (assistant IA)

### 4.1 État actuel
**Fichier** : `lib/screens/chat/oria_screen.dart` (473 lignes).
**Constat** : UI basique. Bulles plates, pas de thinking loader, pas de suggestions contextuelles.

### 4.2 Cible UX ChatGPT-like

**Concept** : reproduire la fluidité ChatGPT — message en bas fixe, bubbles alternées, animations de typing, suggestions "follow-up" après chaque réponse.

**Layout cible** :
1. **AppBar transparent** : bouton retour + menu (3 points).
2. **Empty state** (première visite) :
   - Logo ORIA centré (CustomPainter : étoile 4 branches dégradé).
   - Titre : "Comment puis-je t'aider ?" (displayLarge, centré).
   - 4 cartes suggestions 2×2 :
     - "Comparer 2 filières" (📊)
     - "Trouver une école à Lomé" (📍)
     - "Comprendre mon profil RIASEC" (🧠)
     - "Préparer un entretien" (💼)
3. **Bulles messages** :
   - User : fond `messageBubbleUser` (#3133DD), texte blanc, radius 24, **bottomRight 6**.
   - ORIA : fond `messageBubbleAI` (#F7F7F8), texte sombre, radius 24, **bottomLeft 6**.
   - Avatar ORIA à gauche (24px rond) pour chaque bulle ORIA.
4. **Loader ORIA** : 3 points animés (fade in/out décalés 200ms).
5. **Barre de saisie collée bottom** :
   - Pill radius 24, fond `surfaceSubtle`.
   - Bouton micro à gauche, champ texte au centre, bouton envoi à droite (icône ➤ bleu quand texte saisi).
   - SafeArea padding bottom.
6. **Suggestions follow-up** après réponse IA : 2-3 chips arrondies sous la bulle, "Voir plus", "Préciser".

### 4.3 Fichiers à modifier
- **Refactor** : `oria_screen.dart` (split).
- **Créer** : `lib/widgets/chat/message_bubble.dart`.
- **Créer** : `lib/widgets/chat/typing_indicator.dart` (3 points animés).
- **Créer** : `lib/widgets/chat/input_bar.dart`.
- **Créer** : `lib/widgets/chat/suggestion_grid.dart`.
- **Créer** : `lib/widgets/oria_logo_painter.dart` (CustomPainter pour logo).

### 4.4 Actions concrètes à ChatGPT
```
Refactore `oria_screen.dart` style ChatGPT mobile :
- Empty state central (logo + 4 cartes suggestions)
- Bulles user (bleu, align right) vs ORIA (gris, align left avec avatar)
- Loader 3 points animés
- Barre saisie pill collée bottom (micro + texte + envoi)
- Suggestions follow-up après réponse IA
Utilise `OriaService` existant pour les appels IA (timeout Dio 120s déjà géré).
```

---

## Section 5 — Écran #4 : Profil utilisateur

### 5.1 État actuel
**Fichier** : `lib/screens/profile/profile_screen.dart` (~300 lignes).
**Constat** : liste de settings, dense, sans hiérarchie visuelle.

### 5.2 Cible UX ChatGPT-like (Notion-inspired)

**Concept** : page profil = carte d'identité + sections groupées style iOS Settings.

**Layout cible** :
1. **Carte identité** en haut : photo ronde 88px centrée + nom (displayMedium) + email (bodyMedium) + badge rôle ("Élève 🎓" pill primary).
2. **Stats rapides** : 3 cards en ligne (Favoris, Recommandations, RDV à venir) — chiffres gros + label.
3. **Sections groupées** (cartes arrondies radius 16, séparées par 8px) :
   - **Mon parcours** : niveau, série, notes moyennes (avec icônes colorées).
   - **Préférences** : pays, langue, notifications (Switch Material).
   - **Sécurité** : changer mot de passe, 2FA, déconnexion (rouge).
   - **À propos** : CGU, confidentialité, version (1.2.0).
4. **Bouton "Changer de tableau de bord"** en bas (visible si `role === 'admin' || 'conseiller'`).

### 5.3 Fichiers à modifier
- **Modifier** : `profile_screen.dart` (refactor visuel seulement).
- **Créer** : `lib/widgets/profile/identity_card.dart`.
- **Créer** : `lib/widgets/profile/stats_row.dart`.
- **Créer** : `lib/widgets/profile/settings_section.dart` + `settings_tile.dart`.

### 5.4 Actions concrètes à ChatGPT
```
Refactore `profile_screen.dart` style iOS Settings :
- Carte identité (photo, nom, email, badge rôle)
- 3 stats rapides (Favoris / Reco / RDV)
- Sections groupées (Mon parcours / Préférences / Sécurité / À propos)
- Tuile de paramètres avec icône + label + chevron + Switch Material si bool
Garde `AuthService.logout()` pour la déconnexion.
```

---

## Section 6 — Composants partagés à créer (Design System)

À ajouter dans `lib/widgets/` (nouveaux fichiers) :

| Fichier | Rôle | Inspiré de |
|---|---|---|
| `app_search_bar.dart` | Search bar pill, sticky | Notion search |
| `app_filter_chip.dart` | Chip sélectionnable | Material You |
| `app_card.dart` | Carte générique radius 16 + shadow | iOS card |
| `app_sheet.dart` | Bottom sheet avec drag handle | iOS sheet |
| `app_empty_state.dart` | Empty state (icon CustomPainter + texte + CTA) | Linear |
| `app_skeleton.dart` | Skeleton shimmering (déjà existe, à améliorer) | LinkedIn |
| `app_section_header.dart` | Titre section avec action droite | Notion |
| `app_pill.dart` | Pastille status (success/warning/error) | ChatGPT badge |

**Convention de nommage** : préfixe `app_` pour les composants génériques, pas de préfixe pour les composants spécifiques à un écran.

---

## Section 7 — Animations (à introduire progressivement)

| Animation | Trigger | Durée | Inspiré de |
|---|---|---|---|
| `Hero(oria-callout)` | Tap callout accueil | 300ms | Material |
| Fade-in titre | Push d'écran | 200ms | iOS |
| Bulles chat apparition | Scroll/typing | 150ms | ChatGPT |
| Skeleton → contenu | Données chargées | 250ms | LinkedIn |
| Drag sheet | Pull bottom sheet | 250ms | iOS |
| Bounce CTA | Tap bouton primaire | 100ms scale 1.05 | Headway |

**Impl** : `AnimatedContainer`, `AnimatedOpacity`, `Hero`, `TweenAnimationBuilder`. Pas de librerie externe (Rive = trop gros).

---

## Section 8 — Hors périmètre (à NE PAS toucher)

- ❌ Backend (aucune modif Spring Boot).
- ❌ Backoffice React (hors hackaton).
- ❌ Seed data.
- ❌ Pages : Login, Register, OTP, Reset password — laissons les simples pour le MVP.
- ❌ Pages : Diagnostic, Quiz, Bulletins, RDV, Messages, Simulateur — UI existante conservée.
- ❌ Dark mode.

**On refait juste 4 écrans + 8 widgets partagés**. Tout le reste reste en place.

---

## Section 9 — Séquence d'implémentation

1. **Désigner d'abord** : donner ce brief à ChatGPT, demander les 8 widgets partagés (`Section 6`) en premier — c'est la fondation.
2. **Itérer écran par écran** : Home (Section 2) → Bibliothèque (Section 3) → ORIA Chat (Section 4) → Profil (Section 5).
3. **Tester** : `flutter analyze` doit rester à 0 erreur, `flutter test` doit rester vert.

---

## Section 10 — KPIs de succès

- ✅ Temps de chargement perçu < 1s (Home visible immédiatement, skeleton sur le reste).
- ✅ Toutes les actions principales accessibles en 2 taps max depuis la Home.
- ✅ `flutter analyze` : 0 erreur, 0 warning.
- ✅ Pas d'écran "vide" : chaque écran a un empty state ou un loading state.
- ✅ L'écran Home fait **vraiment** d'ORIA le centre (vs un FAB relégué au coin).
- ✅ Le design donne envie de parler à ORIA (suggestions, callout central, transitions douces).
