#!/usr/bin/env bash
# Instalador DragonX
# Autor original: Danilo (refatorado para DragonX)
set -e

INSTALL_DIR="$HOME/DragonX"
REPO_URL="https://github.com/PhoenixxZ2023/main/proxygo.git"

# ---- CORES / ESTILO (MENU/TÍTULOS) ----
BLUE_BOLD='\033[1;34m'
RESET='\033[0m'

msg()  { printf "%b%s%b\n" "${BLUE_BOLD}" "$*" "${RESET}"; }
msgU() { printf "%b%s%b\n" "${BLUE_BOLD}" "${*^^}" "${RESET}"; }  # MAIÚSCULO

msgU "INSTALANDO O DRAGONX EM: $INSTALL_DIR ..."

# Atualiza apt e instala dependências
if command -v apt >/dev/null 2>&1; then
  msgU "ATUALIZANDO PACOTES E INSTALANDO DEPENDÊNCIAS..."
  sudo apt update
  sudo apt install -y git unzip wget screen
fi

# Baixa/atualiza o código
if [ -d "$INSTALL_DIR/.git" ]; then
  msgU "REPOSITÓRIO EXISTENTE DETECTADO. ATUALIZANDO..."
  git -C "$INSTALL_DIR" fetch origin
  git -C "$INSTALL_DIR" checkout main
  git -C "$INSTALL_DIR" pull --rebase --autostash origin main || true
else
  msgU "CLONANDO REPOSITÓRIO..."
  rm -rf "$INSTALL_DIR"
  git clone --depth 1 --branch main "$REPO_URL" "$INSTALL_DIR"
fi

# Garante executáveis
msgU "AJUSTANDO PERMISSÕES DOS EXECUTÁVEIS..."
chmod +x "$INSTALL_DIR/proxy.sh" 2>/dev/null || true
chmod +x "$INSTALL_DIR/dragon_go-ARM" 2>/dev/null || true
chmod +x "$INSTALL_DIR/dragon_go-x86" 2>/dev/null || true

# Cria comando global
msgU "CRIANDO COMANDO GLOBAL: DRAGONX"
sudo ln -sf "$INSTALL_DIR/proxy.sh" /usr/local/bin/dragonx

msgU "✅ INSTALAÇÃO FINALIZADA!"
msg "Use: ${BLUE_BOLD}dragonx${RESET} para abrir o menu."
msg "Dica: inicie as portas pelo menu; cada porta roda como seu próprio serviço systemd."
