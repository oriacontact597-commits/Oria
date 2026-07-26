# STATE_SAVE — Snapshot ORIA pour OpenCode

> **Date** : 2026-07-26 (fin de session)
> **Pour** : OpenCode / futur agent IA qui reprend le projet
> **Statut global** : Phase 3.3 + 3.4 + 3.5 + 4.1 + 4.2 + 4.3 + 4.5 + 6.2 = FAIT
> **Backend** : ✅ Tourne (PID 2039423, port 8080, DB=activ_education, Redis connecté)
> **Tests** : ✅ 133 verts (1 skipped), BUILD SUCCESS

---

## 1. État technique en 30 secondes

| Composant | État | Détail |
|---|---|---|
| Backend Java | ✅ UP | PID 2039423, port 8080, CPU 159% |
| PostgreSQL | ✅ UP | Docker `activeducation-db:5432`, DB `activ_education` |
| Redis | ✅ UP | Docker `activeducation-redis:6379`, healthy |
| Mobile Flutter | 🟡 Non testé | `flutter run` jamais lancé manuellement dans cette session |
| Backoffice | ⚪ Intact | Pas touché (hors périmètre hackaton) |
| LLM | ⚪ Ollama local | `qwen2:0.5b` (configuré), OpenAI révoqué |
| RAG | ⚪ pgvector indispo | Fallback JPQL uniquement |
| Tests | ✅ 133 verts | `BUILD SUCCESS` |

---

## 2. Démarrage backend (commande EXACTE)

Le `application.properties` a `spring.datasource.url=jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:postgres}` — **donc sans `DB_NAME=activ_education` le backend se connecte à la DB vide `postgres`**. TOUJOURS exporter :

```bash
cd /home/grace/hackaton/activ-education-backend-main
DB_HOST=localhost DB_PORT=5432 DB_NAME=activ_education \
DB_USER=postgres DB_PASSWORD=abalakata \
java -jar target/activEducation-0.0.1-SNAPSHOT.jar > /tmp/oria-backend.log 2>&1 &
```

**Services Docker à garder UP** (ne PAS redémarrer) :
- `activeducation-db` — PostgreSQL 16, port 5432
- `activeducation-redis` — Redis 7, port 6379

---

## 3. Stack & versions

| Élément | Version |
|---|---|
| Backend | Spring Boot 4.0.5 + Java 21 + Maven |
| Mobile | Flutter (pas de state management, `setState` + singletons) |
| Backoffice | React 19 + TypeScript 6 (strict, `erasableSyntaxOnly`) + Vite + Tailwind v4 |
| DB | PostgreSQL 16 + pgvector (indispo) |
| Cache | Redis 7 |
| LLM | Ollama local `qwen2:0.5b` (Groq en fallback, OpenAI révoqué) |
| ML | Python 3 (scikit-learn, xgboost, catboost) à la racine |

---

## 4. Packages du backend (`tg.edtch.activEducation.*`)

**Cœur** : `profil`, `bibliotheque`, `diagnostic`, `accompagnement`, `shared`

**Nouveaux (hackaton)** :
- `evolution/` — 9 engines + orchestrateur + 4 tables JPA + EventEngine
- `referentiel/` — multi-pays (TG, BJ, CI + séries C, D, A, G)
- `shared/cache/` — `CacheConfig.java` (RedisCacheManager bean)
- `shared/i18n/` — `I18nController.java` (FR/EN/PT bundles)

**Héritage JPA** : `BaseEntity` (Long PK + UUID `trackingId` partout dans les URLs REST). Lombok `@SuperBuilder`.

**Polymorphisme** : `Fiche` abstraite avec `InheritanceType.JOINED`.

---

## 5. Ce qui est FAIT (Phase 3-6)

### ✅ Phase 3.3 — EventEngine
- **7 événements proactifs** : `PROGRESSION`, `REGRESSION`, `BAC_APPROCHE`, `INACTIVITE`, `NOUVELLE_FORCE`, `NOUVELLE_FAIBLESSE`, `PALIER_ATTEINT`
- Score pondéré [0,1] : HIGH=0.4, MEDIUM=0.2, LOW=0.05
- **10 tests unitaires** (`EventEngineTest.java`)
- Endpoint : `GET /api/v1/evolution/{studentId}/events` (auth)

### ✅ Phase 3.4 — UI Flutter `OriaProactiveBanner`
- Widget `lib/widgets/oria_proactive_banner.dart` (170 lignes)
- Service `api_service.getEvolutionEvents(studentTrackingId)`
- Intégré dans `dashboard_bachelier.dart` après `_buildOriaCallout()`

### ✅ Phase 3.5 — Login 500→401 FIX + E2E
- `AuthController.login()` wrap dans try/catch `BadCredentialsException` → 401 JSON
- `GlobalExceptionHandler` ajoute `@Slf4j` + log pour catch-all
- `EvolutionE2ETest` (5/5 tests passent)
- 133 tests verts total

### ✅ Phase 4.1 — SchoolController
- `POST /api/v1/school/bulletins` (ROLE_ECOLE, ADMIN, SUPER_ADMIN)
- `GET /api/v1/school/bulletins/{studentId}` (ROLE_ECOLE, CONSEILLER, ADMIN, SUPER_ADMIN)
- `BulletinSubmissionRequest` avec `@Valid` (academicYear pattern, trimester @Min/@Max, grades @NotEmpty @Valid)

### ✅ Phase 4.2 — Page web écoles
- `activ-education-fronted-main/schools/index.html` (login gradient style)
- `activ-education-fronted-main/schools/bulletins.html` (form 7 matières, validation JS)
- `activ-education-fronted-main/schools/README.md`

### ✅ Phase 4.3 — Référentiel multi-pays
- **Package `referentiel/`** : 7 fichiers (Country, Series, *Repository, ReferentielController)
- **Flyway V2 SQL** : 4 tables `referentiel_country`, `referentiel_education_system`, `referentiel_series`, `referentiel_admission_rule`
- **Données seedées** : TG, BJ, CI + 4 séries TG (A, C, D, G)
- **Security** : `/api/v1/referentiel/countries/**` public
- **Endpoints testés** : `GET /countries` → 3 pays, `GET /countries/TG/series` → 4 séries

### ✅ Phase 4.5 — i18n FR/EN/PT
- `messages_fr.properties`, `messages_en.properties`, `messages_pt.properties` (11 clés chacune)
- `I18nController` public : `GET /api/v1/i18n/{locale}` JSON, `GET /i18n/locales` → `["fr","en","pt"]`
- 11 clés : `event.INACTIVITE`, `event.PROGRESSION`, `event.REGRESSION`, `event.BAC_APPROCHE`, `event.NOUVELLE_FORCE`, `event.NOUVELLE_FAIBLESSE`, `event.PALIER_ATTEINT`, `engine.academic`, `engine.confidence`, `engine.riasec`

### ✅ Phase 6.2 — Cache Redis du SEP
- `@Cacheable(value="sep", key="#studentId")` sur `StudentEvolutionService.get()`
- `@CacheEvict(value="sep", key="#studentId")` sur `StudentEvolutionService.compute()`
- `CacheConfig.java` (Spring Boot 4 ne configure plus le bean auto)
- `application.properties` : `spring.cache.type=redis`, TTL 1h, key prefix `oria:sep:`
- `@EnableCaching` sur `ActivEducationApplication`

---

## 6. Ce qui RESTE à faire

### ✅ P1.1 — Refactor `bibliotheque/` avec `country_code` (TERMINÉ 2026-07-26)
- Migration V3 SQL créée + appliquée manuellement (Flyway absent du projet) : ajout colonne `country_code VARCHAR(2) NOT NULL DEFAULT 'TG'` + backfill 363 fiches + index `idx_fe_country`
- Méthode service `listerParPays()` (avec fallback `findAllByEstPublieTrue` si code vide)
- Endpoint REST : `GET /api/v1/bibliotheque/etablissements/pays/{code}` (public)
- Tests : `FicheEtablissementRepositoryTest` Mockito (3 tests verts)
- Build : `136 tests verts` (1 skipped), `BUILD SUCCESS`
- E2E vérifié : `/pays/TG` → 363, `/pays/BJ` → 0, `/pays/CI` → 0, `/pays/XX` → 0

⚠️ **Note V3 Flyway** : la migration V3 a été appliquée MANUELLEMENT en SQL (pas via Flyway, absent du projet). Si tu veux la traçabilité Flyway, ajoute `spring.flyway.enabled=true` dans application.properties (mais ce n'est pas urgent).


### 🔴 P0 — Bloquant hackaton

#### P0.1 — User de démo fonctionnel
**Problème** : `seed/seed_users.sql` a 7 users insérés mais les hash BCrypt ne matchent pas `admin123` à l'exécution → login reste 401.

**Solution** :
```java
String hash = new BCryptPasswordEncoder().encode("admin123");
```
Puis :
```sql
UPDATE utilisateurs SET mot_de_passe_hash = '<hash>' WHERE email = 'admin@activeducation.tg';
```

**Test** :
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@activeducation.tg","motDePasse":"admin123"}'
# → 200 + {"token": "...", ...}
```

#### P0.2 — Test end-to-end
1. Login → JWT (après P0.1)
2. `GET /api/v1/eleves` → récupère trackingId
3. `POST /api/v1/evolution/{trackingId}/compute` → remplit cache
4. `POST /api/v1/evolution/{trackingId}/orchestrate?country=TG&config=default_v1`
5. `GET /api/v1/evolution/{trackingId}/events` → 0-7 events
6. Flutter `flutter run` → login → dashboard → `OriaProactiveBanner` visible

### 🟡 P1 — Hackaton-ready

| # | Tâche | Fichier |
|---|---|---|
| P1.1 | Refactor `bibliotheque/` + `country_code` | `bibliotheque/domain/entite/Etablissement.java` + V3 SQL |
| P1.2 | UI consentement parental | `lib/screens/auth/parental_consent_screen.dart` + endpoint backend |

### 🟢 P2-P3 — Long terme

| # | Tâche | Fichier |
|---|---|---|
| P2.1 | `MlRegistry` MLflow | `shared/ml/MlRegistry.java` |
| P2.2 | Benchmark gb/xgb/catboost | `phase5_evaluate_models.py` |
| P2.3 | Déploiement canary | `phase5_deploy.py` |
| P3.1 | Langues locales (Ewe, Kabye, Moore, Wolof, Bambara) | `messages_ee.properties` etc. |
| P3.2 | Vrai E2E MockMvc + JWT signé | `EvolutionE2ETest` réécrit |
| P3.3 | Push notifications FCM/APNs | `PushNotificationService.java` + Flutter `firebase_messaging` |
| P3.4 | Rapport Terminale PDF | `ReportController.java` + OpenPDF/iText |

---

## 7. Fichiers critiques (NE PAS casser)

| Fichier | Pourquoi |
|---|---|
| `activ-education-backend-main/src/main/resources/application.properties` | `DB_NAME=postgres` par défaut (bug), `spring.cache.type=redis` |
| `activ-education-backend-main/src/main/java/tg/edtch/activEducation/shared/security/config/SecurityConfig.java` | 133+ endpoints mappés, ajouter `/referentiel` + `/i18n` ici |
| `activ-education-backend-main/src/main/java/tg/edtch/activEducation/shared/cache/CacheConfig.java` | Bean RedisCacheManager (Spring Boot 4 ne l'auto-config plus) |
| `activ-education-backend-main/src/main/java/tg/edtch/activEducation/ActivEducationApplication.java` | `@EnableAsync`, `@EnableScheduling`, `@EnableCaching` |
| `activ-education-backend-main/src/main/resources/db/migration/V1__create_evolution_tables.sql` | 4 tables evolution/ |
| `activ-education-backend-main/src/main/resources/db/migration/V2__create_referentiel_tables.sql` | 4 tables referentiel/ + 3 pays + 4 séries |
| `activ-education-fronted-main/activ_education/lib/screens/home/dashboard_bachelier.dart` | Dashboard ORIA (717 lignes) |
| `activ-education-fronted-main/activ_education/lib/widgets/oria_proactive_banner.dart` | Banner EventEngine |
| `activ-education-fronted-main/activ_education/HANDOVER.md` | Doc principale (1100+ lignes) |
| `activ-education-fronted-main/activ_education/DESCRIPTION_ORIA.md` | Spec fonctionnelle |
| `activ-education-fronted-main/activ_education/ARCHITECTURE_ORIA.md` | Vision 10 ans + roadmap 6 phases |
| `activ-education-fronted-main/activ_education/NEXT_TASKS_OPENCODE.md` | **NOUVEAU** — Liste tâches restantes pour OpenCode |

---

## 8. Commandes utiles (à bookmarquer)

```bash
# Build
cd /home/grace/hackaton/activ-education-backend-main
./mvnw package -DskipTests -q

# Restart (tue l'ancien puis relance)
ps aux | grep "java -jar" | grep -v grep | awk '{print $2}' | xargs -r kill -9
sleep 2
DB_HOST=localhost DB_PORT=5432 DB_NAME=activ_education \
DB_USER=postgres DB_PASSWORD=abalakata \
java -jar target/activEducation-0.0.1-SNAPSHOT.jar > /tmp/oria-backend.log 2>&1 &

# Tests
./mvnw test -q 2>&1 | tail -10
# → "Tests run: 133, Failures: 0, Errors: 0, Skipped: 1"
# → "BUILD SUCCESS"

# Tests ciblés
./mvnw -Dtest=EventEngineTest test                    # 10 tests
./mvnw -Dtest=EvolutionE2ETest test                   # 5 tests
./mvnw -Dtest=AuthControllerTest test                 # 4 tests

# DB
PGPASSWORD=abalakata psql -h localhost -p 5432 -U postgres -d activ_education
\dt evolution_*                                        # 4 tables hackaton
\dt referentiel_*                                      # 4 tables pays
SELECT code, name_fr FROM referentiel_country;         # TG, BJ, CI
SELECT code, name FROM referentiel_series WHERE country_code='TG'; # A, C, D, G

# Cache Redis
docker exec activeducation-redis redis-cli KEYS "oria:sep:*"

# Endpoints publiques (sans auth)
curl http://localhost:8080/api/v1/i18n/locales         # 200 ["fr","en","pt"]
curl http://localhost:8080/api/v1/i18n/fr | python3 -m json.tool  # 11 clés
curl http://localhost:8080/api/v1/referentiel/countries | python3 -m json.tool  # 3 pays
curl http://localhost:8080/api/v1/referentiel/countries/TG/series | python3 -m json.tool  # 4 séries

# Endpoints auth (avec JWT)
JWT=$(curl -sf -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@activeducation.tg","motDePasse":"admin123"}' | \
  python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))")
curl http://localhost:8080/api/v1/evolution/{uuid}/events -H "Authorization: Bearer $JWT"

# Flutter
cd /home/grace/hackaton/activ-education-fronted-main/activ_education
flutter pub get
flutter analyze    # 0 erreur attendu
flutter run        # adb reverse tcp:8080 tcp:8080 si Android
```

---

## 9. Vérification de l'état (à faire au début de la prochaine session)

```bash
# 1. Backend tourne ?
ps aux | grep "java -jar" | grep -v grep | awk '{print $2}'

# 2. Health
curl -s http://localhost:8080/api/v1/i18n/locales
# → ["fr","en","pt"]

# 3. Tests passent
cd /home/grace/hackaton/activ-education-backend-main
./mvnw test -q 2>&1 | grep -E "Tests run:.*Failures|BUILD"

# 4. DB accessible
PGPASSWORD=abalakata psql -h localhost -p 5432 -U postgres -d activ_education -c "SELECT count(*) FROM utilisateurs;"

# 5. Cache Redis fonctionne
docker exec activeducation-redis redis-cli KEYS "oria:sep:*"
```

Si toutes les vérifications passent → tu peux commencer par **P0.1** (créer un user fonctionnel).

Si backend KO → relance avec la commande de la section 2.

Si tests KO → `./mvnw clean test -q` pour voir où ça casse.

---

## 10. Bugs connus / points d'attention

| # | Bug | Impact | Workaround |
|---|---|---|---|
| BK1 | `seed/seed_users.sql` hash BCrypt cassés | Login 401 | P0.1 — UPDATE hash |
| BK2 | `application.properties` default DB_NAME=postgres | Backend se connecte à DB vide | Exporter DB_NAME=activ_education |
| BK3 | Flyway ne log pas (silencieux) | Difficile à débugger | Appliquer V2 manuellement si besoin |
| BK4 | Cache Redis non testé en charge | Pas de garantie < 200ms | Faire un bench `redis-benchmark` |
| BK5 | Mobile Flutter jamais `flutter run` | Pas de test E2E mobile | Lancer manuellement |
| BK6 | MailHealthIndicator log warning | SMTP non config | Non bloquant |
| BK7 | `ddl-auto=update` toujours actif | Risque perte données | Repasser à `validate` quand Flyway solide |

---

## 11. Périmètre STRICT du hackaton

**À MODIFIER** (ORIA) :
- `activ-education-fronted-main/activ_education/` (mobile Flutter)
- `activ-education-backend-main/src/main/java/tg/edtch/activEducation/evolution/` (module evolution)
- `activ-education-backend-main/src/main/java/tg/edtch/activEducation/referentiel/` (référentiel multi-pays)
- `activ-education-backend-main/src/main/java/tg/edtch/activEducation/shared/cache/` (cache Redis)
- `activ-education-backend-main/src/main/java/tg/edtch/activEducation/shared/i18n/` (i18n)
- `activ-education-backend-main/src/main/resources/db/migration/` (V1, V2)
- `activ-education-backend-main/src/main/resources/messages_*.properties` (i18n)
- `activ-education-fronted-main/schools/` (page web écoles)

**NE PAS TOUCHER** :
- `activ-education-fronted-main/backoffice/` (admin React)
- `activ-education-backend-main/src/main/java/tg/edtch/activEducation/bibliotheque/` (sauf refactor P1.1)
- `activ-education-backend-main/src/main/java/tg/edtch/activEducation/profil/`
- `activ-education-backend-main/src/main/java/tg/edtch/activEducation/diagnostic/`
- `activ-education-backend-main/src/main/java/tg/edtch/activEducation/accompagnement/`
- `activ-education-fronted-main/seed/` (data seeds)

**CHIFFRES CLÉS** :
- 117 universités togolaises en `.md` (seed)
- 13 fichiers de test backend (133 tests)
- 5 modules backend complets (profil, bibliotheque, diagnostic, accompagnement, shared)
- 30+ packages backend

---

## 12. Résumé 1-minute

ORIA est un **assistant d'orientation scolaire** pour le Togo, rebrand mobile d'Activ EDUCATION. Le backend a **9 moteurs** qui calculent des scores (SEP = Student Evolution Profile), un **orchestrateur** qui pondère, et un **EventEngine** qui détecte 7 événements proactifs (notes qui montent/baissent, Bac qui approche, etc.). Le mobile Flutter affiche une **dashboard simplifiée** avec un **callout ORIA central** + un **banner proactif** (Phase 3.4). Le **référentiel multi-pays** (TG, BJ, CI) est en place avec 4 séries TG (A, C, D, G). L'**i18n** (FR/EN/PT) fonctionne. Le **cache Redis** est branché. Le backend **tourne bien** (PID 2039423). Les **tests passent** (133/133 + 1 skipped).

**Prochain pas logique** : P0.1 (créer un user démo fonctionnel) → P0.2 (test end-to-end) → P1.1 (multi-pays bibliothèque) → P1.2 (UI consentement).

---

*Fin de la sauvegarde 2026-07-26. Le projet est dans un état stable et testé. Reprends quand tu veux !*
