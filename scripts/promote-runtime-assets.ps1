<#
.SYNOPSIS
  Promotes assets from skills_library to active runtime.
  This is the ONLY authorized route to deploy to active_*.
.EXAMPLE
  .\promote-runtime-assets.ps1          # new items only
  .\promote-runtime-assets.ps1 -Force   # overwrite existing
#>
param (
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$baseRoot = Split-Path -Parent $PSScriptRoot

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
        Write-Error "Promotion failed (not in library): $($item.Name) -> $($item.Src)"
        continue
    }

    if (Test-Path $item.Dest) {
        if ($Force) {
            Write-Host "Force overwrite: $($item.Name)" -ForegroundColor Yellow
            if ($item.Type -eq "Dir") {
                Remove-Item $item.Dest -Recurse -Force
                Copy-Item $item.Src $item.Dest -Recurse
            } else {
                Copy-Item $item.Src $item.Dest -Force
            }
        } else {
            Write-Warning "Skipped (already active): $($item.Name). Use -Force to overwrite."
        }
        continue
    }

    Write-Host "Promoted: $($item.Name)" -ForegroundColor Green
    if ($item.Type -eq "Dir") {
        Copy-Item $item.Src $item.Dest -Recurse
    } else {
        Copy-Item $item.Src $item.Dest
    }
}

Write-Host "`n--- Promotion complete ---"

