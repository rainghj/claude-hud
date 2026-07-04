<#
.SYNOPSIS
    ClaudeHud - Claude Code Status Bar Manager for Windows
.DESCRIPTION
    One-click install, enable, disable, and remove ClaudeHud status bar for Claude Code.
    Supports -On / -Off / -Status / -Remove parameters.
.EXAMPLE
    .\install.ps1         # Install and enable
    .\install.ps1 -Off    # Disable (keep installed)
    .\install.ps1 -On     # Re-enable
    .\install.ps1 -Status # Check current state
    .\install.ps1 -Remove # Fully remove
#>

param(
    [switch]$On,
    [switch]$Off,
    [switch]$Status,
    [switch]$Remove,
    [switch]$Help
)

# --- Config ---
$ClaudeDir = Join-Path $env:USERPROFILE ".claude"
$SettingsFile = Join-Path $ClaudeDir "settings.json"
$TargetScript = Join-Path $ClaudeDir "claude-hud.sh"
$SourceScript = Join-Path $PSScriptRoot "claude-hud.sh"
# Unix-style path for Git Bash (Claude Code 在 Windows 也跑在 Git Bash 中)
$TargetScriptUnix = "~/.claude/claude-hud.sh"

# --- Color output ---
function Write-Color($text, $color) {
    $old = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $color
    Write-Host $text
    $Host.UI.RawUI.ForegroundColor = $old
}

function Show-Banner {
    Write-Color "============================================" "Cyan"
    Write-Color "    ClaudeHud for Windows" "Cyan"
    Write-Color "============================================" "Cyan"
    Write-Host ""
}

function Get-Settings {
    if (Test-Path $SettingsFile) {
        return Get-Content $SettingsFile -Raw | ConvertFrom-Json
    }
    return $null
}

function Save-Settings($settings) {
    $json = $settings | ConvertTo-Json -Depth 10
    $backup = "$SettingsFile.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item $SettingsFile $backup -ErrorAction SilentlyContinue
    $json | Out-File $SettingsFile -Encoding UTF8
}

function Get-Status {
    if (-not (Test-Path $SettingsFile)) {
        return "not_installed"
    }
    try {
        $s = Get-Content $SettingsFile -Raw | ConvertFrom-Json
        if ($null -eq $s.statusLine) {
            return "not_installed"
        }
        if ([string]::IsNullOrEmpty($s.statusLine.command)) {
            return "disabled"
        }
        return "enabled"
    } catch {
        return "unknown"
    }
}

function Show-Status {
    switch (Get-Status) {
        "enabled" { Write-Color "[HUD] Enabled" "Green" }
        "disabled" { Write-Color "[HUD] Disabled" "Yellow" }
        "not_installed" { Write-Color "[HUD] Not installed" "Yellow" }
        default { Write-Color "[HUD] Unknown status" "Red" }
    }
}

# --- Install ---
function Install-Hud {
    Show-Banner

    # Check source script exists
    if (-not (Test-Path $SourceScript)) {
        Write-Color "ERROR: claude-hud.sh not found - ensure install.ps1 is in the same directory" "Red"
        exit 1
    }

    Write-Color "[1/3] Copying script..." "Yellow"
    if (-not (Test-Path $ClaudeDir)) {
        New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
    }
    Copy-Item $SourceScript $TargetScript -Force
    Write-Color "  OK: Installed to $TargetScript" "Green"

    Write-Color "[2/3] Configuring settings.json..." "Yellow"
    $command = "bash $TargetScriptUnix"

    if (Test-Path $SettingsFile) {
        try {
            $s = Get-Content $SettingsFile -Raw | ConvertFrom-Json
            if ($null -ne $s.statusLine) {
                Write-Color "  WARN: statusLine already exists in settings.json" "Yellow"
                Write-Host "    Current config:"
                Write-Host "    type: $($s.statusLine.type)"
                Write-Host "    command: $($s.statusLine.command)"
                Write-Host ""
                $choice = Read-Host "    Overwrite? (y/N)"
                if ($choice -ne "y" -and $choice -ne "Y") {
                    Write-Color "  -- Skipping config" "Yellow"
                    Write-Color "[3/3] Installation complete!" "Green"
                    Show-Help
                    return
                }
            }
            # Add/update statusLine
            $s | Add-Member -Force -NotePropertyName "statusLine" -NotePropertyValue @{
                type = "command"
                command = $command
            }
            Save-Settings $s
        } catch {
            Write-Color "  ERROR: Failed to parse settings.json: $_" "Red"
            exit 1
        }
    } else {
        # Create new settings.json
        $s = @{
            statusLine = @{
                type = "command"
                command = $command
            }
        }
        $json = $s | ConvertTo-Json -Depth 10
        $json | Out-File $SettingsFile -Encoding UTF8
    }
    Write-Color "  OK: statusLine configured" "Green"

    Write-Color "[3/3] Installation complete!" "Green"
    Write-Host ""
    Show-Help
}

# --- Toggle ---
function Enable-Hud {
    $status = Get-Status
    if ($status -eq "not_installed") {
        Write-Color "ERROR: Not installed. Run .\install.ps1 first" "Red"
        return
    }
    try {
        $s = Get-Content $SettingsFile -Raw | ConvertFrom-Json
        $s | Add-Member -Force -NotePropertyName "statusLine" -NotePropertyValue @{
            type = "command"
            command = "bash $TargetScriptUnix"
        }
        Save-Settings $s
        Write-Color "[HUD] Enabled" "Green"
    } catch {
        Write-Color "ERROR: Failed to enable: $_" "Red"
    }
}

function Disable-Hud {
    $status = Get-Status
    if ($status -eq "not_installed") {
        Write-Color "ERROR: Not installed" "Red"
        return
    }
    try {
        $s = Get-Content $SettingsFile -Raw | ConvertFrom-Json
        $s | Add-Member -Force -NotePropertyName "statusLine" -NotePropertyValue @{
            type = "command"
            command = ""
        }
        Save-Settings $s
        Write-Color "[HUD] Disabled" "Yellow"
    } catch {
        Write-Color "ERROR: Failed to disable: $_" "Red"
    }
}

# --- Remove ---
function Remove-Hud {
    Show-Banner
    Write-Color "This will:" "Yellow"
    Write-Host "  Delete: $TargetScript" -ForegroundColor Gray
    Write-Host "  Remove statusLine from settings.json" -ForegroundColor Gray
    Write-Host ""

    $confirm = Read-Host "Confirm removal? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Color "Removal cancelled" "Yellow"
        return
    }

    # Delete script
    if (Test-Path $TargetScript) {
        Remove-Item $TargetScript -Force
        Write-Color "  OK: Script deleted" "Green"
    }

    # Remove config
    if (Test-Path $SettingsFile) {
        try {
            $s = Get-Content $SettingsFile -Raw | ConvertFrom-Json
            if ($null -ne $s.statusLine) {
                $backup = "$SettingsFile.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
                Copy-Item $SettingsFile $backup
                $s.PSObject.Properties.Remove('statusLine')
                Save-Settings $s
                Write-Color "  OK: statusLine removed (backup: $backup)" "Green"
            }
        } catch {
            Write-Color "  ERROR: Failed to update settings.json: $_" "Red"
        }
    }

    Write-Color "Removal complete!" "Green"
}

function Show-Help {
    Write-Color "========== Usage ==========" "Cyan"
    Write-Host " Start Claude Code to see the status bar"
    Write-Host ""
    Write-Host " Commands:" -ForegroundColor Gray
    Write-Host "   .\install.ps1          -- Install and enable" -ForegroundColor White
    Write-Host "   .\install.ps1 -On      -- Enable" -ForegroundColor White
    Write-Host "   .\install.ps1 -Off     -- Disable" -ForegroundColor White
    Write-Host "   .\install.ps1 -Status  -- Check status" -ForegroundColor White
    Write-Host "   .\install.ps1 -Remove  -- Uninstall" -ForegroundColor White
    Write-Host ""
    Write-Color "Tip: Restart Claude Code if the status bar doesn't appear" "Yellow"
}

# --- Main ---
if ($Help) {
    Show-Help
    exit
}

if ($Status) {
    Show-Status
    exit
}

if ($Off) {
    Disable-Hud
    exit
}

if ($On) {
    Enable-Hud
    exit
}

if ($Remove) {
    Remove-Hud
    exit
}

# Default: install
Install-Hud
