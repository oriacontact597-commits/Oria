# Présentation — Activ Education / Oria
> Format : 10 slides, ~10 minutes. Une idée par slide. Phrases courtes à dire, pas à lire.

---
## Slide 1 — Titre (30s)
**Activ Education / Oria : l'orientation intelligente pour les jeunes Togolais**
- Plateforme mobile + backoffice + API
- HubCity / Woélab — 2025-2026
- Slogan : « Réussir ton orientation commence par le bon diagnostic »
- À afficher : logo, 3 visuels (mobile, backoffice, ORIA)

> Dire : on résout le manque de conseillers par une app gratuite, locale, IA + humain.

---
## Slide 2 — Problème (1 min)
- 1 conseiller pour 5 000 élèves (norme 1/300)
- Offre de formation dispersée, pas de base centrale
- Orientation = série scolaire seulement, pas de personnalité / notes / goûts
- Opportunité : >80% de smartphones chez les jeunes

> Dire : question centrale — comment orienter chaque jeune, partout, à faible coût ?

---
## Slide 3 — Solution en 1 schéma (1 min)
```
Mobile Flutter ─┐
                ├─ REST/JWT ─> Spring Boot 4 (:8080) ─> Postgres+pgvector / MinIO / Redis / IA
Backoffice React┘
```
- 5 modules : Profils, Bibliothèque, Diagnostic, Accompagnement, Admin
- 3 clients, 1 seul backend (~179 endpoints)

> Dire : 1 API, 2 frontends, infra open source.

---
## Slide 4 — Parcours élève (1 min)
1. Explorer : séries, filières, métiers, 117 établissements, recherche sémantique
2. Diagnostiquer : quiz RIASEC adaptatif + OCR bulletins
3. Recommander : top 10 filières personnalisé
4. Accompagner : chat, RDV visio Jitsi, FAQ IA, ORIA vocal
5. Valoriser : portfolio, badges, CV, attestations, alumni/mentorat

> Démo : recherche « travailler dans la nature » → fiches + RDV conseiller.

---
## Slide 5 — Moteur IA (1 min)
- Recommandation v2 : `50% réalité (notes/seuil) + 35% aspiration (RIASEC) + 15% engagement`
- Anti bulle de filtre : découvertes garanties
- RAG pgvector 768 dim + cosinus, cascade Ollama → Groq → OpenAI
- OCR Vision + Whisper/TTS pour zones rurales / faible littératie

> Dire : l'IA propose, l'humain décide. Plafond engagement validé par ML.

---
## Slide 6 — Résultats ML (1 min)
- Prototype 600 élèves synthétiques, ROC-AUC 0.89 (logreg)
- Variables reines : écart notes/seuil, notes actuelles, match RIASEC
- Comportemental = pas de gain → plafonné, pas de bulle détectée
- Phase 5 : besoin ≥5 000 outcomes réels pour production

> Dire : le 60/40 puis 50/35/15 est un baseline solide, prouvé.

---
## Slide 7 — Backoffice (45s)
- Conseiller : file questions, RDV, compte-rendus, dispos
- Admin : CRUD fiches (brouillon→publié), quiz drag&drop, seuils, FAQ, stats export PDF/Excel
- Super-admin : paramètres, logs audit, maintenance, monitoring Prometheus/Grafana

> Dire : les contenus évoluent sans développeur.

---
## Slide 8 — Tech & Sécurité (1 min)
- Backend : Spring Boot 4.0.5, Java 21, JPA JOINED, UUID trackingId, JWT 15min + refresh 7j, 2FA TOTP, BCrypt 12, rate-limit Redis, 3 couches (SecurityConfig → @PreAuthorize → @security)
- Mobile : Flutter, Dio+JWT, 55 écrans, polling chat
- Web : React 19, TS6 strict, Vite, Query+Zustand+Tailwind
- Docker : API 8080, Postgres 5432/5433, MinIO 9000/9001, Redis 6379

> Dire : stack moderne, open source, conteneurisée.

---
## Slide 9 — État & limites honnêtes (45s)
- Fait : Phases 1-4, CRUD complets, sécurité, RAG, seeds 117 universités, Docker, CI
- Reste : Phase 5 réelle, WebSocket chat, Flyway (actuel update risqué), tests backoffice, écrans 404/offline, Google Sign-In
- Risques : secrets commités à rotationner, RAG désactivé par défaut + mismatch 10 vs 8 ids à réparer

> Dire : on montre ce qui marche, on assume le reste en roadmap.

---
## Slide 10 — Impact & Appel (30s)
- Cibles : 50k actifs/mois, satisfaction >4/5, 60% autonome via ORIA, 30% rural
- Bénéfices : élèves autonomes, conseillers démultipliés, décideurs avec DataHub
- Next : pilote collèges/lycées → 5 000 outcomes → ML réel → cloud
- Contact + QR démo (Swagger `/swagger-ui.html`, mobile, backoffice)

> Finir par : « Et si chaque jeune Togolais avait son conseiller dans la poche ? »

---
### Annexe — Anti-sèche démo (ne pas projeter)
1. `docker compose up -d db minio redis` + `./mvnw spring-boot:run`
2. Seed : users → bibliothèque → quiz → universités
3. Parcours : login élève → quiz → explorer → recommandation v2 → chat/RDV → backoffice validation
4. Secours si offline : captures + `results_prototype.json`
