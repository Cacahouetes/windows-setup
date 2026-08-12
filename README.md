# Windows Setup

Script d'installation post-Windows 11 **100% en ligne** : aucun exécutable local nécessaire.
Il orchestre **WinUtil** (Chris Titus Tech), **Winhance** et l'activation **MAS** (Massgrave),
plus l'installation silencieuse de **Microsoft Office** via l'Office Deployment Tool (CDN Microsoft).

Tout est téléchargé et exécuté à la volée, comme WinUtil. Lancez-le, répondez aux questions, c'est fini.

## Prérequis

- Windows 10 / 11 (PowerShell 5.1+)
- Droits administrateur (le script s'auto-élève via UAC)
- Connexion internet

## Démarrage rapide

**Mode interactif (menu) :**

```powershell
irm https://raw.githubusercontent.com/Cacahouetes/windows-setup/main/setup.ps1 | iex
```

**Mode automatique (questions guidées) :**

```powershell
powershell -ExecutionPolicy Bypass -Command "& ([ScriptBlock]::Create((irm https://raw.githubusercontent.com/Cacahouetes/windows-setup/main/setup.ps1))) -Auto"
```

## Menu

```
MANUEL
  [1] Point de restauration système
  [2] WinUtil - ouverture complète (apps + tweaks, choix libre)
  [3] Winhance - installation + profil (import manuel final)
  [4] Microsoft Office - installation silencieuse (ODT)
  [5] Activation Windows / Office - MAS

AUTOMATIQUE
  [6] Installation automatique (guidée)

  [0] Quitter
```

## Mode automatique

Le mode `-Auto` pose les questions dans l'ordre suivant :

1. **Créer un point de restauration** ?
2. **Tweaks WinUtil** : Aucun / Standard / Advanced (défaut) / Custom (choix manuel dans WinUtil)
3. **Ouvrir WinUtil** pour installer des applications et/ou appliquer des tweaks supplémentaires
   (sautée si `Custom` a été choisi, pour éviter d'ouvrir la fenêtre deux fois)
4. **Installer Microsoft Office** ?
5. **Activation** Windows et/ou Office (MAS : HWID + Ohook)
6. **Installer Winhance et récupérer le profil** ?

## Personnalisation

En tête de `setup.ps1` (section `CONFIG`) :

| Variable | Rôle |
|---|---|
| `$ScriptUrl` | URL de ce script sur GitHub (utilisée pour l'auto-élévation) |
| `$WinhanceConfigUrl` | URL du profil `.winhance` à récupérer |
| `$OfficeEdition` | Édition Office (`O365ProPlusRetail`, `ProPlus2024Volume`, ...) |
| `$OfficeChannel` | Canal (`Current`, `SemiAnnual`, `PerpetualVL2024`, ...) |
| `$OfficeLanguage` | Langue (`fr-fr`, `en-us`, ...) |
| `$OfficeArch` | Architecture (`64` / `32`) |

Options supplémentaires : `-NoOffice`, `-NoWinhance`, `-NoActivation`,
`-Preset Minimal|Standard|Advanced` (défaut : `Advanced`).

## Contenu du dépôt

| Fichier | Rôle |
|---|---|
| `setup.ps1` | Le script principal |
| `Winhance_Config.winhance` | Profil Winhance pré-configuré, importé à l'étape 6 |

## Limitation connue : Winhance

À la date de ce README, Winhance ne dispose pas encore d'une CLI pour appliquer un profil `.winhance`.
C'est la **seule étape non automatisée** : après l'installation, le script télécharge le profil et
l'ouvre dans l'explorateur. Il reste 2 clics manuels dans Winhance :

1. `Config` -> `Import Config`
2. Sélectionner le fichier téléchargé

Dès que Winhance proposera une CLI, cette étape sera automatisée.

## Outils utilisés

- **WinUtil** - <https://christitus.com/win> (apps via winget, tweaks, presets)
- **Winhance** - <https://winhance.net> (personnalisation, debloat, performances)
- **MAS (Massgrave)** - <https://massgrave.dev> (activation Windows / Office)
- **Office Deployment Tool** - CDN Microsoft (installation silencieuse d'Office)

## Avertissement

MAS est un outil de contournement de licence. Son usage engage la responsabilité de
la personne qui l'exécute au regard des conditions de licence Microsoft.
