from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from ..utils.logging import RequestLogMiddleware
from .routers import analyze, vix, flow, toggles

OPENAPI_TAGS = [
    {"name": "analyze", "description": "Hazard / analysis endpoints"},
    {"name": "vix", "description": "VIX term structure & related metrics"},
    {"name": "flow", "description": "Unusual options flow snapshots"},
    {"name": "toggles", "description": "Runtime feature flags"},
]


def create_app() -> FastAPI:
    app = FastAPI(title="GammaBlastEngine", version="0.1.0", openapi_tags=OPENAPI_TAGS)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.add_middleware(RequestLogMiddleware)

    @app.get("/health")
    def health():
        return {"ok": True}

    app.include_router(analyze.router, prefix="/api")
    app.include_router(vix.router, prefix="/api")
    app.include_router(flow.router, prefix="/api")
    app.include_router(toggles.router, prefix="/api")

    return app


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "gamma_blast_engine.service.app:create_app",
        factory=True,
        host="0.0.0.0",
        port=8000,
        reload=True,
    )
