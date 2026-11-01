export ZSH="$HOME/.oh-my-zsh"
export ATAC_KEY_BINDINGS="$HOME/.dot/vim_key_bindings.toml"

ZSH_THEME="spaceship"

plugins=(git)

source $ZSH/oh-my-zsh.sh

eval $(/opt/homebrew/bin/brew shellenv)

unset GOROOT

export PATH="${GOPATH:-$HOME/go}/bin:$HOME/.local/bin:$PATH"

alias rmt="cd /Users/magnus/iCloud/Documents/Studies/spring-rmt"

[ -f "/Users/magnus/.ghcup/env" ] && source "/Users/magnus/.ghcup/env" # ghcup-env



# Abre tmux automaticamente na sessão Zuul (cria se não existir)
if [[ -o interactive && -z "$TMUX" && -z "$ZELLIJ" ]] && command -v tmux >/dev/null; then
  tmux new-session -A -s Zuul
fi


# Added by Antigravity CLI installer
export PATH="/Users/magnus/.local/bin:$PATH"

# Stop macOS AppleDouble ._ files on CLI copies
export COPYFILE_DISABLE=1

eval "$(/opt/homebrew/bin/mise activate zsh)"

