#!/bin/bash
# Instala os dotfiles criando links pro repo. Pode rodar mais de uma vez.
#
#   ./install.sh              menu pra escolher o que instalar
#   ./install.sh tmux zsh     instala só os itens citados
#   ./install.sh --all        instala tudo sem perguntar no menu
#
# Se o destino já existir, avisa e pergunta: remover com backup, sem backup ou pular.
# Compatível com o bash 3.2 do macOS (sem fzf/gum).

# Para o script no primeiro comando que falhar
set -e

# tmux.conf e zshrc apontam pra ~/.dot, então o repo precisa estar lá
DOT="$HOME/.dot"

# ---------- Itens que podem ser instalados ----------
# Cada posição das listas abaixo é um item: NAMES[0] usa SRCS[0], DSTS[0] e DESCS[0].
NAMES=(zsh tmux zellij alacritty)                       # nome no menu e nos argumentos
SRCS=(zshrc tmux.conf zellij alacritty)                 # caminho dentro do repo
DSTS=("$HOME/.zshrc" "$HOME/.tmux.conf" "$HOME/.config/zellij" "$HOME/.config/alacritty")
DESCS=("~/.zshrc" "~/.tmux.conf" "~/.config/zellij" "~/.config/alacritty")  # destino pra mostrar
N=${#NAMES[@]}

# SEL[i]=1 quando o item i foi escolhido pra instalar
SEL=()

# Mostra a ajuda (o cabeçalho deste arquivo, sem os "#")
usage() {
  sed -n '2,9s/^# \{0,1\}//p' "$0"
  echo "Itens: ${NAMES[*]}"
}

# Troca $HOME por ~ pra mensagens mais curtas
short() {
  echo "${1/#$HOME/~}"
}

# ---------- Estado do destino ----------

# Verdadeiro se o destino do item já é o link certo pro repo
installed() {
  [ "$(readlink "${DSTS[$1]}")" = "$DOT/${SRCS[$1]}" ]
}

# Verdadeiro se já existe algo no destino (arquivo, pasta ou link, mesmo quebrado)
exists() {
  [ -e "${DSTS[$1]}" ] || [ -L "${DSTS[$1]}" ]
}

# ---------- Instalação ----------

# Pergunta o que fazer com o que já existe no destino.
# Guarda a resposta em $action: backup, remove ou skip.
ask_replace() {
  local dst="$1" what ans

  # Descreve o que está lá pra pessoa decidir
  if [ -L "$dst" ]; then
    what="link pra $(readlink "$dst")"
  elif [ -d "$dst" ]; then
    what="pasta"
  else
    what="arquivo"
  fi
  echo "  ! $(short "$dst") já existe ($what)"

  # Sem terminal não dá pra perguntar: faz backup, que é o caminho seguro
  if [ ! -t 0 ]; then
    echo "    sem terminal pra perguntar: fazendo backup"
    action=backup
    return
  fi

  # Repete até receber uma tecla válida. Enter sozinho = pular.
  while true; do
    printf '    [b] remover com backup  [r] remover sem backup  [p] pular (enter): '
    IFS= read -rsn1 ans || ans=p
    case "$ans" in
      b | B) echo "backup"; action=backup; return ;;
      r | R) echo "remover"; action=remove; return ;;
      p | P | '') echo "pular"; action=skip; return ;;
      *) echo ;;
    esac
  done
}

# Move o destino pra um backup sem sobrescrever backups anteriores.
# Se já existir .bak, usa .bak.<data-hora>.
backup() {
  local dst="$1" bak="$1.bak"
  if [ -e "$bak" ] || [ -L "$bak" ]; then
    bak="$dst.bak.$(date +%Y%m%d-%H%M%S)"
  fi
  mv "$dst" "$bak"
  echo "    backup em $(short "$bak")"
}

# Instala o item $1: resolve o que já existe no destino e cria o link pro repo
install_item() {
  local i="$1" src="$DOT/${SRCS[$1]}" dst="${DSTS[$1]}"

  if installed "$i"; then
    echo "  = ${NAMES[i]} já instalado"
    return
  fi

  if exists "$i"; then
    ask_replace "$dst"
    case "$action" in
      skip)
        echo "  - ${NAMES[i]} pulado"
        return
        ;;
      backup) backup "$dst" ;;
      remove)
        # Link: apaga só o link. Arquivo/pasta: apaga de vez.
        if [ -L "$dst" ]; then rm -f "$dst"; else rm -rf "$dst"; fi
        ;;
    esac
  fi

  # Cria a pasta pai (ex.: ~/.config numa máquina nova) e o link
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "  ✓ ${NAMES[i]} → ${DESCS[i]}"
}

# ---------- Menu de seleção ----------

# Desenha as linhas do menu. Usa $cur (linha do cursor) definido em menu().
draw() {
  local i box state line
  for ((i = 0; i < N; i++)); do
    if [ "${SEL[i]}" = 1 ]; then box="[x]"; else box="[ ]"; fi

    # Mostra antes de instalar o que já está no lugar
    if installed "$i"; then
      state=" (instalado)"
    elif exists "$i"; then
      state=" (já existe: vai perguntar)"
    else
      state=""
    fi

    line=$(printf '%s %-10s %s%s' "$box" "${NAMES[i]}" "${DESCS[i]}" "$state")
    # \033[2K limpa a linha antes de escrever; a linha do cursor fica em amarelo
    if [ "$i" = "$cur" ]; then
      printf '\033[2K \033[1;33m> %s\033[0m\n' "$line"
    else
      printf '\033[2K   %s\n' "$line"
    fi
  done
}

# Mostra o menu e preenche SEL com o que foi marcado
menu() {
  local i key rest all cur=0

  # Começa com tudo marcado
  for ((i = 0; i < N; i++)); do SEL[i]=1; done

  # Esconde o cursor do terminal e garante que ele volta ao sair ou com Ctrl+C
  tput civis
  trap 'tput cnorm' EXIT
  trap 'tput cnorm; echo; exit 130' INT

  echo "O que instalar?"
  echo "  ↑/↓ ou j/k move · espaço marca · a todos · enter confirma · q sai"
  echo
  draw

  while true; do
    # Lê uma tecla por vez, sem eco (IFS vazio pra conseguir ler o espaço)
    IFS= read -rsn1 key
    case "$key" in
      $'\x1b')
        # Setas chegam como ESC [ A/B: lê os 2 caracteres que faltam
        read -rsn2 -t 1 rest || true
        case "$rest" in
          '[A') cur=$(((cur - 1 + N) % N)) ;;
          '[B') cur=$(((cur + 1) % N)) ;;
        esac
        ;;
      k) cur=$(((cur - 1 + N) % N)) ;;
      j) cur=$(((cur + 1) % N)) ;;
      ' ') SEL[cur]=$((1 - SEL[cur])) ;;
      a)
        # Se tudo está marcado desmarca tudo; senão marca tudo
        all=1
        for ((i = 0; i < N; i++)); do [ "${SEL[i]}" = 1 ] || all=0; done
        for ((i = 0; i < N; i++)); do SEL[i]=$((1 - all)); done
        ;;
      '') break ;; # enter
      q) echo; echo "Nada instalado."; exit 0 ;;
    esac

    # Sobe o cursor N linhas e redesenha o menu no mesmo lugar
    printf '\033[%dA' "$N"
    draw
  done

  tput cnorm
  echo
}

# Marca em SEL os itens passados como argumento (ou todos com --all)
select_args() {
  local arg i found
  for ((i = 0; i < N; i++)); do SEL[i]=0; done
  for arg in "$@"; do
    found=0
    for ((i = 0; i < N; i++)); do
      if [ "$arg" = --all ] || [ "$arg" = "${NAMES[i]}" ]; then
        SEL[i]=1
        found=1
      fi
    done
    if [ "$found" = 0 ]; then
      echo "Item desconhecido: $arg" >&2
      usage >&2
      exit 1
    fi
  done
}

# ---------- Execução ----------

case "$1" in
  -h | --help) usage; exit 0 ;;
esac

if [ ! -d "$DOT" ]; then
  echo "Repo não está em $DOT. Clone ele lá (tmux.conf e zshrc usam esse caminho)." >&2
  exit 1
fi

# Escolhe os itens: pelos argumentos, pelo menu ou falha se não tem terminal
if [ $# -gt 0 ]; then
  select_args "$@"
elif [ -t 0 ] && [ -t 1 ]; then
  menu
else
  echo "Sem terminal pro menu. Passe os itens como argumento." >&2
  usage >&2
  exit 1
fi

# Instala cada item marcado
count=0
for ((i = 0; i < N; i++)); do
  [ "${SEL[i]}" = 1 ] || continue
  install_item "$i"
  count=$((count + 1))
done
[ "$count" -gt 0 ] || echo "Nada selecionado."
