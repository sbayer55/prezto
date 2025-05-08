#!/bin/bash

# Terminal Rizz Script
# Save this file and add "source /path/to/this/file" to your .bashrc or .zshrc

# Terminal Colors
RESET="\[\033[0m\]"
RED="\[\033[0;31m\]"
GREEN="\[\033[0;32m\]"
YELLOW="\[\033[0;33m\]"
BLUE="\[\033[0;34m\]"
PURPLE="\[\033[0;35m\]"
CYAN="\[\033[0;36m\]"
BOLD_RED="\[\033[1;31m\]"
BOLD_GREEN="\[\033[1;32m\]"
BOLD_YELLOW="\[\033[1;33m\]"
BOLD_PURPLE="\[\033[1;35m\]"
BOLD_CYAN="\[\033[1;36m\]"

# Function to display Git branch if in a Git repository
git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

# Set a stylish prompt
set_prompt() {
    # Get the status code of the last command
    local last_status=$?
    local status_color="$BOLD_GREEN"
    if [ $last_status -ne 0 ]; then
        status_color="$BOLD_RED"
    fi

    # Current time
    PS1="$BOLD_PURPLE[\$(date +%H:%M:%S)] "
    # Username and hostname
    PS1+="$BOLD_CYAN\u@\h "
    # Current directory
    PS1+="$BOLD_YELLOW\w"
    # Git branch if applicable
    PS1+="$GREEN\$(git_branch) "
    # Status indicator ($ for normal user, # for root)
    PS1+="\n$status_color\\$ $RESET"
}

# Set the prompt command to refresh the prompt
PROMPT_COMMAND=set_prompt

# Custom terminal title showing user@host:directory
set_title() {
    echo -ne "\033]0;\u@\h: \w\007"
}
PROMPT_COMMAND="$PROMPT_COMMAND; set_title"

# Welcome message with ASCII art
show_welcome() {
    clear
    echo -e "\033[1;36m"
    cat << "EOF"
 ____  _            _____                      _             _
|  _ \(_)_______   |_   _|__ _ __ _ __ ___  __| |_   _ _ __ | |
| |_) | |_  / _ \    | |/ _ \ '__| '_ ` _ \/ _` | | | | '_ \| |
|  _ <| |/ /  __/    | |  __/ |  | | | | | | (_| | |_| | | | |_|
|_| \_\_/___\___|    |_|\___|_|  |_| |_| |_|\__,_|\__, |_| |_(_)
                                                  |___/
EOF
    echo -e "\033[0m"
    echo -e "\033[1;35m Welcome to your rizzed up terminal! \033[0m"
    echo -e "\033[0;33m $(date) \033[0m"
    echo

    # System information
    echo -e "\033[1;32m=== System Information ===\033[0m"
    echo -e "\033[0;36mOS:\033[0m $(uname -s)"
    echo -e "\033[0;36mHostname:\033[0m $(hostname)"
    echo -e "\033[0;36mKernel:\033[0m $(uname -r)"
    echo -e "\033[0;36mUptime:\033[0m $(uptime | sed 's/.*up \([^,]*\), .*/\1/')"
    echo
}

# Call the welcome function when the script loads
show_welcome

# Useful aliases
alias ls='ls --color=auto'
alias ll='ls -la --color=auto'
alias la='ls -lah --color=auto'
alias grep='grep --color=auto'
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias please='sudo'
alias yeet='rm -rf'
alias vibes='fortune | cowsay'

# Weather function - get current weather
weather() {
    local city="$1"
    if [ -z "$city" ]; then
        city="New York" # Default city
    fi
    curl -s "wttr.in/$city?format=3"
}

# Function to extract various archive types
extract() {
    if [ -f "$1" ] ; then
        case $1 in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Enhanced cd command that lists directory after changing
function cd {
    builtin cd "$@" && ls -F
}

# History setup
export HISTCONTROL=ignoredups:erasedups # No duplicate entries
export HISTSIZE=10000                   # Big history
export HISTFILESIZE=10000               # Big file size
shopt -s histappend                     # Append to history, don't overwrite

# Check if this is an interactive shell
if [[ $- == *i* ]]; then
    # Enable tab completion
    bind 'set show-all-if-ambiguous on'
    bind 'TAB:menu-complete'

    # Cycle through commands with up/down arrows
    bind '"\e[A": history-search-backward'
    bind '"\e[B": history-search-forward'
fi

echo -e "\033[1;32mTerminal rizzed up and ready to go! 🚀\033[0m"
