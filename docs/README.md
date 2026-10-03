# Documentation Activ'Education

Structure de la documentation du projet.

## Arborescence

```
docs/
├── architecture/      # Architecture technique, API, schémas DB
├── design/            # Design, charte graphique, maquettes
├── guides/            # Guides de développement, déploiement, prompts
├── ml/                # Machine Learning, modèles de prédiction
├── reports/           # Rapports de sessions, journal de bord, changelog
├── specs/             # Spécifications fonctionnelles et techniques
└── seed/              # Données de seed, universités, prompts d'import
    ├── frontend/      # Prompts et scripts frontend
    └── universites/   # Fiches établissements (copiées depuis frontend/seed)
```

## Catégories principales

### Architecture (`architecture/`)
- `api-endpoints.md` - Liste des endpoints API
- `audit_endpoints.md` / `audit_endpoints_v2.md` - Audit des endpoints
- `CHANGES_BACKEND.md` - Changements backend
- `CHANGELOG_SCHEMA.md` - Changelog schéma DB

### Design (`design/`)
- `CHARTE_GRAPHIQUE.md` - Charte graphique
- `DESIGN_ORIA_ACTUEL.md` - Design actuel ORIA
- `BRIEF_DESIGN_CHATGPT.md` - Brief design
- `BACKOFFICE_pages.md` / `MOBILE_pages.md` - Maquettes textuelles
- `DIRECTIVES_MAQUETTISTE.md` - Directives pour maquettiste
- `maquettes_specs.md` - Spécifications maquettes

### Guides (`guides/`)
- `AGENTS.md` - Configuration agents IA
- `CLAUDE.md` / `instructions_claude.md` - Instructions Claude
- `DEPLOY.md` - Guide déploiement
- `PROMPT_CLAUDE_CODE_MODULE_PREDICTION.md` - Prompt module prédiction
- `prompt_*.md` - Divers prompts de développement

### Machine Learning (`ml/`)
- `RESULTATS_PROTOTYPE.md` - Résultats prototype prédiction

### Rapports (`reports/`)
- `RAPPORT_SESSION_2026-07-17.md` - Rapport session
- `STATE_SAVE_2026-07-26.md` - Sauvegarde état
- `session-ses_*.md` - Sessions de travail
- `JOURNAL_BORD_IA.md` - Journal de bord IA
- `CHANGELOG.md` - Changelog projet
- `memoire_oria_education.md` - Mémoire projet
- `rapport-2026-05-20.md` - Rapport mai 2026
- `etat-projet.md` - État du projet
- `valeur_ajoutee_memoire.md` - Valeur ajoutée mémoire

### Spécifications (`specs/`)
- `DESCRIPTION_PROJET.md` - Description projet
- `cahierdecharge.md` / `cahier_de_charge.md` - Cahier des charges
- `cahier_charge_fonctionnel.md` - Cahier charges fonctionnel
- `cahier_charge_technique.md` - Cahier charges technique
- `specification_techinique.md` - Spécifications techniques
- `FONCTIONNALITES.md` - Fonctionnalités
- `problematique.md` - Problématique

### Seed (`seed/`)
- `module_prediction.md` - Module prédiction
- `fonctionnalites_ia.md` - Fonctionnalités IA
- `universites/` - Fiches détaillées établissements (200+ fichiers)