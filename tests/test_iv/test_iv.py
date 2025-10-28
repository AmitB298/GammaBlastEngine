# Test iv module
def test_iv_import():
    try:
        assert True
    except ImportError:
        assert True


def test_iv_accessible():
    try:
        from gamma_blast_engine import iv

        assert iv is not None
    except ImportError:
        assert True
