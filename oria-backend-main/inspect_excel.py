import pandas as pd
file_path = '/home/grace/hackaton/donnée/Base_Etablissements_Superieurs_Benin_Cote_Ivoire.xlsx'
try:
    df_etab = pd.read_excel(file_path, sheet_name='Etablissements')
    print("Unique values in 'Type':\n", df_etab['Type'].unique())
    print("\nUnique values in 'Statut juridique':\n", df_etab['Statut juridique'].unique())
except Exception as e:
    print(f"Error: {e}")
