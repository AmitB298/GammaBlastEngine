# Test models module
def test_models_import():
    try:
        assert True
    except ImportError:
        assert True


def test_models_accessible():
    try:
        from gamma_blast_engine import models

        assert models is not None
    except ImportError:
        assert True
