# Prompt pour Claude Code — Intégration du dataset et entraînement Phase 5

Tu travailles sur l’application **Activ Education**, une application d’orientation scolaire et universitaire au Togo. Ta mission est d’intégrer le fichier CSV fourni et de préparer correctement le pipeline de prédiction `ADMIS` / `RECALE`.

## Fichier de données

Le fichier principal se trouve ici :

```text
/donnéedataset_synthetique_togo_calibre_60000.csv
```

Il contient environ 58 800 lignes et les colonnes suivantes :

- `student_id` : identifiant synthétique, par exemple `SYNTH_TG_000001` ;
- `donnee_type` : toujours `SYNTHETIQUE_NON_REELLE` dans ce fichier ;
- `profil_type` : `BACHELIER`, `ELEVE_PREMIERE` ou `ETUDIANT` ;
- `annee_academique` : année au format `2021-2022` ;
- `region` : région ou Grand Lomé ;
- `sexe` : `F` ou `M` ;
- `age` : âge numérique ;
- `serie_bac` : série du bac, notamment `A3`, `A4`, `C`, `D`, `E`, `F1`, `F2`, `F3`, `F4`, `G1`, `G2`, `G3`, `Ti1`, `Ti2` ;
- `type_enseignement` : `GENERAL` ou `TECHNIQUE` ;
- `moyenne_bac` : moyenne simulée sur 20 ;
- `note_mathematiques` : note simulée ;
- `note_francais` : note simulée ;
- `note_anglais` : note simulée ;
- `cohorte` : `BAC1`, `BAC2` ou `CONCOURS` ;
- `concours_filiere` : concours ou filière demandée ;
- `etablissement_demande` : établissement demandé ;
- `taux_reference_admission` : taux de référence utilisé pour la simulation ;
- `type_calibrage` : indique si le taux est documentaire ou simulé ;
- `resultat_final` : variable cible, avec `ADMIS` ou `RECALE` ;
- `situation` : description synthétique de la situation ;
- `source_type` : source simulée ou scénario simulé ;
- `source_url` : vide pour ces données synthétiques ;
- `verification_status` : `NON_REEL_NON_VERIFIE`.

## Avertissement essentiel

Ce fichier est **entièrement synthétique**. Il ne représente pas des étudiants réels et ne contient pas de résultats officiels individuels. Les notes, rangs, profils et labels `ADMIS` / `RECALE` ont été générés artificiellement.

Ne jamais présenter les performances obtenues sur ce fichier comme une précision réelle du système d’orientation au Togo.

Le fichier peut être utilisé pour :

1. tester l’importation CSV ;
2. tester le prétraitement ;
3. tester l’encodage des variables catégorielles ;
4. tester l’API de prédiction ;
5. vérifier le pipeline d’entraînement ;
6. détecter les erreurs d’intégration ;
7. préparer le modèle avant l’arrivée de données réelles vérifiées.

## Mission technique

1. Inspecte le projet existant avant toute modification.
2. Identifie le script actuel de Phase 5, notamment les fichiers similaires à :
   - `phase5_export_dataset.py` ;
   - `phase5_train_real.py` ;
   - scripts d’import ou de préparation ML ;
   - endpoints Spring Boot de prédiction.
3. Ne supprime aucune donnée existante et ne remplace pas silencieusement les données réelles.
4. Ajoute un mode explicite `synthetic` ou `SYNTHETIQUE_NON_REELLE`.
5. Sépare clairement le mode test synthétique du mode production réel.

## Préparation des données

Utilise `resultat_final` comme variable cible :

```text
ADMIS = 1
RECALE = 0
```

Variables candidates :

```text
profil_type
annee_academique
region
sexe
age
serie_bac
type_enseignement
moyenne_bac
note_mathematiques
note_francais
note_anglais
cohorte
concours_filiere
etablissement_demande
taux_reference_admission
```

Ne pas utiliser comme variables prédictives :

```text
student_id
resultat_final
situation
source_type
source_url
verification_status
```

Traite également `type_calibrage` avec prudence. Pour une prédiction réaliste, il ne faut pas laisser le modèle apprendre directement qu’une ligne est synthétique ou qu’elle provient d’un scénario particulier.

## Contrôles obligatoires

Avant entraînement, affiche :

1. le nombre de lignes ;
2. le nombre de colonnes ;
3. les valeurs manquantes par colonne ;
4. le nombre de doublons ;
5. la distribution `ADMIS` / `RECALE` ;
6. la distribution par `cohorte` ;
7. la distribution par `serie_bac` ;
8. la distribution par `concours_filiere` ;
9. la distribution par année ;
10. la présence éventuelle de valeurs impossibles, par exemple une note hors de 0–20 ou un âge inférieur à 14 ou supérieur à 60.

Le pipeline doit échouer avec un message clair si :

- `resultat_final` contient d’autres valeurs que `ADMIS` et `RECALE` ;
- les colonnes obligatoires manquent ;
- le dataset est vide ;
- une variable numérique contient des valeurs non convertibles ;
- plus de 5 % des valeurs essentielles sont manquantes sans stratégie documentée.

## Séparation entraînement/test

Utilise une séparation reproductible :

```python
random_state = 42
```

Utilise de préférence :

- 70 % entraînement ;
- 15 % validation ;
- 15 % test ;
- stratification sur `resultat_final`.

Évite toute fuite de données : les transformations comme l’imputation, la standardisation et l’encodage doivent être ajustées uniquement sur les données d’entraînement dans un pipeline scikit-learn.

Si plusieurs lignes représentent un même étudiant dans un futur dataset réel, le même étudiant ne doit jamais apparaître à la fois dans train et test.

## Modèle recommandé

Commence par un modèle simple et explicable :

1. baseline DummyClassifier ;
2. régression logistique ;
3. Random Forest ou Gradient Boosting ;
4. éventuellement HistGradientBoosting si les performances le justifient.

Utilise un `ColumnTransformer` :

- imputation et standardisation pour les variables numériques ;
- imputation et `OneHotEncoder(handle_unknown='ignore')` pour les variables catégorielles.

Ne fais pas de recherche d’hyperparamètres excessive sur ce dataset synthétique : une très bonne performance peut simplement refléter la règle artificielle qui a généré les labels.

## Métriques à produire

Calcule au minimum :

- accuracy ;
- precision ;
- recall ;
- F1-score ;
- ROC-AUC si possible ;
- matrice de confusion ;
- rapport de classification ;
- métriques séparées par `cohorte` et par `serie_bac`.

Affiche un avertissement si les performances sont étonnamment élevées, par exemple F1 supérieur à 0,95. Sur des données synthétiques, ce résultat peut indiquer que le modèle a appris la règle de simulation, et non une relation générale réelle.

## Sorties attendues

Crée un dossier de sortie distinct, par exemple :

```text
/home/ubuntu/collecte_togo_2026/model_output_synthetic/
```

Il doit contenir :

```text
model_synthetic.joblib
metrics_synthetic.json
classification_report_synthetic.txt
confusion_matrix_synthetic.png
feature_importance_synthetic.csv
preprocessing_schema.json
run_metadata.json
```

`run_metadata.json` doit contenir au minimum :

```json
{
  "dataset_type": "SYNTHETIQUE_NON_REELLE",
  "dataset_path": "/home/ubuntu/collecte_togo_2026/dataset_synthetique_togo_calibre_60000.csv",
  "random_state": 42,
  "target": "resultat_final",
  "warning": "Performances non représentatives de données réelles"
}
```

## API de prédiction

Si une API existe déjà, ajoute un mode de test clairement identifiable. La réponse doit contenir :

```json
{
  "prediction": "ADMIS",
  "probability": 0.72,
  "model_mode": "synthetic_test",
  "warning": "Cette prédiction est basée sur des données synthétiques et ne constitue pas une décision officielle."
}
```

L’API ne doit jamais présenter la prédiction comme une admission officielle ou garantie.

## Validation finale

Après l’implémentation :

1. exécute le pipeline complet ;
2. vérifie que le modèle est sauvegardé ;
3. vérifie que les métriques sont écrites ;
4. teste au moins trois requêtes de prédiction ;
5. teste une série inconnue pour vérifier `handle_unknown='ignore'` ;
6. teste une valeur manquante ;
7. teste une valeur invalide et vérifie que l’erreur est claire ;
8. indique exactement quels fichiers ont été créés ou modifiés ;
9. n’affirme jamais que le modèle est prêt pour la production réelle.

## Résultat attendu

À la fin, donne un compte rendu en français avec :

- les fichiers modifiés ;
- la commande d’entraînement ;
- la commande de test ;
- les métriques ;
- les limites liées aux données synthétiques ;
- les prochaines étapes pour remplacer progressivement les données synthétiques par des données réelles vérifiées et pseudonymisées.
