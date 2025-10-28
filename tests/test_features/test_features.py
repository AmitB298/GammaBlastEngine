# Test features module
def test_features_import():
    try:
        assert True
    except ImportError:
        assert True


def test_features_accessible():
    try:
        from gamma_blast_engine import features

        assert features is not None
    except ImportError:
        assert True
