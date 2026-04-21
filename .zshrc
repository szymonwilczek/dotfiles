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
alias n='nvim'

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
export PATH=$PATH:$HOME/go/bin

################
### START UP ###
################
clear
