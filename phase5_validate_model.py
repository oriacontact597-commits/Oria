import joblib
import pandas as pd
import json
import numpy as np
from pathlib import Path

# Configuration
MODEL_PATH = Path("/home/grace/hackaton/model_output_synthetic/model_synthetic.joblib")
SCHEMA_PATH = Path("/home/grace/hackaton/model_output_synthetic/preprocessing_schema.json")

def predict(data_dict):
    if not MODEL_PATH.exists():
        return {"error": "Modèle non trouvé"}

    model = joblib.load(MODEL_PATH)

    # Conversion en DataFrame
    df = pd.DataFrame([data_dict])

    # Vérification des colonnes requises
    with open(SCHEMA_PATH, 'r') as f:
        schema = json.load(f)

    required_cols = schema["numeric_features"] + schema["categorical_features"]
    missing = [c for c in required_cols if c not in df.columns]
    if missing:
        return {"error": f"Colonnes manquantes : {missing}"}

    # Prédiction
    try:
        prob = model.predict_proba(df)[0][1]
        pred = "ADMIS" if prob >= 0.5 else "RECALE"
        return {
            "prediction": pred,
            "probability": round(float(prob), 2),
            "model_mode": "synthetic_test",
            "warning": "Cette prédiction est basée sur des données synthétiques et ne constitue pas une décision officielle."
        }
    except Exception as e:
        return {"error": str(e)}

# =============================================================================
# TESTS DE VALIDATION
# =============================================================================
if __name__ == "__main__":
    print("--- Lancement des tests de validation Phase 5 ---\n")

    # 1. Requête nominale
    test_1 = {
        "age": 18, "moyenne_bac": 14.5, "note_mathematiques": 15, "note_francais": 12, "note_anglais": 13, "taux_reference_admission": 0.6,
        "profil_type": "BACHELIER", "annee_academique": "2024-2025", "region": "Grand Lomé", "sexe": "M", "serie_bac": "D", "type_enseignement": "GENERAL", "cohorte": "BAC1", "concours_filiere": "Informatique", "etablissement_demande": "UL"
    }
    print(f"Test 1 (Nominal) : {predict(test_1)}")

    # 2. Série inconnue (Vérification handle_unknown='ignore')
    test_2 = test_1.copy()
    test_2["serie_bac"] = "SERIE_INCONNUE_999"
    print(f"Test 2 (Série inconnue) : {predict(test_2)}")

    # 3. Valeur manquante (Vérification imputer)
    test_3 = test_1.copy()
    test_3["moyenne_bac"] = np.nan
    print(f"Test 3 (Valeur manquante) : {predict(test_3)}")

    # 4. Valeur invalide/manquante colonne (Vérification erreur claire)
    test_4 = {"age": 18} # Manque presque tout
    print(f"Test 4 (Colonnes manquantes) : {predict(test_4)}")
