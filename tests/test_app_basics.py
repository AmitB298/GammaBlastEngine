from gamma_blast_engine.service.app import create_app

def test_app_boots_and_routes_present():
    app = create_app()
    # openapi build should include our tags
    spec = app.openapi()
    tags = {t["name"] for t in spec.get("tags", [])}
    assert {"analyze", "vix", "flow"}.issubset(tags)
