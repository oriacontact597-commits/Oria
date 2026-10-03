import pandas as pd
file_path = '/home/grace/hackaton/docs/Base_Etablissements_Superieurs_Togo.xlsx'
try:
    loc = pd.read_excel(file_path, sheet_name='Localisation')
    con = pd.read_excel(file_path, sheet_name='Contacts')
    print("Localisation Headers:")
    print(loc.columns.tolist())
    print("\nContacts Headers:")
    print(con.columns.tolist())
except Exception as e:
    print(f"Error: {e}")
