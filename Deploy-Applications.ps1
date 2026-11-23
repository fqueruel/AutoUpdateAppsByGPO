# =================================================================
# Generic Application Deployment Engine
# =================================================================

$ConfigFile = Join-Path $PSScriptRoot "Applications.psd1"

if (-not (Test-Path $ConfigFile)) {

    Write-Host ""
    Write-Host "Fichier de configuration introuvable." -ForegroundColor Red
    Write-Host $ConfigFile -ForegroundColor Yellow

    exit 1
}

$Config = Import-PowerShellDataFile $ConfigFile

$LogFolder = "C:\ProgramData\Lucas\Logs"
$CentralLogRoot = "\\sblvpn001\logs$\Applications"

$EventLogName = "Application"
$EventSource = "Lucas Software Deployment"

if (-not (Test-Path $LogFolder)) {

    New-Item `
        -Path $LogFolder `
        -ItemType Directory `
        -Force | Out-Null
}

# Purge des logs > 90 jours
Get-ChildItem `
    -Path $LogFolder `
    -Filter *.log `
    -File `
    -ErrorAction SilentlyContinue |
    Where-Object {
        $_.LastWriteTime -lt (Get-Date).AddDays(-90)
    } |
    Remove-Item `
        -Force `
        -ErrorAction SilentlyContinue

# =================================================================
# Fonctions
# =================================================================

function Write-Log {

    param(
        [string]$Application,
        [string]$Message,
        [string]$Level = "INFO"
    )

    $Line = "{0} [{1}] [{2}] {3}" -f `
        (Get-Date -Format "yyyy-MM-dd HH:mm:ss"),
        $Application,
        $Level,
        $Message

    switch ($Level) {

        "ERROR" {
            Write-Host $Line -ForegroundColor Red
        }

        "WARNING" {
            Write-Host $Line -ForegroundColor Yellow
        }

        default {
            Write-Host $Line -ForegroundColor White
        }
    }

    try {

        $EntryType = switch ($Level) {

            "ERROR" { "Error" }
            "WARNING" { "Warning" }

            default { "Information" }
        }

        $EventId = switch ($Level) {

            "ERROR" { 1002 }
            "WARNING" { 1001 }

            default { 1000 }
        }

        Write-EventLog `
            -LogName $EventLogName `
            -Source $EventSource `
            -EntryType $EntryType `
            -EventId $EventId `
            -Message "[$Application] $Message"

    }
    catch {}

    $SafeApplicationName =
        ($Application -replace '[\\/:*?"<>| ]','_')

    $LogFile = Join-Path `
        $LogFolder `
        "$SafeApplicationName.log"

    Add-Content `
        -Path $LogFile `
        -Value $Line `
        -Encoding UTF8
}

function Initialize-EventLog {

    try {

        $RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\$EventLogName\$EventSource"

        if (-not (Test-Path $RegistryPath)) {

            New-EventLog `
                -LogName $EventLogName `
                -Source $EventSource
        }
    }
    catch {}
}

function Copy-ApplicationLog {

    param(
        [string]$Application
    )

    try {

        $SafeApplicationName =
            ($Application -replace '[\\/:*?"<>| ]','_')

        $SourceLog = Join-Path `
            $LogFolder `
            "$SafeApplicationName.log"

        if (-not (Test-Path $SourceLog)) {
            return
        }

        $DestinationFolder = Join-Path `
            $CentralLogRoot `
            "$SafeApplicationName\$((Get-Date).ToString('yyyy-MM'))"

        if (-not (Test-Path $DestinationFolder)) {

            New-Item `
                -Path $DestinationFolder `
                -ItemType Directory `
                -Force | Out-Null
        }

        $DestinationFile = Join-Path `
    $DestinationFolder `
    "$($env:COMPUTERNAME).log"

        Copy-Item `
            -Path $SourceLog `
            -Destination $DestinationFile `
            -Force
    }
    catch {}
}


function Get-InstalledVersion {

    param(
        [string]$DisplayNamePattern
    )

    $RegistryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($Path in $RegistryPaths) {

        $Application = Get-ItemProperty `
            -Path $Path `
            -ErrorAction SilentlyContinue |
            Where-Object {

                $_.DisplayName -match $DisplayNamePattern

            } |
            Select-Object -First 1

        if ($Application) {

            #Write-Host "Trouvé : $($Application.DisplayName)"

            return $Application.DisplayVersion
        }
    }

    return $null
}

function Get-TargetVersion {

    param(
        [hashtable]$Application
    )

    switch ($Application.VersionSource) {

        "FileVersion" {

            $Info = Get-Item $Application.Installer

            if ($Info.VersionInfo.ProductVersion) {

                return $Info.VersionInfo.ProductVersion
            }

            return $Info.VersionInfo.FileVersion
        }

        "FileName" {

            $FileName = [System.IO.Path]::GetFileNameWithoutExtension(
                $Application.Installer
            )

            if ($FileName -match '(\d+\.\d+(\.\d+)*)') {

                return $Matches[1]
            }

            return $null
        }
    }
}

function Test-TeamViewerOtherEditionInstalled {

    $RegistryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($Path in $RegistryPaths) {

        $Application = Get-ItemProperty `
            -Path $Path `
            -ErrorAction SilentlyContinue |
            Where-Object {
                $_.DisplayName -match "TeamViewer" -and
                $_.DisplayName -ne "TeamViewer Host"
            }

        if ($Application) {
            return $true
        }
    }

    return $false
}

# =================================================================
# Début
# =================================================================
Initialize-EventLog

Clear-Host

Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host " Déploiement automatique des applications " -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

$SuccessCount = 0
$SkippedCount = 0
$FailedCount = 0

$TotalApplications = $Config.Applications.Count
$CurrentIndex = 0

foreach ($Application in $Config.Applications) {

    $CurrentIndex++

    $Percent = [math]::Round(
        ($CurrentIndex / $TotalApplications) * 100,
        0
    )

    Write-Progress `
        -Activity "Déploiement des applications" `
        -Status $Application.Name `
        -PercentComplete $Percent

    $Name = $Application.Name

    Write-Host ""
    Write-Host "---------------------------------------------------" -ForegroundColor Cyan
    Write-Host " $Name" -ForegroundColor Cyan
    Write-Host "---------------------------------------------------" -ForegroundColor Cyan

    Write-Log $Name "Début traitement"

    if (-not (Test-Path $Application.Installer)) {

        Write-Log `
            $Name `
            "Installeur introuvable : $($Application.Installer)" `
            "ERROR"

        $FailedCount++
        Copy-ApplicationLog $Name
        continue
    }

    if (
    $Application.Name -eq "TeamViewer Host" `
    -and
    $Application.ContainsKey("IgnoreIfOtherEditionInstalled") `
    -and
    $Application.IgnoreIfOtherEditionInstalled
) {

    if (Test-TeamViewerOtherEditionInstalled) {

        $InstalledVersion = Get-InstalledVersion `
            $Application.DisplayNamePattern

        if (-not $InstalledVersion) {

            Write-Log `
                $Name `
                "Edition TeamViewer différente détectée. Ignoré." `
                "WARNING"

            Copy-ApplicationLog $Name

            $SkippedCount++
            continue
        }
    }
}

    $InstalledVersion = Get-InstalledVersion `
        $Application.DisplayNamePattern

    $TargetVersion = Get-TargetVersion `
        $Application

    Write-Log $Name "Version installée : [$InstalledVersion]"
    Write-Log $Name "Version cible : [$TargetVersion]"

    if (-not $TargetVersion) {

        Write-Log `
            $Name `
            "Impossible de déterminer la version cible." `
            "ERROR"

            Copy-ApplicationLog $Name
        $FailedCount++
        continue
    }

    $InstallNeeded = $false

    if (-not $InstalledVersion) {

        Write-Log $Name "Application non installée"
        $InstallNeeded = $true
    }
    else {

        try {
            $InstalledVersion =
                ($InstalledVersion -replace '[^0-9\.]', '').Trim()

            $TargetVersion =
                ($TargetVersion -replace '[^0-9\.]', '').Trim()

            if ([Version]$InstalledVersion -lt [Version]$TargetVersion) {

                Write-Log $Name "Mise à jour nécessaire"
                $InstallNeeded = $true
            }
            else {

                Write-Log $Name "Déjà à jour"
            }
        }
        catch {

            Write-Log `
                $Name `
                "Erreur comparaison : $($_.Exception.Message)" `
                "ERROR"

            Copy-ApplicationLog $Name    
            $FailedCount++
            continue
        }
    }

    if (-not $InstallNeeded) {

        Copy-ApplicationLog $Name
        $SkippedCount++
        continue
    }

    foreach ($Process in $Application.Processes) {

        Write-Log `
            $Name `
            "Arrêt du processus : $Process"

        Get-Process `
            -Name $Process `
            -ErrorAction SilentlyContinue |
            Stop-Process -Force
    }

    try {

        Write-Log `
            $Name `
            "Installation en cours"

        if ($Application.InstallerType -eq "MSI") {

            $Arguments = "/i `"$($Application.Installer)`" $($Application.SilentArgs)"

            Write-Log `
                $Name `
                "Commande : msiexec.exe $Arguments"

            $Result = Start-Process `
                msiexec.exe `
                -ArgumentList $Arguments `
                -Wait `
                -PassThru
        }
        else {

            Write-Log `
                $Name `
                "Commande : $($Application.Installer) $($Application.SilentArgs)"

            $Result = Start-Process `
                -FilePath $Application.Installer `
                -ArgumentList $Application.SilentArgs `
                -Wait `
                -PassThru
        }

        Write-Log `
            $Name `
            "Code retour : $($Result.ExitCode)"

        if (
            $Result.ExitCode -eq 0 `
            -or
            $Result.ExitCode -eq 3010 `
            -or
            $Result.ExitCode -eq 1641
        ) {

            Write-Log `
                $Name `
                "Installation réussie"
                

            if ($Application.ContainsKey("PostInstallRegistry")) {

                Write-Log `
                    $Name `
                    "Configuration du registre"

                if (-not (Test-Path $Application.RegistryPath)) {

                    New-Item `
                        -Path $Application.RegistryPath `
                        -Force | Out-Null
                }

                foreach (
                    $Setting in
                    $Application.PostInstallRegistry.GetEnumerator()
                ) {

                    New-ItemProperty `
                        -Path $Application.RegistryPath `
                        -Name $Setting.Key `
                        -Value $Setting.Value.Value `
                        -PropertyType $Setting.Value.Type `
                        -Force | Out-Null
                }
            }

            if ($Application.ContainsKey("RestartService")) {

                Write-Log `
                    $Name `
                    "Redémarrage du service $($Application.RestartService)"

                Restart-Service `
                    $Application.RestartService `
                    -ErrorAction SilentlyContinue
            }
            
            Copy-ApplicationLog $Name
            $SuccessCount++
        }
        else {

            Write-Log `
                $Name `
                "Installation échouée" `
                "ERROR"

            $FailedCount++
            Copy-ApplicationLog $Name
        }

    }
    catch {

        Write-Log `
            $Name `
            $_.Exception.Message `
            "ERROR"

        Copy-ApplicationLog $Name    
        $FailedCount++
    }
}

Write-Progress `
    -Activity "Déploiement des applications" `
    -Completed

Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host " Résumé du traitement " -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""

Write-Host "Succès  : $SuccessCount" -ForegroundColor Green
Write-Host "Ignorés : $SkippedCount" -ForegroundColor Yellow
Write-Host "Erreurs : $FailedCount" -ForegroundColor Red

Write-Host ""
Write-Host "Traitement terminé." -ForegroundColor Cyan
Write-Host ""