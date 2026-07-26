# Fonctionnalités IA — Activ Education

## Sommaire

1. [ORIA — Assistant IA d'orientation (chat)](#1-oria--assistant-ia-dorientation-chat)
2. [Assistant Vocal (STT / TTS)](#2-assistant-vocal-stt--tts)
3. [OCR Bulletins — Reconnaissance de notes](#3-ocr-bulletins--reconnaissance-de-notes)
4. [Relevé de Notes — Validation BEPC/BAC](#4-relevé-de-notes--validation-bepcbac)
5. [Recommandation IA v1 — Texte LLM](#5-recommandation-ia-v1--texte-llm)
6. [Recommandation 3 Signaux v2 — Algorithmique](#6-recommandation-3-signaux-v2--algorithmique)
7. [Quiz IA — Génération automatique](#7-quiz-ia--génération-automatique)
8. [Recherche Globale IA — Recherche sémantique](#8-recherche-globale-ia--recherche-sémantique)
9. [FAQ RAG — Question/Réponse sur les fiches](#9-faq-rag--questionréponse-sur-les-fiches)
10. [Entretien IA — Simulation d'entretien](#10-entretien-ia--simulation-dentretien)
11. [Modèles ML Prédictifs — ADMIS/REORIENTE](#11-modèles-ml-prédictifs--admismisroiente)
12. [Annexe : Modèles IA utilisés](#12-annexe--modèles-ia-utilisés)

---

## 1. ORIA — Assistant IA d'orientation (chat)

### Description
Chatbot intelligent spécialisé dans l'orientation scolaire au Togo. Répond aux questions sur les filières, métiers, établissements, procédures d'admission.

### Pages
- **Flutter :** `oria_screen.dart` (route `/oria`) — bouton dans le `main_scaffold.dart:119`
- **Backoffice :** `OriaPage.tsx` (routes `/conseiller/oria`, `/admin/oria`)

### Backend
- `OriaController.java` — `POST /api/v1/oria/message`, `GET /api/v1/oria/session/{sessionId}`, `DELETE /api/v1/oria/session/{sessionId}`
- `OriaService.java` — orchestre le chat avec RAG

### Fonctionnement
1. L'utilisateur envoie un message
2. Le message est converti en embedding (`text-embedding-3-small`, 768 dims)
3. Recherche pgvector : top 8 fiches (filières, métiers, établissements, séries) les plus pertinentes
4. Contexte injecté dans le prompt système du LLM
5. Appel LLM avec fallback : **Ollama** (local, `qwen2:0.5b`) → **Groq** (`llama-3.1-8b-instant`) → **OpenAI** (`gpt-4o-mini`)
6. Protection anti-injection : 3 patterns bloqués (`ignore previous`, `jailbreak`, `system prompt`) + liste de mots interdits
7. Session gérée en mémoire (LRU, max 1000 sessions, 20 messages) + persistée en BDD (`oria_messages`)

### Délai
Timeout 120s sur le client Flutter (Dio).

---

## 2. Assistant Vocal (STT / TTS)

### Description
Permet de parler à ORIA au lieu d'écrire. Transcription vocale (STT) et synthèse vocale (TTS).

### Pages
- **Flutter :** `oria_screen.dart` (micro vert dans le champ de saisie) — `voice_service.dart`

### Backend
- `VocalController.java` — 3 endpoints :
  - `POST /api/v1/vocal/transcrire` — audio → texte (Whisper)
  - `POST /api/v1/vocal/chat` — audio → texte → ORIA → réponse audio
  - `POST /api/v1/vocal/synthese` — texte → audio (TTS)
- `VocalService.java` — orchestre STT → ORIA → TTS

### Fonctionnement
1. Côté Flutter : `speech_to_text` (Google STT offline, `fr_FR`), 20s timeout
2. Envoi du fichier audio au backend
3. **Whisper** (`whisper-1`) → transcription texte
4. Texte → ORIA → réponse texte
5. **TTS** (`tts-1`, voix `alloy`) → audio (base64 mp3)
6. Flutter : `flutter_tts` pour lecture locale, ou lecture du mp3 retourné

---

## 3. OCR Bulletins — Reconnaissance de notes

### Description
Extraction automatique des notes à partir de bulletins scolaires (PDF ou image). Permet à l'élève d'importer ses bulletins plutôt que de saisir manuellement.

**Note :** Cette fonctionnalité est disponible côté **mobile** et **backoffice**. La saisie manuelle des notes est retirée du mobile (selon décision d'architecture), mais l'upload OCR reste actif.

### Pages
- **Flutter :** upload bulletins → déclenche OCR → sauvegarde notes → recommandation 3 signaux
- **Backend :** `BulletinUploadController.java`

### Backend
- `OcrController.java` — `POST /api/v1/eleves/{trackingId}/ocr` (OCR seul)
- `OcrService.java` — logique OCR
- `BulletinUploadController.java` — endpoints upload avec OCR intégré

### Fonctionnement
1. **PDF numérique :** extraction texte via **PDFBox** (`PDFTextStripper`)
2. **PDF scanné / image :** rendu en image (150 DPI) → **OpenAI Vision** (`gpt-4o-mini`)
3. Parsing du JSON retourné : `[{matiere, note, coefficient}]`
4. Fallback : extraction par regex si le JSON est invalide
5. Notes sauvegardées dans `notes_historique`
6. Déclenchement automatique de la `Recommandation 3 Signaux`

### Upload batch
3 endpoints :
- `POST /.../bulletins/preview` — OCR sans sauvegarde (validation visuelle)
- `POST /.../bulletins/preview/confirm` — confirmation et sauvegarde
- `POST /.../bulletins` — upload + OCR + sauvegarde directe
- `POST /.../bulletins/batch` — 1 à 3 bulletins en une requête

---

## 4. Relevé de Notes — Validation BEPC/BAC

### Description
Validation automatique des relevés de notes du BEPC et du BAC. Extrait la série, la moyenne, la décision (ADMIS/RECALE) et met à jour le niveau scolaire de l'élève.

### Pages
- **Backoffice :** upload de relevé dans le profil élève

### Backend
- `ReleveNotesController.java` — `POST /api/v1/eleves/{trackingId}/releve-notes`
- `ReleveNotesService.java`

### Fonctionnement
1. PDF → **PDFBox** (texte) ou image → **OpenAI Vision** (`gpt-4o-mini`)
2. Prompt détaillé demandant 11 champs : `typeDocument`, `valide`, `candidat`, `moyenne`, `decision`, `serie`, etc.
3. Si `valide=true` et `moyenne >= 10/20` → **ADMIS**
4. Mise à jour automatique :
   - BEPC admis → `NiveauScolaire = LYCEEN`, `TypeApprenant = LYCEE_2ND`
   - BAC admis série C → `TypeApprenant = BAC_1`
5. Fallback : extraction par regex si l'IA échoue

---

## 5. Recommandation IA v1 — Texte LLM

### Description
Génération d'une recommandation textuelle personnalisée par OpenAI. Prend en compte le profil complet de l'élève (RIASEC, notes, quiz, filière souhaitée, métier souhaité).

### Pages
- **Flutter :** `recommandation_ia_screen.dart` (route `/recommandation-ia`)
  - Accès depuis la page d'accueil ou fallback depuis l'écran 3 signaux

### Backend
- `RecommandationIAController.java` — `GET /api/v1/eleves/{trackingId}/recommandation-ia`
- `RecommandationIAService.java`

### Fonctionnement
1. Agrégation du profil élève : niveau, filière, métier souhaité, matières préférées, notes, quiz RIASEC
2. Récupération des top 10 filières, métiers, établissements depuis la BDD
3. Prompt OpenAI (`gpt-4o-mini`) demandant : 3 filières + 3 métiers + établissements adaptés
4. Retour texte formaté affiché dans une carte gradient
5. Si profil vide → message invitant à compléter le profil

---

## 6. Recommandation 3 Signaux v2 — Algorithmique

*(Documenté en détail dans `module_prediction.md`)*

### Description
Moteur de recommandation structuré combinant 3 signaux pondérés : aspiration (RIASEC), réalité (notes), engagement (comportemental).

### Pages
- **Flutter :** `recommandation_3_signaux_screen.dart` (route `/recommandation-3-signaux`)
- **Backoffice :** `ParametresPage.tsx` (configuration des poids)

### Backend
- `RecommandationIAController.java` — `GET /api/v1/eleves/{trackingId}/recommandation-ia/v2`
- `Recommandation3SignauxServiceImpl.java`

### Formule
```
score_final = 0.35 × aspiration + 0.50 × réalité + 0.15 × engagement
               (engagement plafonné à 0.20)
```

### Affichage Flutter
- Header : profil RIASEC, dernière moyenne, projection, confiance, poids
- Top 10 cartes avec 3 barres de progression (bleu/vert/jaune)
- Badge "Découverte" pour les filières peu consultées mais prometteuses

---

## 7. Quiz IA — Génération automatique

### Description
Génération de QCM (5 questions) à partir du contenu d'une fiche (filière, métier, établissement). Quiz caché en BDD, régénéré si absent.

### Pages
- **Flutter :** `fiche_detail_screen.dart:680` — bouton "Générer un quiz"

### Backend
- `QuizGenerationController.java` — `POST /api/v1/quiz/generate`
- `QuizGenerationServiceImpl.java`

### Fonctionnement
1. Vérification cache : si un `QuizIA` existe déjà pour cette fiche, retour direct
2. Sinon, envoi du contenu de la fiche à `AIEmbeddingService.generateQuizQuestions()`
3. Prompt OpenAI (`gpt-4o-mini`, `response_format: json_object`) → 5 questions QCM
4. Parsing JSON → création des entités `Question` + `Reponse`
5. Sauvegarde dans `QuizIA` (trackingId → cache)
6. Fallback si pas de clé API : extraction de phrases + trous + distracteurs génériques

---

## 8. Recherche Globale IA — Recherche sémantique

### Description
Recherche vectorielle (pgvector) sur toutes les fiches (filières, métiers, établissements, séries). Permet de trouver du contenu par similarité sémantique, pas seulement par mot-clé.

### Pages
- **Flutter :** barre de recherche dans la bibliothèque

### Backend
- `RechercheGlobaleController.java` — `GET /api/v1/bibliotheque/recherche-fiche-ia/globale?phrase=...`
- `RechercheGlobaleServiceImpl.java`

### Fonctionnement
1. Phrase utilisateur → `AIEmbeddingService.generateEmbedding()` → vecteur float 768d
2. SQL natif pgvector : `ORDER BY embedding <=> CAST(:vecteur AS vector)`
3. Hydratation des entités (héritage JOINED → requête en 2 phases : d'abord les IDs, puis JPQL)
4. Mapping en `RechercheGlobaleResponse` avec type (`METIER`, `FILIERE`, `ETABLISSEMENT`, `SERIE`)

### Embeddings générés à la création/édition de chaque fiche
- `FicheFiliereServiceImpl.java`
- `FicheMetierServiceImpl.java`
- `FicheEtablissementServiceImpl.java`
- `FicheSerieServiceImpl.java`
- `EntreeFAQServiceImpl.java`

---

## 9. FAQ RAG — Question/Réponse sur les fiches

### Description
Réponse à une question libre en utilisant les FAQ comme source de connaissance. Pipeline RAG complet : embedding → recherche → synthèse LLM.

### Pages
- **Flutter :** champ "Poser une question" dans la FAQ

### Backend
- `EntreeFAQController.java` — `GET /api/v1/bibliotheque/faq/recherche-ia?question=...`
- `EntreeFAQServiceImpl.java`

### Fonctionnement
1. Question → embedding (`text-embedding-3-small`)
2. pgvector : recherche des FAQ les plus proches (`<=>` operator)
3. Contexte formaté + question → `AIEmbeddingService.generateAnswer()`
4. Réponse synthétisée par `gpt-4o-mini`

---

## 10. Entretien IA — Simulation d'entretien

### Description
Simulation d'entretien d'embauche pour un métier choisi. 5 questions générées par IA, évaluation de chaque réponse (note 0-20 + feedback), et appréciation finale.

### Pages
- **Flutter :** `entretien_screen.dart` — choix du métier → 5 questions → résultats

### Backend
- `EntretienController.java` :
  - `POST /api/v1/entretien/start` — démarre une session
  - `POST /api/v1/entretien/{sessionId}/repondre` — soumet une réponse
  - `GET /api/v1/entretien/{sessionId}/resultat` — récupère les résultats
- `EntretienService.java`

### Fonctionnement
1. L'utilisateur choisit un métier
2. OpenAI (`gpt-4o-mini`, temp=0.7) génère 5 questions spécifiques au métier (contexte togolais)
3. Chaque réponse est évaluée : note 0-20 + feedback constructif
4. Après les 5 questions : appréciation récapitulative
5. Session persistée dans `SimulationEntretien`

---

## 11. Modèles ML Prédictifs — ADMIS/REORIENTE

*(Documenté en détail dans `module_prediction.md`)*

### Description
Modèles supervisés prédisant la réussite d'un élève (ADMIS vs REORIENTE) dans une filière donnée.

### Scripts Python
- `generate_synthetic_data.py` — 600 profils synthétiques
- `train_model.py` — entraînement GradientBoosting + LogisticRegression
- `phase5_export_dataset.py` — export dataset réel depuis l'API
- `phase5_train_real.py` — entraînement sur données réelles (≥ 5000)

### Backend
- `PredictionDatasetController.java` — `GET /api/v1/admin/prediction/dataset` (CSV)
- `PredictionController.java` — `GET/POST /api/v1/eleves/{id}/predictions`
- `OrientationOutcomeController.java` — suivi des résultats réels

### Modèles
| Modèle | Features | Fichier |
|--------|----------|---------|
| `gb_sans_comportemental` | RIASEC + notes + score_60_40 + match_riasec | `models/gb_sans_comportemental.joblib` |
| `gb_avec_comportemental` | + consultations + favori + similarité recherche | `models/gb_avec_comportemental.joblib` |

### 7 niveaux (COLLEGE → BAC_3)
Prédiction par filière, avec test "bulle de filtre" : vérifie que le signal comportemental ne tire pas artificiellement des élèves faibles vers ADMIS.

---

## 12. Annexe : Modèles IA utilisés

| Modèle | Usage | Fournisseur | Coût / Limites |
|--------|-------|-------------|----------------|
| `gpt-4o-mini` | Chat ORIA, recommandation v1, quiz, entretien, OCR, relevé notes, FAQ RAG | **OpenAI** | Clé dans `.env` |
| `text-embedding-3-small` | Embeddings 768d (recherche, RAG, similarité) | **OpenAI** | 768 dimensions |
| `whisper-1` | Transcription vocale (STT) | **OpenAI** | Fichiers audio |
| `tts-1` | Synthèse vocale (TTS), voix `alloy` | **OpenAI** | Base64 mp3 |
| `llama-3.1-8b-instant` | Fallback ORIA | **Groq** | Clé dans `.env` |
| `qwen2:0.5b` | Fallback ORIA local | **Ollama** | Local, lent |
| PDFBox | Extraction texte PDF (numérique) | Apache | Pas d'API |
| Cosine similarity | Moteur 3 signaux (aspiration RIASEC) | Algorithmique | Pas d'IA |

### Provider (OpenAIEmbeddingServiceImpl.java)
Chaîne de fallback pour le chat ORIA : `Ollama (local)` → `Groq` → `OpenAI`. Pour les embeddings et autres features : **OpenAI uniquement** (pas de fallback).

### Clés API (`.env`)
- `OPENAI_API_KEY` — OpenAI (obligatoire)
- `GROQ_API_KEY` — Groq (fallback)
- Ollama : local, pas de clé
