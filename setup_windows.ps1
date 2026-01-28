# ===========================================
# Limpeza David TOP - Instalador Windows
# ===========================================

param(
    [switch]$Silent = $false
)

$ErrorActionPreference = "Stop"

# Cores
function Write-Color {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

Clear-Host
Write-Color "`n╔══════════════════════════════════════════════════════╗" "Magenta"
Write-Color "║                                                      ║" "Magenta"
Write-Color "║        🧹 LIMPEZA DAVID TOP - INSTALADOR            ║" "Magenta"
Write-Color "║                                                      ║" "Magenta"
Write-Color "╚══════════════════════════════════════════════════════╝`n" "Magenta"

# Diretórios
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallDir = "$env:LOCALAPPDATA\LimpezaDavid"
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$StartMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"

# Funções auxiliares
function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Install-Chocolatey {
    if (-not (Test-CommandExists "choco")) {
        Write-Color "  Instalando Chocolatey..." "Yellow"
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }
}

# [1/6] Verificar dependências
Write-Color "[1/6] Verificando dependências..." "Yellow"

# Python
if (Test-CommandExists "python") {
    Write-Color "  ✓ Python" "Green"
} else {
    Write-Color "  Instalando Python..." "Yellow"
    Install-Chocolatey
    choco install python -y --no-progress
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Node.js
if (Test-CommandExists "node") {
    Write-Color "  ✓ Node.js" "Green"
} else {
    Write-Color "  Instalando Node.js..." "Yellow"
    Install-Chocolatey
    choco install nodejs -y --no-progress
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Git
if (Test-CommandExists "git") {
    Write-Color "  ✓ Git" "Green"
}

# [2/6] Copiar arquivos
Write-Color "`n[2/6] Copiando arquivos para $InstallDir..." "Yellow"

if (Test-Path $InstallDir) {
    Remove-Item -Recurse -Force $InstallDir
}
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Copy-Item -Recurse -Force "$ScriptDir\*" $InstallDir

Set-Location $InstallDir

# [3/6] Ambiente Python
Write-Color "`n[3/6] Configurando ambiente Python..." "Yellow"

python -m venv venv
& ".\venv\Scripts\Activate.ps1"
python -m pip install --upgrade pip -q
pip install flask flask-cors -q

Write-Color "  ✓ Flask instalado" "Green"

# [4/6] Frontend
Write-Color "`n[4/6] Instalando frontend React..." "Yellow"

Set-Location frontend
npm install --silent 2>$null
npm run build --silent 2>$null
Set-Location ..

Write-Color "  ✓ Frontend compilado" "Green"

# [5/6] Script de execução
Write-Color "`n[5/6] Criando script de execução..." "Yellow"

$StartScript = @"
@echo off
cd /d "%~dp0"
call venv\Scripts\activate.bat
python run_web.py
"@

Set-Content -Path "$InstallDir\start.bat" -Value $StartScript

# Script PowerShell oculto (para atalho sem janela do CMD)
$StartScriptPS = @"
Set-Location `"$InstallDir`"
& `".\venv\Scripts\Activate.ps1`"
python run_web.py
"@

Set-Content -Path "$InstallDir\start.ps1" -Value $StartScriptPS

# [6/6] Atalho na área de trabalho
Write-Color "`n[6/6] Criando atalho na área de trabalho..." "Yellow"

$WshShell = New-Object -ComObject WScript.Shell

# Atalho Desktop
$Shortcut = $WshShell.CreateShortcut("$DesktopPath\Limpeza David.lnk")
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$InstallDir\start.ps1`""
$Shortcut.WorkingDirectory = $InstallDir
$Shortcut.IconLocation = "$InstallDir\assets\icon.ico,0"
$Shortcut.Description = "Ferramenta de Limpeza de Sistema"
$Shortcut.Save()

Write-Color "  ✓ Atalho criado: Desktop" "Green"

# Atalho Menu Iniciar
$Shortcut = $WshShell.CreateShortcut("$StartMenuPath\Limpeza David.lnk")
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$InstallDir\start.ps1`""
$Shortcut.WorkingDirectory = $InstallDir
$Shortcut.IconLocation = "$InstallDir\assets\icon.ico,0"
$Shortcut.Description = "Ferramenta de Limpeza de Sistema"
$Shortcut.Save()

Write-Color "  ✓ Atalho criado: Menu Iniciar" "Green"

# Finalização
Write-Color "`n╔══════════════════════════════════════════════════════╗" "Green"
Write-Color "║                                                      ║" "Green"
Write-Color "║     ✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO!            ║" "Green"
Write-Color "║                                                      ║" "Green"
Write-Color "╚══════════════════════════════════════════════════════╝" "Green"

Write-Color "`n  Para usar o Limpeza David:" "Cyan"
Write-Color ""
Write-Color "  ➜ Clique duas vezes no ícone `"Limpeza David`"" "White"
Write-Color "    na sua área de trabalho!" "Gray"
Write-Color ""

if (-not $Silent) {
    $response = Read-Host "Deseja abrir o Limpeza David agora? [S/n]"
    if ($response -eq "" -or $response -match "^[Ss]") {
        Write-Color "`n🚀 Iniciando Limpeza David...`n" "Green"
        Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$InstallDir\start.ps1`""
    }
}
