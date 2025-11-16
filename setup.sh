#!/usr/bin/env zsh

# enable script debugging
set -x

# Set colors for better readability
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

ZPREZTO_HOME=${HOME}/.zprezto

# Check user dir
if [ "$(pwd)" != "$(echo ~$USER)/.zprezto" ]; then
    echo "You must download Steven's repo in ~/.zprezto"
    exit 1
fi

echo "Install submodule"
git submodule update --init --recursive

chsh -s /bin/zsh

eval "${ZPREZTO_HOME}/setup-symlinks.sh"

# Register "$(bat --config-dir)/themes" with bat
bat cache --build

git clone https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
eval "${HOME}/.fzf/install"

echo -e "${YELLOW}Install Lunar Vim profile? [Y/n]${NC}"
read -r input

if [[ -z "$input" || "$input" =~ ^[Yy]$ ]]; then
    LV_BRANCH='release-1.4/neovim-0.9' bash <(curl -s https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.4/neovim-0.9/utils/installer/install.sh)
fi

eval "${ZPREZTO_HOME}/scripts/install-dev-tools.sh"

git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.fzf"

ZSH_CUSTOM="${HOME}/.zprezto/oh-my-zsh/custom"
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git $ZSH_CUSTOM/plugins/zsh-autocomplete
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

echo -e "${YELLOW}Install Starship? [Y/n]${NC}"
read -r input

if [[ -z "$input" || "$input" =~ ^[Yy]$ ]]; then
    # Need OS check
    curl -sS https://starship.rs/install.sh | shi
fi

echo -e "${YELLOW}Install Oh My ZSH? [Y/n]${NC}"
read -r input

if [[ -z "$input" || "$input" =~ ^[Yy]$ ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
