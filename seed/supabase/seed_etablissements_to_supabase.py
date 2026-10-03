#!/usr/bin/env python3
"""
seed_etablissements_to_supabase.py
==================================

Parse seed/Etablissements.html (Google Sheet exporté, 97 établissements,
19 colonnes) et INSERT dans Supabase via l'API REST (PostgREST).

Usage:
    export SUPABASE_URL="https://xxxx.supabase.co"
    export SUPABASE_SERVICE_ROLE_KEY="eyJhbGciOi..."   # service_role (bypass RLS)
    python3 seed_etablissements_to_supabase.py

Le script est idempotent : on s'appuie sur la contrainte UNIQUE(id_etablissement)
et on utilise upsert (ON CONFLICT DO UPDATE) pour pouvoir le relancer.

Dépendances : requests (déjà présent en standard ? sinon pip install requests)
"""
from __future__ import annotations

import html as htmlmod
import json
import os
import re
import sys
import time
from pathlib import Path
from typing import Any, Dict, List

try:
    import requests
except ImportError:
    sys.exit("Manque le module 'requests'. Installe-le : pip install requests")

# --------------------------------------------------------------------------
# Config
# --------------------------------------------------------------------------
HTML_PATH = Path("/home/grace/hackaton/seed/Etablissements.html")
TABLE = "etablissements_togo"
BATCH_SIZE = 50  # Supabase accepte jusqu'à 1000 rows / requête, on prend 50 par sécurité

# Mapping header HTML -> nom de colonne SQL (snake_case)
COLUMN_MAP = {
    "ID_ETABLISSEMENT":    "id_etablissement",
    "Nom officiel":        "nom_officiel",
    "Sigle":               "sigle",
    "Logo_URL":            "logo_url",
    "Devise":              "devise",
    "Slogan":              "slogan",
    "Type":                "type",
    "Statut juridique":    "statut_juridique",
    "Numéro d'agrément":   "numero_agrement",
    "Date d'agrément":     "date_agrement",
    "Autorité de tutelle": "autorite_tutelle",
    "Accréditations":      "accreditations",
    "Reconnaissance CAMES":"reconnaissance_cames",
    "Année de création":   "annee_creation",
    "Historique":          "historique",
    "Présentation":        "presentation",
    "Mission":             "mission",
    "Vision":              "vision",
    "Valeurs":             "valeurs",
}

# --------------------------------------------------------------------------
# Parse HTML
# --------------------------------------------------------------------------
def parse_html(path: Path) -> List[Dict[str, Any]]:
    """Retourne une liste de dicts {colonne_sql: valeur} à partir du HTML Google Sheet."""
    raw = path.read_text(encoding="utf-8")

    # Le HTML est une Google Sheet avec : 1 ligne d'en-têtes de colonnes (A, B, C...)
    # puis 1 ligne d'en-têtes logiques (ID_ETABLISSEMENT, Nom officiel...)
    # puis 97 lignes d'établissements.
    rows = re.findall(r"<tr[^>]*>.*?</tr>", raw, re.DOTALL)
    if len(rows) < 3:
        sys.exit(f"HTML inattendu : seulement {len(rows)} <tr>")

    # 1ère ligne d'en-têtes logiques
    header_cells = re.findall(r"<td[^>]*>(.*?)</td>", rows[1], re.DOTALL)
    headers = [htmlmod.unescape(re.sub(r"<[^>]+>", "", c).strip()) for c in header_cells]
    missing = [h for h in COLUMN_MAP if h not in headers]
    if missing:
        sys.exit(f"Colonnes attendues manquantes dans le HTML : {missing}")

    records: List[Dict[str, Any]] = []
    for row in rows[2:]:
        cells = re.findall(r"<td[^>]*>(.*?)</td>", row, re.DOTALL)
        if not cells or all(re.sub(r"<[^>]+>", "", c).strip() == "" for c in cells):
            continue
        rec: Dict[str, Any] = {}
        for i, header in enumerate(headers):
            if i >= len(cells) or header not in COLUMN_MAP:
                continue
            value = htmlmod.unescape(re.sub(r"<[^>]+>", "", cells[i]).strip())
            sql_col = COLUMN_MAP[header]
            rec[sql_col] = _coerce(header, value)
        if rec.get("id_etablissement"):
            records.append(rec)
    return records


def _coerce(header: str, value: str) -> Any:
    """Convertit les valeurs selon le type attendu en base."""
    if not value:
        return None
    if header == "Année de création":
        try:
            return int(value)
        except ValueError:
            return None
    if header == "Date d'agrément":
        # Le Sheet renvoie déjà de l'ISO (AAAA-MM-JJ), on valide quand même
        if re.match(r"^\d{4}-\d{2}-\d{2}$", value):
            return value
        return None
    return value


# --------------------------------------------------------------------------
# Supabase REST
# --------------------------------------------------------------------------
def supabase_headers() -> Dict[str, str]:
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    if not key:
        sys.exit("Variable d'env SUPABASE_SERVICE_ROLE_KEY manquante.")
    return {
        "apikey": key,
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates,return=minimal",
    }


def upsert_batch(session: requests.Session, base_url: str, batch: List[Dict[str, Any]]) -> int:
    """POST /etablissements_togo?on_conflict=id_etablissement avec Prefer upsert."""
    url = f"{base_url}/rest/v1/{TABLE}?on_conflict=id_etablissement"
    r = session.post(url, headers={**supabase_headers(), "Prefer": "resolution=merge-duplicates,return=minimal"},
                     data=json.dumps(batch, ensure_ascii=False), timeout=60)
    if r.status_code >= 300:
        raise RuntimeError(f"Supabase {r.status_code} : {r.text[:500]}")
    return len(batch)


# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------
def main() -> int:
    base_url = os.environ.get("SUPABASE_URL", "").rstrip("/")
    if not base_url.startswith("https://"):
        sys.exit("Variable d'env SUPABASE_URL manquante ou invalide (ex: https://xxxx.supabase.co)")

    print(f"📄 Parse HTML : {HTML_PATH}")
    records = parse_html(HTML_PATH)
    print(f"✅ {len(records)} établissements extraits")

    if not records:
        return 0

    # Aperçu
    print("\n🔎 Aperçu (1er enregistrement) :")
    print(json.dumps(records[0], indent=2, ensure_ascii=False)[:600])

    session = requests.Session()
    total = 0
    for i in range(0, len(records), BATCH_SIZE):
        batch = records[i : i + BATCH_SIZE]
        n = upsert_batch(session, base_url, batch)
        total += n
        print(f"  ↳ batch {i // BATCH_SIZE + 1} : {n} lignes upsertées (total {total}/{len(records)})")
        time.sleep(0.2)  # éviter le rate-limit

    print(f"\n🎉 Terminé : {total} établissements synchronisés sur {base_url}/rest/v1/{TABLE}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
