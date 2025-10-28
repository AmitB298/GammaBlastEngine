#!/bin/bash

echo \"🧪 Running GammaBlastEngine Test Suite\"
echo \"=====================================\"

# Check if we're in a CI environment
if [ \"\\" = \"true\" ]; then
    echo \"Running in CI mode\"
    PYTEST_ARGS=\"-v --tb=short\"
else
    echo \"Running in local mode\"
    PYTEST_ARGS=\"-v --tb=long\"
fi

# Run specific test categories
echo \"\"
echo \"1. Running core engine tests...\"
pytest \ tests/test_correlation.py tests/test_decider.py tests/test_conformal.py

echo \"\"
echo \"2. Running market data tests...\"
pytest \ tests/test_depth_analyzer.py tests/test_microstructure_l20.py tests/test_microstructure_l200.py

echo \"\"
echo \"3. Running analysis tests...\"
pytest \ tests/test_gex.py tests/test_iv_svi.py tests/test_vix_term.py

echo \"\"
echo \"4. Running application tests...\"
pytest \ tests/test_app_basics.py tests/test_autosave.py tests/test_bandit.py

echo \"\"
echo \"✅ All test categories completed!\"
