<#
    debloat-admin.ps1
    ------------------------------------------------------------------
    Removes the OEM/PUP bloatware that was contributing to the
    "Disk 0 (C:) 100% active time" spikes on this machine.

    Main cause of the spikes is memory over-commit (26.8 GB commit vs
    11.8 GB RAM -> ~15 GB living in the page file), NOT these apps.
    But these still add background commit, services and periodic tasks.

    HOW TO RUN
      1. Open PowerShell as Administrator (Win+X -> "Terminal (Admin)")
      2. cd "C:\Users\bubby\Downloads\Roblox"
      3. Set-ExecutionPolicy -Scope Process Bypass -Force
      4. .\debloat-admin.ps1

    Nothing here is irreversible except where noted - all of these can
    be reinstalled from the vendor if you actually want them back.
#>

$ErrorActionPreference = 'Continue'
$removed = New-Object System.Collections.Generic.List[string]
$failed  = New-Object System.Collections.Generic.List[string]

# ---------------------------------------------------------------- elevation
$isAdmin = (New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host ""
    Write-Host "  !! Not elevated - this script will do nothing useful." -ForegroundColor Red
    Write-Host "     Open an ADMIN PowerShell and re-run:" -ForegroundColor Red
    Write-Host "         Set-ExecutionPolicy -Scope Process Bypass -Force" -ForegroundColor Yellow
    Write-Host "         & '$PSCommandPath'" -ForegroundColor Yellow
    Write-Host ""
    return
}

Write-Host ""
Write-Host "=== Debloat: removing OEM/PUP software ===" -ForegroundColor Cyan
Write-Host ""

$uninstallRoots = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

function Get-InstalledApp {
    param([string]$Match)
    Get-ItemProperty $uninstallRoots -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match $Match } |
        Select-Object -First 1
}

function Invoke-SilentUninstall {
    param(
        [string]$Label,
        [string]$Exe,
        [string]$ArgumentList
    )

    $app = Get-InstalledApp $Label
    if (-not $app) {
        Write-Host ("  [skip] {0} - not installed" -f $Label) -ForegroundColor DarkGray
        return
    }

    if (-not (Test-Path $Exe)) {
        Write-Host ("  [warn] {0} - uninstaller missing at {1}" -f $Label, $Exe) -ForegroundColor Yellow
        $failed.Add("$Label (uninstaller not found)")
        return
    }

    Write-Host ("  [run ] {0}  ({1})" -f $Label, $app.DisplayName) -ForegroundColor White
    try {
        $proc = Start-Process -FilePath $Exe -ArgumentList $ArgumentList -Wait -PassThru -ErrorAction Stop
        Write-Host ("         exit code = {0}" -f $proc.ExitCode) -ForegroundColor DarkGray
    } catch {
        Write-Host ("         launch failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        $failed.Add("$Label (launch failed)")
        return
    }

    # give the uninstaller a moment, then re-check
    Start-Sleep -Seconds 5
    if (Get-InstalledApp $Label) {
        Write-Host "         still registered - may need an interactive run" -ForegroundColor Yellow
        $failed.Add("$Label (still registered)")
    } else {
        Write-Host "         removed OK" -ForegroundColor Green
        $removed.Add($Label)
    }
}

# ---------------------------------------------------------------------------
# 1. McAfee Security Scan Plus - pure OEM bundleware. Its service was already
#    stopped; it contributes an uninstall nag and a background scheduler task.
# ---------------------------------------------------------------------------
Invoke-SilentUninstall `
    -Label 'McAfee Security Scan' `
    -Exe   'C:\Program Files (x86)\McAfee Security Scan\uninstall.exe' `
    -ArgumentList '/S'

# ---------------------------------------------------------------------------
# 2. Outbyte Driver Updater - scareware-style driver updater (PUP). No reason
#    to keep it; Windows Update + Lenovo Vantage already handle drivers.
# ---------------------------------------------------------------------------
Invoke-SilentUninstall `
    -Label 'Outbyte Driver Updater' `
    -Exe   'C:\Program Files (x86)\Outbyte\Driver Updater\unins000.exe' `
    -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART'

# ---------------------------------------------------------------------------
# 3. Google Play Games - OEM bundle. Registry adds two logon/unlock tasks
#    (\GoogleUserPEH\RunPlatformExperienceHelper_Metrics and _OnUnlock).
#    Reinstallable from Google at any time.
# ---------------------------------------------------------------------------
Invoke-SilentUninstall `
    -Label 'Google Play Games' `
    -Exe   'C:\Program Files\Google\Play Games\Uninstaller.exe' `
    -ArgumentList '/S /o{47B07D71-505D-4665-AFD4-4972A30C6530}'

# ---------------------------------------------------------------------------
# 4. Leftover HP Print Scan Doctor background bits. The app itself has no
#    Uninstall entry on this machine, so only the orphan service + task are
#    cleaned up. Harmless if they are already gone.
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "--- HP Print Scan Doctor leftovers ---" -ForegroundColor Cyan

$hpTask = Get-ScheduledTask -TaskPath '\HP\HP Print Scan Doctor\*' -ErrorAction SilentlyContinue
if ($hpTask) {
    foreach ($t in $hpTask) {
        try {
            Unregister-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath -Confirm:$false -ErrorAction Stop
            Write-Host ("  [ok  ] removed task {0}{1}" -f $t.TaskPath, $t.TaskName) -ForegroundColor Green
            $removed.Add("HP task $($t.TaskName)")
        } catch {
            Write-Host ("  [warn] could not remove {0}: {1}" -f $t.TaskName, $_.Exception.Message) -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  [skip] no HP Print Scan Doctor tasks" -ForegroundColor DarkGray
}

$hpSvc = Get-Service -Name 'HPPrintScanDoctorService' -ErrorAction SilentlyContinue
if ($hpSvc) {
    Write-Host "  [note] HPPrintScanDoctorService still present - remove via HP's own uninstaller if you want it gone" -ForegroundColor Yellow
} else {
    Write-Host "  [skip] no HPPrintScanDoctorService" -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------------
# 5. NOT REMOVED ON PURPOSE - holds your data, left installed:
#
#       BlueStacks / BlueStacks Services  -> Android emulator, deleting
#                                            destroys your VMs + Android apps
#       Adobe Acrobat / Creative Cloud    -> you may need PDF / CC
#       Lenovo Vantage + its addins       -> you asked to keep this
#       Lenovo Euterpe Wireless Keyboard  -> this drives your laptop keyboard
#       Lenovo A940 Calliope Keyboard     -> driver package, left alone to
#                                            avoid breaking input devices
#       EA app / Riot Client / Firefox / Chrome / Epson / Canon
#                                         -> real user software, not bloat
#
#    If you DO want BlueStacks gone, uncomment the two lines below and
#    re-run this script (this is irreversible - it deletes your VMs):
# ---------------------------------------------------------------------------
# Invoke-SilentUninstall -Label 'BlueStacks Services' -Exe "$env:LOCALAPPDATA\Programs\bluestacks-services\Uninstall BlueStacksServices.exe" -ArgumentList '/currentuser /S'
# Invoke-SilentUninstall -Label 'BlueStacks'          -Exe 'C:\Program Files\BlueStacks_nxt\BlueStacksUninstaller.exe' -ArgumentList '-s -removeAll'

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Result ===" -ForegroundColor Cyan
if ($removed.Count) {
    Write-Host "  Removed:" -ForegroundColor Green
    $removed | ForEach-Object { Write-Host "    - $_" }
} else {
    Write-Host "  Nothing was removed." -ForegroundColor Yellow
}
if ($failed.Count) {
    Write-Host "  Needs attention:" -ForegroundColor Yellow
    $failed | ForEach-Object { Write-Host "    - $_" }
}

Write-Host ""
Write-Host "Reboot, then re-check Task Manager > Performance > Disk 0." -ForegroundColor Cyan
Write-Host "If it still pegs at 100%, the cause is page-file thrashing from" -ForegroundColor Cyan
Write-Host "memory pressure (26.8 GB committed vs 11.8 GB RAM)." -ForegroundColor Cyan
Write-Host ""
