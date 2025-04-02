#!/usr/bin/zsh

# Script to check if Cargo is installed and install it if needed
# ------------------------------------------------------------

# Set colors for better readability
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect the OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        # Extract information from /etc/os-release
        source /etc/os-release
        readonly OS_NAME="${ID}"
        readonly OS_LIKE="${ID_LIKE:-}"
        readonly OS_VERSION="${VERSION_ID:-}"
        echo -e "${BLUE}Detected OS: ${OS_NAME} ${OS_VERSION}${NC}"
    elif [[ "$(uname)" == "Darwin" ]]; then
        readonly OS_NAME="macos"
        if command_exists sw_vers; then
            readonly OS_VERSION=$(sw_vers -productVersion)
            echo -e "${BLUE}Detected OS: macOS ${OS_VERSION}${NC}"
        else
            readonly OS_VERSION=""
            echo -e "${BLUE}Detected OS: macOS${NC}"
        fi
    else
        echo -e "${RED}Could not detect OS. Exiting.${NC}"
        exit 1
    fi
}

# Function to install Cargo
install_cargo() {
    echo -e "${BLUE}Installing Cargo...${NC}"
    
    case "${OS_NAME}" in
        # Debian-based distributions
        "debian"|"ubuntu"|"pop"|"mint"|"kali"|"elementary")
            echo -e "${YELLOW}Using apt package manager...${NC}"
            sudo apt update && sudo apt install -y rustc cargo
            ;;
        
        # Red Hat-based distributions
        "fedora"|"rhel"|"centos"|"rocky"|"alma")
            echo -e "${YELLOW}Using dnf package manager...${NC}"
            sudo dnf install -y rust cargo
            ;;
            
        # Arch-based distributions
        "arch"|"manjaro"|"endeavouros")
            echo -e "${YELLOW}Using pacman package manager...${NC}"
            sudo pacman -Sy rust
            ;;
            
        # openSUSE
        "opensuse"*|"suse"*|"sles"*)
            echo -e "${YELLOW}Using zypper package manager...${NC}"
            sudo zypper install -y rust cargo
            ;;
            
        # Alpine Linux
        "alpine")
            echo -e "${YELLOW}Using apk package manager...${NC}"
            sudo apk add rust cargo
            ;;
            
        # macOS
        "macos")
            if command_exists brew; then
                echo -e "${YELLOW}Using Homebrew...${NC}"
                brew install rust
            else
                echo -e "${YELLOW}Homebrew not found. Installing Rust using rustup...${NC}"
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            fi
            ;;
            
        # Other Linux distributions - use rustup
        *)
            # Check if we have ID_LIKE info that might help
            if [[ -n "${OS_LIKE}" ]]; then
                if [[ "${OS_LIKE}" == *"debian"* ]]; then
                    echo -e "${YELLOW}OS appears Debian-like. Using apt package manager...${NC}"
                    sudo apt update && sudo apt install -y rustc cargo
                elif [[ "${OS_LIKE}" == *"fedora"* || "${OS_LIKE}" == *"rhel"* ]]; then
                    echo -e "${YELLOW}OS appears Red Hat-like. Using dnf package manager...${NC}"
                    sudo dnf install -y rust cargo
                elif [[ "${OS_LIKE}" == *"arch"* ]]; then
                    echo -e "${YELLOW}OS appears Arch-like. Using pacman package manager...${NC}"
                    sudo pacman -Sy rust
                elif [[ "${OS_LIKE}" == *"suse"* ]]; then
                    echo -e "${YELLOW}OS appears SUSE-like. Using zypper package manager...${NC}"
                    sudo zypper install -y rust cargo
                else
                    echo -e "${YELLOW}Using rustup installer as fallback...${NC}"
                    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                fi
            else
                echo -e "${YELLOW}Using rustup installer as fallback...${NC}"
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            fi
            ;;
    esac
    
    # Check if installation was successful
    if command_exists cargo; then
        echo -e "${GREEN}Cargo has been successfully installed!${NC}"
        echo -e "${BLUE}Cargo version: $(cargo --version)${NC}"
        return 0
    else
        echo -e "${RED}Failed to install Cargo via package manager.${NC}"
        echo -e "${YELLOW}Would you like to try installing with rustup instead? [y/N]${NC}"
        read -r USE_RUSTUP
        
        if [[ "${USE_RUSTUP}" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Installing Rust and Cargo using rustup...${NC}"
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            
            # Source cargo for current shell after rustup install
            if [[ -f "$HOME/.cargo/env" ]]; then
                source "$HOME/.cargo/env"
            fi
            
            if command_exists cargo; then
                echo -e "${GREEN}Cargo has been successfully installed via rustup!${NC}"
                echo -e "${BLUE}Cargo version: $(cargo --version)${NC}"
                
                # Remind the user to update their shell configuration
                echo -e "${YELLOW}Important: To use Cargo in new terminal sessions, add this to your ~/.zshrc:${NC}"
                echo -e "${BLUE}  source \$HOME/.cargo/env${NC}"
                return 0
            else
                echo -e "${RED}Failed to install Cargo via rustup. Please install manually:${NC}"
                echo -e "${BLUE}  https://www.rust-lang.org/tools/install${NC}"
                return 1
            fi
        else
            echo -e "${RED}Cargo installation failed. Please install manually:${NC}"
            echo -e "${BLUE}  https://www.rust-lang.org/tools/install${NC}"
            return 1
        fi
    fi
}

# Main script

# Check if Cargo is already installed
if command_exists cargo; then
    echo -e "${GREEN}Cargo is already installed on your system.${NC}"
    echo -e "${BLUE}Cargo version: $(cargo --version)${NC}"
else
    echo -e "${YELLOW}Cargo is not installed on your system.${NC}"
    echo -e "${YELLOW}Would you like to install Cargo? [y/N]${NC}"
    read -r INSTALL_CARGO
    
    if [[ "${INSTALL_CARGO}" =~ ^[Yy]$ ]]; then
        detect_os
        install_cargo
    else
        echo -e "${BLUE}Cargo installation skipped.${NC}"
    fi
fi

exit 0