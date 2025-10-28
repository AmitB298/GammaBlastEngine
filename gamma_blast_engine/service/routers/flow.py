from fastapi import APIRouter
from pydantic import BaseModel
from typing import List

router = APIRouter(tags=["flow"])


class UnusualFlowItem(BaseModel):
    symbol: str
    expiry: str
    strike: float
    side: str  # CALL/PUT
    notional_cr: float
    iv: float


class FlowSnapshot(BaseModel):
    items: List[UnusualFlowItem]


@router.get("/flow", response_model=FlowSnapshot)
def flow_snapshot_stub():
    return FlowSnapshot(
        items=[
            UnusualFlowItem(
                symbol="NIFTY",
                expiry="2025-10-30",
                strike=23000,
                side="CALL",
                notional_cr=12.4,
                iv=11.2,
            ),
            UnusualFlowItem(
                symbol="BANKNIFTY",
                expiry="2025-10-30",
                strike=48500,
                side="PUT",
                notional_cr=8.1,
                iv=13.9,
            ),
        ]
    )
