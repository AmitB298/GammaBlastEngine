"""
CUSUM-style change-point detectors for (a) lambda z-score stream and (b) realized precision.
When a regime shift is detected, we emit a bias bump (tighten) or bias ease (loosen).
"""

from dataclasses import dataclass


@dataclass
class CusumConfig:
    k: float = 0.15  # slack (smaller -> more sensitive)
    h: float = 2.0  # threshold to trigger
    bump_up: float = 2.0  # bias increase on stress
    bump_dn: float = 1.0  # bias decrease when calm
    min_bias: float = 5.0
    max_bias: float = 45.0


class Cusum:
    def __init__(self, cfg: CusumConfig | None = None):
        self.cfg = cfg or CusumConfig()
        self.gp = 0.0
        self.gn = 0.0

    def step(self, x: float) -> int:
        """
        x is a centered stream: positive means stress, negative means calm.
        Returns +1 on stress change, -1 on calm change, 0 otherwise.
        """
        k, h = self.cfg.k, self.cfg.h
        self.gp = max(0.0, self.gp + x - k)
        self.gn = max(0.0, self.gn - x - k)
        if self.gp > h:
            self.gp = self.gn = 0.0
            return +1
        if self.gn > h:
            self.gp = self.gn = 0.0
            return -1
        return 0


def clamp(x: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, x))


class BiasRegimeController:
    """
    Maintains a dynamic decision bias, nudged by CUSUM events.
    Use with lambda_z and realized precision deviation.
    """

    def __init__(self, base_bias: float = 20.0, cfg: CusumConfig | None = None):
        self.cfg = cfg or CusumConfig()
        self.bias = base_bias
        self.cusum_lambda = Cusum(self.cfg)
        self.cusum_ppv = Cusum(self.cfg)

    def step_lambda(self, lambda_z: float) -> float:
        # Center around ~2.0: above => stress; below => calm
        event = self.cusum_lambda.step(lambda_z - 2.0)
        if event == +1:
            self.bias = clamp(
                self.bias + self.cfg.bump_up, self.cfg.min_bias, self.cfg.max_bias
            )
        elif event == -1:
            self.bias = clamp(
                self.bias - self.cfg.bump_dn, self.cfg.min_bias, self.cfg.max_bias
            )
        return self.bias

    def step_ppv(self, ppv_err: float) -> float:
        # Positive error (target_ppv - actual_ppv) => we are too loose -> bump up
        event = self.cusum_ppv.step(ppv_err)
        if event == +1:
            self.bias = clamp(
                self.bias + self.cfg.bump_up, self.cfg.min_bias, self.cfg.max_bias
            )
        elif event == -1:
            self.bias = clamp(
                self.bias - self.cfg.bump_dn, self.cfg.min_bias, self.cfg.max_bias
            )
        return self.bias
