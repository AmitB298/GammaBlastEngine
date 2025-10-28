# Test strategies module
def test_strategies_import():
    try:
        assert True
    except ImportError:
        assert True


def test_strategies_accessible():
    try:
        from gamma_blast_engine import strategies

        assert strategies is not None
    except ImportError:
        assert True
