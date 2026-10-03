import pandas as pd
file_path = '/home/grace/hackaton/docs/Base_Etablissements_Superieurs_Togo.xlsx'
try:
    xl = pd.ExcelFile(file_path)
    print(xl.sheet_names)
except Exception as e:
    print(f"Error: {e}")
