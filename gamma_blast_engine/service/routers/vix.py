from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(tags=["vix"])

class VixTerm(BaseModel):
    spot: float
    vix3m: float
    vix6m: float
    slope_1_3m: float
    slope_3_6m: float

@router.get("/vix", response_model=VixTerm)
def vix_term_stub():
    # placeholder values; wire to real calc later
    return VixTerm(spot=13.8, vix3m=14.6, vix6m=15.2, slope_1_3m=0.8, slope_3_6m=0.6)
