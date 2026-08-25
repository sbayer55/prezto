#!/usr/bin/env zsh

# Script to install development tools using preferred package manager
# ------------------------------------------------------------------

# Define the list of packages to install
readonly PACKAGES=(
  "midnight-commander:Visual file manager with Norton Commander interface"
  "wget:Internet file retriever"
  "git-delta:Syntax-highlighting pager for git and diff output"
  "fd:Simple, fast and user-friendly alternative to find"
  "eza:Modern alternative to ls with more features and better defaults"
  "bat:Cat clone with syntax highlighting and Git integration"
  "ollama:Run large language models locally"
  "fish:User-friendly command-line shell"
  "tree:Display directories as trees"
  "htop:Interactive process viewer"
  "gnupg:GNU Privacy Guard: free implementation of the OpenPGP standard"
  "neovim:Hyperextensible Vim-based text editor"
  "ripgrep:Fast, recursive grep alternative"
  "jq:Lightweight and flexible command-line JSON processor"
  "fzf:Command-line fuzzy finder"
  "zoxide:Smarter cd command with learning capabilities"
  "btop:Resource monitor with responsive UI"
  "bottom:Graphical process/system monitor similar to top"
  "atuin:Magical shell history"
  "zsh-autosuggestions:Fish-like autosuggestions for zsh"
  # Runtimes the Neovim config needs: Mason installs most of its language
  # servers with npm, pyright needs Node too, and jdtls needs a JDK.
  "node:JavaScript runtime required by Mason language servers"
  "npm:Node package manager used by Mason"
  "python:Python 3 interpreter used by Python tooling"
  "openjdk:Java Development Kit required by the jdtls language server"
  "unzip:Archive extractor used by Mason package installs"
  "awscli:Amazon Web Services command line interface (v2)"
  "uv:Fast Python package and project manager"
)

# Package name mappings for different package managers.
# The PACKAGES list above uses Homebrew names; only the differences are listed.
map_package_name() {
  local manager="$1" package="$2"

  case "$manager" in
    apt)
      case "$package" in
        midnight-commander) echo "mc" ;;
        fd)                 echo "fd-find" ;;
        node)               echo "nodejs" ;;
        python)             echo "python3" ;;
        openjdk)            echo "default-jdk" ;;
        # Debian/Ubuntu only package awscli v1; ensure_awscli installs v2.
        awscli)             echo "awscli" ;;
        *)                  echo "$package" ;;
      esac
      ;;
    dnf)
      case "$package" in
        midnight-commander) echo "mc" ;;
        fd)                 echo "fd-find" ;;
        gnupg)              echo "gnupg2" ;;
        node)               echo "nodejs" ;;
        python)             echo "python3" ;;
        openjdk)            echo "java-devel" ;;
        awscli)             echo "awscli2" ;;
        *)                  echo "$package" ;;
      esac
      ;;
    pacman)
      case "$package" in
        midnight-commander) echo "mc" ;;
        node)               echo "nodejs" ;;
        openjdk)            echo "jdk-openjdk" ;;
        awscli)             echo "aws-cli-v2" ;;
        *)                  echo "$package" ;;
      esac
      ;;
    zypper)
      case "$package" in
        midnight-commander) echo "mc" ;;
        node)               echo "nodejs" ;;
        python)             echo "python3" ;;
        openjdk)            echo "java-devel" ;;
        awscli)             echo "aws-cli" ;;
        *)                  echo "$package" ;;
      esac
      ;;
    apk)
      case "$package" in
        midnight-commander) echo "mc" ;;
        node)               echo "nodejs" ;;
        python)             echo "python3" ;;
        openjdk)            echo "openjdk21" ;;
        awscli)             echo "aws-cli" ;;
        *)                  echo "$package" ;;
      esac
      ;;
    brew)
      case "$package" in
        # The node formula ships npm; there is no separate npm formula.
        npm)     echo "node" ;;
        openjdk) echo "openjdk@21" ;;
        *)       echo "$package" ;;
      esac
      ;;
    *)
      echo "$package"
      ;;
  esac
}

# Debian and Fedora ship fd and bat under different binary names to avoid
# clashes; the shell config in this repo calls them fd and bat.
link_renamed_binaries() {
  local bin_dir="${HOME}/.local/bin"
  local shimmed=()

  mkdir -p "$bin_dir"

  if ! command_exists fd && command_exists fdfind; then
    ln -sf "$(command -v fdfind)" "${bin_dir}/fd"
    shimmed+=("fd -> fdfind")
  fi
  if ! command_exists bat && command_exists batcat; then
    ln -sf "$(command -v batcat)" "${bin_dir}/bat"
    shimmed+=("bat -> batcat")
  fi

  if ((${#shimmed[@]} > 0)); then
    echo -e "${BLUE}Linked in ${bin_dir}: ${shimmed[*]}${NC}"
  fi
}

# Set colors for better readability
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to detect available package managers
detect_package_managers() {
  local available_managers=()
  
  if command_exists brew; then
    available_managers+=("brew:Homebrew")
  fi
  
  if command_exists cargo; then
    available_managers+=("cargo:Rust Cargo")
  fi
  
  if command_exists apt || command_exists apt-get; then
    available_managers+=("apt:APT (Debian/Ubuntu)")
  fi
  
  if command_exists dnf; then
    available_managers+=("dnf:DNF (Fedora/RHEL)")
  fi
  
  if command_exists pacman; then
    available_managers+=("pacman:Pacman (Arch Linux)")
  fi
  
  if command_exists zypper; then
    available_managers+=("zypper:Zypper (openSUSE)")
  fi
  
  if command_exists apk; then
    available_managers+=("apk:APK (Alpine Linux)")
  fi
  
  if ((${#available_managers[@]} > 0)); then
    printf '%s\n' "${available_managers[@]}"
  fi
}

# Function to install with Homebrew
install_with_brew() {
  echo -e "${BLUE}Installing packages with Homebrew...${NC}"
  
  # Disable analytics
  brew analytics off
  
  # Check for updates
  echo -e "${BLUE}Updating Homebrew...${NC}"
  brew update
  
  local success_count=0
  local failed_packages=()
  local skipped_packages=()
  
  for package_info in "${PACKAGES[@]}"; do
    local package_name="${package_info%%:*}"
    package_name="$(map_package_name brew "$package_name")"
    
    echo -e "\n${YELLOW}Processing $package_name...${NC}"
    
    if brew list "$package_name" &>/dev/null; then
      echo -e "${GREEN}$package_name is already installed. Skipping.${NC}"
      skipped_packages+=("$package_name")
      ((success_count++))  # Count as success since it's already installed
    else
      echo -e "${BLUE}Installing $package_name...${NC}"
      if brew install "$package_name"; then
        echo -e "${GREEN}Successfully installed $package_name.${NC}"
        ((success_count++))
      else
        echo -e "${RED}Failed to install $package_name.${NC}"
        failed_packages+=("$package_name")
      fi
    fi
  done
  
  # Print installation summary
  echo -e "\n${GREEN}Installation summary:${NC}"
  echo -e "${BLUE}Total packages processed: ${#PACKAGES[@]}${NC}"
  echo -e "${GREEN}Successfully installed: $success_count${NC}"
  echo -e "${CYAN}Already installed (skipped): ${#skipped_packages[@]}${NC}"
  
  if ((${#skipped_packages[@]} > 0)); then
    echo -e "${CYAN}Skipped packages: ${skipped_packages[*]}${NC}"
  fi
  
  if ((${#failed_packages[@]} > 0)); then
    echo -e "${RED}Failed installations: ${#failed_packages[@]}${NC}"
    echo -e "${RED}Failed packages: ${failed_packages[*]}${NC}"
  fi
}

# Function to install with Cargo
install_with_cargo() {
  local packages=("$@")
  local success_count=0
  local failed_packages=()
  local skipped_packages=()
  
  echo -e "${BLUE}Installing packages with Cargo...${NC}"
  
  for package in "${packages[@]}"; do
    echo -e "\n${YELLOW}Processing $package...${NC}"
    
    if cargo install --list | grep -q "^$package "; then
      echo -e "${GREEN}$package is already installed. Skipping.${NC}"
      skipped_packages+=("$package")
      ((success_count++))  # Count as success since it's already installed
    else
      echo -e "${BLUE}Installing $package...${NC}"
      if cargo install "$package"; then
        echo -e "${GREEN}Successfully installed $package.${NC}"
        ((success_count++))
      else
        echo -e "${RED}Failed to install $package.${NC}"
        failed_packages+=("$package")
      fi
    fi
  done
  
  # Print installation summary
  if ((${#packages[@]} > 0)); then
    echo -e "\n${GREEN}Cargo installation summary:${NC}"
    echo -e "${BLUE}Total packages processed: ${#packages[@]}${NC}"
    echo -e "${GREEN}Successfully installed: $success_count${NC}"
    echo -e "${CYAN}Already installed (skipped): ${#skipped_packages[@]}${NC}"
    
    if ((${#skipped_packages[@]} > 0)); then
      echo -e "${CYAN}Skipped packages: ${skipped_packages[*]}${NC}"
    fi
    
    if ((${#failed_packages[@]} > 0)); then
      echo -e "${RED}Failed installations: ${#failed_packages[@]}${NC}"
      echo -e "${RED}Failed packages: ${failed_packages[*]}${NC}"
    fi
  fi
}

# Function to install with native Linux package manager
install_with_native() {
  local package_manager=$1
  local all_packages=()
  local failed_packages=()
  local success_count=0
  
  echo -e "${BLUE}Installing packages with $package_manager...${NC}"
  
  case "$package_manager" in
    apt)
      # Update package lists
      sudo apt update
      
      for package_info in "${PACKAGES[@]}"; do
        local package_name="${package_info%%:*}"
        package_name="$(map_package_name "$package_manager" "$package_name")"
        
        # Check if already installed
        if dpkg -l | grep -q "^ii.*$package_name "; then
          echo -e "${GREEN}$package_name is already installed. Skipping.${NC}"
          skipped_packages+=("$package_name")
          ((success_count++))
          continue
        fi
        
        # Try to install individual packages so we can track success/failure
        echo -e "\n${YELLOW}Installing $package_name with apt...${NC}"
        if sudo apt install -y "$package_name"; then
          echo -e "${GREEN}Successfully installed $package_name.${NC}"
          ((success_count++))
        else
          echo -e "${RED}Failed to install $package_name with apt.${NC}"
          failed_packages+=("$package_name")
        fi
      done
      ;;
      
    dnf)
      # Update package lists
      sudo dnf check-update
      
      for package_info in "${PACKAGES[@]}"; do
        local package_name="${package_info%%:*}"
        package_name="$(map_package_name "$package_manager" "$package_name")"
        
        echo -e "\n${YELLOW}Installing $package_name with dnf...${NC}"
        if sudo dnf install -y "$package_name"; then
          echo -e "${GREEN}Successfully installed $package_name.${NC}"
          ((success_count++))
        else
          echo -e "${RED}Failed to install $package_name with dnf.${NC}"
          failed_packages+=("$package_name")
        fi
      done
      ;;
      
    pacman)
      # Update package lists
      sudo pacman -Sy
      
      for package_info in "${PACKAGES[@]}"; do
        local package_name="${package_info%%:*}"
        package_name="$(map_package_name "$package_manager" "$package_name")"
        
        echo -e "\n${YELLOW}Installing $package_name with pacman...${NC}"
        if sudo pacman -S --needed --noconfirm "$package_name"; then
          echo -e "${GREEN}Successfully installed $package_name.${NC}"
          ((success_count++))
        else
          echo -e "${RED}Failed to install $package_name with pacman.${NC}"
          failed_packages+=("$package_name")
        fi
      done
      ;;
      
    zypper)
      # Update package lists
      sudo zypper refresh
      
      for package_info in "${PACKAGES[@]}"; do
        local package_name="${package_info%%:*}"
        package_name="$(map_package_name "$package_manager" "$package_name")"
        
        echo -e "\n${YELLOW}Installing $package_name with zypper...${NC}"
        if sudo zypper install -y "$package_name"; then
          echo -e "${GREEN}Successfully installed $package_name.${NC}"
          ((success_count++))
        else
          echo -e "${RED}Failed to install $package_name with zypper.${NC}"
          failed_packages+=("$package_name")
        fi
      done
      ;;
      
    apk)
      # Update package lists
      sudo apk update
      
      for package_info in "${PACKAGES[@]}"; do
        local package_name="${package_info%%:*}"
        package_name="$(map_package_name "$package_manager" "$package_name")"
        
        echo -e "\n${YELLOW}Installing $package_name with apk...${NC}"
        if sudo apk add "$package_name"; then
          echo -e "${GREEN}Successfully installed $package_name.${NC}"
          ((success_count++))
        else
          echo -e "${RED}Failed to install $package_name with apk.${NC}"
          failed_packages+=("$package_name")
        fi
      done
      ;;
  esac
  
  link_renamed_binaries

  echo -e "\n${GREEN}Installation with $package_manager completed.${NC}"
  echo -e "${BLUE}Total packages processed: ${#PACKAGES[@]}${NC}"
  echo -e "${GREEN}Successfully installed: $success_count${NC}"
  
  if ((${#failed_packages[@]} > 0)); then
    echo -e "${RED}Failed installations: ${#failed_packages[@]}${NC}"
    echo -e "${RED}Failed packages: ${failed_packages[*]}${NC}"
  fi
  
  # Offer to try installing failed packages with Cargo if available
  if ((${#failed_packages[@]} > 0)) && command_exists cargo; then
    echo -e "\n${YELLOW}Some packages failed to install with $package_manager.${NC}"
    echo -e "${YELLOW}Would you like to try installing these packages with Cargo? [Y/n]${NC}"
    echo -e "${BLUE}Packages: ${failed_packages[*]}${NC}"
    read -r USE_CARGO_FALLBACK
    
    if [[ -z "$USE_CARGO_FALLBACK" || "$USE_CARGO_FALLBACK" =~ ^[Yy]$ ]]; then
      install_with_cargo "${failed_packages[@]}"
    else
      echo -e "${BLUE}Skipping Cargo fallback installation.${NC}"
    fi
  fi
}

# The Neovim config in this repo needs 0.11 (vim.hl.on_yank, treesitter
# foldexpr, the vim.lsp.config era). Several distros still ship 0.9/0.10, so
# fall back to the official release tarball when the package is too old.
readonly NVIM_MIN_MAJOR=0
readonly NVIM_MIN_MINOR=11

neovim_is_recent() {
  command_exists nvim || return 1

  local version major minor
  version="$(nvim --version 2>/dev/null | head -1 | sed -E 's/^NVIM v?//; s/[^0-9.].*$//')"
  [[ -n "$version" ]] || return 1

  major="${version%%.*}"
  minor="${version#*.}"
  minor="${minor%%.*}"

  ((major > NVIM_MIN_MAJOR)) && return 0
  ((major == NVIM_MIN_MAJOR && minor >= NVIM_MIN_MINOR))
}

install_neovim_from_release() {
  local arch tarball url

  case "$(uname -s)-$(uname -m)" in
    Linux-x86_64)        arch="linux-x86_64" ;;
    Linux-aarch64|Linux-arm64) arch="linux-arm64" ;;
    *)
      echo -e "${YELLOW}No official Neovim tarball for $(uname -s)/$(uname -m); skipping.${NC}"
      return 1
      ;;
  esac

  tarball="nvim-${arch}.tar.gz"
  url="https://github.com/neovim/neovim/releases/download/stable/${tarball}"

  echo -e "${BLUE}Downloading ${url}...${NC}"
  if ! curl -fsSL -o "/tmp/${tarball}" "$url"; then
    echo -e "${RED}Failed to download Neovim from ${url}.${NC}"
    return 1
  fi

  sudo rm -rf "/opt/nvim-${arch}"
  if ! sudo tar -C /opt -xzf "/tmp/${tarball}"; then
    echo -e "${RED}Failed to unpack ${tarball}.${NC}"
    rm -f "/tmp/${tarball}"
    return 1
  fi
  rm -f "/tmp/${tarball}"

  sudo ln -sf "/opt/nvim-${arch}/bin/nvim" /usr/local/bin/nvim
  hash -r
  echo -e "${GREEN}Installed $(nvim --version | head -1) to /opt/nvim-${arch}.${NC}"
}

# Make sure whatever the package manager gave us is new enough for the config.
ensure_recent_neovim() {
  if neovim_is_recent; then
    echo -e "${GREEN}$(nvim --version | head -1) is new enough for this config.${NC}"
    return 0
  fi

  if command_exists nvim; then
    echo -e "\n${YELLOW}$(nvim --version | head -1) is older than the ${NVIM_MIN_MAJOR}.${NVIM_MIN_MINOR} this config requires.${NC}"
  else
    echo -e "\n${YELLOW}Neovim is not installed.${NC}"
  fi
  echo -e "${YELLOW}Install the official Neovim release build? [Y/n]${NC}"
  read -r INSTALL_NVIM

  if [[ -z "$INSTALL_NVIM" || "$INSTALL_NVIM" =~ ^[Yy]$ ]]; then
    install_neovim_from_release
  else
    echo -e "${BLUE}Leaving Neovim as is; ~/.config/nvim will not work correctly.${NC}"
  fi
}

# Not every distro packages the AWS CLI v2 (Debian and Ubuntu ship only the
# deprecated v1), so fall back to Amazon's official installer.
ensure_awscli() {
  if command_exists aws; then
    echo -e "${GREEN}$(aws --version 2>&1 | head -1) is installed.${NC}"
    return 0
  fi

  local os arch url
  os="$(uname -s)"

  if [[ "$os" == "Darwin" ]]; then
    echo -e "${BLUE}Installing the AWS CLI v2 from awscli.amazonaws.com...${NC}"
    if curl -fsSL "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o /tmp/AWSCLIV2.pkg; then
      sudo installer -pkg /tmp/AWSCLIV2.pkg -target /
      rm -f /tmp/AWSCLIV2.pkg
    else
      echo -e "${RED}Failed to download the AWS CLI installer.${NC}"
      return 1
    fi
  else
    case "$(uname -m)" in
      x86_64)          arch="x86_64" ;;
      aarch64|arm64)   arch="aarch64" ;;
      *)
        echo -e "${YELLOW}No official AWS CLI build for $(uname -m); skipping.${NC}"
        return 1
        ;;
    esac

    url="https://awscli.amazonaws.com/awscli-exe-linux-${arch}.zip"
    echo -e "${BLUE}Installing the AWS CLI v2 from ${url}...${NC}"

    if ! command_exists unzip; then
      echo -e "${RED}unzip is required to install the AWS CLI; skipping.${NC}"
      return 1
    fi
    if ! curl -fsSL "$url" -o /tmp/awscliv2.zip; then
      echo -e "${RED}Failed to download the AWS CLI from ${url}.${NC}"
      return 1
    fi

    rm -rf /tmp/aws
    unzip -q -o /tmp/awscliv2.zip -d /tmp
    sudo /tmp/aws/install --update
    rm -rf /tmp/aws /tmp/awscliv2.zip
  fi

  hash -r
  if command_exists aws; then
    echo -e "${GREEN}Installed $(aws --version 2>&1 | head -1).${NC}"
  else
    echo -e "${RED}The AWS CLI is still not on PATH.${NC}"
    return 1
  fi
}

# uv is not in every distro's repositories yet; astral.sh publishes an
# installer that drops it in ~/.local/bin.
ensure_uv() {
  if command_exists uv; then
    echo -e "${GREEN}$(uv --version 2>&1 | head -1) is installed.${NC}"
    return 0
  fi

  echo -e "${BLUE}Installing uv from astral.sh...${NC}"
  if ! curl -LsSf https://astral.sh/uv/install.sh | sh; then
    echo -e "${RED}Failed to install uv.${NC}"
    return 1
  fi

  # The installer targets ~/.local/bin, which the zshrc adds to PATH.
  export PATH="${HOME}/.local/bin:${PATH}"
  hash -r

  if command_exists uv; then
    echo -e "${GREEN}Installed $(uv --version 2>&1 | head -1).${NC}"
  else
    echo -e "${RED}uv is still not on PATH.${NC}"
    return 1
  fi
}

# Function to display usage tips
display_usage_tips() {
  # Tool-specific tips
  declare -A TOOL_TIPS
  TOOL_TIPS=(
    ["eza"]="$(cat << EOF
${YELLOW}eza (modern ls replacement):${NC}
${CYAN}Add to your ~/.zshrc:${NC}
  alias ls='eza'
  alias ll='eza -la'
  alias lt='eza --tree'
EOF
    )"
    
    ["bat"]="$(cat << EOF
${YELLOW}bat (better cat with syntax highlighting):${NC}
${CYAN}Usage examples:${NC}
  bat file.txt               ${BLUE}# View file with syntax highlighting${NC}
  bat -p file.txt            ${BLUE}# Plain mode without decorations${NC}
  bat -A file.txt            ${BLUE}# Show invisible characters${NC}
EOF
    )"
    
    ["neovim"]="$(cat << EOF
${YELLOW}neovim (improved vim editor):${NC}
${CYAN}Add to your ~/.zshrc:${NC}
  alias vim='nvim'
  alias vi='nvim'
${CYAN}Basic usage:${NC}
  nvim file.txt              ${BLUE}# Edit a file${NC}
EOF
    )"
    
    ["fzf"]="$(cat << EOF
${YELLOW}fzf (fuzzy finder):${NC}
${CYAN}Usage examples:${NC}
  fzf                        ${BLUE}# Start interactive finder${NC}
  vim \$(fzf)                ${BLUE}# Open selected file in vim${NC}
  history | fzf              ${BLUE}# Search command history${NC}
EOF
    )"
    
    ["ripgrep"]="$(cat << EOF
${YELLOW}ripgrep (faster grep):${NC}
${CYAN}Usage examples:${NC}
  rg pattern                 ${BLUE}# Search for pattern in current directory${NC}
  rg -i pattern              ${BLUE}# Case insensitive search${NC}
  rg -t py pattern           ${BLUE}# Search only Python files${NC}
EOF
    )"
    
    ["zoxide"]="$(cat << EOF
${YELLOW}zoxide (smarter cd command):${NC}
${CYAN}Add to your ~/.zshrc:${NC}
  eval "\$(zoxide init zsh)"
${CYAN}Usage:${NC}
  z directory                ${BLUE}# Jump to a directory${NC}
  zi directory               ${BLUE}# Interactive selection${NC}
EOF
    )"
    
    ["atuin"]="$(cat << EOF
${YELLOW}atuin (shell history manager):${NC}
${CYAN}Setup:${NC}
  atuin init zsh > ~/.atuin.zsh
  echo 'source ~/.atuin.zsh' >> ~/.zshrc
${CYAN}Usage:${NC}
  Ctrl+r                     ${BLUE}# Search history${NC}
EOF
    )"
    
    ["git-delta"]="$(cat << EOF
${YELLOW}git-delta (improved git diff):${NC}
${CYAN}Add to your ~/.gitconfig:${NC}
  [core]
      pager = delta
  [interactive]
      diffFilter = delta --color-only
  [delta]
      navigate = true
      light = false
      side-by-side = true
EOF
    )"
    
    ["fd"]="$(cat << EOF
${YELLOW}fd (alternative to find):${NC}
${CYAN}Usage examples:${NC}
  fd pattern                 ${BLUE}# Find files/dirs matching pattern${NC}
  fd -t f pattern            ${BLUE}# Find only files${NC}
  fd -e md                   ${BLUE}# Find only markdown files${NC}
EOF
    )"
    
    ["midnight-commander"]="$(cat << EOF
${YELLOW}midnight-commander (file manager):${NC}
${CYAN}Usage:${NC}
  mc                         ${BLUE}# Start Midnight Commander${NC}
  F9                         ${BLUE}# Access menu bar${NC}
  F5                         ${BLUE}# Copy files${NC}
EOF
    )"
    
    ["awscli"]="$(cat << EOF
${YELLOW}awscli (AWS command line interface):${NC}
${CYAN}Usage examples:${NC}
  aws configure sso          ${BLUE}# Set up SSO credentials${NC}
  aws s3 ls                  ${BLUE}# List S3 buckets${NC}
  aws sts get-caller-identity ${BLUE}# Show the current identity${NC}
EOF
    )"

    ["uv"]="$(cat << EOF
${YELLOW}uv (Python package and project manager):${NC}
${CYAN}Usage examples:${NC}
  uv venv                    ${BLUE}# Create a virtual environment${NC}
  uv pip install -r reqs.txt ${BLUE}# Install dependencies (pip compatible)${NC}
  uv run script.py           ${BLUE}# Run a script in a managed environment${NC}
  uv tool install ruff       ${BLUE}# Install a CLI tool globally${NC}
EOF
    )"

    ["zsh-autosuggestions"]="$(cat << EOF
${YELLOW}zsh-autosuggestions:${NC}
${CYAN}Add to your ~/.zshrc:${NC}
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  # or if installed with Homebrew:
  source \$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
EOF
    )"
  )
  
  # Display tips for commonly installed tools
  echo -e "\n${BLUE}===== Tool Usage Tips =====${NC}"
  
  for tool in eza bat neovim fzf ripgrep zoxide atuin git-delta fd midnight-commander awscli uv zsh-autosuggestions; do
    binary="$tool"
    [[ "$tool" == "awscli" ]] && binary="aws"
    if command_exists "$binary" || [[ "$tool" == "zsh-autosuggestions" ]]; then
      echo -e "\n${TOOL_TIPS[$tool]}"
    fi
  done
  
  echo -e "\n${GREEN}Remember to restart your shell after making configuration changes!${NC}"
}

# Main script

# Detect available package managers
available_managers=(${(f)"$(detect_package_managers)"})

if ((${#available_managers[@]} == 0)); then
  echo -e "${RED}No supported package managers found.${NC}"
  echo -e "${YELLOW}Please install at least one of: Homebrew, Cargo, or a supported Linux package manager.${NC}"
  exit 1
fi

# Display available package managers
echo -e "${BLUE}Available package managers:${NC}"
for i in {1..${#available_managers[@]}}; do
  manager_info="${available_managers[$i]}"
  manager_name="${manager_info%%:*}"
  manager_desc="${manager_info#*:}"
  echo -e "${CYAN}[$i] $manager_name${NC}: $manager_desc"
done

# Ask user to select a package manager
echo -e "\n${YELLOW}Which package manager would you like to use? (Enter number)${NC}"
read -r MANAGER_CHOICE

if [ -z "${MANAGER_CHOICE##*[!0-9]*}" ] || [ "$MANAGER_CHOICE" -lt 1 ] || [ "$MANAGER_CHOICE" -gt "${#available_managers[@]}" ]; then
  echo -e "${RED}Invalid selection. Exiting.${NC}"
  exit 1
fi

# Get selected package manager
selected_manager="${available_managers[$MANAGER_CHOICE]}"
manager_name="${selected_manager%%:*}"
manager_desc="${selected_manager#*:}"

echo -e "${GREEN}Using $manager_desc ($manager_name) as the package manager.${NC}"

# List packages that will be installed
echo -e "\n${YELLOW}Would you like to install the following tools using $manager_name?${NC}"

for package_info in "${PACKAGES[@]}"; do
  package_name="${package_info%%:*}"
  package_desc="${package_info#*:}"
  echo -e "  - ${BLUE}${package_name}${NC}: ${package_desc}"
done

echo -e "${YELLOW}Install these packages? [Y/n]${NC}"
read -r INSTALL_TOOLS

if [[ -z "$INSTALL_TOOLS" || "$INSTALL_TOOLS" =~ ^[Yy]$ ]]; then
  case "$manager_name" in
    brew)
      install_with_brew
      ;;
    cargo)
      # Extract just the package names for all packages
      cargo_packages=()
      for package_info in "${PACKAGES[@]}"; do
        package_name="${package_info%%:*}"
        cargo_packages+=("$package_name")
      done
      
      install_with_cargo "${cargo_packages[@]}"
      ;;
    apt|dnf|pacman|zypper|apk)
      install_with_native "$manager_name"
      ;;
    *)
      echo -e "${RED}Unsupported package manager: $manager_name. Exiting.${NC}"
      exit 1
      ;;
  esac

  # The bundled Neovim config needs a recent Neovim, which not every distro has.
  ensure_recent_neovim

  # Neither of these is packaged everywhere; fall back to the vendor installers.
  ensure_awscli
  ensure_uv

  # Display usage tips
  display_usage_tips
else
  echo -e "${BLUE}Installation cancelled. Exiting.${NC}"
fi

exit 0