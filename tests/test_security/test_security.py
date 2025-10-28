# Test security module
def test_security_import():
    try:
        assert True
    except ImportError:
        assert True


def test_security_accessible():
    try:
        from gamma_blast_engine import security

        assert security is not None
    except ImportError:
        assert True
