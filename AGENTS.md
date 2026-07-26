# Activ Education / ORIA — AGENTS.md

## Key documents (read before any modification)

| File | Why |
|---|---|
| `activ-education-fronted-main/seed/cahier_de_charge.md` | Functional specs — confirm feature is specified before coding |
| `activ-education-fronted-main/activ_education/HANDOVER.md` | Latest handover (2026-07-26): what was done, bugs, priorities |
| `activ-education-fronted-main/activ_education/DESCRIPTION_ORIA.md` | ORIA mobile functional description (699 lines) |
| `activ-education-fronted-main/activ_education/ARCHITECTURE_ORIA.md` | Strategic 10yr architecture vision (956 lines) |
| `activ-education-fronted-main/seed/AGENTS.md` | Detailed seed scripts execution order |

## Repository structure

```
activ-education-backend-main/      # Spring Boot 4.0.5 (Java 21, Maven)
activ-education-fronted-main/
├── activ_education/               # Flutter mobile (Dart, setState), entry: lib/main.dart — rebranded "ORIA" (hackaton)
├── backoffice/                    # React 19 + TS 6 + Tailwind v4, entry: src/main.tsx
└── seed/                          # SQL + shell scripts + 117 university markdown files
```

## Commands

### Backend (workdir: activ-education-backend-main/)
```
docker compose up -d db minio redis   # Services only (app runs locally)
docker compose up -d --build           # Full stack (db :5433, minio :9000/9001, redis :6379, app :8080)
./mvnw spring-boot:run                 # Local dev (needs DB on :5432)
./mvnw clean install                   # Full build with tests
./mvnw package -DskipTests             # Fast rebuild
```
- DB: `localhost:5432` (5433 in Docker), user `postgres`, pass `abalakata`, db `activ_education`
- `ddl-auto=update` — **Flyway installé avec baseline-on-migrate (V1 migration) mais ddl-auto conservé en transition**
- Secrets (`JWT_SECRET`, `OPENAI_API_KEY`, `GROQ_API_KEY`) must be set in env or `.env` — **present on disk, rotate before deploying**
- Rate limits disabled in dev (`99999` in `application-dev.properties`)
- Swagger: `http://localhost:8080/swagger-ui.html`
- `start-backend.sh` at root wraps JAR launch with env vars (uses absolute paths from another machine — adjust on new dev setup)
- All tests: `./mvnw test` (118 tests, 0 failures)
- Single test: `./mvnw -Dtest=AuthServiceTest test`

### Flutter (workdir: activ-education-fronted-main/activ_education/)
```
flutter pub get
flutter run
flutter test         # 6 test files (widget, API, models, simulateur, bulletins, scenarios)
flutter analyze      # dart analyze lib/ — expect 0 errors
```
- `API_BASE_URL` in `.env` — **no `/api/v1` suffix** (backoffice adds it)
- **No state management** — `setState` + static singletons on `BaseService`
- `flutter_secure_storage` fails on web — always wrap in try-catch with in-memory fallback
- 401 interceptor: `_refreshWithLock()` in `base_service.dart`, skips `/auth/login` and `/auth/refresh`
- 4-second polling for chat (no WebSocket)
- Android: `adb reverse tcp:8080 tcp:8080` to reach `localhost:8080`
- `image_picker` must be wrapped in try-catch (`PlatformException(already_active)`)
- **`bottom_nav.dart`** — each `_NavItem` in `Expanded`, never revert to `spaceAround`
- **Nouveau**: écran `/evolution` (`OrchestrationResultScreen`) avec score global, moteurs, analyse
- **Nouveau**: `EvolutionService` dans `lib/services/evolution_service.dart`
- **Nouveau**: carte "Recommandation ORIA" sur l'écran Profil

### Backoffice (workdir: activ-education-fronted-main/backoffice/)
```
npm install
npm run dev     # Vite dev server :5174
npm run build   # tsc -b && vite build
npm run lint
```
- **No test framework**; TS 6 strict (`erasableSyntaxOnly`: no enums, namespaces, parameterProperties)
- `VITE_API_BASE_URL` includes `/api/v1` suffix
- `@/` → `src/`; react-router-dom v7, @tanstack/react-query v5, Zustand, Tailwind v4, Recharts, Lucide, Axios
- 3 role levels: `CONSEILLER`, `ADMIN`, `SUPER_ADMIN` via `ProtectedRoute`
- **Nouveau**: `/conseiller/evolution` (EvolutionPage) avec sélection élève + graphique barres + scores par moteur
- **Nouveau**: `src/api/evolution.ts` pour l'appel à `POST /evolution/{id}/orchestrate` + `GET /evolution/configs`
- **Nouveau**: lien "Recommandation" dans la sidebar conseiller

## Backend architecture

31+ packages (Package by Feature). Original 5 core modules (`profil`, `bibliotheque`, `diagnostic`, `accompagnement`, `shared`) + many feature packages (`alumni`, `badge`, `calendrier`, `defis`, `emploi`, `entretien`, `mentorat`, `portfolio`, `recommandation`, `riasec`, `simulateur`, `temoignage`, `vae`, `evolution`, etc.).

- All entities extend `BaseEntity` (Long PK + UUID `trackingId` in REST URLs)
- All write endpoints use `@Valid` on DTOs — **validation errors produce 400 at `/error`, caught by JWT filter → 401**
- Lombok `@SuperBuilder` on abstract `Fiche` hierarchy with `InheritanceType.JOINED`
- Two-phase pgvector: native SQL for vector search, then JPQL for entity hydration (JOINED loses discriminator in native queries)
- MinIO: 3 buckets (images/videos/documents), upload via `/files/upload/{fileType}`, max 500MB
- `DataLoader.java` seeds default admin (`admin@activeducation.tg`) on startup
- AI: **OpenAI** (migrated from Gemini in Session 4) — `AIEmbeddingService` → `OpenAIEmbeddingServiceImpl`
- Nouveau package `shared/llm/`: `LlmGateway` interface + `OllamaLlmGateway` (POST /api/chat), pas encore branché sur `OriaService`
- Nouveau package `evolution/`: 4 entités JPA (`BulletinHistory`, `InterviewResponseHistory`, `StudentEvolutionProfile`, `ScoringConfig`), `AcademicEngine`, `StudentEvolutionService`

## Module evolution (Phase 1-3 complète)

### 9 moteurs de scoring
| Moteur | Package | Dépendances |
|---|---|---|
| `AcademicEngine` | `evolution/engines/` | `BulletinHistoryRepository` |
| `InterestEngine` | `evolution/engines/` | `InterviewResponseHistoryRepository`, `ProfilOrientationRepository` |
| `RIASECEngine` | `evolution/engines/` | `TestRIASECResultatRepository` |
| `SkillsEngine` | `evolution/engines/` | `PortfolioCompetenceRepository` |
| `BehaviourEngine` | `evolution/engines/` | `DefiReleveRepository`, `BadgeDecerneRepository`, `SimulationEntretienRepository` |
| `ActivitiesEngine` | `evolution/engines/` | `DefiReleveRepository` |
| `CareerMatchingEngine` | `evolution/engines/` | `FicheMetierRepository`, `TestRIASECResultatRepository` + `ProfilFiliereRiasecCatalog` |
| `UniversityMatchingEngine` | `evolution/engines/` | `FicheEtablissementRepository` |
| `ConfidenceEngine` | `evolution/engines/` | 7 repositories (volume de données) |
| `ExplainabilityEngine` | `evolution/engines/` | Prend `Map<String, Engine.Output>` — agrège les résultats |

### Services & endpoints
- `StudentEvolutionService` — injecte `List<Engine<UUID, Engine.Output>>`, itère tous les moteurs
- `RecommendationOrchestrator` — fusionne scores pondérés + ExplainabilityEngine
- `ScoringConfigService` — lecture config active depuis `evolution_scoring_config` (fallback poids par défaut)
- `EvolutionController` — 4 endpoints :
  - `POST /api/v1/evolution/{studentId}/compute` — recalcule le SEP
  - `GET /api/v1/evolution/{studentId}` — récupère le SEP
  - `POST /api/v1/evolution/{studentId}/orchestrate` — recommandation complète (Phase 3)
  - `GET /api/v1/evolution/configs` — poids par défaut (admin)
  - `GET /api/v1/evolution/_health` — health check

### Tests (11 fichiers, 47 tests evolution)
- `AcademicEngineTest` (6 tests), `InterestEngineTest` (4), `RIASECEngineTest` (4), `SkillsEngineTest` (4),
  `BehaviourEngineTest` (4), `ActivitiesEngineTest` (4), `CareerMatchingEngineTest` (4),
  `UniversityMatchingEngineTest` (3), `ConfidenceEngineTest` (4),
  `StudentEvolutionServiceTest` (5), `RecommendationOrchestratorTest` (4)

## Security

- JWT filter always active (stateless, CSRF disabled, CORS multi-origins)
- **Three-layer defense**: SecurityConfig (path-based) → `@PreAuthorize` (method-based) → SPEL `@security` bean (ownership)
- All unprotected paths default to `.authenticated()` (last rule in SecurityConfig)
- `@PreAuthorize` on controllers with custom SPEL bean `@security`:
  - `isOwner(#trackingId)`, `isOwnChild(#eleveTrackingId)`, `isOwnConseiller(#conseillerTrackingId)`, `isRdvParticipant(#rdvTrackingId)`
- Role comparison in Flutter must use `.toUpperCase()` (backend returns PascalCase like `"Parent"`)
- `.env` secrets (JWT, OpenAI, Groq) gitignored in backend — but present on disk, rotate before deploying
- Rate limiting via Redis: login (20/15min), refresh (20/5min), API (200/1min)
- Files: IMAGE downloads public, DOCUMENT/PDF downloads require authentication
- GlobalExceptionHandler handles `@Valid` validation errors → 400 JSON (not `/error` 401)
- No CI/CD, no formatting configs (Prettier/EditorConfig), no pre-commit hooks

## Before any modification

1. **Read `seed/cahier_de_charge.md`** to confirm the feature is specified
2. **Check existing controllers + `SecurityConfig.java`** before creating new endpoints — 133+ endpoints exist
3. **Do not duplicate routes** — verify exact path isn't already mapped

## Décisions d'architecture (mobile)

- **Fonctionnalité NOTE retirée du mobile** : la saisie manuelle des notes, l'upload OCR de bulletins, et l'analyse des résultats scolaires sont exclus de l'application mobile. Ces fonctionnalités restent disponibles côté backoffice si nécessaire.

## Key gotchas

- **Backend `.env` contains secrets** (OPENAI_API_KEY, JWT_SECRET, GROQ_API_KEY, Supabase keys) — gitignored but present on disk; rotate before any deploy
- **20 backend test files** exist (profil: bulletin upload + eleve; prediction: note-trajectoire, outcome, lookup, prediction, recommandation3signaux; simulateur: template + parcours; evolution: AcademicEngine + StudentEvolutionService; shared: stats + test controller; auth: service + controller; JacksonTest, TestBeansConfig, ActivEducationApplicationTests)
- **Deployed DB is empty** — run `seed/*.sh` scripts in order (need JWT from admin account). See `activ-education-fronted-main/seed/AGENTS.md` for execution order
- **`ParentRequest.java` / `ConseillerRequest.java`** — `motDePasse` `@NotBlank`/`@Size` removed (was causing 401 on update)
- **Backoffice admin pages** (quiz editor, FAQ moderation, stats) are partially stubs/mock data
- **`matieresPreferees`** stored as CSV in `TEXT` column, parsed by `EleveMapper`
- **`GET /api/v1/eleves/{id}/resultats-diagnostic`** returns `Page<>` but Flutter calls without pagination
- **OCR** requires `OPENAI_API_KEY` for image extraction (PDF uses PDFBox without key)
- **2FA login** — if `requires2fa=true`, client must call `/auth/2fa/validate` with challengeToken
- **ORIA** uses Ollama (`mistral:7b-instruct`) locally; Flutter Dio timeout set to 120s. Backend's `LlmGateway` interface exists but `OriaService` still calls Ollama directly (not yet refactored)
- **`ddl-auto=update` bug**: ne crée pas automatiquement les nouvelles tables du package `evolution/` — workaround : Flyway V1 migration (cf. `db/migration/V1__create_evolution_tables.sql`)
- **Login endpoint renvoie 500** : `POST /api/v1/auth/login` pré-existant, pas causé par les changements récents
- **Maintenance mode** — static in-memory flag (not persistent)
- **Monitoring** — requires `docker compose -f docker-compose.monitoring.yml up -d` separately
- **Flutter web** unstable (`Dart compiler exited unexpectedly`) — DDC hot reload ne réinitialise pas les nouveaux champs State, faire F5 plein
- **`bottom_nav.dart`** — each `_NavItem` in `Expanded`, never revert to `spaceAround`
- **MinIO 500 bug** — si `files/download` retourne 500 : 1) `MinioExceptionHandler` doit avoir `@Order(HIGHEST_PRECEDENCE)` pour passer avant `GlobalExceptionHandler` 2) l'import du handler doit être la classe custom pas `java.io.FileNotFoundException` 3) `contentLength()` peut NPE si `fileSize` null
- **Simulateur parcours** — les slots de bulletins sont automatiques selon le niveau (`_slotsPourNiveau()`), la série scolaire est masquée pour collège/supérieur

## ML Pipeline : entraînement jusqu'à la fin (workdir: projet racine)

```bash
# 1. Générer les données synthétiques (Phase 0)
python3 generate_synthetic_data.py

# 2. Entraîner les modèles (LogisticRegression + GradientBoosting)
python3 train_model.py          # → models/gb_*.joblib + results_prototype.json

# 3. (Quand ≥ 5000 orientation_outcome réels) Phase 5 :
JWT=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@activeducation.tg","motDePasse":"abalakata"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))")
python3 phase5_export_dataset.py --token "$JWT" --out real_dataset.csv
python3 phase5_train_real.py --csv real_dataset.csv   # → results_phase5.json
```

- Modèles : `LogisticRegression` (class_weight=balanced) + `GradientBoostingClassifier`
- Configs : `sans_comportemental` (RIASEC + notes + 60/40) et `avec_comportemental` (+ comportemental)
- 7 niveaux : COLLEGE → BAC_3, prédiction ADMIS vs REORIENTE par filière
- Phase 5 nécessite ≥ 5 000 orientation_outcome réels (DB vide actuellement)

## Session 2026-07-25 — Bug Flutter web : ERR_CONNECTION_REFUSED

**Cause**: Spring Boot backend (`localhost:8080`) wasn't started. Start via `start-backend.sh` (root) or `./mvnw spring-boot:run`. Flutter has no offline fallback in `BaseService`.
