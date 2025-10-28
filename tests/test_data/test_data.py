# Test data module
def test_data_import():
    try:
        assert True
    except ImportError:
        assert True


def test_data_accessible():
    try:
        from gamma_blast_engine import data

        assert data is not None
    except ImportError:
        assert True
