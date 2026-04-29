import sys
sys.path.append(r"C:\Users\AMOS SARL\OneDrive\Documents\Projet_1\Nexa_commerce\src\nexa_commerce")
import pytest
import pandas as pd
from data_loader import DataLoader, inspect_dataset
import tempfile

@pytest.fixture
def sample_csv():
    with tempfile.NamedTemporaryFile(mode='w', suffix='.csv', delete=False) as f:
        f.write("a,b,c\n1,2,\n4,5,6")
        return f.name

def test_load_csv_ok(sample_csv):
    loader = DataLoader(sample_csv)
    df = loader.load_csv()
    assert isinstance(df, pd.DataFrame)
    assert df.shape == (2, 3)

def test_load_csv_file_not_found():
    loader = DataLoader("inexistant.csv")
    with pytest.raises(FileNotFoundError):
        loader.load_csv()


def test_inspect_dataset_shape():
    df = pd.DataFrame({'x': [1, 2], 'y': [3, None]})
    report = inspect_dataset(df)
    assert report['shape'] == (2, 2)

def test_inspect_dataset_null_counts():
    df = pd.DataFrame({'x': [1, None], 'y': [3, 4]})
    report = inspect_dataset(df)
    assert 'x' in report['null_counts']
    assert report['null_counts']['x'] == 1

def test_inspect_dataset_duplicates():
    df = pd.DataFrame({'a': [1, 1, 2]})
    report = inspect_dataset(df)
    assert report['duplicate_rows'] == 1

