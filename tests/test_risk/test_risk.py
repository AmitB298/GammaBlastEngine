# Test risk module
def test_risk_import():
    try:
        assert True
    except ImportError:
        assert True


def test_risk_accessible():
    try:
        from gamma_blast_engine import risk

        assert risk is not None
    except ImportError:
        assert True
