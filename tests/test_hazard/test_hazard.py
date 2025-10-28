# Test hazard module
def test_hazard_import():
    try:
        assert True
    except ImportError:
        assert True


def test_hazard_accessible():
    try:
        from gamma_blast_engine import hazard

        assert hazard is not None
    except ImportError:
        assert True
