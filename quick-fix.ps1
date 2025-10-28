<#
.SYNOPSIS
    Quick task runner for repository maintenance
#>

param(
    [ValidateSet("pydantic", "venv", "ci", "branch", "release", "all")]
    [string]$Task = "all"
)

$taskMap = @{
    "pydantic" = "PydanticFix"
    "venv" = "VenvCleanup"
    "ci" = "CISetup"
    "branch" = "BranchMigration"
    "release" = "ReleaseHygiene"
    "all" = "All"
}

if ($taskMap.ContainsKey($Task)) {
    $taskToRun = $taskMap[$Task]
    if ($taskToRun -eq "All") {
        & "./repo-health-check.ps1"
    } else {
        & "./repo-health-check.ps1" -Tasks $taskToRun
    }
} else {
    Write-Host "Invalid task. Use: pydantic, venv, ci, branch, release, or all" -ForegroundColor Red
}
