#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect OS
OS="$(uname -s)"
ARCH="$(uname -m)"

# Normalize architecture names
case "$ARCH" in
    x86_64) ARCH_ALT="amd64" ;;
    aarch64|arm64) ARCH_ALT="arm64"; ARCH="aarch64" ;;
    *) error "Unsupported architecture: $ARCH"; exit 1 ;;
esac

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_BIN="$HOME/.local/bin"

mkdir -p "$LOCAL_BIN"

# Helper to get latest GitHub release tag
get_latest_release() {
    local repo="$1"
    curl -fsSL "https://api.github.com/repos/$repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

# Helper to prompt for confirmation
confirm() {
    local msg="$1"
    local default="${2:-y}"

    if [[ "$default" == "y" ]]; then
        read -p "$msg [Y/n] " response
        [[ -z "$response" || "$response" =~ ^[Yy] ]]
    else
        read -p "$msg [y/N] " response
        [[ "$response" =~ ^[Yy] ]]
    fi
}

# Helper to backup and link files
link_file() {
    local src="$1"
    local dest="$2"

    if [[ -e "$dest" || -L "$dest" ]]; then
        if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
            success "Already linked: $dest"
            return
        fi

        if confirm "File exists: $dest. Backup and replace?"; then
            local backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
            mv "$dest" "$backup"
            warn "Backed up to: $backup"
        else
            warn "Skipping: $dest"
            return
        fi
    fi

    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    success "Linked: $dest -> $src"
}

# Install system dependencies (only if missing)
install_system_deps() {
    local missing=()
    command -v git &>/dev/null || missing+=("git")
    command -v curl &>/dev/null || missing+=("curl")
    command -v zsh &>/dev/null || missing+=("zsh")
    command -v xclip &>/dev/null || missing+=("xclip")

    if [[ ${#missing[@]} -eq 0 ]]; then
        success "System dependencies already installed (git, curl, zsh)"
        return
    fi

    info "Installing missing dependencies: ${missing[*]}"

    if [[ "$OS" == "Linux" ]]; then
        if command -v apt-get &>/dev/null; then
            sudo apt-get update
            sudo apt-get install -y "${missing[@]}"
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y "${missing[@]}"
        elif command -v pacman &>/dev/null; then
            sudo pacman -Sy --noconfirm "${missing[@]}"
        elif command -v apk &>/dev/null; then
            sudo apk add "${missing[@]}"
        else
            error "Unknown package manager. Please install manually: ${missing[*]}"
            exit 1
        fi
    elif [[ "$OS" == "Darwin" ]]; then
        if ! command -v brew &>/dev/null; then
            info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install "${missing[@]}"
    fi

    success "System dependencies installed"
}

# Install Neovim
install_neovim() {
    info "Installing Neovim..."

    local version
    version=$(get_latest_release "neovim/neovim")

    if [[ "$OS" == "Linux" ]]; then
        # Neovim uses x86_64 and arm64 (not aarch64)
        local nvim_arch="$ARCH"
        [[ "$ARCH" == "aarch64" ]] && nvim_arch="arm64"

        curl -fsSL "https://github.com/neovim/neovim/releases/download/${version}/nvim-linux-${nvim_arch}.tar.gz" -o /tmp/nvim.tar.gz
        tar -xzf /tmp/nvim.tar.gz -C /tmp
        cp -r /tmp/nvim-linux-${nvim_arch}/* "$HOME/.local/"
        rm -rf /tmp/nvim.tar.gz /tmp/nvim-linux-${nvim_arch}
    elif [[ "$OS" == "Darwin" ]]; then
        brew install neovim
    fi

    success "Neovim installed"
}

# Install fzf
install_fzf() {
    info "Installing fzf..."

    local version
    version=$(get_latest_release "junegunn/fzf")

    local fzf_arch="$ARCH"
    [[ "$ARCH" == "x86_64" ]] && fzf_arch="amd64"
    [[ "$ARCH" == "aarch64" ]] && fzf_arch="arm64"

    local os_lower
    os_lower=$(echo "$OS" | tr '[:upper:]' '[:lower:]')

    curl -fsSL "https://github.com/junegunn/fzf/releases/download/${version}/fzf-${version#v}-${os_lower}_${fzf_arch}.tar.gz" -o /tmp/fzf.tar.gz
    tar -xzf /tmp/fzf.tar.gz -C "$LOCAL_BIN"
    rm /tmp/fzf.tar.gz

    success "fzf installed"
}

# Install ripgrep
install_ripgrep() {
    info "Installing ripgrep..."

    local version
    version=$(get_latest_release "BurntSushi/ripgrep")

    local rg_arch="$ARCH"
    [[ "$ARCH" == "aarch64" ]] && rg_arch="aarch64"

    if [[ "$OS" == "Linux" ]]; then
        curl -fsSL "https://github.com/BurntSushi/ripgrep/releases/download/${version}/ripgrep-${version#v}-${rg_arch}-unknown-linux-musl.tar.gz" -o /tmp/rg.tar.gz
        tar -xzf /tmp/rg.tar.gz -C /tmp
        cp /tmp/ripgrep-${version#v}-${rg_arch}-unknown-linux-musl/rg "$LOCAL_BIN/"
        rm -rf /tmp/rg.tar.gz /tmp/ripgrep-*
    elif [[ "$OS" == "Darwin" ]]; then
        brew install ripgrep
    fi

    success "ripgrep installed"
}



# Install zoxide
install_zoxide() {
    info "Installing zoxide..."

    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

    success "zoxide installed"
}

# Install Starship
install_starship() {
    info "Installing Starship..."

    curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$LOCAL_BIN"

    success "Starship installed"
}

# Install tmux plugin manager
install_tpm() {
    info "Installing tmux plugin manager..."

    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [[ -d "$tpm_dir" ]]; then
        success "TPM already installed"
    else
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
        success "TPM installed"
    fi
}

# Install tmux plugins (must run after dotfiles are linked)
install_tmux_plugins() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    if [[ -f "$HOME/.tmux.conf" ]] && [[ -x "$tpm_dir/bin/install_plugins" ]]; then
        info "Installing tmux plugins..."
        "$tpm_dir/bin/install_plugins"
        success "tmux plugins installed"
    fi
}

# Setup LazyVim
setup_neovim() {
    info "Setting up LazyVim..."

    local nvim_config="$HOME/.config/nvim"

    if [[ -d "$nvim_config" ]]; then
        if confirm "Neovim config exists at $nvim_config. Backup and replace?"; then
            local backup="${nvim_config}.bak.$(date +%Y%m%d%H%M%S)"
            mv "$nvim_config" "$backup"
            warn "Backed up to: $backup"
        else
            warn "Skipping Neovim setup"
            return
        fi
    fi

    git clone https://github.com/LazyVim/starter "$nvim_config"
    rm -rf "$nvim_config/.git"
    success "LazyVim installed"
}

# Setup capslock to escape (Linux only, X11)
setup_capslock_remap() {
    if [[ "$OS" != "Linux" ]]; then
        return
    fi

    info "Setting up capslock -> escape mapping..."

    # Create xmodmap config
    local xmodmap_file="$HOME/.Xmodmap"
    if [[ ! -f "$xmodmap_file" ]] || ! grep -q "Caps_Lock" "$xmodmap_file"; then
        cat >> "$xmodmap_file" << 'EOF'
! Map Caps Lock to Escape
clear Lock
keycode 66 = Escape
EOF
        success "Created ~/.Xmodmap for capslock -> escape"
        warn "Run 'xmodmap ~/.Xmodmap' or re-login to apply"
    else
        success "Capslock mapping already configured in ~/.Xmodmap"
    fi

    # Also create a systemd user service for Wayland (using keyd would be better but requires root)
    warn "Note: For Wayland, consider using 'keyd' or your DE's keyboard settings"
}

# Link dotfiles
link_dotfiles() {
    info "Linking dotfiles..."

    link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
    link_file "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

    success "Dotfiles linked"
}

# Change default shell to zsh
set_default_shell() {
    if [[ "$SHELL" != *"zsh"* ]]; then
        info "Changing default shell to zsh..."
        local zsh_path
        zsh_path=$(which zsh)

        if ! grep -q "$zsh_path" /etc/shells; then
            echo "$zsh_path" | sudo tee -a /etc/shells
        fi

        chsh -s "$zsh_path"
        success "Default shell changed to zsh"
    else
        success "Already using zsh"
    fi
}

# Main installation
main() {
    echo ""
    echo "========================================="
    echo "        Dotfiles Installation"
    echo "========================================="
    echo ""

    # Ensure ~/.local/bin is in PATH for this session
    export PATH="$LOCAL_BIN:$PATH"

    if confirm "Install system dependencies (git, curl, zsh)?"; then
        install_system_deps
    fi

    if confirm "Install CLI tools (fzf, ripgrep, zoxide)?"; then
        install_fzf
        install_ripgrep
        install_zoxide
    fi

    if confirm "Install Starship prompt?"; then
        install_starship
    fi

    if confirm "Install Neovim?"; then
        install_neovim
    fi

    if confirm "Setup LazyVim?"; then
        setup_neovim
    fi

    if confirm "Install tmux plugin manager (TPM)?"; then
        install_tpm
    fi

    if confirm "Setup capslock -> escape mapping (X11)?"; then
        setup_capslock_remap
    fi

    link_dotfiles

    # Install tmux plugins after dotfiles are linked
    install_tmux_plugins

    if confirm "Set zsh as default shell?"; then
        set_default_shell
    fi

    echo ""
    success "Installation complete!"
    echo ""
    info "Next steps:"
    echo "  1. Restart your terminal or run: exec zsh"
    echo "  2. Open nvim to let LazyVim install plugins"
    echo ""
}

main "$@"
