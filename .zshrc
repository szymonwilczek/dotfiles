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
)
source $ZSH/oh-my-zsh.sh

###############
### ALIASES ###
###############
alias ls='lsd'
alias l='lsd -l --group-dirs first'
alias la='lsd -a --group-dirs first'
alias ll='lsd -al --group-dirs first'
alias lg='lazygit'

################
### KEYBINDS ###
################
bindkey 'K' up-line-or-history
bindkey 'J' down-line-or-history
bindkey 'L' autosuggest-accept


############
### EVAL ###
############
eval "$(starship init zsh)"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

##############
### EXPORT ###
##############
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"#
export PATH=~/.npm-global/bin:$PATH

################
### START UP ###
################
clear
