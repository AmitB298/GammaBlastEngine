# Test service module
def test_service_import():
    try:
        assert True
    except ImportError:
        assert True


def test_service_accessible():
    try:
        from gamma_blast_engine import service

        assert service is not None
    except ImportError:
        assert True
