param(
    [string]$RemoteName = 'origin'
)

$ErrorActionPreference = 'Stop'

function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

try {
    $repoRoot = git rev-parse --show-toplevel 2>$null
    if (-not $repoRoot) {
        throw 'This folder is not inside a Git repository.'
    }

    Set-Location $repoRoot
    Write-Info "Repository: $repoRoot"

    $remoteUrl = git remote get-url $RemoteName 2>$null
    if (-not $remoteUrl) {
        throw "Remote '$RemoteName' was not found."
    }

    Write-Info "Remote: $RemoteName"
    Write-Info "URL:    $remoteUrl"

    if ($remoteUrl -notmatch 'github\.com') {
        Write-Info 'Warning: the remote URL does not look like a GitHub repository.'
    }

    $branch = git branch --show-current 2>$null
    if (-not $branch) {
        $branch = 'HEAD'
    }

    Write-Info "Branch: $branch"
    Write-Info 'Running a dry-run push to verify upload access...'

    $pushOutput = git push --dry-run $RemoteName $branch 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        if ($pushOutput -match 'fetch first') {
            throw "Dry-run push failed because the remote branch has commits you do not have locally. Pull or rebase first, then try again.`n$pushOutput"
        }

        throw "Dry-run push failed. Check authentication, permissions, and remote settings.`n$pushOutput"
    }

    Write-Ok 'Dry-run push succeeded. GitHub upload should work from this repo.'
}
catch {
    Write-Fail $_.Exception.Message
    exit 1
}
