#!/usr/bin/env python3
"""
Génère seed_etablissements.sh à partir de :
  1. Spreadsheet Google (noms officiels + IDs)
  2. Fichiers universites/*.md (site web, vidéo YouTube)
  3. seed_universites.sh existant (descriptions, villes, types, formations)

Usage :
  python3 generate_seed_etablissements.py > seed_etablissements.sh
  bash seed_etablissements.sh admin@activeducation.tg abalakata
"""

import csv
import json
import os
import re
import sys
import unicodedata
from pathlib import Path

UNIVERSITES_DIR = Path(__file__).parent / "universites"
EXISTING_SEED = Path(__file__).parent / "seed_universites.sh"

# ── 1. Lecture du CSV (spreadsheet Google) ────────────
CSV_URL = (
    "https://docs.google.com/spreadsheets/d/"
    "1iL39mVkJTQ0rEB-jhlfXzaiOAHzOxdJZay_3LUljq_U/"
    "export?format=csv&gid=692298284"
)

def fetch_csv():
    import urllib.request
    try:
        with urllib.request.urlopen(CSV_URL) as f:
            return f.read().decode("utf-8").splitlines()
    except Exception as e:
        print(f"⚠️  Impossible de télécharger le CSV : {e}", file=sys.stderr)
        print("   Utilisation du fichier local s'il existe...", file=sys.stderr)
        return None

def parse_csv(lines):
    reader = csv.DictReader(lines)
    schools = []
    for row in reader:
        schools.append({
            "id": row.get("ID_ETABLISSEMENT", "").strip(),
            "official_name": row.get("Nom officiel", "").strip(),
        })
    return [s for s in schools if s["id"] and s["official_name"]]

# ── 2. Lecture des fichiers universites/*.md ──────────
def normalize_name(name):
    nfkd = unicodedata.normalize("NFKD", name)
    ascii_ = nfkd.encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]", "", ascii_.lower())

def parse_markdown_files():
    data = {}
    if not UNIVERSITES_DIR.exists():
        return data
    for folder in UNIVERSITES_DIR.iterdir():
        if not folder.is_dir():
            continue
        md_files = list(folder.glob("*.md"))
        if not md_files:
            continue
        md = md_files[0].read_text(encoding="utf-8")
        lines = md.strip().splitlines()
        title = lines[0].lstrip("# ").strip() if lines else folder.name
        website = ""
        youtube = ""
        for line in lines[1:]:
            line = line.strip()
            if "youtu" in line.lower():
                m = re.search(r"https?://\S+", line)
                if m:
                    youtube = m.group()
            elif line.startswith("http"):
                m = re.search(r"https?://\S+", line)
                if m:
                    website = m.group()
        key = normalize_name(title)
        data[key] = {"title": title, "website": website, "youtube": youtube}
    return data

# ── 3. Lecture du seed existant pour extraire les infos ──
def parse_existing_seed():
    """Extrait les infos (ville, type, resume, offre, filieres) du seed existant."""
    schools = []
    if not EXISTING_SEED.exists():
        return schools

    text = EXISTING_SEED.read_text(encoding="utf-8")

    # On concatène les lignes continuées par backslash pour former des blocs
    # puis on extrait les appels pub/priv avec leurs arguments.
    # On nettoie les retours à la ligne et backslashes de continuation.
    cleaned = re.sub(r'\\\s*\n\s*', ' ', text)

    # Pattern: pub "titre" "resume" "adresse" "ville" "type" "niveau" "contacts" "siteWeb" "offre" "filieres"
    pattern = re.compile(
        r'(pub|priv)\s+'
        r'"([^"]*)"\s+'  # titre
        r'"([^"]*)"\s+'  # resume
        r'"([^"]*)"\s+'  # adresse
        r'"([^"]*)"\s+'  # ville
        r'"([^"]*)"\s+'  # typeEtab
        r'"([^"]*)"\s+'  # niveau
        r'"([^"]*)"\s+'  # contacts
        r'"([^"]*)"\s+'  # siteWeb
        r'"([^"]*)"\s+'  # offreFormation
        r'"([^"]*)"\s*'  # filieres
    )
    for m in pattern.finditer(cleaned):
        schools.append({
            "title": m.group(2),
            "resume": m.group(3),
            "adresse": m.group(4),
            "ville": m.group(5),
            "type": m.group(6),
            "niveau": m.group(7),
            "contacts": m.group(8),
            "siteWeb": m.group(9),
            "offreFormation": m.group(10),
            "filieres": m.group(11),
            "estPublic": m.group(1) == "pub",
        })
    return schools

# ── 4. Fuzzy matching ─────────────────────────────────
def best_match(name, candidates):
    """Trouve la meilleure correspondance par similarité de nom normalisé."""
    target = normalize_name(name)
    best_score = 0
    best = None
    for c in candidates:
        c_norm = normalize_name(c["title"])
        # Score simple : nombre de caractères communs / longueur max
        common = sum(1 for a, b in zip(target, c_norm) if a == b)
        score = common / max(len(target), len(c_norm)) if max(len(target), len(c_norm)) > 0 else 0
        # Bonus si l'un contient l'autre
        if target in c_norm or c_norm in target:
            score += 0.2
        if score > best_score:
            best_score = score
            best = c
    return best if best_score > 0.3 else None

# ── 5. Génération du script shell ─────────────────────
def generate_shell(schools_csv, md_data, existing):
    """Génère un script shell seed propre."""
    print(r"""#!/bin/bash
# seed_etablissements.sh — Généré automatiquement par generate_seed_etablissements.py
# Source : https://docs.google.com/spreadsheets/d/1iL39mVkJTQ0rEB-jhlfXzaiOAHzOxdJZay_3LUljq_U
# Usage: bash seed_etablissements.sh [email] [password]
set -e
API="${API_URL:-http://localhost:8080/api/v1}"
EMAIL="${1:-admin@activeducation.tg}"
PASS="${2:-abalakata}"

echo "=== Authentification ==="
TOKEN=$(curl -s -X POST "$API/auth/login" -H "Content-Type: application/json" \
  -d "{\"email\": \"$EMAIL\", \"motDePasse\": \"$PASS\"}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['accessToken'])")
AUTH="Authorization: Bearer $TOKEN"
echo "Token obtenu"

post() { curl -s -o /dev/null -X POST "$API/$1" -H "$AUTH" -H "Content-Type: application/json" -d "$2"; }

echo "╔═══════════════════════════════════════════════╗"
echo "║  SEED ÉTABLISSEMENTS (feuille officielle)    ║"
echo "╚═══════════════════════════════════════════════╝"
""")

    for s in schools_csv:
        name = s["official_name"]
        sid = s["id"]

        name_norm = normalize_name(name)
        md_info = md_data.get(name_norm) or best_match(name, list(md_data.values()))
        existing_info = best_match(name, existing)

        resume = existing_info["resume"] if existing_info else f"{name} — Établissement d'enseignement supérieur au Togo."
        adresse = existing_info["adresse"] if existing_info else ""
        ville = existing_info["ville"] if existing_info else "Lomé"

        type_etab = "ECOLE_SUPERIEURE"
        if existing_info:
            type_etab = existing_info["type"]
        elif "université" in name.lower() or "university" in name.lower():
            type_etab = "UNIVERSITE"
        elif any(w in name.lower() for w in ["école", "institut"]):
            type_etab = "ECOLE_SUPERIEURE"
        elif "centre" in name.lower():
            type_etab = "CENTRE_FORMATION_PROFESSIONNELLE"

        niveau = existing_info["niveau"] if existing_info else "Licence, Master"
        contacts = existing_info["contacts"] if existing_info else ""
        site_web = existing_info["siteWeb"] if existing_info and existing_info["siteWeb"] else ""
        if not site_web and md_info:
            site_web = md_info.get("website", "")
        offre = existing_info["offreFormation"] if existing_info else f"Formations supérieures à {ville}."
        est_public = existing_info["estPublic"] if existing_info else ("UNIVERSITE" in type_etab and "privé" not in name.lower() and "privée" not in name.lower())

        # Construction du JSON via json.dumps() pour un échappement correct
        payload = json.dumps({
            "titre": name,
            "resume": resume,
            "contenu": resume,
            "estPublie": True,
            "adresse": adresse,
            "ville": ville,
            "typeEtablissement": type_etab,
            "niveau": niveau,
            "contacts": contacts,
            "siteWeb": site_web,
            "offreFormation": offre,
            "estPublic": est_public,
        }, ensure_ascii=False)

        print(f'echo "  {sid} - {name}"')
        payload_escaped = payload.replace("'", "'\\''")
        print(f"post \"bibliotheque/etablissements\" \\")
        print(f"  '{payload_escaped}'")
        print()

    print(r"""echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║        SEED TERMINÉ AVEC SUCCÈS !             ║"
echo "╚═══════════════════════════════════════════════╝"
""")

def main():
    print("📥 Téléchargement du CSV…", file=sys.stderr)
    csv_lines = fetch_csv()
    if not csv_lines:
        print("❌ Impossible de récupérer le CSV.", file=sys.stderr)
        sys.exit(1)

    print(f"📄 {len(csv_lines)} lignes CSV téléchargées", file=sys.stderr)
    csv_schools = parse_csv(csv_lines)
    print(f"🏫 {len(csv_schools)} écoles dans le CSV", file=sys.stderr)

    print("📂 Lecture des fichiers markdown…", file=sys.stderr)
    md_data = parse_markdown_files()
    print(f"📁 {len(md_data)} fichiers markdown", file=sys.stderr)

    print("📖 Lecture du seed existant…", file=sys.stderr)
    existing = parse_existing_seed()
    print(f"📋 {len(existing)} écoles dans le seed existant", file=sys.stderr)

    print("⚙️  Génération du script…", file=sys.stderr)
    generate_shell(csv_schools, md_data, existing)
    print("✅ Terminé !", file=sys.stderr)

if __name__ == "__main__":
    main()
