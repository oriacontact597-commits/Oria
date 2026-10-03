import pandas as pd
import uuid
import re

file_path = '/home/grace/hackaton/docs/Base_Etablissements_Superieurs_Togo.xlsx'

# Load sheets
df_etab = pd.read_excel(file_path, sheet_name='Etablissements')
df_loc = pd.read_excel(file_path, sheet_name='Localisation')
df_con = pd.read_excel(file_path, sheet_name='Contacts')
df_form = pd.read_excel(file_path, sheet_name='Formations')

# Aggregate formations
df_offers = df_form.groupby('ID_ETABLISSEMENT')['Filière'].apply(lambda x: ', '.join(x.dropna().unique())).reset_index()
df_offers.columns = ['ID_ETABLISSEMENT', 'offre_formation']

# Merge everything
df = df_etab.merge(df_loc, on='ID_ETABLISSEMENT', how='left')
df = df.merge(df_con, on='ID_ETABLISSEMENT', how='left')
df = df.merge(df_offers, on='ID_ETABLISSEMENT', how='left')

def map_type(t):
    t = str(t).lower()
    if 'université publique' in t: return 'UNIVERSITE'
    if 'grande école publique' in t: return 'GRANDE_ECOLE'
    if 'institut supérieur public' in t: return 'ECOLE_SUPERIEURE'
    if 'lycée' in t: return 'LYCEE'
    if 'collège' in t: return 'COLLEGE'
    if 'centre de formation professionnelle' in t: return 'CENTRE_FORMATION_PROFESSIONNELLE'
    return 'AUTRE'

def clean_val(val):
    if pd.isna(val) or str(val).strip().lower() in ['non disponible', 'nan', 'null']:
        return 'NULL'
    s = str(val).replace("'", "''")
    return f"'{s}'"

def clean_float(val):
    if pd.isna(val) or str(val).strip().lower() in ['non disponible', 'nan', 'null']:
        return 'NULL'
    try:
        # Extract numeric part (handle cases like "6.1725 N")
        match = re.search(r"[-+]?\d*\.\d+|\d+", str(val))
        if match: return match.group(0)
        return 'NULL'
    except:
        return 'NULL'

sql = "BEGIN;\n\n"
sql += "DO $$\nDECLARE\n    v_fiche_id BIGINT;\nBEGIN\n"

for _, row in df.iterrows():
    # Fiche
    titre = clean_val(row['Nom officiel'])
    resume = clean_val(row['Présentation'])
    contenu = clean_val(row['Historique'])
    
    sql += f"    INSERT INTO fiches (tracking_id, titre, resume, contenu, est_publie, nb_consultations, created_by, created_at) \n"
    sql += f"    VALUES (gen_random_uuid(), {titre}, {resume}, {contenu}, true, 0, 'seed', now()) RETURNING id INTO v_fiche_id;\n"
    
    # Fiche Etablissement
    ville = clean_val(row['Ville'])
    type_etab = f"'{map_type(row['Type'])}'"
    site_web = clean_val(row['Site web'])
    adresse = clean_val(row['Adresse complète'])
    contacts = clean_val(row['Téléphone principal'])
    offre = clean_val(row['offre_formation'])
    statut = clean_val(row['Statut juridique'])
    num_agrement = clean_val(row["Numéro d'agrément"])
    date_agrement = clean_val(row["Date d'agrément"])
    tutelle = clean_val(row['Autorité de tutelle'])
    
    # Year extraction
    annee = row['Année de création']
    annee_val = 'NULL'
    if pd.notna(annee):
        try:
            match = re.search(r'\d{4}', str(annee))
            if match: annee_val = match.group(0)
        except: pass

    mission = clean_val(row['Mission'])
    vision = clean_val(row['Vision'])
    valeurs = clean_val(row['Valeurs'])
    
    # Geo
    lat = clean_float(row['Latitude'])
    lon = clean_float(row['Longitude'])
    reg = clean_val(row['Région'])
    com = clean_val(row['Commune'])
    pref = clean_val(row['Préfecture'])
    quart = clean_val(row['Quartier'])

    sql += f"    INSERT INTO fiches_etablissement (id, ville, type_etablissement, site_web, adresse, contacts, offre_formation, est_public, country_code, statut_juridique, numero_agrement, date_agrement, autorite_tutelle, annee_creation, mission, vision, valeurs, latitude, longitude, region, commune, prefecture, quartier) \n"
    sql += f"    VALUES (v_fiche_id, {ville}, {type_etab}, {site_web}, {adresse}, {contacts}, {offre}, true, 'TG', {statut}, {num_agrement}, {date_agrement}, {tutelle}, {annee_val}, {mission}, {vision}, {valeurs}, {lat}, {lon}, {reg}, {com}, {pref}, {quart});\n"
    sql += "    \n"

sql += "END $$\n;"
sql += "\nCOMMIT;"

with open('import_etablissements.sql', 'w', encoding='utf-8') as f:
    f.write(sql)
