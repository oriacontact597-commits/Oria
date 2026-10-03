import pandas as pd
import psycopg2
import uuid
from psycopg2 import extras

# Configuration
DB_CONFIG = {
    "host": "localhost",
    "port": 5433,
    "database": "oria_education",
    "user": "postgres",
    "password": "OriaContactHeubLab"
}
FILE_PATH = '/home/grace/hackaton/donnée/Base_Etablissements_Superieurs_Benin_Cote_Ivoire.xlsx'

def map_type(type_str):
    if not isinstance(type_str, str): return 'AUTRE'
    t = type_str.lower()
    if 'université publique' in t: return 'UNIVERSITE'
    if 'établissement privé d’enseignement supérieur' in t: return 'ECOLE_SUPERIEURE'
    if 'université / établissement privé autorisé' in t: return 'ECOLE_SUPERIEURE'
    if 'grande école privée autorisée' in t: return 'GRANDE_ECOLE'
    if 'centre de formation professionnelle' in t: return 'CENTRE_FORMATION_PROFESSIONNELLE'
    return 'AUTRE'

def map_public(statut):
    if not isinstance(statut, str): return False
    return 'public' in statut.lower()

def import_data():
    try:
        print("Reading Excel file...")
        xls = pd.ExcelFile(FILE_PATH)
        df_etab = pd.read_excel(xls, sheet_name='Etablissements')
        df_loc = pd.read_excel(xls, sheet_name='Localisation')

        loc_cols = ['ID_ETABLISSEMENT', 'Ville', 'Adresse complète']
        df_loc_reduced = df_loc[loc_cols]

        df = pd.merge(df_etab, df_loc_reduced, on='ID_ETABLISSEMENT', how='inner')
        print(f"Found {len(df)} establishments to import.")

        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()

        count = 0
        for _, row in df.iterrows():
            try:
                tracking_id = str(uuid.uuid4())
                titre = row['Nom officiel']
                resume = row.get('Présentation', '')
                if pd.isna(resume): resume = ''
                
                cur.execute(
                    "INSERT INTO fiches (tracking_id, titre, resume, est_publie) VALUES (%s, %s, %s, %s) RETURNING id",
                    (tracking_id, titre, resume, True)
                )
                fiche_id = cur.fetchone()[0]

                ville = row.get('Ville', 'Inconnue')
                if pd.isna(ville): ville = 'Inconnue'
                
                type_etab = map_type(row.get('Type'))
                adresse = row.get('Adresse complète', '')
                if pd.isna(adresse): adresse = ''
                
                site_web = row.get('Site Web', '') 
                if pd.isna(site_web): site_web = ''
                
                id_str = str(row['ID_ETABLISSEMENT'])
                country_code = id_str.split('-')[0] if '-' in id_str else 'TG'
                est_public = map_public(row.get('Statut juridique'))
                
                cur.execute(
                    """INSERT INTO fiches_etablissement 
                       (id, ville, type_etablissement, adresse, site_web, niveau, country_code, est_public) 
                       VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""",
                    (fiche_id, ville, type_etab, adresse, site_web, 'ENSEIGNEMENT SUPERIEUR', country_code, est_public)
                )
                count += 1
            except Exception as row_e:
                print(f"Error importing {row['ID_ETABLISSEMENT']}: {row_e}")
                conn.rollback()
                continue
            else:
                conn.commit()

        print(f"Successfully imported {count} establishments.")
        cur.close()
        conn.close()

    except Exception as e:
        print(f"Critical error: {e}")

if __name__ == "__main__":
    import_data()
