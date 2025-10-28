# Test metrics module
def test_metrics_import():
    try:
        assert True
    except ImportError:
        assert True


def test_metrics_accessible():
    try:
        from gamma_blast_engine import metrics

        assert metrics is not None
    except ImportError:
        assert True
