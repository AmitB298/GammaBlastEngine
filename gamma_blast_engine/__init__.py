"""Gamma Blast Engine - Advanced Algorithmic Trading Platform"""

__version__ = "1.0.0"
__author__ = "AmitB298"
__description__ = "Enterprise-grade algorithmic trading engine with AI/ML capabilities"

# Import and re-export subpackages explicitly
from gamma_blast_engine import data as data
from gamma_blast_engine import features as features
from gamma_blast_engine import fusion as fusion
from gamma_blast_engine import hazard as hazard
from gamma_blast_engine import iv as iv
from gamma_blast_engine import metrics as metrics
from gamma_blast_engine import microstructure as microstructure
from gamma_blast_engine import models as models
from gamma_blast_engine import options as options
from gamma_blast_engine import reinforcement as reinforcement
from gamma_blast_engine import risk as risk
from gamma_blast_engine import security as security
from gamma_blast_engine import sentiment as sentiment
from gamma_blast_engine import service as service
from gamma_blast_engine import strategies as strategies
from gamma_blast_engine import utils as utils
from gamma_blast_engine import visualization as visualization

__all__ = [
    "data",
    "features",
    "fusion",
    "hazard",
    "iv",
    "metrics",
    "microstructure",
    "models",
    "options",
    "reinforcement",
    "risk",
    "security",
    "sentiment",
    "service",
    "strategies",
    "utils",
    "visualization",
]
