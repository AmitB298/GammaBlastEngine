Write-Host "🚀 GAMMA BLAST ENGINE - LOCAL TEST SUITE" -ForegroundColor Cyan
Write-Host "=========================================`n" -ForegroundColor Cyan

# Run Ruff checks
Write-Host "🔍 Running Code Quality Checks..." -ForegroundColor Yellow
ruff check .
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Ruff checks passed" -ForegroundColor Green
} else {
    Write-Host "❌ Ruff checks failed" -ForegroundColor Red
    exit 1
}

# Run MyPy type checking
Write-Host "`n📝 Running Type Checks..." -ForegroundColor Yellow
mypy gamma_blast_engine/
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ MyPy checks passed" -ForegroundColor Green
} else {
    Write-Host "❌ MyPy checks failed" -ForegroundColor Red
    exit 1
}

# Run tests
Write-Host "`n🧪 Running Test Suite..." -ForegroundColor Yellow
python -m pytest tests/ -v --tb=short
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ All tests passed" -ForegroundColor Green
} else {
    Write-Host "❌ Some tests failed" -ForegroundColor Red
    exit 1
}

Write-Host "`n🎉 GAMMA BLAST ENGINE READY FOR LOCAL DEVELOPMENT!" -ForegroundColor Magenta
Write-Host "   Package: v$((python -c "from gamma_blast_engine import __version__; print(__version__)"))" -ForegroundColor White
Write-Host "   Subpackages: 17" -ForegroundColor White
Write-Host "   Modules: 123" -ForegroundColor White
