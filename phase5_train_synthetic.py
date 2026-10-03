import pandas as pd
import numpy as np
import json
import os
from pathlib import Path
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime

from sklearn.model_selection import train_test_split, StratifiedKFold
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.dummy import DummyClassifier
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
    roc_auc_score, confusion_matrix, classification_report, roc_curve, auc
)
import joblib

# =============================================================================
# CONFIGURATION
# =============================================================================
DATASET_PATH = "/home/grace/hackaton/donnée/dataset_synthetique_togo_calibre_60000.csv"
OUTPUT_DIR = Path("/home/grace/hackaton/model_output_synthetic/")
RANDOM_STATE = 42

# Variables candidates définies dans le prompt
NUMERIC_FEATURES = [
    "age", "moyenne_bac", "note_mathematiques", "note_francais",
    "note_anglais", "taux_reference_admission"
]
CATEGORICAL_FEATURES = [
    "profil_type", "annee_academique", "region", "sexe",
    "serie_bac", "type_enseignement", "cohorte",
    "concours_filiere", "etablissement_demande"
]
TARGET = "resultat_final"

# =============================================================================
# 1. CHARGEMENT ET CONTRÔLES OBLIGATOIRES
# =============================================================================
def perform_mandatory_checks(df):
    print("\n" + "="*60)
    print("CONTRÔLES OBLIGATOIRES DU DATASET")
    print("="*60)

    # 1 & 2. Nombre de lignes et colonnes
    n_rows, n_cols = df.shape
    print(f"Nombre de lignes : {n_rows}")
    print(f"Nombre de colonnes : {n_cols}")

    # 3. Valeurs manquantes
    print("\nValeurs manquantes par colonne :")
    print(df.isnull().sum())

    # 4. Doublons
    n_dups = df.duplicated().sum()
    print(f"\nNombre de doublons : {n_dups}")

    # 5. Distribution ADMIS / RECALE
    if TARGET not in df.columns:
        raise ValueError(f"Colonne cible {TARGET} manquante !")

    dist_target = df[TARGET].value_counts()
    print("\nDistribution cible :")
    print(dist_target)

    # Vérification des valeurs de la cible
    valid_targets = {"ADMIS", "RECALE"}
    actual_targets = set(df[TARGET].unique())
    if not actual_targets.issubset(valid_targets):
        raise ValueError(f"Valeurs invalides dans {TARGET} : {actual_targets - valid_targets}")

    # 6, 7, 8, 9. Distributions
    for col in ["cohorte", "serie_bac", "concours_filiere", "annee_academique"]:
        if col in df.columns:
            print(f"\nDistribution par {col} :")
            print(df[col].value_counts().head(10))

    # 10. Valeurs impossibles
    print("\n--- Vérification des valeurs aberrantes ---")
    # Notes 0-20
    note_cols = [c for c in df.columns if "note_" in c or c == "moyenne_bac"]
    for col in note_cols:
        if pd.api.types.is_numeric_dtype(df[col]):
            out_of_range = df[(df[col] < 0) | (df[col] > 20)]
            if not out_of_range.empty:
                print(f"⚠️ {col} : {len(out_of_range)} valeurs hors plage [0, 20]")

    # Âge 14-60
    if "age" in df.columns and pd.api.types.is_numeric_dtype(df["age"]):
        out_of_age = df[(df["age"] < 14) | (df["age"] > 60)]
        if not out_of_age.empty:
            print(f"⚠️ age : {len(out_of_age)} valeurs hors plage [14, 60]")

    # Validation finale du dataset
    if n_rows == 0:
        raise ValueError("Le dataset est vide !")

    essential_cols = NUMERIC_FEATURES + CATEGORICAL_FEATURES + [TARGET]
    missing_cols = [c for c in essential_cols if c not in df.columns]
    if missing_cols:
        raise ValueError(f"Colonnes obligatoires manquantes : {missing_cols}")

    # Vérification des types numériques
    for col in NUMERIC_FEATURES:
        if not pd.api.types.is_numeric_dtype(df[col]):
            try:
                df[col] = pd.to_numeric(df[col])
            except Exception:
                raise ValueError(f"Variable numérique non convertible : {col}")

    print("\n✅ Tous les contrôles obligatoires sont passés.")
    return df

# =============================================================================
# 2. PRÉPARATION ET PIPELINE
# =============================================================================
def build_ml_pipeline(model):
    numeric_transformer = Pipeline(steps=[
        ('imputer', SimpleImputer(strategy='median')),
        ('scaler', StandardScaler())
    ])

    categorical_transformer = Pipeline(steps=[
        ('imputer', SimpleImputer(strategy='constant', fill_value='missing')),
        ('onehot', OneHotEncoder(handle_unknown='ignore'))
    ])

    preprocessor = ColumnTransformer(
        transformers=[
            ('num', numeric_transformer, NUMERIC_FEATURES),
            ('cat', categorical_transformer, CATEGORICAL_FEATURES)
        ])

    return Pipeline(steps=[('preprocessor', preprocessor),
                            ('model', model)])

def run_experiment(X_train, X_val, X_test, y_train, y_val, y_test, model_name, model_obj):
    print(f"\nEntraînement du modèle : {model_name}...")

    clf = build_ml_pipeline(model_obj)
    clf.fit(X_train, y_train)

    # Evaluation sur le set de test
    preds = clf.predict(X_test)
    probas = clf.predict_proba(X_test)[:, 1]

    metrics = {
        "accuracy": accuracy_score(y_test, preds),
        "precision": precision_score(y_test, preds),
        "recall": recall_score(y_test, preds),
        "f1": f1_score(y_test, preds),
        "roc_auc": roc_auc_score(y_test, probas),
    }

    # Avertissement performance trop élevée
    if metrics["f1"] > 0.95:
        print(f"⚠️ ATTENTION : Performance étonnamment élevée (F1={metrics['f1']:.3f}) sur données synthétiques.")

    return clf, metrics, preds, probas

# =============================================================================
# 3. EXECUTION PRINCIPALE
# =============================================================================
def main():
    # Chargement
    df = pd.read_csv(DATASET_PATH)

    # Contrôles
    df = perform_mandatory_checks(df)

    # Target encoding
    df['target'] = df[TARGET].map({"ADMIS": 1, "RECALE": 0})

    # Séparation Train / Val / Test (70% / 15% / 15%)
    X = df[NUMERIC_FEATURES + CATEGORICAL_FEATURES]
    y = df['target']

    # 1. Split Train (70%) vs Temp (30%)
    X_train, X_temp, y_train, y_temp = train_test_split(
        X, y, test_size=0.30, random_state=RANDOM_STATE, stratify=y
    )

    # 2. Split Temp into Val (15%) and Test (15%)
    X_val, X_test, y_val, y_test = train_test_split(
        X_temp, y_temp, test_size=0.50, random_state=RANDOM_STATE, stratify=y_temp
    )

    print(f"\nRépartition : Train({len(X_train)}), Val({len(X_val)}), Test({len(X_test)})")

    # Modèles à tester
    models_to_test = {
        "Dummy": DummyClassifier(strategy="stratified"),
        "LogisticRegression": LogisticRegression(max_iter=1000, class_weight="balanced"),
        "RandomForest": RandomForestClassifier(n_estimators=100, random_state=RANDOM_STATE),
        "GradientBoosting": GradientBoostingClassifier(random_state=RANDOM_STATE)
    }

    best_model = None
    best_f1 = -1
    final_metrics = {}

    for name, obj in models_to_test.items():
        clf, m, p, pr = run_experiment(X_train, X_val, X_test, y_train, y_val, y_test, name, obj)
        final_metrics[name] = m
        if m["f1"] > best_f1:
            best_f1 = m["f1"]
            best_model = clf
            best_model_name = name

    print(f"\nMeilleur modèle : {best_model_name} (F1: {best_f1:.3f})")

    # --- SAUVEGARDE DES RESULTATS ---
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # 1. Modèle
    joblib.dump(best_model, OUTPUT_DIR / "model_synthetic.joblib")

    # 2. Métriques
    with open(OUTPUT_DIR / "metrics_synthetic.json", "w", encoding="utf-8") as f:
        json.dump(final_metrics, f, indent=2)

    # 3. Rapport de classification (meilleur modèle)
    # On recalcule les preds pour le meilleur
    best_preds = best_model.predict(X_test)
    report = classification_report(y_test, best_preds, target_names=["RECALE", "ADMIS"])
    with open(OUTPUT_DIR / "classification_report_synthetic.txt", "w", encoding="utf-8") as f:
        f.write(report)

    # 4. Matrice de confusion
    plt.figure(figsize=(8,6))
    cm = confusion_matrix(y_test, best_preds)
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', xticklabels=["RECALE", "ADMIS"], yticklabels=["RECALE", "ADMIS"])
    plt.xlabel('Prédit')
    plt.ylabel('Réel')
    plt.title(f'Matrice de Confusion - {best_model_name}')
    plt.savefig(OUTPUT_DIR / "confusion_matrix_synthetic.png")
    plt.close()

    # 5. Importance des variables (si applicable)
    if hasattr(best_model.named_steps["model"], "feature_importances_"):
        importances = best_model.named_steps["model"].feature_importances_
        # Récupérer les noms des features après OneHotEncoding
        feature_names = best_model.named_steps["preprocessor"].get_feature_names_out()
        feat_imp = pd.DataFrame({"feature": feature_names, "importance": importances})
        feat_imp = feat_imp.sort_values("importance", ascending=False)
        feat_imp.to_csv(OUTPUT_DIR / "feature_importance_synthetic.csv", index=False)

    # 6. Schéma de prétraitement
    # On exporte simplement la liste des colonnes et transformations
    schema = {
        "numeric_features": NUMERIC_FEATURES,
        "categorical_features": CATEGORICAL_FEATURES,
        "target": TARGET,
        "random_state": RANDOM_STATE
    }
    with open(OUTPUT_DIR / "preprocessing_schema.json", "w", encoding="utf-8") as f:
        json.dump(schema, f, indent=2)

    # 7. Metadata du run
    metadata = {
        "dataset_type": "SYNTHETIQUE_NON_REELLE",
        "dataset_path": DATASET_PATH,
        "random_state": RANDOM_STATE,
        "target": TARGET,
        "warning": "Performances non représentatives de données réelles",
        "execution_date": datetime.now().isoformat(),
        "best_model": best_model_name,
        "best_f1": best_f1
    }
    with open(OUTPUT_DIR / "run_metadata.json", "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2)

    print(f"\n✅ Pipeline terminé. Résultats sauvegardés dans {OUTPUT_DIR}")

if __name__ == "__main__":
    main()
