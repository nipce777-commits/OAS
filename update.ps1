Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Ensure-GitRepo {
  if (-not (Test-Path ".git")) { throw "Not a git repo. Run this inside C:\OAS." }
  git rev-parse --is-inside-work-tree | Out-Null
}

function Ensure-MainBranch {
  # Create main if missing; otherwise stay on current
  try {
    $branch = (git branch --show-current).Trim()
    if ($branch -eq "") { $branch = "main" }
    if ($branch -ne "main") {
      Write-Host "Switching to main..."
      git checkout main 2>$null | Out-Null
    }
  } catch {
    # If main doesn't exist yet, create it
    git checkout -b main | Out-Null
  }
}

function Pull-Latest {
  Write-Host "Pulling latest from origin/main..."
  git pull --rebase origin main
}

function Get-AppliedListPath { return Join-Path ".oas" "applied.txt" }

function Read-AppliedPatches {
  $p = Get-AppliedListPath
  if (-not (Test-Path $p)) { return @() }
  return Get-Content $p | Where-Object { $_ -and ($_).Trim() -ne "" }
}

function Mark-Applied([string]$patchName) {
  $p = Get-AppliedListPath
  if (-not (Test-Path ".oas")) { New-Item -ItemType Directory -Force ".oas" | Out-Null }
  Add-Content -Path $p -Value $patchName
}

function Apply-NewPatches {
  $applied = Read-AppliedPatches
$patchFiles = @(Get-ChildItem -Path "patches" -Filter "*.patch" -File | Sort-Object Name)

  if ($patchFiles.Count -eq 0) {
    Write-Host "No patches found in patches/."
    return $false
  }

  $changed = $false

  foreach ($pf in $patchFiles) {
    if ($applied -contains $pf.Name) { continue }

    Write-Host "Applying patch: $($pf.Name)"
        $applyOut = & git apply --whitespace=fix "$($pf.FullName)" 2>&1
    if ($LASTEXITCODE -ne 0) {
      Write-Host "Patch failed: $($pf.Name)"
      Write-Host $applyOut
      throw "git apply failed"
    }

    # Commit patch changes
    git add -A
    git commit -m "Apply patch $($pf.Name)"

    Mark-Applied $pf.Name
    $changed = $true
  }

  return $changed
}

function Push-IfNeeded {
  # Push only if local main is ahead of origin/main
  $ahead = (& git rev-list --count origin/main..HEAD).Trim()
  if ($ahead -eq "0") {
    Write-Host "Nothing to push."
    return
  }
  Write-Host "Pushing to origin/main..."
  git push origin main
}

# --- main ---
Ensure-GitRepo
Ensure-MainBranch
Pull-Latest

$hadChanges = Apply-NewPatches
if ($hadChanges) {
  Push-IfNeeded
  Write-Host "Done. New patches applied and pushed."
} else {
  Write-Host "Done. Nothing to apply."
}




