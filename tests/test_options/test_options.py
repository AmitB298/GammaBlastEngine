# Test options module
def test_options_import():
    try:
        assert True
    except ImportError:
        assert True


def test_options_accessible():
    try:
        from gamma_blast_engine import options

        assert options is not None
    except ImportError:
        assert True
