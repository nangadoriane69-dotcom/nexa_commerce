import pandas as pd
from typing import Dict, Any
from pathlib import Path


class DataLoader:
    def __init__(self, file_path: str):
        self.file_path = Path(file_path)

    def load_csv(self) -> pd.DataFrame:
        if not self.file_path.exists():
            raise FileNotFoundError(f"Fichier introuvable : {self.file_path}")
        return pd.read_csv(self.file_path)


def inspect_dataset(df: pd.DataFrame) -> Dict[str, Any]:
    null_counts = df.isnull().sum().to_dict()
    duplicate_count = df.duplicated().sum()

    return {
        "shape": df.shape,
        "column_types": {col: str(df[col].dtype) for col in df.columns},
        "null_counts": {col: cnt for col, cnt in null_counts.items() if cnt > 0},
        "duplicate_rows": int(duplicate_count)
    }


if __name__ == "__main__":
    df = pd.DataFrame({'a': [1, 2], 'b': [3, 4]})
    print(inspect_dataset(df))

def detect_duplicates(df: pd.DataFrame) -> int:
    
    ## Détecte les lignes dupliquées dans un DataFrame.
    
    ## Complexité temporelle : O(n) en moyenne (hachage)
    ## Complexité spatiale : O(n) pour stocker les signatures des lignes.
   
    return df.duplicated().sum()  