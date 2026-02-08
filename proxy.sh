#!/usr/bin/env bash
# DragonX Manager - systemd + menu completo
# Suporte multi-porta
# Autor original: Danilo (refatorado para DragonX)

set -e

PROXY_DIR="$HOME/DragonX"
SERVICE_PREFIX="dragonx_port"
LOG_DIR="$PROXY_DIR/logs"
PORTS_FILE="$PROXY_DIR/ports.list"

mkdir -p "$LOG_DIR"
mkdir -p "$PROXY_DIR"

# ---- CORES / ESTILO ----
BLUE_BOLD='\033[1;34m'
RESET='\033[0m'

# texto do menu em AZUL + NEGRITO + MAIÚSCULO
menu_txt() {
  local s="$*"
  printf "%b%s%b\n" "${BLUE_BOLD}" "${s^^}" "${RESET}"
}

# item do menu
menu_item() {
  local key="$1"; shift
  menu_txt "[$key] $*"
}

# mensagem normal (sem uppercase)
msg() {
  printf "%b%s%b\n" "${BLUE_BOLD}" "$*" "${RESET}"
}

# Detecta arquitetura automaticamente
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|i386|i686)
    BIN_NAME="dragon_go-x86"
    ;;
  aarch64|armv7l|armv6l|arm*)
    BIN_NAME="dragon_go-ARM"
    ;;
  *)
    menu_txt "ARQUITETURA NÃO SUPORTADA: $ARCH"
    exit 1
    ;;
esac

# Cria/atualiza um serviço systemd
update_service() {
  local PORT=$1
  local SERVICE_NAME="${SERVICE_PREFIX}_${PORT}.service"
  sudo tee /etc/systemd/system/$SERVICE_NAME > /dev/null <<EOF
[Unit]
Description=DragonX SSH Proxy (Porta $PORT)
After=network.target

[Service]
Type=simple
WorkingDirectory=$PROXY_DIR
ExecStart=$PROXY_DIR/$BIN_NAME -port :$PORT
Restart=always
StandardOutput=file:$LOG_DIR/proxy_$PORT.log
StandardError=file:$LOG_DIR/proxy_$PORT.log

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable $SERVICE_NAME
}

# Inicia uma porta
start_port() {
  read -p "DIGITE A PORTA DO PROXY (1-65535): " PORT
  while ! [[ $PORT =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )); do
    menu_txt "⚠️ DIGITE UMA PORTA VÁLIDA (1-65535)."
    read -p "DIGITE A PORTA DO PROXY: " PORT
  done

  if ! grep -q "^$PORT$" "$PORTS_FILE" 2>/dev/null; then
    echo "$PORT" >> "$PORTS_FILE"
  fi

  update_service "$PORT"
  sudo systemctl start "${SERVICE_PREFIX}_${PORT}.service"
  menu_txt "✅ DRAGONX INICIADO NA PORTA $PORT"
  read -p "PRESSIONE ENTER PARA VOLTAR AO MENU..."
}

# Para uma porta
stop_port() {
  read -p "DIGITE A PORTA PARA PARAR: " PORT
  local SERVICE_NAME="${SERVICE_PREFIX}_${PORT}.service"
  sudo systemctl stop "$SERVICE_NAME"
  menu_txt "🛑 DRAGONX PARADO NA PORTA $PORT"
  read -p "PRESSIONE ENTER PARA VOLTAR AO MENU..."
}

# Reinicia uma porta
restart_port() {
  read -p "DIGITE A PORTA PARA REINICIAR: " PORT
  update_service "$PORT"
  sudo systemctl restart "${SERVICE_PREFIX}_${PORT}.service"
  menu_txt "🔄 DRAGONX REINICIADO NA PORTA $PORT"
  read -p "PRESSIONE ENTER PARA VOLTAR AO MENU..."
}

# Remove todas as portas configuradas e serviços
uninstall_dragonx() {
  menu_txt "❌ REMOVENDO DRAGONX..."
  if [ -f "$PORTS_FILE" ]; then
    while read -r PORT; do
      sudo systemctl stop "${SERVICE_PREFIX}_${PORT}.service" 2>/dev/null || true
      sudo systemctl disable "${SERVICE_PREFIX}_${PORT}.service" 2>/dev/null || true
      sudo rm -f "/etc/systemd/system/${SERVICE_PREFIX}_${PORT}.service"
    done < "$PORTS_FILE"
    rm -f "$PORTS_FILE"
  fi
  sudo systemctl daemon-reload
  rm -rf "$PROXY_DIR"
  sudo rm -f /usr/local/bin/dragonx
  menu_txt "✅ DRAGONX REMOVIDO COM SUCESSO!"
  exit 0
}

# Menu principal
menu() {
  clear
  menu_txt "=============================="
  menu_txt "           DRAGONX"
  menu_txt "=============================="

  if [ -f "$PORTS_FILE" ]; then
    HAS_ACTIVE=0
    menu_txt "PORTAS ATIVAS:"
    while read -r PORT; do
      local SERVICE_NAME="${SERVICE_PREFIX}_${PORT}.service"
      if systemctl is-active --quiet "$SERVICE_NAME"; then
        # linha informativa (mantém legível)
        msg " - PORTA $PORT (🟢 ATIVA)"
        HAS_ACTIVE=1
      fi
    done < "$PORTS_FILE"

    if [ $HAS_ACTIVE -eq 0 ]; then
      menu_txt "NENHUMA PORTA ATIVA"
    fi
  else
    menu_txt "NENHUMA PORTA ATIVA"
  fi

  menu_txt "------------------------------"
  menu_item 1 "INICIAR DRAGONX (ADICIONAR PORTA)"
  menu_item 2 "PARAR DRAGONX (PORTA)"
  menu_item 3 "REINICIAR DRAGONX (PORTA)"
  menu_item 4 "DESINSTALAR DRAGONX"
  menu_item 5 "SAIR"
  menu_txt "=============================="

  read -p "ESCOLHA UMA OPÇÃO: " option

  case "$option" in
    1) start_port ;;
    2) stop_port ;;
    3) restart_port ;;
    4) uninstall_dragonx ;;
    5) exit 0 ;;
    *) menu_txt "OPÇÃO INVÁLIDA!"; sleep 1; menu ;;
  esac
}

# Loop do menu
while true; do
  menu
done
