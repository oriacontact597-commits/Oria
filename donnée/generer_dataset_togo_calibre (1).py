import csv, random, math
from pathlib import Path

SEED = 20260927
N_BAC_PAR_COHORTE = 2500
N_CONCOURS_PAR_CATEGORIE_AN = 400
OUT_DIR = Path('/home/ubuntu/collecte_togo_2026')
DATA = OUT_DIR / 'dataset_synthetique_togo_calibre_60000.csv'
RATES = OUT_DIR / 'taux_calibrage_bac_concours.csv'
random.seed(SEED)

# Taux BAC : 2021-2023 et 2025-2026 documentés par le portail officiel ou une source institutionnelle.
# 2024 BAC I/II est conservé comme taux rapporté à vérifier, pas comme vérité officielle définitive.
bac_rates = {
    (2021, 'BAC1'): (0.7658, 'OFFICIEL_PORTAIL_TOGO'),
    (2021, 'BAC2'): (0.6900, 'OFFICIEL_PORTAIL_TOGO'),
    (2022, 'BAC1'): (0.7500, 'OFFICIEL_PORTAIL_TOGO'),
    (2022, 'BAC2'): (0.7434, 'OFFICIEL_PORTAIL_TOGO'),
    (2023, 'BAC1'): (0.7850, 'OFFICIEL_PORTAIL_TOGO'),
    (2023, 'BAC2'): (0.7943, 'OFFICIEL_PORTAIL_TOGO'),
    (2024, 'BAC1'): (0.7173, 'A_VERIFIER_SOURCE_OFFICIELLE'),
    (2024, 'BAC2'): (0.4671, 'A_VERIFIER_SOURCE_OFFICIELLE'),
    (2025, 'BAC1'): (0.6049, 'OFFICIEL_PORTAIL_TOGO'),
    (2025, 'BAC2'): (0.7263, 'SOURCE_SECONDAIRE_A_CROISER'),
    (2026, 'BAC1'): (0.7305, 'OFFICIEL_PORTAIL_TOGO'),
    (2026, 'BAC2'): (0.8127, 'OFFICIEL_PORTAIL_TOGO'),
}

# Catégories de concours/filières pour le scénario de test.
# Ces taux ne sont pas des taux nationaux publiés : ils sont explicitement SIMULES.
contest_rates = {
    'IUT-Gestion': 0.30,
    'ESA-Agronomie': 0.25,
    'ESTBA-Sciences': 0.28,
    'EPL-Education': 0.25,
    'EAM-Arts-Metiers': 0.35,
    'INSE-Economie': 0.20,
    'Informatique': 0.30,
    'Droit': 0.45,
    'Medecine': 0.12,
    'Sciences économiques': 0.32,
    'Lettres': 0.42,
    'ENFPE-Education': 0.18,
}

regions = ['Grand Lomé','Maritime','Plateaux','Centrale','Kara','Savanes']
# Séries générales et techniques représentées dans le scénario de test.
series = ['A4','A3','C','D','E','G1','G2','G3','F1','F2','F3','F4','Ti1','Ti2']
series_weights = [24, 4, 5, 18, 2, 7, 5, 4, 6, 5, 4, 3, 7, 6]
sexes = ['F','M']
institutions = ['Université de Lomé','Université de Kara','École publique','Institut privé agréé']

def clamp(x, lo, hi): return max(lo, min(hi, x))
def pick_outcome(rate): return 'ADMIS' if random.random() < rate else 'RECALE'

def profile(i, year, kind):
    serie = random.choices(series, weights=series_weights, k=1)[0]
    mean = round(clamp(random.gauss(12.0, 2.1), 7.0, 18.5), 2)
    math = round(clamp(random.gauss(mean + (1 if serie in ['C','D'] else -0.3), 2), 4, 19.5), 2)
    french = round(clamp(random.gauss(mean, 1.8), 4, 19.5), 2)
    english = round(clamp(random.gauss(mean, 1.9), 4, 19.5), 2)
    return {
        'student_id': f'SYNTH_TG_{i:06d}',
        'donnee_type': 'SYNTHETIQUE_NON_REELLE',
        'profil_type': kind,
        'annee_academique': f'{year}-{year+1}',
        'region': random.choice(regions),
        'sexe': random.choice(sexes),
        'age': random.randint(17, 25) if kind == 'BACHELIER' else random.randint(18, 30),
        'serie_bac': serie,
        'type_enseignement': 'GENERAL' if serie in ['A3','A4','C','D','E'] else 'TECHNIQUE',
        'moyenne_bac': mean,
        'note_mathematiques': math,
        'note_francais': french,
        'note_anglais': english,
    }

rows = []
rate_rows = []
i = 0
# 12 cohortes BAC x 2500 = 30 000 lignes.
for year in range(2021, 2027):
    for stage in ['BAC1', 'BAC2']:
        rate, source = bac_rates[(year, stage)]
        rate_rows.append({'annee': year, 'cohorte': stage, 'categorie': stage, 'taux_reference': rate, 'type_taux': source, 'source_url': ''})
        for _ in range(N_BAC_PAR_COHORTE):
            i += 1
            r = profile(i, year, 'BACHELIER' if stage == 'BAC2' else 'ELEVE_PREMIERE')
            r.update({'cohorte': stage, 'concours_filiere': stage, 'etablissement_demande': random.choice(institutions), 'taux_reference_admission': rate, 'type_calibrage': source, 'resultat_final': pick_outcome(rate), 'situation': 'Resultat_synthetique_calibre_sur_taux_BAC', 'source_type': 'TAUX_AGREGE_ET_SIMULATION', 'source_url': '', 'verification_status': 'NON_REEL_NON_VERIFIE'})
            rows.append(r)
# 12 catégories x 6 années x 400 = 28 800 lignes.
for year in range(2021, 2027):
    for contest, rate in contest_rates.items():
        rate_rows.append({'annee': year, 'cohorte': 'CONCOURS', 'categorie': contest, 'taux_reference': rate, 'type_taux': 'SIMULE_SCENARIO_NON_OFFICIEL', 'source_url': ''})
        for _ in range(N_CONCOURS_PAR_CATEGORIE_AN):
            i += 1
            r = profile(i, year, 'ETUDIANT')
            r.update({'cohorte': 'CONCOURS', 'concours_filiere': contest, 'etablissement_demande': random.choice(institutions), 'taux_reference_admission': rate, 'type_calibrage': 'SIMULE_SCENARIO_NON_OFFICIEL', 'resultat_final': pick_outcome(rate), 'situation': 'Resultat_synthetique_de_concours', 'source_type': 'SCENARIO_SIMULE', 'source_url': '', 'verification_status': 'NON_REEL_NON_VERIFIE'})
            rows.append(r)

fields = list(rows[0])
with DATA.open('w', newline='', encoding='utf-8') as f:
    w = csv.DictWriter(f, fieldnames=fields); w.writeheader(); w.writerows(rows)
with RATES.open('w', newline='', encoding='utf-8') as f:
    fields2 = list(rate_rows[0]); w = csv.DictWriter(f, fieldnames=fields2); w.writeheader(); w.writerows(rate_rows)
print(f'data={DATA} rows={len(rows)}')
print(f'rates={RATES} rows={len(rate_rows)}')
print('admis=', sum(r['resultat_final']=='ADMIS' for r in rows), 'recale=', sum(r['resultat_final']=='RECALE' for r in rows))
