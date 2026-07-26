# Module Prédiction & Recommandation

## Architecture générale

Deux couches distinctes :

1. **Moteur 3 signaux** (Phase 3 — actif en prod) → recommandation temps réel
2. **Modèles ML supervisés** (Phase 5 — prototypé, pas encore en prod) → prédiction ADMIS/REORIENTE

---

## 1. Moteur 3 signaux

### Endpoint

```
GET /api/v1/eleves/{eleveTrackingId}/recommandation-ia/v2
```

**Backend :**
- `Recommandation3SignauxServiceImpl.java` — cœur du moteur
- `Recommandation3SignauxController.java` — point d'entrée REST

**Frontend Flutter :**
- `recommandation_3_signaux_screen.dart` — écran "Recommandations 3 signaux"
- `prediction_service.dart` — client HTTP (`recommander3Signaux(id)`)

**Backoffice :**
- `ParametresPage.tsx:309` — configuration des poids (super-admin)

### Niveaux supportés

7 niveaux (enum `NiveauScolaire`) :

| Code | Libellé |
|------|---------|
| `COLLEGE` | 6e, 5e, 4e, 3e |
| `LYCEE_2ND` | Seconde |
| `LYCEE_1ERE` | Première |
| `LYCEE_TLE` | Terminale |
| `BAC_1` | Bac+1 (L1, BTS 1) |
| `BAC_2` | Bac+2 (L2, BTS 2) |
| `BAC_3` | Bac+3 (Licence) |

### Algorithme

```
score_final = 0.35 × aspiration + 0.50 × réalité + 0.15 × engagement
               (engagement plafonné à 0.20)
```

#### Signal 1 — Aspiration (RIASEC)

Similarité cosinus entre le profil RIASEC de l'élève et celui de la filière.

**Source élève :** dernier `TestRIASECResultat` (6 dimensions : R, I, A, S, E, C, normalisées `/10`)

**Source filière :** `ProfilFiliereRiasecCatalog.java` — catalogue statique de 15 profils :
- Sciences/tech : `informatique` [0.80,0.95,0.30,0.30,0.40,0.60], `mathématiques`, `physique`, `genie civil`, `genie electrique`
- Santé : `medecine` [0.55,0.95,0.30,0.90,0.40,0.80], `pharmacie`, `biologie`, `sante`
- Lettres/droit : `droit` [0.30,0.70,0.50,0.85,0.80,0.85], `lettres`, `communication`, `psychologie`
- Gestion/éco : `gestion` [0.40,0.55,0.40,0.80,0.95,0.85], `economie`, `commerce`, `comptabilite`

Recherche par `containsIgnoreCase` — fallback profil neutre [0.5, 0.5, 0.5, 0.5, 0.5, 0.5].

**Calcul :**
```java
cosinus = dot(a, b) / (norm(a) * norm(b))  // borné [0, 1]
```

#### Signal 2 — Réalité (notes)

Rapport entre la note projetée et le seuil d'admission de la filière.

**Données :** 3 dernières moyennes générales annuelles (`NotesHistorique`)

**Trajectoire :** `NoteTrajectoireServiceImpl.java`
- 3 points : régression linéaire (moindres carrés) → note extrapolée = `intercept + pente × 3`
- 2 points : pente simple → `n1 + (n1 - n0)`
- 1 point : pas de projection, confiance 0.5

**Confiance trajectoire :**
- 3 notes → `confiance = 1.0`
- 2 notes → `confiance = 0.7`
- 1 note → `confiance = 0.5`
- 0 note → `confiance = 0.0`

**Calcul :**
```python
ratio = min(1, note_extrapolée / seuil_admission)
bonus = +0.05 si pente > 0
score = max(0, ratio + bonus)
```
Seuil par défaut : `12/20` (`PredictionProperties.seuilAdmissionDefaut`)

#### Signal 3 — Engagement (comportemental)

**Données :** `EngagementSignal` (entité JPA) — agrégat par (élève, fiche) consolidé par batch quotidien.

Champs :
- `nb_consultations` — nombre de consultations de la fiche
- `en_favori` — booléen mis en favori
- `score_similarite_recherche` — similarité cosinus entre la dernière recherche RAG et l'embedding de la fiche

**Calcul :**
```java
raw = 0.1 × min(5, consultations) + 0.5 × enFavori + 0.3 × similarité
score = 1 - exp(-raw)  // sigmoid-like, borné [0, 1]
```

#### Combinaison

```java
score_final = aspiration × poidsAspiration
            + realite × poidsRealite
            + engagement × poidsEngagementEffectif
```

**Poids effectifs (configurables) :**

| Propriété | Défaut | Plafond | Rôle |
|-----------|--------|---------|------|
| `poidsAspiration` | 0.35 | 1.0 | Profil RIASEC |
| `poidsRealite` | 0.50 | 1.0 | Notes académiques |
| `poidsEngagement` | 0.15 | 0.20 | Comportemental (plafonné anti-bulle) |

Le plafond `poidsEngagementMax = 0.20` est un garde-fou : même si un admin configure 0.50, le moteur utilise `min(0.50, 0.20) = 0.20`.

### Découvertes

Mécanisme anti **bulle de filtre** : 2 filières "découverte" forcées dans le top N.

**Critères :**
- Hors du top N initial
- `score_aspiration ≥ 0.60` (bon profil RIASEC)
- `score_engagement ≤ 0.10` (peu consultée — l'élève ne la connaît pas)

Affichées avec un badge "Découverte — à explorer" dans l'UI.

### Filtrage par niveau

Un élève de Terminale voit les filières des niveaux `{LYCEE_TLE, BAC_1, BAC_2, BAC_3}`.

Les candidats sont déterminés via la table `NiveauFiliere` (many-to-many entre `FicheFiliere` et `NiveauScolaire`).

### Parcours utilisateur Flutter

1. `selection_niveau_screen.dart` → l'élève choisit son niveau (`PUT /api/v1/eleves/{id}`)
2. `bulletins_historique_screen.dart` → saisit ses 3 dernières moyennes (`POST /api/v1/eleves/{id}/notes-historique`)
3. `recommandation_3_signaux_screen.dart` → affiche le top 10 avec 3 barres de progression + score final

Si pas de notes : message "Renseigne ton niveau et tes 3 dernières moyennes".

---

## 2. Modèles ML supervisés (Phase 5)

### Scripts Python

| Fichier | Rôle |
|---------|------|
| `generate_synthetic_data.py` | Génère 600 profils synthétiques (Phase 0) |
| `train_model.py` | Entraîne et compare 2 configs × 2 modèles |
| `phase5_export_dataset.py` | Exporte le dataset réel depuis l'API (`GET /api/v1/admin/prediction/dataset`) |
| `phase5_train_real.py` | Entraîne sur données réelles (≥ 5 000 `orientation_outcome`) |

### Niveaux supportés

Identiques au moteur 3 signaux (COLLEGE → BAC_3), plus 8 filières simulées :

| Filière | Seuil | RIASEC attendu |
|---------|-------|----------------|
| Informatique | 12 | [0.7, 0.8, 0.2, 0.1, 0.3, 0.4] |
| Medecine | 15 | [0.3, 0.9, 0.1, 0.6, 0.2, 0.5] |
| Droit | 12 | [0.1, 0.5, 0.2, 0.5, 0.6, 0.7] |
| Genie_Civil | 13 | [0.8, 0.6, 0.1, 0.1, 0.4, 0.6] |
| Communication | 10 | [0.1, 0.3, 0.8, 0.6, 0.5, 0.2] |
| Gestion_Commerce | 10 | [0.1, 0.2, 0.2, 0.4, 0.9, 0.6] |
| Agronomie | 11 | [0.7, 0.5, 0.1, 0.3, 0.3, 0.3] |
| Lettres | 10 | [0.1, 0.6, 0.9, 0.5, 0.2, 0.3] |

### Variables (features)

**Catégorielles :** `serie`, `filiere_choisie`, `niveau_actuel`

**Numériques (sans_comportemental) :**
- RIASEC : `riasec_R`, `riasec_I`, `riasec_A`, `riasec_S`, `riasec_E`, `riasec_C`
- Notes : `notes_n2`, `notes_n1`, `notes_actuelle`, `tendance_notes`
- Synthétiques : `moyenne_generale`, `score_60_40`, `match_riasec`, `ecart_notes_seuil`

**Ajout (avec_comportemental) :**
- `nb_consultations`, `en_favori`, `score_similarite_recherche`

### Modèles

| Modèle | Classe | Paramètres |
|--------|--------|------------|
| Régression logistique | `LogisticRegression` | `max_iter=2000, class_weight=balanced` |
| Gradient Boosting | `GradientBoostingClassifier` | `random_state=42` |

### Cible

Binaire : `ADMIS = 1` vs `REORIENTE = 0`

### Pipeline d'entraînement

```bash
# 1. Génération synthétique (Phase 0)
python3 generate_synthetic_data.py
# → orientation_outcome_synthetic.csv (600 lignes)

# 2. Entraînement prototype
python3 train_model.py
# → models/gb_sans_comportemental.joblib
# → models/gb_avec_comportemental.joblib
# → results_prototype.json

# 3. Phase 5 (données réelles, ≥ 5000 orientation_outcome)
python3 phase5_export_dataset.py --token "$JWT" --out real_dataset.csv
python3 phase5_train_real.py --csv real_dataset.csv
# → results_phase5.json
```

### Mécanisme de vérité synthétique

```python
logit = 2.5 × match_riasec + 0.35 × ecart_notes + 0.5 × bonus_trajectoire - 1.5
proba_reussite = 1 / (1 + exp(-logit))
reussite = 1 if (proba_reussite + bruit_normal(0, 0.15)) > 0.5 else 0
```

Les poids (2.5, 0.35, 0.5) sont les vrais coefficients que le modèle doit retrouver.

### Résultats prototype attendus (synthétique)

Le test "bulle de filtre" vérifie que l'ajout du signal comportemental ne fait pas passer artificiellement des élèves académiquement faibles en `ADMIS` prédit. La sous-population `ecart_notes_seuil < 0` doit garder un taux d'ADMIS prédit proche du taux réel.

---

## 3. Endpoints API

| Méthode | Route | Rôle | Controller |
|---------|-------|------|------------|
| GET | `/api/v1/eleves/{id}/recommandation-ia/v2` | Moteur 3 signaux | `RecommandationIAController.java` |
| GET | `/api/v1/eleves/{id}/recommandation-ia` | Conseil IA textuelle (v1) | `RecommandationIAController.java` |
| GET | `/api/v1/niveaux` | Liste des niveaux | `NiveauController.java` |
| GET | `/api/v1/filieres?niveau={niveau}` | Filières par niveau | `FilierePourNiveauController.java` |
| GET | `/api/v1/eleves/{id}/predictions` | Historique prédictions | `PredictionController.java` |
| POST | `/api/v1/eleves/{id}/predictions` | Sauvegarder prédiction | `PredictionController.java` |
| POST | `/api/v1/eleves/{id}/orientation-outcome` | Créer suivi orientation | `OrientationOutcomeController.java` |
| GET | `/api/v1/eleves/{id}/orientation-outcome` | Lister suivis | `OrientationOutcomeController.java` |
| PATCH | `/api/v1/eleves/{id}/orientation-outcome/{oid}` | Maj statut (ADMIS/RECALE/ABANDON/REORIENTE) | `OrientationOutcomeController.java` |
| GET | `/api/v1/admin/prediction/dataset` | Export CSV dataset (ADMIN) | `PredictionDatasetController.java` |

## 4. Tables JPA

| Table | Entité | Rôle |
|-------|--------|------|
| `engagement_signal` | `EngagementSignal.java` | Signal comportemental par (élève, fiche) |
| `predictions_reussite` | `PredictionReussite.java` | Snapshot d'une prédiction émise |
| `orientation_outcome` | `OrientationOutcome.java` | Résultat réel d'orientation (ADMIS/RECALE/ABANDON/REORIENTE) |

## 5. Configuration

`application.properties` (préfixe `app.prediction.*`) :

```properties
app.prediction.poids-aspiration=0.35
app.prediction.poids-realite=0.50
app.prediction.poids-engagement=0.15
app.prediction.poids-engagement-max=0.20
app.prediction.top-n=10
app.prediction.decouvertes-min=2
app.prediction.seuil-admission-defaut=12
```

Modifiable dans le backoffice (super-admin) via `ParametresPage.tsx`.
