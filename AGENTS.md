# Repository Instructions

## Scope

- This is a multi-project repository with no root build, test, package-manager, formatter, CI workflow, or pre-commit command. Run each command from the owning project directory.
- `oria-backend-main/` is the Spring Boot 4.0.5 / Java 21 / Maven API; the application entrypoint is `src/main/java/tg/edtch/activEducation/OriaEducationApplication.java`.
- `oria-fronted-main/oria_education/` is the Flutter mobile app; the entrypoint is `lib/main.dart`, and state is handled with `setState` plus singleton services.
- `oria-fronted-main/backoffice/` is the React 19 / TypeScript 6 / Vite admin app; `src/main.tsx` mounts `App.tsx`.
- `oria-fronted-main/schools/` is a static school bulletin portal, not a package-managed frontend.
- Do not confuse root `seed/` (Supabase/PostgREST HTML data) with `oria-fronted-main/seed/` (backend API and SQL seeds).

## Commands

### Backend

Run from `oria-backend-main/`:

```bash
./mvnw clean install
./mvnw test
./mvnw -Dtest=AuthServiceTest test
./mvnw package -DskipTests
./mvnw spring-boot:run
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
docker compose up -d db minio redis
docker compose up -d --build
```

- The local dev profile raises rate limits to `99999`; it is not production-like.
- Compose maps PostgreSQL to host port `5433`, while a host-run app defaults to port `5432`; set `DB_PORT=5433` when using the compose database from the host.
- The regular `Dockerfile` only copies `target/*.jar`; build the JAR before `docker compose up -d --build`. The app container also needs required environment variables such as `JWT_SECRET` and the Supabase settings; the backend `.env` is not copied wholesale into the image.
- `OriaEducationApplicationTests` is disabled because its context test needs PostgreSQL and pgvector; a green `mvn test` does not prove startup against the real services.
- API health/docs are at `/actuator/health`, `/api-docs`, and `/swagger-ui.html` on port `8080`.
- `docker-compose.prod.yml` mounts `../oria-fronted-main/backoffice/dist` into Nginx, so build the backoffice before production compose. Its `Dockerfile.prod` currently runs `./mvnw` without copying the Maven wrapper; verify or fix that builder before deployment.

### Flutter

Run from `oria-fronted-main/oria_education/`:

```bash
flutter pub get
flutter analyze
flutter test
flutter test test/api_test.dart
flutter run
adb reverse tcp:8080 tcp:8080
```

- `.env` is loaded at startup; `API_BASE_URL` must be the host root without `/api/v1` because service paths already include that prefix.
- `test/api_test.dart` is an integration test: it needs a running backend and reachable `/api-docs` and library endpoints.
- Chat uses `/ws/chat` first and falls back to REST polling every 15 seconds; do not assume it is polling-only.
- `BaseService` catches secure-storage failures and falls back to web/memory storage; preserve that behavior when changing auth persistence.

### Backoffice

Run from `oria-fronted-main/backoffice/`:

```bash
npm install
npm run dev
npm run lint
npm run build
```

- There is no test script or test framework in `package.json`.
- TypeScript is strict with `noUnusedLocals`, `noUnusedParameters`, and `erasableSyntaxOnly`; do not add enums, namespaces, or parameter properties.
- The `@/*` alias maps to `src/*`; `VITE_API_BASE_URL` must include `/api/v1`.
- `vite.config.ts` does not pin a dev-server port; use the port Vite prints instead of assuming `5174`.

### School portal

Run from `oria-fronted-main/schools/`:

```bash
python3 -m http.server 8081
```

- The form posts to `/api/v1/school/bulletins` and requires a backend account with `ROLE_ECOLE`.

### Seeds and ML

- `bash oria-fronted-main/seed/seed_local.sh [email] [password]` checks the local API and then runs library, establishment images, quiz, and legacy university seeds; it does not create users and mutates the database.
- Pass working admin credentials explicitly: `seed_local.sh` defaults to `admin123!`, while the backend `DataLoader` defaults its generated admin password to `admin123`. `seed_etablissements.sh` is the separate official establishment dataset.
- `seed_users.sql` is direct database setup; `seed_users_api.sh` is the API alternative. Both are separate from `seed_local.sh`.
- From the repository root, `python3 generate_synthetic_data.py` creates the input for `python3 train_model.py`; the latter writes model artifacts under `models/` and result JSON files.
- Phase 5 requires a running backend, an ADMIN/SUPER_ADMIN JWT, and at least 5,000 real outcomes for meaningful results. `phase5_train_real.py` sets `PHASE5_DATASET`, but `train_model.py` currently ignores that variable and always loads `orientation_outcome_synthetic.csv`; verify the input before trusting real-data output. It also invokes `python`, not `python3`.
- `seed/supabase/seed_etablissements_to_supabase.py` requires `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` and currently hard-codes `/home/grace/hackaton/seed/Etablissements.html`; update that path in another checkout.

## Backend Guardrails

- REST resources expose UUID `trackingId`; `Fiche` also has an internal `Long` primary key. Use the UUID in API paths and DTOs, never the database ID.
- Before adding or changing an endpoint, inspect existing controllers and `shared/security/config/SecurityConfig.java`: path rules and controller `@PreAuthorize` checks jointly enforce authentication, roles, and ownership, and unmatched requests require authentication.
- `Fiche` uses JPA `InheritanceType.JOINED`. Vector search intentionally does native pgvector ID lookup followed by JPQL polymorphic hydration; preserve both phases when changing RAG/search.
- The RAG hydration query hard-codes ten `ids` positions, while `OriaRechercheContexteService` currently requests eight; repair or handle this mismatch before enabling or relying on vector RAG (`oria.rag.vectoriel` defaults to `false`).
- Flyway is enabled with migrations in `src/main/resources/db/migration/`, but `spring.jpa.hibernate.ddl-auto=update` remains during transition. Add schema changes as a new migration and test against an existing database; do not treat `ddl-auto=update` as a safe migration strategy.
- Redis is used for cache and rate limiting and is included in the normal compose dependency set. AI provider wiring is separate from properties: `OllamaLlmGateway` is currently not a Spring component, while `GroqLlmGateway` is active when its key is configured.
- `.env` files and the root backend launch scripts contain credentials or API keys in the working tree. Never copy them into logs or instructions; use the example env files and rotate any exposed secret.
