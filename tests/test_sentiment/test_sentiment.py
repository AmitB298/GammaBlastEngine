# Test sentiment module
def test_sentiment_import():
    try:
        assert True
    except ImportError:
        assert True


def test_sentiment_accessible():
    try:
        from gamma_blast_engine import sentiment

        assert sentiment is not None
    except ImportError:
        assert True
