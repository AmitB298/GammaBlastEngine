"""
Conformal quantile band for hazard: we keep two rolling deques of hazard
scores conditioned on outcome (y=1 and y=0). At inference, we form an
upper/lower band around the raw hazard and require the LOWER band to clear
the percentile for confirmation -> stricter & more robust.
"""

from dataclasses import dataclass, field
from typing import List
import bisect


@dataclass
class QuantileBand:
    alpha: float = 0.05
    winsz: int = 2000
    pos: List[float] = field(default_factory=list)  # hazards when y=1
    neg: List[float] = field(default_factory=list)  # hazards when y=0

    def _push_sorted(self, arr: List[float], v: float):
        bisect.insort(arr, v)
        if len(arr) > self.winsz:
            arr.pop(0)

    def update(self, hazard: float, y: int):
        if y == 1:
            self._push_sorted(self.pos, hazard)
        else:
            self._push_sorted(self.neg, hazard)

    def band(self, h_raw: float) -> tuple[float, float]:
        """
        Lower band = raw hazard minus typical miss noise (from negatives).
        Upper band = raw hazard plus typical hit overshoot (from positives).
        """
        if not self.pos and not self.neg:
            return h_raw * 0.8, min(1.0, h_raw * 1.2)

        # Quantiles
        def q(arr: List[float], p: float) -> float:
            if not arr:
                return 0.0
            k = max(0, min(len(arr) - 1, int(p * (len(arr) - 1))))
            return arr[k]

        miss_noise = q(self.neg, 1.0 - self.alpha)  # how high negatives can get
        hit_overs = q(self.pos, 1.0 - self.alpha / 2)  # how high hits usually go
        lower = max(0.0, h_raw - 0.5 * miss_noise)
        upper = min(1.0, h_raw + 0.25 * hit_overs)
        return lower, upper
