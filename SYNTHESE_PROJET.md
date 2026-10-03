# Synthèse du projet — Activ Education / Oria

> Plateforme intelligente d'orientation scolaire et professionnelle au Togo.
> Thème mémoire : « Conception et développement d'une plateforme intelligente d'orientation scolaire pour les élèves togolais » — HubCity / Woélab, 2025-2026.

## 1. Problème et objectifs

**Contexte :** ~1 conseiller pour 5 000 élèves au Togo (recommandé 1/300), services concentrés à Lomé/Kara, pas de base centralisée filières/établissements/métiers. Opportunité : >80 % des jeunes ont un smartphone.

**Question centrale :** comment offrir un accompagnement personnalisé, accessible et pertinent à chaque jeune Togolais, quel que soit lieu, niveau ou moyens ?

**Objectifs :**
1. Structurer l'offre de formation (bibliothèque explorable : séries, filières, métiers, établissements).
2. Diagnostiquer multidimensionnel (quiz RIASEC + notes/OCR + centres d'intérêt) au lieu de la seule série scolaire.
3. Recommander pertinent (scoring + IA + RAG local) et accompagner humain (messagerie, RDV, visio).
4. Passer à l'échelle à coût minimal (open source, mobile-first, hors-ligne partiel).
5. Permettre la maintenance par non-développeurs (backoffice no-code, paramètres, versionning fiches).

**Indicateurs visés :** 50 000 actifs/mois à 12 mois, satisfaction >4/5, >60 % questions résolues par ORIA sans humain, >30 % utilisateurs ruraux.

## 2. Acteurs

| Acteur | Usage |
|---|---|
| Élève / Étudiant | mobile : diagnostic, exploration, RDV, chat, portfolio, badges |
| Parent | mobile : suivi enfant, consentement mineurs, historique |
| Conseiller | backoffice + mobile : file questions, RDV, compte-rendus, disponibilités |
| Admin | backoffice : CRUD contenus, quiz, FAQ, stats, modération |
| Super-Admin | backoffice : comptes admin, paramètres, logs audit, maintenance, backups |

## 3. Architecture globale

```
Mobile Flutter (élèves/parents) ─┐
                                 ├─ REST + JWT ─> Spring Boot 4.0.5 / Java 21 (:8080)
Backoffice React 19 (conseillers/admins) ─┘                │
                                              ┌─────────────┼──────────────┐
                                              │             │              │
                                         PostgreSQL 16  MinIO (S3)    Redis 7
                                         + pgvector     3 buckets    cache + rate-limit
                                         (768 dim)      images/vidéos/  + blacklist JWT
                                                        documents
                                              │
                                         IA : OpenAI (embeddings+génération),
                                         Groq (fallback), Ollama qwen2:0.5b (local),
                                         Whisper/TTS, OpenAI Vision (OCR)
```

**Repos :**
- `oria-backend-main/` — API, entrée `src/main/java/tg/edtch/activEducation/OriaEducationApplication.java`
- `oria-fronted-main/oria_education/` — mobile Flutter, entrée `lib/main.dart`
- `oria-fronted-main/backoffice/` — admin React, entrée `src/main.tsx` → `App.tsx`
- `oria-fronted-main/schools/` — portail statique bulletins (`python3 -m http.server 8081`, POST `/api/v1/school/bulletins`, rôle `ROLE_ECOLE`)
- Racine : `generate_synthetic_data.py`, `train_model.py`, `phase5_*.py`, `predict_api.py`, `orientation_outcome_synthetic.csv`, `models/`

## 4. Backend — Spring Boot 4.0.5 / Java 21 / Maven

**Stack :** Spring MVC, Data JPA (Hibernate 6), Security (JWT HS512), Validation, WebSocket, Actuator, Data Redis ; PostgreSQL+pgvector, MinIO 8.5.17, PDFBox 3.0.3, Tika, jjwt 0.12.5, springdoc-openapi 2.7.0, dotenv-java, Micrometer/Prometheus, Flyway (présent mais `ddl-auto=update` encore actif en transition).

**Organisation :** Package by Feature (~30 packages, ~68 contrôleurs, ~170-179 endpoints, base `/api/v1`, docs `/swagger-ui.html`, `/api-docs`, `/actuator/health`).
- `shared/` : sécurité JWT, MinIO, IA, WebSocket, BaseEntity (PK Long + UUID `trackingId` exposé en API)
- `profil/` : `Utilisateur` abstraite → `Eleve`, `Parent`, `Conseiller`, `Administrateur` + `Role`, `Document`, `Notification`, `Historique`, `NoteSaisiManuel`
- `bibliotheque/` : `Fiche` abstraite (`JOINED`) → `FicheSerie`, `FicheFiliere`, `FicheMetier`, `FicheEtablissement` + `Favori`, `EntreeFAQ`, `RechercheOrpheline`, embeddings pgvector
- `diagnostic/` : `Quiz`, `Question`, `Reponse` (RIASEC R,I,A,S,E,C), `ResultatDiagnostic`, `ScoreMatrice`, `SeuilAdmission`
- `accompagnement/` : `Message`, `RendezVous` (PLANIFIE/TERMINE/ANNULE), `Disponibilite` (jour 1-7 ISO), `Ticket`
- `prediction/` : `NiveauFiliere`, `NotesHistorique`, `OrientationOutcome`, `EngagementSignal`
- + ~21 modules métier : `alumni`, `badge`, `calendrier`, `cvgenerateur`, `defis`, `emploi`, `entretien`, `mentorat`, `portfolio`, `recommandation`, `riasec`, `simulateur`, `temoignage`, `vae`, `reseau`, `parrainage`, `datahub`, `cartemetiers`, `sallevirtuelle`, `reorientation`, `cahierdebord`, `attestations`, `horsligne`

**Endpoints clés :** `/auth/login|refresh|logout|2fa/*`, `/eleves|parents|conseillers|administrateurs`, `/quiz|questions|reponses|resultats-diagnostic|score-matrices|seuils-admission`, `/bibliotheque/metiers|series|filieres|etablissements|favoris|faq|recherche-fiche-ia|analytics`, `/messages| rendez-vous|disponibilites|tickets`, `/files/upload|download|stream|url|presigned-url`, `/eleves/{id}/notes-historique|orientation-outcome|recommandation-ia/v2`, `/oria`, `/vocal`, OCR, `/stats`, `/parametres`, `/maintenance`, `/csv/import|export`, `/admin/logs`.

**Moteur recommandation v2 (3 signaux) :**
```
score_final = 0.50·score_realite (notes/seuil + tendance) + 0.35·score_aspiration (cosinus RIASEC) + 0.15·score_engagement (consultations, favoris, RAG)
```
+ N découvertes garanties anti bulle de filtre. RAG : recherche native pgvector cosinus (`<=>`) + réhydratation JPQL polymorphique.

**Sécurité 3 couches :** `SecurityConfig.java` (paths) → `@PreAuthorize` (rôles) → bean SPEL `@security` (ownership : `isOwner`, `isOwnChild`, `isOwnConseiller`, `isRdvParticipant`). JWT 15 min + refresh 7 j, BCrypt 12, 2FA TOTP RFC 6238, blacklist Redis, rate-limit (login 20/15min, refresh 20/5min, API 200/1min), CSP/HSTS/CORS, consentement parental <15 ans, soft-delete + audit.

**Tests :** 8-9 fichiers (`AuthServiceTest`, `AuthControllerTest`, `EleveServiceTest`, `StatsServiceTest`, etc.) ; test contexte désactivé (nécessite Postgres+pgvector réel).

## 5. Mobile — Flutter / Dart

**Stack :** Flutter Material 3, Dart ≥3.3, Dio 5.7 + intercepteur JWT, `flutter_secure_storage` (fallback web/mémoire), `setState` + singletons (pas de Riverpod/Bloc), `flutter_map`, `fl_chart`, `speech_to_text` + `flutter_tts`, Inter/Poppins, `flutter_dotenv` (`API_BASE_URL` sans `/api/v1`).

**Structure `lib/` :** `main.dart`, `models/` (~15), `screens/` (~55 écrans : auth/onboarding 11, home 11, explorer 6, diagnostic 4, messages 5, orientation, entretien, simulateur, portfolio, datahub…), `services/` (~21 : API, auth, diagnostic, prédiction…), `theme/`, `utils/`, `widgets/`.

**Fonctions :** onboarding 3 slides, login/OTP/mot de passe oublié, dashboard bachelier, explorer 4 fiches (public + favoris + recherche sémantique + tendances + similaires), quiz RIASEC adaptatif + résultats, messagerie (polling 4 s ; `/ws/chat` + fallback REST 15 s selon config), RDV (CRUD + visio Jitsi), recommandation v2 (niveau → bulletins → top 10), assistant vocal ORIA, badges/alumni/défis/mentorat/portfolio/CV/attestations/calendrier. Tests : 3 fichiers (`widget_test`, `model_test`, `api_test.dart` = intégration, exige backend + `/api-docs` joignables).

## 6. Backoffice — React 19 / TypeScript 6 / Vite 8

**Stack :** React 19.2, TS 6 strict (`noUnusedLocals`, `noUnusedParameters`, `erasableSyntaxOnly` — pas d'enum/namespace), Vite 8, react-router v7, TanStack Query v5, Zustand v5, Tailwind v4, Recharts, Axios, Lucide. Alias `@/*` → `src/*`, `VITE_API_BASE_URL` avec `/api/v1`. Pas de framework de test.

**Pages (29) :** `login`, `conseiller/` (dashboard, messages, RDV, FAQ, ORIA console, stats, utilisateurs, profil/dispos), `admin/` (dashboard KPIs, stats export PDF/Excel, élèves/parents/conseillers, bibliothèque CRUD brouillon→publié + planif + historique, quiz éditeur drag&drop + matrices + seuils, FAQ modération, notifications), `superadmin/` (dashboard plateforme, paramètres système, logs audit). Garde `<ProtectedRoute>` par rôle CONSEILLER/ADMIN/SUPER_ADMIN, 2FA obligatoire.

## 7. IA / ML — ORIA + RAG + Prédiction Phase 0-5

- **ORIA conversationnel :** cascade Ollama local → Groq `llama-3.1-8b` → OpenAI `gpt-4o-mini`, sessions `sessionId`, RAG fiches+FAQ (embeddings `text-embedding-3-small` 768 dim → pgvector).
- **OCR bulletins :** OpenAI Vision (images) / PDFBox (PDF texte), validation Groq/regex.
- **Vocal :** Whisper STT + OpenAI TTS.
- **Prototype Phase 0 (validée, 2026-07-16, 600 élèves synthétiques) :** baseline 60/40 ROC-AUC ~0.89 (logreg) / 0.87 (GB) ; signal comportemental sans gain (Δ −0.001 à −0.017) → plafonné à 15-25 % ; pas de bulle de filtre détectée ; `ecart_notes_seuil`, `notes_actuelle`, `match_riasec` dominants ; `tendance_notes` top-8 → intégrée à 10 % de `score_realite`. Logreg plus robuste (déséquilibre 88/12) → baseline, GB challenger.
- **Phase 1-4 faites :** entités JPA, algo 50/35/15, API+sécurité, front Flutter+backoffice. **Phase 5 en cours :** exige backend + JWT ADMIN/SUPER_ADMIN + ≥5 000 outcomes réels ; `train_model.py` ignore encore `PHASE5_DATASET` (charge toujours `orientation_outcome_synthetic.csv`) — vérifier avant usage réel.

## 8. Données et seeds

Ordre : `seed_users.sql` (7 users) → `seed_bibliotheque.sh` (13 séries, 32 filières, 42 métiers, 22 établissements, 12 FAQ) → `seed_etablissement_images.sh` → `seed_quiz.sh` (RIASEC 30Q + personnalité 5Q) → `seed_universites.sh` (117 établissements togolais, fiches `.md`) ; `seed_local.sh [email] [password]` ne crée pas d'users et mute la DB (défaut `admin123!` vs `admin123` DataLoader — passer credentials explicites). `seed_users_api.sh` = alternative API. Dataset Togo/Bénin/Côte d'Ivoire via scripts `import_*.py`.

## 9. Déploiement

| Service | Port hôte |
|---|---|
| API Spring | 8080 |
| Postgres | 5432 (5433 en compose) — `DB_PORT=5433` si app sur hôte + DB en compose |
| MinIO API / Console | 9000 / 9001 |
| Redis | 6379 |
| Monitoring opt. | Prometheus 9090, Grafana 3000, ES 9200, Kibana 5601 |

```bash
# dev : infra seule
docker compose up -d db minio redis
# stack complète (builder JAR au préalable : ./mvnw package -DskipTests, image ne copie que target/*.jar)
docker compose up -d --build
./mvnw test / ./mvnw -Dtest=AuthServiceTest test / ./mvnw spring-boot:run [-Dspring-boot.run.profiles=dev : rate-limit 99999]
# mobile : flutter pub get && flutter analyze && flutter test && flutter run (+ adb reverse tcp:8080 tcp:8080)
# backoffice : npm install && npm run dev|lint|build  (build requis avant docker-compose.prod.yml qui monte dist/ dans Nginx)
# schools : python3 -m http.server 8081
# ML : python3 generate_synthetic_data.py → python3 train_model.py (artifacts models/ + results JSON)
```
`.env` requis : DB_*, `JWT_SECRET` (64B base64), MinIO, Redis, `OPENAI_API_KEY`, `GROQ_API_KEY`, `OLLAMA_URL/MODEL`, `JPA_DDL_AUTO`, `SERVER_PORT`, `RATE_LIMIT_*`.

## 10. État, risques, à faire

**Fait :** Phases 1-4, ~179 endpoints, sécurité JWT+2FA+rate-limit, RAG sémantique, ORIA, OCR, CRUD complets, seeds 117 universités, Docker + monitoring/Logstash/ELK, CI (backend/backoffice/flutter).

**Points d'attention :** `ddl-auto=update` sans Flyway effectif (risque perte) → ajouter migrations + tester sur DB existante ; secrets commités dans `.env`/scripts → rotationner, ne jamais logger ; RAG vectoriel désactivé par défaut (`oria.rag.vectoriel=false`) + mismatch hydratation (10 `ids` en dur vs 8 demandés) → réparer avant activation ; `OllamaLlmGateway` non-bean vs `GroqLlmGateway` actif si clé ; chat polling (pas WebSocket) ; RIASEC catalogue 15 profils en dur ; pas de tests backoffice ; TS strict + Flutter web instable + `image_picker already_active` ; 401-update via `@Valid` sans password ; MinIO handler `@Order(HIGHEST_PRECEDENCE)` ; `Dockerfile.prod` invoque `./mvnw` sans wrapper → vérifier.

**Reste :** Phase 5 ML réel, déploiement cloud + QA, tests, WebSocket chat, Flyway, écrans état (404/offline/skeleton), catalogues/tabs détail, dashboards reconversion/parent/conseiller, lecteur vidéo, Google Sign-In, backups/rapports programmés, droit à l'oubli/export RGPD complets.

---
*Sources : `docs/specs/DESCRIPTION_PROJET.md`, `FONCTIONNALITES.md`, `problematique.md`, `cahier_charge_technique.md`, `architecture/api-endpoints.md`, `ml/RESULTATS_PROTOTYPE.md`, `reports/etat-projet.md`, `reports/memoire_activ_education.md`, `AGENTS.md`, `pom.xml`, `backoffice/package.json`.*
