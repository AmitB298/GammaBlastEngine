from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(tags=["analyze"])


class AnalyzeResponse(BaseModel):
    status: str
    hazard_score: float
    notes: str


@router.get("/analyze", response_model=AnalyzeResponse)
def analyze_stub():
    return AnalyzeResponse(
        status="ok", hazard_score=0.12, notes="stub response; wire real pipeline later."
    )
