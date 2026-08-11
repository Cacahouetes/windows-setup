#Requires -Version 5.1
# ======================================================================
#  setup.ps1 - Post-installation Windows 11
#  WinUtil + Winhance + MAS (activation) - 100% en ligne : aucun
#  executable local, tout est telecharge et execute a la volee.
#
#  Usage interactif (menu) :
#    powershell -ExecutionPolicy Bypass -Command "irm 'URL_DU_SCRIPT' | iex"
#
#  Usage automatique guide (questions en debut) :
#    powershell -ExecutionPolicy Bypass -Command "& ([ScriptBlock]::Create((irm 'URL_DU_SCRIPT'))) -Auto"
#
#  A personnaliser avant mise en ligne : section CONFIG ci-dessous.
# ======================================================================
param(
    [switch]$Interactive,
    [switch]$Auto,
    [ValidateSet('Standard','Minimal','Advanced')]
    [string]$Preset = 'Advanced',
    [switch]$NoOffice,
    [switch]$NoWinhance,
    [switch]$NoActivation
)

# ======================================================================
#  CONFIG - A ADAPTER A VOTRE DEPOT GITHUB
# ======================================================================
$ScriptUrl          = "https://raw.githubusercontent.com/Cacahouetes/windows-setup/main/setup.ps1"
$WinhanceConfigUrl  = "https://raw.githubusercontent.com/Cacahouetes/windows-setup/main/Winhance_Config.winhance"
$OfficeEdition      = "O365ProPlusRetail"
$OfficeChannel      = "Current"
$OfficeLanguage     = "fr-fr"
$OfficeArch         = "64"

# ======================================================================
#  PRETRAITEMENT (TLS, admin, elevation)
# ======================================================================
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
$ProgressPreference = 'SilentlyContinue'

function Test-Admin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-Switches {
    $list = @()
    if ($Interactive) { $list += '-Interactive' }
    if ($Auto)        { $list += '-Auto' }
    if ($Preset -ne 'Advanced') { $list += "-Preset '$Preset'" }
    if ($NoOffice)    { $list += '-NoOffice' }
    if ($NoWinhance)  { $list += '-NoWinhance' }
    if ($NoActivation){ $list += '-NoActivation' }
    return ($list -join ' ')
}

function Restart-Elevated {
    $switches = Get-Switches
    if ($ScriptUrl -match '^https?://' -and $ScriptUrl -notmatch 'VOTRE_') {
        $cmd = "& ([ScriptBlock]::Create((irm '$ScriptUrl'))) $switches"
        $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $enc"
    }
    elseif ($PSCommandPath) {
        $cmd = "& '$PSCommandPath' $switches"
        $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $enc"
    }
    else {
        Write-Host "Impossible de relancer en admin : renseignez l'URL du script (CONFIG) ou lancez PowerShell en tant qu'administrateur." -ForegroundColor Red
        Read-Host "Appuyez sur Entree pour quitter"
    }
    exit
}

# ======================================================================
#  FONCTIONS
# ======================================================================
function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "   +-------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "   |  POST-INSTALLATION WINDOWS 11 - tout en ligne         |" -ForegroundColor Cyan
    Write-Host "   |  WinUtil  +  Winhance  +  MAS (activation)            |" -ForegroundColor Cyan
    Write-Host "   +-------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
}

function Confirm-Prompt {
    param([string]$Message)
    $r = Read-Host "$Message (O/N)"
    return ($r -match '^(o|oui|y|yes)$')
}

function New-RestorePointSystem {
    Write-Host ""
    Write-Host "   Point de restauration..." -ForegroundColor Cyan
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Setup Windows $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -RestoreType 'MODIFY_SETTINGS' -ErrorAction Stop
        Write-Host "   Point de restauration cree." -ForegroundColor Green
    }
    catch {
        Write-Host "   Erreur : $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Invoke-WinUtilPreset {
    param([string]$PresetName = $script:Preset)
    if ([string]::IsNullOrWhiteSpace($PresetName) -or $PresetName -eq '0') { return }
    Write-Host ""
    Write-Host "   WinUtil - application du preset '$PresetName' (automatique, sans fenetre)..." -ForegroundColor Cyan
    & ([ScriptBlock]::Create((irm https://christitus.com/win))) -Preset $PresetName
    Write-Host "   Preset WinUtil '$PresetName' termine." -ForegroundColor Green
}

function Invoke-WinUtilInteractive {
    Write-Host ""
    Write-Host "   WinUtil - ouverture de la fenetre (choix libre des applications" -ForegroundColor Cyan
    Write-Host "   et des tweaks). Fermez WinUtil pour continuer." -ForegroundColor Cyan
    irm https://christitus.com/win | iex
    Write-Host "   WinUtil ferme." -ForegroundColor Green
}

function Install-Winhance {
    Write-Host ""
    Write-Host "   Installation de Winhance (get.winhance.net)..." -ForegroundColor Cyan
    Write-Host "   Un installeur peut s'ouvrir : suivez l'installation."
    irm "https://get.winhance.net" | iex
    Write-Host "   Winhance installe." -ForegroundColor Green
}

function Apply-WinhanceConfig {
    if ($WinhanceConfigUrl -match 'VOTRE_') {
        Write-Host "   [ATTENTION] URL du profil Winhance non configuree (section CONFIG)." -ForegroundColor Yellow
        Write-Host "   Hebergez votre fichier .winhance sur GitHub et renseignez $WinhanceConfigUrl."
        return
    }
    $local = "$env:TEMP\Winhance_Config.winhance"
    if (Test-Path $local) { Remove-Item $local -Force }
    Write-Host "   Telechargement du profil Winhance..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest $WinhanceConfigUrl -OutFile $local -UseBasicParsing
    }
    catch {
        Write-Host "   Erreur de telechargement du profil : $($_.Exception.Message)" -ForegroundColor Red
        return
    }
    Write-Host ""
    Write-Host "   Profil telecharge : $local" -ForegroundColor Green
    Write-Host "   Winhance ne dispose pas encore d'une CLI pour appliquer un profil."
    Write-Host "   Derniere etape manuelle (2 clics) :"
    Write-Host "     1. Dans Winhance : Config -> Import Config"
    Write-Host "     2. Selectionnez le fichier ci-dessus (ouvert dans l'explorateur)."
    Start-Process explorer.exe "/select,`"$local`""
}

function Install-OfficeOnline {
    Write-Host ""
    Write-Host "   Installation de Microsoft Office via l'Office Deployment Tool (CDN Microsoft)..." -ForegroundColor Cyan
    try {
        $temp = "$env:TEMP\OfficeODT"
        New-Item -ItemType Directory -Force -Path $temp | Out-Null
        $odt = "$env:TEMP\officedeploymenttool.exe"
        Write-Host "   Telechargement de l'ODT..."
        Invoke-WebRequest "https://go.microsoft.com/fwlink/p/?LinkID=626890" -OutFile $odt -UseBasicParsing
        Write-Host "   Extraction..."
        Start-Process $odt -ArgumentList "/quiet", "/extract:`"$temp`"" -Wait
        $setup = "$temp\setup.exe"
        if (-not (Test-Path $setup)) {
            Write-Host "   [ERREUR] setup.exe de l'ODT introuvable dans $temp" -ForegroundColor Red
            return
        }
        $config = @"
<Configuration>
  <Add OfficeClientEdition="$OfficeArch" Channel="$OfficeChannel" ForceUpgrade="TRUE">
    <Product ID="$OfficeEdition">
      <Language ID="$OfficeLanguage" />
    </Product>
  </Add>
  <Display Level="None" AcceptEULA="TRUE" />
  <Property Name="AUTOACTIVATE" Value="0" />
  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
</Configuration>
"@
        $config | Set-Content "$temp\config.xml" -Encoding ASCII
        Write-Host "   Installation silencieuse (peut prendre plusieurs minutes)..."
        Start-Process $setup -ArgumentList "/configure", "`"$temp\config.xml`"" -Wait
        Write-Host "   Microsoft Office installe." -ForegroundColor Green
    }
    catch {
        Write-Host "   Erreur : $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Invoke-MASActivation {
    Write-Host ""
    Write-Host "   Activation Windows / Office - MAS (massgrave.dev)" -ForegroundColor Cyan
    Write-Host "    [1] Aucune"
    Write-Host "    [2] Windows uniquement (HWID, permanent)"
    Write-Host "    [3] Windows + Office (HWID + Ohook, permanent)"
    Write-Host "    [4] Office uniquement (Ohook, permanent)"
    $choice = Read-Host "   Votre choix"
    switch ($choice) {
        '2' { $mas = @('/HWID', '/S') }
        '3' { $mas = @('/HWID', '/Ohook', '/S') }
        '4' { $mas = @('/Ohook', '/S') }
        default { $mas = $null }
    }
    if ($mas) {
        Write-Host "   Activation en cours (silencieux) : $($mas -join ' ')"
        & ([ScriptBlock]::Create((irm https://get.activated.win))) @mas
        Write-Host "   Activation terminee." -ForegroundColor Green
    }
    else {
        Write-Host "   Activation ignoree." -ForegroundColor Yellow
    }
}

function Start-Auto {
    Write-Banner
    Write-Host "   MODE AUTOMATIQUE (guide)" -ForegroundColor Cyan
    Write-Host ""

    # --- Question 1 : point de restauration ---
    if (Confirm-Prompt "   Creer un point de restauration ?") { New-RestorePointSystem }

    # --- Question 2 : tweaks WinUtil ---
    $winutilOpened = $false
    Write-Host ""
    Write-Host "   Tweaks WinUtil a appliquer automatiquement :"
    Write-Host "    [0] Aucun"
    Write-Host "    [1] Standard"
    Write-Host "    [2] Advanced (defaut)"
    Write-Host "    [3] Custom (choix manuel dans WinUtil)"
    $t = Read-Host "   Votre choix (Entree = Advanced)"
    if ([string]::IsNullOrWhiteSpace($t)) { $t = '2' }
    switch ($t) {
        '1' { Invoke-WinUtilPreset -PresetName 'Standard' }
        '2' { Invoke-WinUtilPreset -PresetName 'Advanced' }
        '3' { Invoke-WinUtilInteractive; $winutilOpened = $true }
        default { Write-Host "   Aucun tweak WinUtil applique." -ForegroundColor Yellow }
    }

    # --- Question 3 : ouverture de WinUtil pour apps / tweaks customs ---
    if (-not $winutilOpened -and (Confirm-Prompt "`n   Ouvrir WinUtil pour installer des applications et/ou appliquer des tweaks supplementaires ?")) {
        Invoke-WinUtilInteractive
    }

    # --- Question 4 : Office ---
    if (-not $NoOffice -and (Confirm-Prompt "`n   Installer Microsoft Office ?")) { Install-OfficeOnline }

    # --- Question 5 : activation ---
    if (-not $NoActivation) { Invoke-MASActivation }

    # --- Question 6 : Winhance + profil ---
    if (-not $NoWinhance -and (Confirm-Prompt "`n   Installer Winhance et recuperer le profil ?")) {
        Install-Winhance
        Apply-WinhanceConfig
    }

    Write-Host ""
    Write-Host "   ================================================================" -ForegroundColor Green
    Write-Host "   INSTALLATION AUTOMATIQUE TERMINEE" -ForegroundColor Green
    Write-Host "   Rappel : la seule action manuelle restante est l'import du profil" -ForegroundColor Green
    Write-Host "   Winhance (Config -> Import Config), Winhance n'ayant pas encore" -ForegroundColor Green
    Write-Host "   de CLI pour appliquer un profil." -ForegroundColor Green
    Write-Host "   ================================================================" -ForegroundColor Green
    Write-Host ""
}

function Show-MainMenu {
    do {
        Write-Banner
        Write-Host "   MANUEL" -ForegroundColor Cyan
        Write-Host "   ---------------------------------------------------------"
        Write-Host "    [1] Point de restauration systeme"
        Write-Host "    [2] WinUtil - ouverture complete (apps + tweaks, libre)"
        Write-Host "    [3] Winhance - installation + profil (import manuel final)"
        Write-Host "    [4] Microsoft Office - installation silencieuse (ODT)"
        Write-Host "    [5] Activation Windows / Office - MAS"
        Write-Host ""
        Write-Host "   AUTOMATIQUE" -ForegroundColor Cyan
        Write-Host "    [6] Installation automatique (guidee)"
        Write-Host ""
        Write-Host "    [0] Quitter"
        Write-Host ""
        $c = Read-Host "   Votre choix"
        switch ($c) {
            '1' { New-RestorePointSystem }
            '2' { Invoke-WinUtilInteractive }
            '3' { Install-Winhance; Apply-WinhanceConfig }
            '4' { Install-OfficeOnline }
            '5' { Invoke-MASActivation }
            '6' { Start-Auto }
            '0' { break }
            default { Write-Host "   Choix invalide." -ForegroundColor Red }
        }
        if ($c -ne '0') {
            Write-Host ""
            Read-Host "   Appuyez sur Entree pour revenir au menu"
        }
    } while ($c -ne '0')
}

# ======================================================================
#  POINT D'ENTREE
# ======================================================================
if (-not (Test-Admin)) { Restart-Elevated }

if ($Auto)      { Start-Auto }
else            { Show-MainMenu }
