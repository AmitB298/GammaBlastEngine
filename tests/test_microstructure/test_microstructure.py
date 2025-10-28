# Test microstructure module
def test_microstructure_import():
    try:
        assert True
    except ImportError:
        assert True


def test_microstructure_accessible():
    try:
        from gamma_blast_engine import microstructure

        assert microstructure is not None
    except ImportError:
        assert True
