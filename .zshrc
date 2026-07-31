export ZSH="$HOME/.oh-my-zsh"

###########
### ZSH ###
###########
ZSH_THEME="minimal"
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  dirhistory
  z
  sudo
  extract
  ssh-agent
)

zstyle :omz:plugins:ssh-agent lifetime 4h
zstyle :omz:plugins:ssh-agent identities id_ed25519

source $ZSH/oh-my-zsh.sh

###############
### ALIASES ###
###############
alias ls='lsd'
alias l='lsd -l --group-dirs first'
alias la='lsd -a --group-dirs first'
alias ll='lsd -al --group-dirs first'
alias lg='lazygit'
alias zathura='zathura --fork'
alias n='nvim'
alias nvim-dev="VIMRUNTIME=/home/wolfie/Dokumenty/GitHub/neovim/runtime /home/wolfie/Dokumenty/GitHub/neovim/build/bin/nvim"
alias nd="VIMRUNTIME=/home/wolfie/Dokumenty/GitHub/neovim/runtime /home/wolfie/Dokumenty/GitHub/neovim/build/bin/nvim"
alias claude='WAKATIME_DISABLE=true claude'
alias f='fzf'

#################
### FUNCTIONS ###
#################
convert-video() {
    if [ -z "$1" ]; then
        echo "Błąd: Nie podano pliku wejściowego!"
        echo "Użycie: convert-video nazwa_pliku.mkv"
        return 1
    fi
    local output="${1%.*}_2k.mp4"
    ffmpeg -i "$1" -vf "scale=2560:1440:flags=lanczos" -c:v libx264 -crf 18 -preset slow -c:a copy "$output"
}

# hide tmux-jot internal sessions from tmux ls
tmux() {
  if [[ "$1" == "ls" || "$1" == "list-sessions" ]]; then
    command tmux "$@" 2>/dev/null | grep -v '^__tmux__jot_'
  else
    command tmux "$@"
  fi
}

################
### KEYBINDS ###
################
bindkey '\ek' up-line-or-history      # Alt + K
bindkey '\ej' down-line-or-history    # Alt + J
bindkey '\el' autosuggest-accept      # Alt + L


############
### EVAL ###
############
eval "$(starship init zsh)"

##############
### EXPORT ###
##############
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"#
export PATH=~/.npm-global/bin:$PATH
export TMUX_TMPDIR=$XDG_RUNTIME_DIR
export PATH="$PATH:$HOME/.config/emacs/bin"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/home/wolfie/.local/bin:$PATH"
export PATH=$PATH:$HOME/go/bin
export PATH=$PATH:$HOME/.cargo/bin
export GPG_TTY=$(tty)
export QT_QPA_PLATFORMTHEME=kde

################
### START UP ###
################
clear
