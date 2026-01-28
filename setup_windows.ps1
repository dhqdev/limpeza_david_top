# ═══════════════════════════════════════════════════════════════
# 🧹 LIMPEZA DAVID TOP - INSTALADOR COMPLETO PARA WINDOWS
# ═══════════════════════════════════════════════════════════════
# Instala TUDO automaticamente, mesmo em máquinas sem programação
# Execute como Administrador no PowerShell
# ═══════════════════════════════════════════════════════════════

# Cores
$Host.UI.RawUI.WindowTitle = "Instalador - Limpeza David Top"

function Write-Color {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Write-Banner {
    Clear-Host
    Write-Color @"

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🧹  LIMPEZA DAVID TOP - INSTALADOR AUTOMÁTICO          ║
║                                                           ║
║   Instala TUDO que você precisa, mesmo em máquinas       ║
║   que não têm nada de programação instalado!             ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

"@ "Magenta"
}

Write-Banner

# Verificar se é administrador
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Color "[ERRO] Execute este script como Administrador!" "Red"
    Write-Color "Clique direito no PowerShell > 'Executar como administrador'" "Yellow"
    pause
    exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallDir = "$env:LOCALAPPDATA\LimpezaDavid"

# ══════════════════════════════════════════════════════════
# ETAPA 1: INSTALAR CHOCOLATEY (gerenciador de pacotes)
# ══════════════════════════════════════════════════════════
Write-Color "`n[1/7] 📦 Verificando Chocolatey..." "Cyan"

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Color "  Instalando Chocolatey (gerenciador de pacotes)..." "Yellow"
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    
    # Atualizar PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Color "  [OK] Chocolatey instalado" "Green"
} else {
    Write-Color "  [OK] Chocolatey já instalado" "Green"
}

# ══════════════════════════════════════════════════════════
# ETAPA 2: INSTALAR GIT
# ══════════════════════════════════════════════════════════
Write-Color "`n[2/7] 📦 Verificando Git..." "Cyan"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Color "  Instalando Git..." "Yellow"
    choco install git -y --no-progress
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Color "  [OK] Git instalado" "Green"
} else {
    Write-Color "  [OK] Git já instalado" "Green"
}

# ══════════════════════════════════════════════════════════
# ETAPA 3: INSTALAR PYTHON
# ══════════════════════════════════════════════════════════
Write-Color "`n[3/7] 🐍 Verificando Python..." "Cyan"

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Color "  Instalando Python 3.12..." "Yellow"
    choco install python312 -y --no-progress
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Color "  [OK] Python instalado" "Green"
} else {
    Write-Color "  [OK] Python já instalado" "Green"
}

# ══════════════════════════════════════════════════════════
# ETAPA 4: INSTALAR NODE.JS
# ══════════════════════════════════════════════════════════
Write-Color "`n[4/7] ⚛️ Verificando Node.js..." "Cyan"

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Color "  Instalando Node.js 20 LTS..." "Yellow"
    choco install nodejs-lts -y --no-progress
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Color "  [OK] Node.js instalado" "Green"
} else {
    Write-Color "  [OK] Node.js já instalado" "Green"
}

# ══════════════════════════════════════════════════════════
# ETAPA 5: COPIAR ARQUIVOS
# ══════════════════════════════════════════════════════════
Write-Color "`n[5/7] 📁 Copiando arquivos..." "Cyan"

if (Test-Path $InstallDir) {
    Remove-Item -Path $InstallDir -Recurse -Force
}

New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
Copy-Item -Path "$ScriptDir\*" -Destination $InstallDir -Recurse -Force
Set-Location $InstallDir

Write-Color "  [OK] Arquivos copiados para $InstallDir" "Green"

# ══════════════════════════════════════════════════════════
# ETAPA 6: CONFIGURAR AMBIENTE PYTHON
# ══════════════════════════════════════════════════════════
Write-Color "`n[6/7] 🐍 Configurando ambiente Python..." "Cyan"

# Recarregar PATH após instalações
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Criar venv
python -m venv venv

# Ativar venv e instalar dependências
& "$InstallDir\venv\Scripts\Activate.ps1"
python -m pip install --upgrade pip -q
pip install flask flask-cors -q

Write-Color "  [OK] Flask instalado" "Green"

# Compilar frontend
Write-Color "`n  Compilando frontend React..." "Yellow"
Set-Location "$InstallDir\frontend"
npm install --silent 2>$null
npm run build --silent 2>$null
Set-Location $InstallDir

Write-Color "  [OK] Frontend compilado" "Green"

# ══════════════════════════════════════════════════════════
# ETAPA 7: CRIAR ATALHOS
# ══════════════════════════════════════════════════════════
Write-Color "`n[7/7] 🖥️ Criando atalhos..." "Cyan"

# Script de inicialização
$StartScript = @"
@echo off
cd /d "$InstallDir"
call venv\Scripts\activate.bat
python run_web.py
"@
Set-Content -Path "$InstallDir\start.bat" -Value $StartScript

# Criar atalho na área de trabalho
$WshShell = New-Object -ComObject WScript.Shell
$DesktopPath = [System.Environment]::GetFolderPath('Desktop')
$Shortcut = $WshShell.CreateShortcut("$DesktopPath\Limpeza David.lnk")
$Shortcut.TargetPath = "$InstallDir\start.bat"
$Shortcut.WorkingDirectory = $InstallDir
$Shortcut.IconLocation = "$InstallDir\assets\icon.ico"
$Shortcut.Description = "Ferramenta de Limpeza de Sistema"
$Shortcut.WindowStyle = 7  # Minimizado
$Shortcut.Save()

Write-Color "  [OK] Atalho criado na área de trabalho" "Green"

# Criar atalho no Menu Iniciar
$StartMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
$StartMenuShortcut = $WshShell.CreateShortcut("$StartMenuPath\Limpeza David.lnk")
$StartMenuShortcut.TargetPath = "$InstallDir\start.bat"
$StartMenuShortcut.WorkingDirectory = $InstallDir
$StartMenuShortcut.IconLocation = "$InstallDir\assets\icon.ico"
$StartMenuShortcut.Description = "Ferramenta de Limpeza de Sistema"
$StartMenuShortcut.WindowStyle = 7
$StartMenuShortcut.Save()

Write-Color "  [OK] Adicionado ao Menu Iniciar" "Green"

# ══════════════════════════════════════════════════════════
# FINALIZAÇÃO
# ══════════════════════════════════════════════════════════
Write-Color @"

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ✅  INSTALAÇÃO CONCLUÍDA COM SUCESSO!                  ║
║                                                           ║
║   🖥️  Um ícone "Limpeza David" foi criado na sua         ║
║       área de trabalho. Clique duas vezes para abrir!    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

"@ "Green"

Write-Color "  Dica: Você também pode encontrar no Menu Iniciar!" "Yellow"
Write-Host ""

$response = Read-Host "Deseja abrir o Limpeza David agora? [S/n]"
if ($response -eq "" -or $response -match "^[Ss]") {
    Write-Color "`n🚀 Iniciando..." "Green"
    Start-Process "$InstallDir\start.bat" -WindowStyle Hidden
}
