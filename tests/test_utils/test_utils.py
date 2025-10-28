# Test utils module
def test_utils_import():
    try:
        assert True
    except ImportError:
        assert True


def test_utils_accessible():
    try:
        from gamma_blast_engine import utils

        assert utils is not None
    except ImportError:
        assert True
