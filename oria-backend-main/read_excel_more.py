import pandas as pd
file_path = '/home/grace/hackaton/docs/Base_Etablissements_Superieurs_Togo.xlsx'
try:
    df = pd.read_excel(file_path, header=None)
    print(df.head(20).to_string())
except Exception as e:
    print(f"Error: {e}")
