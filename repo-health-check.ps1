<#
.SYNOPSIS
    Repository Health Check and Cleanup Script
.DESCRIPTION
    Performs various repository health checks and cleanup tasks including:
    - Fixing Pydantic deprecation warnings
    - Cleaning up tracked virtual environment files
    - Setting up CI workflow
    - Branch management
    - Release hygiene setup
.PARAMETER Tasks
    Specify which tasks to run (default: all)
.PARAMETER BranchName
    New branch name for migration (default: main)
.PARAMETER License
    License type to add (default: MIT)
#>

param(
    [ValidateSet("PydanticFix", "VenvCleanup", "CISetup", "BranchMigration", "ReleaseHygiene", "All")]
    [string[]]$Tasks = @("All"),
    [string]$BranchName = "main",
    [ValidateSet("MIT", "Apache-2.0")]
    [string]$License = "MIT"
)

# Configuration
$RepoRoot = Get-Location
$GitHubWorkflowsDir = ".github/workflows"
$CIWorkflowFile = "$GitHubWorkflowsDir/ci.yml"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-CommandExists {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Invoke-PydanticFix {
    Write-ColorOutput "`n=== Fixing Pydantic Deprecation Warnings ===" -Color "Yellow"

    # Find all Python files that might contain Pydantic models
    $pythonFiles = Get-ChildItem -Path $RepoRoot -Filter "*.py" -Recurse |
                   Where-Object { $_.FullName -notlike "*\.venv*" -and $_.FullName -notlike "*\__pycache__*" }

    $filesModified = 0

    foreach ($file in $pythonFiles) {
        $content = Get-Content $file.FullName -Raw
        $originalContent = $content

        # Pattern 1: Replace class-based Config with ConfigDict
        if ($content -match "class Config:\s*\n\s*extra\s*=\s*[\""']forbid[\""']") {
            Write-ColorOutput "Found class-based Config in: $($file.Name)" -Color "Cyan"

            # Replace the class Config with model_config
            $content = $content -replace "class Config:\s*\n\s*extra\s*=\s*[\""']forbid[\""']", 'model_config = ConfigDict(extra="forbid")'

            # Add ConfigDict import if not present
            if ($content -match "from pydantic import BaseModel" -and $content -notmatch "from pydantic import ConfigDict") {
                $content = $content -replace "from pydantic import BaseModel", "from pydantic import BaseModel, ConfigDict"
            } elseif ($content -match "import pydantic" -and $content -notmatch "ConfigDict") {
                # Handle case where pydantic is imported as module
                # This is a simple approach - might need manual review
            }
        }

        # Pattern 2: Update validator decorators (basic pattern)
        if ($content -match "@validator\(") {
            Write-ColorOutput "Found old validators in: $($file.Name)" -Color "Cyan"
            $content = $content -replace "@validator\(", "@field_validator("
        }

        if ($content -ne $originalContent) {
            Set-Content -Path $file.FullName -Value $content
            $filesModified++
            Write-ColorOutput "Updated: $($file.Name)" -Color "Green"
        }
    }

    if ($filesModified -eq 0) {
        Write-ColorOutput "No Pydantic configs found to update." -Color "Yellow"
    } else {
        Write-ColorOutput "Updated $filesModified files with Pydantic v2 config." -Color "Green"
    }
}

function Invoke-VenvCleanup {
    Write-ColorOutput "`n=== Cleaning up Virtual Environment Tracking ===" -Color "Yellow"

    # Check if .venv is tracked
    $trackedVenvFiles = git ls-files .venv 2>$null

    if ($trackedVenvFiles) {
        Write-ColorOutput "Found tracked .venv files:" -Color "Red"
        $trackedVenvFiles | ForEach-Object { Write-Host "  $_" }

        $response = Read-Host "`nDo you want to remove these from Git tracking? (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            try {
                git rm -r --cached .venv
                git commit -m "chore: stop tracking .venv"
                Write-ColorOutput "Successfully removed .venv from tracking." -Color "Green"
            }
            catch {
                Write-ColorOutput "Error removing .venv: $_" -Color "Red"
            }
        } else {
            Write-ColorOutput "Skipping .venv cleanup." -Color "Yellow"
        }
    } else {
        Write-ColorOutput "No .venv files are tracked by Git." -Color "Green"
    }

    # Double-check .gitignore
    $gitignoreContent = Get-Content ".gitignore" -ErrorAction SilentlyContinue
    if ($gitignoreContent -notcontains ".venv/" -and $gitignoreContent -notcontains ".venv") {
        Write-ColorOutput "Warning: .venv/ not found in .gitignore" -Color "Yellow"
        $response = Read-Host "Add .venv/ to .gitignore? (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            Add-Content -Path ".gitignore" -Value "`n.venv/"
            Write-ColorOutput "Added .venv/ to .gitignore" -Color "Green"
        }
    }
}

function Invoke-CISetup {
    Write-ColorOutput "`n=== Setting up CI Workflow ===" -Color "Yellow"

    # Create workflows directory if it doesn't exist
    if (!(Test-Path $GitHubWorkflowsDir)) {
        New-Item -ItemType Directory -Path $GitHubWorkflowsDir -Force
        Write-ColorOutput "Created $GitHubWorkflowsDir directory" -Color "Green"
    }

    # CI workflow content
    $ciContent = @"
name: CI

on:
  push:
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Cache pip
        uses: actions/cache@v4
        with:
          path: ~/.cache/pip
          key: `${{ runner.os }}-pip-`${{ hashFiles('requirements.txt', 'pyproject.toml') }}
          restore-keys: |
            `${{ runner.os }}-pip-

      - name: Install deps
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install -e .

      - name: Ruff (lint + format check)
        run: |
          ruff check .
          ruff format --check .

      - name: MyPy
        run: mypy .

      - name: Pytest
        run: pytest -q
"@

    if (Test-Path $CIWorkflowFile) {
        Write-ColorOutput "CI workflow already exists at $CIWorkflowFile" -Color "Yellow"
        $response = Read-Host "Overwrite? (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            return
        }
    }

    Set-Content -Path $CIWorkflowFile -Value $ciContent
    Write-ColorOutput "Created CI workflow at $CIWorkflowFile" -Color "Green"

    # Update README with badge
    $readmeFiles = @("README.md", "readme.md", "Readme.md")
    $readmePath = $null

    foreach ($readme in $readmeFiles) {
        if (Test-Path $readme) {
            $readmePath = $readme
            break
        }
    }

    if ($readmePath) {
        $readmeContent = Get-Content $readmePath -Raw
        $badgeMarkdown = "`n![CI](https://github.com/AmitB298/GammaBlastEngine/actions/workflows/ci.yml/badge.svg)`n"

        if ($readmeContent -notmatch "!\[CI\]") {
            # Add badge after the first header
            $updatedContent = $readmeContent -replace "(#.*?`n)", "`$1$badgeMarkdown"
            Set-Content -Path $readmePath -Value $updatedContent
            Write-ColorOutput "Added CI badge to $readmePath" -Color "Green"
        } else {
            Write-ColorOutput "CI badge already exists in $readmePath" -Color "Yellow"
        }
    } else {
        Write-ColorOutput "No README found to add CI badge." -Color "Yellow"
    }
}

function Invoke-BranchMigration {
    Write-ColorOutput "`n=== Branch Migration ===" -Color "Yellow"

    $currentBranch = git branch --show-current

    if ($currentBranch -eq "master" -and $BranchName -ne "master") {
        Write-ColorOutput "Current branch: master" -Color "Cyan"
        $response = Read-Host "Rename 'master' to '$BranchName'? (y/N)"

        if ($response -eq 'y' -or $response -eq 'Y') {
            try {
                git branch -m master $BranchName
                git push -u origin $BranchName
                Write-ColorOutput "Branch renamed to $BranchName and pushed to origin" -Color "Green"

                $response = Read-Host "Delete remote master branch? (y/N)"
                if ($response -eq 'y' -or $response -eq 'Y') {
                    git push origin --delete master
                    Write-ColorOutput "Remote master branch deleted" -Color "Green"
                }
            }
            catch {
                Write-ColorOutput "Error during branch migration: $_" -Color "Red"
            }
        }
    } else {
        Write-ColorOutput "Current branch is '$currentBranch'. No migration needed." -Color "Green"
    }
}

function Invoke-ReleaseHygiene {
    Write-ColorOutput "`n=== Release Hygiene Setup ===" -Color "Yellow"

    # Add LICENSE
    $licenseContent = switch ($License) {
        "MIT" {
@"
MIT License

Copyright (c) $(Get-Date).Year AmitB298

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"@
        }
        "Apache-2.0" {
@"
Apache License
Version 2.0, January 2004
http://www.apache.org/licenses/

TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

[Full Apache 2.0 license text...]
"@
        }
    }

    if (!(Test-Path "LICENSE")) {
        Set-Content -Path "LICENSE" -Value $licenseContent
        Write-ColorOutput "Created $License LICENSE file" -Color "Green"
    } else {
        Write-ColorOutput "LICENSE file already exists" -Color "Yellow"
    }

    # Create CONTRIBUTING.md
    $contributingContent = @"
# Contributing to GammaBlastEngine

We love your input! We want to make contributing as easy and transparent as possible.

## Development Process

1. Fork the repo
2. Create a feature branch (\`git checkout -b feature/amazing-feature\`)
3. Commit your changes (\`git commit -m 'Add amazing feature'\`)
4. Push to the branch (\`git push origin feature/amazing-feature\`)
5. Open a Pull Request

## Code Style

- Use Ruff for linting and formatting
- Type annotations with MyPy
- Write tests for new functionality
- Ensure all tests pass before submitting

## Pull Request Process

1. Update the README.md if needed
2. Add or update tests as necessary
3. Ensure the CI pipeline passes
4. Request review from maintainers
"@

    if (!(Test-Path "CONTRIBUTING.md")) {
        Set-Content -Path "CONTRIBUTING.md" -Value $contributingContent
        Write-ColorOutput "Created CONTRIBUTING.md" -Color "Green"
    }

    # Create CODE_OF_CONDUCT.md
    $cocContent = @"
# Code of Conduct

## Our Pledge

We as members, contributors, and leaders pledge to make participation in our
community a harassment-free experience for everyone.

## Our Standards

Examples of behavior that contributes to a positive environment:
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community

## Enforcement

Instances of abusive behavior may be reported to the repository maintainers.
"@

    if (!(Test-Path "CODE_OF_CONDUCT.md")) {
        Set-Content -Path "CODE_OF_CONDUCT.md" -Value $cocContent
        Write-ColorOutput "Created CODE_OF_CONDUCT.md" -Color "Green"
    }

    # Suggest version tagging
    Write-ColorOutput "`nConsider creating your first release:" -Color "Cyan"
    Write-Host "  git tag v0.1.0"
    Write-Host "  git push --tags"
}

# Main execution
Write-ColorOutput "🚀 Repository Health Check and Cleanup" -Color "Magenta"
Write-ColorOutput "======================================" -Color "Magenta"

# Check prerequisites
if (!(Test-CommandExists "git")) {
    Write-ColorOutput "Error: Git is not installed or not in PATH" -Color "Red"
    exit 1
}

if (!(Test-Path ".git")) {
    Write-ColorOutput "Error: Not a Git repository" -Color "Red"
    exit 1
}

# Determine which tasks to run
if ($Tasks -contains "All") {
    $Tasks = @("PydanticFix", "VenvCleanup", "CISetup", "BranchMigration", "ReleaseHygiene")
}

# Execute tasks
foreach ($task in $Tasks) {
    switch ($task) {
        "PydanticFix" { Invoke-PydanticFix }
        "VenvCleanup" { Invoke-VenvCleanup }
        "CISetup" { Invoke-CISetup }
        "BranchMigration" { Invoke-BranchMigration }
        "ReleaseHygiene" { Invoke-ReleaseHygiene }
    }
}

Write-ColorOutput "`n✅ All tasks completed!" -Color "Green"
Write-ColorOutput "`nNext steps:" -Color "Cyan"
Write-Host "1. Review the changes made"
Write-Host "2. Run your tests to ensure everything still works"
Write-Host "3. Commit and push the changes"
Write-Host "4. Check that GitHub Actions CI is running successfully"
