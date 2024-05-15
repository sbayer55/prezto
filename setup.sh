#!/bin/zsh

# enable script debugging
set -x

ZPREZTO_HOME=${HOME}/.zprezto

# Check user dir
if [ "$(pwd)" != "$(echo ~$USER)/.zprezto" ]; then
    echo "You must download Steven's repo in ~/.zprezto"
    exit 1
fi

echo "Install submodule"
git submodule update --init --recursive

chsh -s /bin/zsh

source "${ZPREZTO_HOME}/setup-symlinks.sh"

git clone https://github.com/tmux-plugins/tpm ${HOME}/.tmux/plugins/tpm

# echo "Install VIM profile? (yes/no [yes])"
# read input

# if [[ "x${input}" == "x" ]]; then
#     input="yes"
# fi

# if [[ "${input}" == "yes" ]]; then
#     cv ${ZPREZTO_HOME}/vim
#     ./vim_setup.sh
# fi

echo "Install Lunar Vim profile? (yes/no [yes])"
read input

if [[ "x${input}" == "x" ]]; then
    input="yes"
fi

if [[ "${input}" == "yes" ]]; then
    LV_BRANCH='release-1.3/neovim-0.9' bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.3/neovim-0.9/utils/installer/install.sh)
fi

echo "Run brew install? (yes/no [yes])"
read input

if [[ "x${input}" == "x" ]]; then
    input="yes"
fi

if [[ "${input}" == "yes" ]]; then
    if type brew; then
        brew analytics off
        brew install midnight-commander wget git-delta fd eza bat ollama fish tree htop gnupg neovim ripgrep jq fzf zoxide btop bottom atuin
    else
        echo "Attempting cargo install"
        if ! type cargo; then
            if type yum; then
                sudo yum install cargo
            fi
        fi
        if type cargo; then
            cargo install atuin
            cargo install eza
            cargo install git-delta
        else
            echo "Cargo install failed"
        fi
    fi
fi

echo "Install Starship? (yes/no [yes])"
read input

if [[ "x${input}" == "x" ]]; then
    input="yes"
fi

if [[ "${input}" == "yes" ]]; then
    # Need OS check
    curl -sS https://starship.rs/install.sh | shi
fi

