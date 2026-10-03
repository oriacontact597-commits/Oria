#!/usr/bin/env python3
"""Importe les bases XLSX d'établissements supérieurs (TG / BJ / CI) en SQL.

Sources :
  donnée/Base_Etablissements_Superieurs_Togo.xlsx          (97 établissements)
  donnée/Base_Etablissements_Superieurs_Benin_Cote_Ivoire.xlsx (836)

Usage :
  python3 import_etablissements_xlsx.py > /tmp/etab.sql
  docker exec -i oria-db psql -U postgres -d oria_education -v ON_ERROR_STOP=1 -f - < /tmp/etab.sql

Le pays est déduit du préfixe ID_ETABLISSEMENT (TG- / BJ- / CI-).
Idempotent : supprime d'abord les établissements marqués 'seed' ou 'seed_xlsx'.
"""
import re
import sys
import uuid

import pandas as pd

TOGO = '/home/grace/hackaton/donnée/Base_Etablissements_Superieurs_Togo.xlsx'
BJ_CI = '/home/grace/hackaton/donnée/Base_Etablissements_Superieurs_Benin_Cote_Ivoire.xlsx'

CREATED_BY = 'seed_xlsx'

# Contraintes du schéma
RESUME_MAX = 500       # fiches.resume varchar(500)
ADRESSE_MAX = 300      # fiches_etablissement.adresse varchar(300)
SITE_MAX = 255
CONTACTS_MAX = 300
VILLE_MAX = 100
NIVEAU = 'ENSEIGNEMENT SUPERIEUR'

TYPE_MAP = [
    ('université publique', 'UNIVERSITE'),
    ('université / établissement privé', 'UNIVERSITE'),
    ('université', 'UNIVERSITE'),
    ('grande école', 'GRANDE_ECOLE'),
    ('faculté', 'ECOLE_SUPERIEURE'),
    ('institut supérieur', 'ECOLE_SUPERIEURE'),
    ('institut universitaire', 'ECOLE_SUPERIEURE'),
    ('établissement privé d’enseignement supérieur', 'ECOLE_SUPERIEURE'),
    ('établissement privé d\'enseignement supérieur', 'ECOLE_SUPERIEURE'),
    ('centre de formation professionnelle', 'CENTRE_FORMATION_PROFESSIONNELLE'),
    ('lycée', 'LYCEE'),
    ('collège', 'COLLEGE'),
]

VALID_TYPES = {
    'UNIVERSITE', 'ECOLE_SUPERIEURE', 'LYCEE', 'COLLEGE',
    'CENTRE_FORMATION_PROFESSIONNELLE', 'GRANDE_ECOLE', 'AUTRE',
}


def sql(value):
    """Échappement SQL simple ('' pour apostrophe)."""
    if value is None:
        return 'NULL'
    s = str(value).strip()
    if s.lower() in ('', 'nan', 'none', 'non disponible', 'n/a', 'na', 'null'):
        return 'NULL'
    s = re.sub(r'\s+', ' ', s)
    return "'" + s.replace("'", "''") + "'"


def sql_len(value, maxlen):
    if value is None:
        return 'NULL'
    s = str(value).strip()
    if s.lower() in ('', 'nan', 'none', 'non disponible', 'n/a', 'na', 'null'):
        return 'NULL'
    return sql(s[:maxlen])


def to_float(value):
    try:
        if value is None or pd.isna(value):
            return 'NULL'
        v = float(str(value).replace(',', '.'))
        if not -180 <= v <= 180:
            return 'NULL'
        return str(v)
    except (TypeError, ValueError):
        return 'NULL'


def map_type(raw):
    t = str(raw or '').lower()
    for needle, mapped in TYPE_MAP:
        if needle in t:
            return mapped
    return 'AUTRE'


def map_public(raw):
    return 'true' if 'public' in str(raw or '').lower() else 'false'


def country_from_id(etab_id, default):
    prefix = str(etab_id)[:2].upper()
    return prefix if prefix in ('TG', 'BJ', 'CI') else default


def clean_name(raw):
    """Normalise les apostrophes typographiques pour éviter les doublons."""
    return str(raw or '').replace('’', "'").replace('`', "'").strip()


def load(path, default_country):
    xl = pd.ExcelFile(path)
    etab = xl.parse('Etablissements')
    loc = xl.parse('Localisation')
    con = xl.parse('Contacts')

    offers = {}
    if 'Formations' in xl.sheet_names:
        form = xl.parse('Formations')
        grouped = (
            form.dropna(subset=['ID_ETABLISSEMENT'])
            .groupby('ID_ETABLISSEMENT')['Filière']
            .apply(lambda s: ', '.join(dict.fromkeys(str(v).strip() for v in s.dropna())))
        )
        offers = grouped.to_dict()

    df = etab.merge(loc, on='ID_ETABLISSEMENT', how='left', suffixes=('', '_loc'))
    df = df.merge(con, on='ID_ETABLISSEMENT', how='left', suffixes=('', '_con'))

    rows = []
    for _, r in df.iterrows():
        rows.append({
            'id': r['ID_ETABLISSEMENT'],
            'titre': clean_name(r.get('Nom officiel')),
            'resume': r.get('Présentation'),
            'contenu': r.get('Présentation') or r.get('Historique'),
            'type': map_type(r.get('Type')),
            'public': map_public(r.get('Statut juridique')),
            'ville': r.get('Ville'),
            'adresse': r.get('Adresse complète'),
            'site': r.get('Site web'),
            'tel': r.get('Téléphone principal'),
            'email': r.get('Email'),
            'lat': r.get('Latitude'),
            'lng': r.get('Longitude'),
            'country': country_from_id(r['ID_ETABLISSEMENT'], default_country),
            'offre': offers.get(r['ID_ETABLISSEMENT']),
        })
    return rows


def main():
    rows = load(TOGO, 'TG') + load(BJ_CI, 'TG')
    rows = [r for r in rows if r['titre']]

    out = sys.stdout
    out.write('-- Généré par import_etablissements_xlsx.py\n')
    out.write('BEGIN;\n\n')

    # Nettoyage : établissements déjà importés (seed SQL ou seed_xlsx)
    out.write("""-- Nettoyage des anciens établissements (seed SQL + imports antérieurs)
CREATE TEMP TABLE _etab_old AS
SELECT f.id FROM fiches f
JOIN fiches_etablissement e ON e.id = f.id
WHERE f.created_by IN ('seed', 'seed_xlsx');
DELETE FROM etablissement_filiere WHERE etablissement_id IN (SELECT id FROM _etab_old);
DELETE FROM fiche_images WHERE fiche_id IN (SELECT id FROM _etab_old);
DELETE FROM fiche_documents WHERE fiche_id IN (SELECT id FROM _etab_old);
DELETE FROM fiche_videos WHERE fiche_id IN (SELECT id FROM _etab_old);
DELETE FROM fiches_etablissement WHERE id IN (SELECT id FROM _etab_old);
DELETE FROM fiches WHERE id IN (SELECT id FROM _etab_old);
DROP TABLE _etab_old;

""")
    out.write(f"-- {len(rows)} établissements à importer\n\n")

    seen = set()
    inserted = 0
    for r in rows:
        key = re.sub(r'[^a-z0-9]', '', r['titre'].lower())
        if key in seen:
            continue
        seen.add(key)

        tracking = uuid.uuid4()
        contacts = ' — '.join(
            str(v) for v in (r['tel'], r['email'])
            if v is not None and str(v).strip().lower() not in ('', 'nan', 'non disponible')
        ) or None

        out.write(
            "WITH f AS (\n"
            "  INSERT INTO fiches (tracking_id, titre, resume, contenu, est_publie, "
            "nb_consultations, created_by, created_at)\n"
            f"  VALUES ('{tracking}', {sql_len(r['titre'], 255)}, {sql_len(r['resume'], RESUME_MAX)}, "
            f"{sql(r['contenu'])}, true, 0, '{CREATED_BY}', now())\n"
            "  RETURNING id\n"
            ")\n"
            "INSERT INTO fiches_etablissement (id, ville, type_etablissement, adresse, "
            "site_web, contacts, niveau, country_code, est_public, latitude, longitude, "
            "offre_formation)\n"
            "SELECT id, "
            f"{sql_len(r['ville'], VILLE_MAX)}, {sql(r['type'])}, {sql_len(r['adresse'], ADRESSE_MAX)}, "
            f"{sql_len(r['site'], SITE_MAX)}, {sql_len(contacts, CONTACTS_MAX)}, "
            f"'{NIVEAU}', '{r['country']}', {r['public']}, "
            f"{to_float(r['lat'])}, {to_float(r['lng'])}, {sql_len(r['offre'], None)}\n"
            "FROM f;\n\n"
        )
        inserted += 1

    out.write("COMMIT;\n")
    print(f"-- {inserted} établissements générés "
          f"(TG/BJ/CI) — relancer via psql", file=sys.stderr)


if __name__ == '__main__':
    main()
