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
alias emacs='emacs --init-directory=~/.config/emacs'

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

# restart the Emacs daemon;
# waits for the old one to exit so the new one can take over its socket.
# Without COLORTERM from the terminal it runs in, tty frames use 256 colors,
# which terminals over ssh or mosh (Termius) show correctly
ereload() {
    local pid
    pid=$(emacsclient -e '(emacs-pid)' 2>/dev/null)
    if [[ -n "$pid" ]]; then
        emacsclient -e '(kill-emacs)' >/dev/null 2>&1
        while kill -0 "$pid" 2>/dev/null; do sleep 0.1; done
    fi
    env -u COLORTERM emacs --daemon
}

# hide tmux-jot internal sessions from tmux ls
tmux() {
    if [[ "$1" == "ls" || "$1" == "list-sessions" ]]; then
        command tmux "$@" 2>/dev/null | grep -v '^__tmux__jot_'
    else
        command tmux "$@"
    fi
}

# top 15 programs by PSS + swapped-out PSS
topmem() {
    awk '
    BEGINFILE { if (ERRNO != "") nextfile }  # root-only smaps: skip, not fatal
    FILENAME ~ /smaps_rollup$/ {
        split(FILENAME, p, "/")
        if ($1 == "Pss:") pss[p[3]] = $2
        else if ($1 == "SwapPss:") pss[p[3]] += $2
        next
    }
    FILENAME ~ /status$/ {
        split(FILENAME, p, "/")
        if ($1 == "Name:") { sub(/^Name:[ \t]*/, ""); name[p[3]] = $0 }
        else if ($1 == "VmRSS:" || $1 == "VmSwap:") rss[p[3]] += $2
        next
    }
    FILENAME ~ /mm_stat$/ { zram += $3 / 1024; next }
    { mem[$1] = $2 }
    END {
        for (pid in name) {
            kb = (pid in pss) ? pss[pid] : rss[pid]
            if (kb) { prog[name[pid]] += kb; procs += kb }
        }
        for (n = 0; n < 15; n++) {
            best = ""
            for (i in prog) if (best == "" || prog[i] > prog[best]) best = i
            if (best == "") break
            printf "%8.1f MB  %s\n", prog[best] / 1024, best
            delete prog[best]
        }
        printf "\n%8.1f MB  all processes\n", procs / 1024
        printf "%8.1f MB  shmem / tmpfs in RAM\n", mem["Shmem:"] / 1024
        printf "%8.1f MB  kernel (slab, stacks, page tables)\n",
            (mem["Slab:"] + mem["KernelStack:"] + mem["PageTables:"]) / 1024
        printf "%8.1f MB  zram pool\n", zram / 1024
        printf "%8.1f MB  used (total - available)\n",
            (mem["MemTotal:"] - mem["MemAvailable:"]) / 1024
        printf "%8.1f MB  swap used\n", (mem["SwapTotal:"] - mem["SwapFree:"]) / 1024
    }' /proc/[0-9]*/smaps_rollup(N) /proc/[0-9]*/status(N) \
        /sys/block/zram*/mm_stat(N) /proc/meminfo 2>/dev/null
}

################
### KEYBINDS ###
################
bindkey '\ek' up-line-or-history   # Alt + K
bindkey '\ej' down-line-or-history # Alt + J
bindkey '\el' autosuggest-accept   # Alt + L

############
### EVAL ###
############
eval "$(starship init zsh)"

##############
### EXPORT ###
##############
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"
export PATH=~/.npm-global/bin:$PATH
export TMUX_TMPDIR=$XDG_RUNTIME_DIR
export PATH="$PATH:$HOME/.config/emacs/bin"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/home/wolfie/.local/bin:$PATH"
export PATH=$PATH:$HOME/go/bin
export PATH=$PATH:$HOME/.cargo/bin
export GPG_TTY=$(tty)
export QT_QPA_PLATFORMTHEME=kde

# Machine-local overrides
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

################
### START UP ###
################
clear
