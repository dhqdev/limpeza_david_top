#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# 🧹 LIMPEZA DAVID TOP - INSTALADOR COMPLETO PARA LINUX
# ═══════════════════════════════════════════════════════════════
# Funciona em: Ubuntu, Debian, Linux Mint, Fedora, Arch, openSUSE
# Instala TUDO automaticamente, mesmo em máquinas sem programação
# ═══════════════════════════════════════════════════════════════

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Função de log
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[AVISO]${NC} $1"; }
log_error() { echo -e "${RED}[ERRO]${NC} $1"; }

clear
echo -e "${PURPLE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🧹  LIMPEZA DAVID TOP - INSTALADOR AUTOMÁTICO          ║
║                                                           ║
║   Instala TUDO que você precisa, mesmo em máquinas       ║
║   que não têm nada de programação instalado!             ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.limpeza_david"

# Detectar gerenciador de pacotes
detect_package_manager() {
    if command -v apt &> /dev/null; then
        PKG_MANAGER="apt"
        PKG_INSTALL="sudo apt install -y"
        PKG_UPDATE="sudo apt update"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        PKG_INSTALL="sudo dnf install -y"
        PKG_UPDATE="sudo dnf check-update || true"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
        PKG_INSTALL="sudo pacman -S --noconfirm"
        PKG_UPDATE="sudo pacman -Sy"
    elif command -v zypper &> /dev/null; then
        PKG_MANAGER="zypper"
        PKG_INSTALL="sudo zypper install -y"
        PKG_UPDATE="sudo zypper refresh"
    else
        log_error "Gerenciador de pacotes não suportado!"
        exit 1
    fi
    log_success "Detectado: $PKG_MANAGER"
}

# ══════════════════════════════════════════════════════════
# ETAPA 1: INSTALAR DEPENDÊNCIAS DO SISTEMA
# ══════════════════════════════════════════════════════════
echo -e "\n${CYAN}[1/6] 📦 Instalando dependências do sistema...${NC}\n"

detect_package_manager

log_info "Atualizando lista de pacotes..."
$PKG_UPDATE 2>/dev/null || true

# Instalar Python
if ! command -v python3 &> /dev/null; then
    log_info "Instalando Python 3..."
    case $PKG_MANAGER in
        apt) $PKG_INSTALL python3 python3-pip python3-venv python3-tk ;;
        dnf) $PKG_INSTALL python3 python3-pip python3-tkinter ;;
        pacman) $PKG_INSTALL python python-pip tk ;;
        zypper) $PKG_INSTALL python3 python3-pip python3-tk ;;
    esac
fi
log_success "Python 3 instalado"

# Instalar pip e venv
case $PKG_MANAGER in
    apt) $PKG_INSTALL python3-pip python3-venv 2>/dev/null || true ;;
    dnf) $PKG_INSTALL python3-pip 2>/dev/null || true ;;
esac

# Instalar Node.js
if ! command -v node &> /dev/null; then
    log_info "Instalando Node.js..."
    case $PKG_MANAGER in
        apt)
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
            $PKG_INSTALL nodejs
            ;;
        dnf)
            sudo dnf module install -y nodejs:20 || $PKG_INSTALL nodejs npm
            ;;
        pacman)
            $PKG_INSTALL nodejs npm
            ;;
        zypper)
            $PKG_INSTALL nodejs npm
            ;;
    esac
fi
log_success "Node.js instalado"

# Instalar Git
if ! command -v git &> /dev/null; then
    log_info "Instalando Git..."
    $PKG_INSTALL git
fi
log_success "Git instalado"

# Instalar curl (necessário para algumas operações)
if ! command -v curl &> /dev/null; then
    log_info "Instalando curl..."
    $PKG_INSTALL curl
fi

# ══════════════════════════════════════════════════════════
# ETAPA 2: COPIAR ARQUIVOS
# ══════════════════════════════════════════════════════════
echo -e "\n${CYAN}[2/6] 📁 Copiando arquivos para $INSTALL_DIR...${NC}\n"

rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cp -r "$SCRIPT_DIR"/* "$INSTALL_DIR/"
cd "$INSTALL_DIR"
log_success "Arquivos copiados"

# ══════════════════════════════════════════════════════════
# ETAPA 3: AMBIENTE PYTHON
# ══════════════════════════════════════════════════════════
echo -e "\n${CYAN}[3/6] 🐍 Configurando ambiente Python...${NC}\n"

python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip -q
pip install flask flask-cors -q
log_success "Flask instalado"

# ══════════════════════════════════════════════════════════
# ETAPA 4: FRONTEND REACT
# ══════════════════════════════════════════════════════════
echo -e "\n${CYAN}[4/6] ⚛️ Compilando frontend React...${NC}\n"

cd frontend
npm install --silent 2>/dev/null
npm run build --silent 2>/dev/null
cd ..
log_success "Frontend compilado"

# ══════════════════════════════════════════════════════════
# ETAPA 5: SCRIPT DE EXECUÇÃO
# ══════════════════════════════════════════════════════════
echo -e "\n${CYAN}[5/6] 🔧 Criando script de execução...${NC}\n"

cat > "$INSTALL_DIR/start.sh" << 'SCRIPT'
#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate
python3 run_web.py
SCRIPT
chmod +x "$INSTALL_DIR/start.sh"
log_success "Script criado"

# ══════════════════════════════════════════════════════════
# ETAPA 6: ATALHO NA ÁREA DE TRABALHO
# ══════════════════════════════════════════════════════════
echo -e "\n${CYAN}[6/6] 🖥️ Criando atalho na área de trabalho...${NC}\n"

DESKTOP_CONTENT="[Desktop Entry]
Version=1.0
Type=Application
Name=Limpeza David
Comment=Ferramenta de Limpeza de Sistema
Exec=bash -c 'cd $INSTALL_DIR && ./start.sh'
Icon=$INSTALL_DIR/assets/icon.png
Terminal=false
Categories=Utility;System;
StartupNotify=true
"

# Área de trabalho em português
if [ -d "$HOME/Área de trabalho" ]; then
    DESKTOP_PATH="$HOME/Área de trabalho/Limpeza David.desktop"
    echo "$DESKTOP_CONTENT" > "$DESKTOP_PATH"
    chmod +x "$DESKTOP_PATH"
    gio set "$DESKTOP_PATH" metadata::trusted true 2>/dev/null || true
    log_success "Atalho criado: Área de trabalho"
fi

# Área de trabalho em inglês
if [ -d "$HOME/Desktop" ]; then
    DESKTOP_PATH="$HOME/Desktop/Limpeza David.desktop"
    echo "$DESKTOP_CONTENT" > "$DESKTOP_PATH"
    chmod +x "$DESKTOP_PATH"
    gio set "$DESKTOP_PATH" metadata::trusted true 2>/dev/null || true
    log_success "Atalho criado: Desktop"
fi

# Menu de aplicativos
mkdir -p "$HOME/.local/share/applications"
echo "$DESKTOP_CONTENT" > "$HOME/.local/share/applications/limpeza-david.desktop"
log_success "Adicionado ao menu de aplicativos"

# ══════════════════════════════════════════════════════════
# FINALIZAÇÃO
# ══════════════════════════════════════════════════════════
echo -e "\n${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ✅  INSTALAÇÃO CONCLUÍDA COM SUCESSO!                  ║
║                                                           ║
║   🖥️  Um ícone "Limpeza David" foi criado na sua         ║
║       área de trabalho. Clique duas vezes para abrir!    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "  ${YELLOW}Dica:${NC} Você também pode encontrar no menu de aplicativos!\n"

read -p "Deseja abrir o Limpeza David agora? [S/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]?$ ]]; then
    echo -e "\n${GREEN}🚀 Iniciando...${NC}\n"
    "$INSTALL_DIR/start.sh" &
fi
