import pandas as pd
file_path = '/home/grace/hackaton/docs/Base_Etablissements_Superieurs_Togo.xlsx'
try:
    df = pd.read_excel(file_path)
    print("Headers:")
    print(df.columns.tolist())
    print("\nFirst 5 rows:")
    print(df.head().to_string())
except Exception as e:
    print(f"Error: {e}")
