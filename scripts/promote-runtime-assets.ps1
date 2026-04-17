<#
.SYNOPSIS
  Promotes assets from skills_library to active runtime.
  This is the ONLY authorized route to deploy to active_*.
.EXAMPLE
  .\promote-runtime-assets.ps1          # new items only
  .\promote-runtime-assets.ps1 -Force   # overwrite existing (safe swap)
#>
param (
    [switch]$Force
)

$ErrorActionPreference = "Continue"
$baseRoot = Split-Path -Parent $PSScriptRoot
$hasError = $false

Write-Host "--- Promote: skills_library -> active_* ---"

$promoteMap = @(
    @{ Type="File"; Name="RULES.md";
       Src="$baseRoot\runtime\skills_library\rules\RULES.md";
       Dest="$baseRoot\runtime\active_rules\RULES.md" },
    @{ Type="Dir"; Name="writing-plans";
       Src="$baseRoot\runtime\skills_library\workflows\writing-plans";
       Dest="$baseRoot\runtime\active_workflows\writing-plans" },
    @{ Type="Dir"; Name="verification-before-completion";
       Src="$baseRoot\runtime\skills_library\workflows\verification-before-completion";
       Dest="$baseRoot\runtime\active_workflows\verification-before-completion" },
    @{ Type="Dir"; Name="context-manager";
       Src="$baseRoot\runtime\skills_library\skills\context-manager";
       Dest="$baseRoot\runtime\active_skills\context-manager" },
    @{ Type="Dir"; Name="security-review";
       Src="$baseRoot\runtime\skills_library\skills\security-review";
       Dest="$baseRoot\runtime\active_skills\security-review" }
)

foreach ($item in $promoteMap) {
    if (-not (Test-Path $item.Src)) {
        Write-Warning "Promotion source missing in library: $($item.Name) (Expected at $($item.Src))"
        $hasError = $true
        continue
    }

    if (Test-Path $item.Dest) {
        if (-not $Force) {
            Write-Host "Skipped (Already active): $($item.Name). Use -Force to overwrite."
            continue
        }
        Write-Host "Force Refresh: $($item.Name) (using temp-staging swap)" -ForegroundColor Yellow
    } else {
        Write-Host "New Promotion: $($item.Name)" -ForegroundColor Green
    }

    # Hardening Sprint 2: Temp Staging -> Swap Approach
    $tempDest = "$($item.Dest).tmp"
    if (Test-Path $tempDest) { Remove-Item $tempDest -Recurse -Force }
    
    try {
        if ($item.Type -eq "Dir") {
            Copy-Item $item.Src $tempDest -Recurse -ErrorAction Stop
        } else {
            Copy-Item $item.Src $tempDest -ErrorAction Stop
        }

        # Staging Success -> Swap into Active
        if (Test-Path $item.Dest) {
            Remove-Item $item.Dest -Recurse -Force -ErrorAction Stop
        }
        Move-Item $tempDest $item.Dest -ErrorAction Stop
        
        Write-Host "  Successfully promoted: $($item.Name)" -ForegroundColor Green
    } catch {
        Write-Warning "  FAILED to promote $($item.Name): $($_.Exception.Message)"
        $hasError = $true
        if (Test-Path $tempDest) { Remove-Item $tempDest -Recurse -Force }
    }
}

if ($hasError) {
    Write-Host "`nRESULT: Promotion process encountered errors. Check warnings above." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nRESULT: All authorized promotions complete." -ForegroundColor Cyan
    exit 0
}
