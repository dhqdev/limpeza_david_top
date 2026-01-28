#!/bin/bash
# ===========================================
# Limpeza David TOP - Instalador Linux
# ===========================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

clear
echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║                                                      ║"
echo "║        🧹 LIMPEZA DAVID TOP - INSTALADOR            ║"
echo "║                                                      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Diretório do script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.limpeza_david"
DESKTOP_FILE="$HOME/Área de trabalho/Limpeza David.desktop"
DESKTOP_FILE_EN="$HOME/Desktop/Limpeza David.desktop"

cd "$SCRIPT_DIR"

# Função para verificar comando
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "  ${RED}✗${NC} $1 não encontrado"
        return 1
    fi
}

echo -e "\n${YELLOW}[1/6]${NC} Verificando dependências..."

# Verifica Python
if ! check_command python3; then
    echo -e "\n${RED}Instalando Python...${NC}"
    sudo apt update && sudo apt install -y python3 python3-pip python3-venv
fi

# Verifica Node.js
if ! check_command node; then
    echo -e "\n${YELLOW}Instalando Node.js...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Verifica npm
check_command npm

# Verifica git
check_command git

echo -e "\n${YELLOW}[2/6]${NC} Copiando arquivos para $INSTALL_DIR..."

# Cria diretório de instalação
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cp -r . "$INSTALL_DIR/"
cd "$INSTALL_DIR"

echo -e "\n${YELLOW}[3/6]${NC} Configurando ambiente Python..."

# Instala python3-venv se necessário
sudo apt install -y python3-venv python3-pip 2>/dev/null || true

# Cria virtual environment
python3 -m venv venv
source venv/bin/activate

# Instala dependências Python
pip install --upgrade pip -q
pip install flask flask-cors -q

echo -e "  ${GREEN}✓${NC} Flask instalado"

echo -e "\n${YELLOW}[4/6]${NC} Instalando frontend React..."

cd frontend
npm install --silent 2>/dev/null
npm run build --silent 2>/dev/null
cd ..

echo -e "  ${GREEN}✓${NC} Frontend compilado"

echo -e "\n${YELLOW}[5/6]${NC} Criando script de execução..."

# Cria script de execução
cat > "$INSTALL_DIR/start.sh" << 'SCRIPT'
#!/bin/bash
cd "$(dirname "$0")"
source venv/bin/activate
python3 run_web.py
SCRIPT

chmod +x "$INSTALL_DIR/start.sh"

echo -e "\n${YELLOW}[6/6]${NC} Criando atalho na área de trabalho..."

# Cria arquivo .desktop
DESKTOP_CONTENT="[Desktop Entry]
Version=1.0
Type=Application
Name=Limpeza David
Comment=Ferramenta de Limpeza de Sistema
Exec=$INSTALL_DIR/start.sh
Icon=$INSTALL_DIR/assets/icon.png
Terminal=false
Categories=Utility;System;
StartupNotify=true
"

# Tenta criar na área de trabalho em português
if [ -d "$HOME/Área de trabalho" ]; then
    echo "$DESKTOP_CONTENT" > "$DESKTOP_FILE"
    chmod +x "$DESKTOP_FILE"
    # Marca como confiável (GNOME)
    gio set "$DESKTOP_FILE" metadata::trusted true 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} Atalho criado: Área de trabalho"
fi

# Tenta criar na área de trabalho em inglês
if [ -d "$HOME/Desktop" ]; then
    echo "$DESKTOP_CONTENT" > "$DESKTOP_FILE_EN"
    chmod +x "$DESKTOP_FILE_EN"
    gio set "$DESKTOP_FILE_EN" metadata::trusted true 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} Atalho criado: Desktop"
fi

# Cria entrada no menu de aplicativos
mkdir -p "$HOME/.local/share/applications"
echo "$DESKTOP_CONTENT" > "$HOME/.local/share/applications/limpeza-david.desktop"

echo -e "\n${GREEN}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║                                                      ║"
echo "║     ✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO!            ║"
echo "║                                                      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "
  ${BLUE}Para usar o Limpeza David:${NC}
  
  ${YELLOW}➜${NC} Clique duas vezes no ícone ${GREEN}\"Limpeza David\"${NC}
    na sua área de trabalho!

  ${YELLOW}➜${NC} Ou execute: ${PURPLE}~/.limpeza_david/start.sh${NC}

"

# Pergunta se quer abrir agora
read -p "Deseja abrir o Limpeza David agora? [S/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]?$ ]]; then
    echo -e "\n${GREEN}🚀 Iniciando Limpeza David...${NC}\n"
    "$INSTALL_DIR/start.sh"
fi
