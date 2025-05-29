#!/bin/bash

# -----------------------------------------------
# Proxy Configuration Script for Development Container
# -----------------------------------------------

# Default proxy settings (modify as needed)
DEFAULT_HTTP_PROXY="http://127.0.0.1:7890"
DEFAULT_HTTPS_PROXY="http://127.0.0.1:7890"
DEFAULT_SOCKS_PROXY="socks5://127.0.0.1:7891"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display colored output
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTION] [PROXY_URL]"
    echo "Options:"
    echo "  -s, --set [URL]     Set proxy (use default if URL not provided)"
    echo "  -u, --unset         Unset proxy"
    echo "  -t, --test          Test proxy connection"
    echo "  -st, --status       Show current proxy status"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -s                           # Set default proxy"
    echo "  $0 -s http://127.0.0.1:8080     # Set custom proxy"
    echo "  $0 -u                           # Unset proxy"
    echo "  $0 -t                           # Test current proxy"
}

# Function to set proxy
set_proxy() {
    local http_proxy=${1:-$DEFAULT_HTTP_PROXY}
    local https_proxy=${2:-$DEFAULT_HTTPS_PROXY}
    
    log "Setting proxy to: $http_proxy"
    
    # Set environment variables
    export HTTP_PROXY="$http_proxy"
    export HTTPS_PROXY="$https_proxy"
    export http_proxy="$http_proxy"
    export https_proxy="$https_proxy"
    export NO_PROXY="localhost,127.0.0.1,::1"
    export no_proxy="localhost,127.0.0.1,::1"
    
    # Add to shell configuration files
    {
        echo "# Proxy settings (auto-generated)"
        echo "export HTTP_PROXY=\"$http_proxy\""
        echo "export HTTPS_PROXY=\"$https_proxy\""
        echo "export http_proxy=\"$http_proxy\""
        echo "export https_proxy=\"$https_proxy\""
        echo "export NO_PROXY=\"localhost,127.0.0.1,::1\""
        echo "export no_proxy=\"localhost,127.0.0.1,::1\""
    } > ~/.proxy_config
    
    # Source the proxy config in shell rc files
    for rc_file in ~/.bashrc ~/.zshrc; do
        if [ -f "$rc_file" ]; then
            # Remove existing proxy config lines
            sed -i '/# Proxy settings/d' "$rc_file"
            sed -i '/source.*\.proxy_config/d' "$rc_file"
            
            # Add new proxy config
            echo "source ~/.proxy_config" >> "$rc_file"
        fi
    done
    
    # Configure git proxy
    if command -v git &> /dev/null; then
        git config --global http.proxy "$http_proxy"
        git config --global https.proxy "$https_proxy"
        log "Git proxy configured"
    fi
    
    # Configure npm proxy if npm is available
    if command -v npm &> /dev/null; then
        npm config set proxy "$http_proxy"
        npm config set https-proxy "$https_proxy"
        log "NPM proxy configured"
    fi
    
    # Configure pip proxy
    mkdir -p ~/.pip
    cat > ~/.pip/pip.conf << EOF
[global]
proxy = $http_proxy
trusted-host = pypi.org
               pypi.python.org
               files.pythonhosted.org
EOF
    log "Pip proxy configured"
    
    # Configure conda proxy if conda is available
    if command -v conda &> /dev/null; then
        conda config --set proxy_servers.http "$http_proxy"
        conda config --set proxy_servers.https "$https_proxy"
        log "Conda proxy configured"
    fi
    
    log "Proxy set successfully. Please restart your shell or run 'source ~/.bashrc' or 'source ~/.zshrc'"
}

# Function to unset proxy
unset_proxy() {
    log "Unsetting proxy..."
    
    # Unset environment variables
    unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy NO_PROXY no_proxy
    
    # Remove proxy config file
    rm -f ~/.proxy_config
    
    # Remove from shell rc files
    for rc_file in ~/.bashrc ~/.zshrc; do
        if [ -f "$rc_file" ]; then
            sed -i '/# Proxy settings/d' "$rc_file"
            sed -i '/source.*\.proxy_config/d' "$rc_file"
        fi
    done
    
    # Unset git proxy
    if command -v git &> /dev/null; then
        git config --global --unset http.proxy 2>/dev/null || true
        git config --global --unset https.proxy 2>/dev/null || true
        log "Git proxy unset"
    fi
    
    # Unset npm proxy
    if command -v npm &> /dev/null; then
        npm config delete proxy 2>/dev/null || true
        npm config delete https-proxy 2>/dev/null || true
        log "NPM proxy unset"
    fi
    
    # Remove pip proxy config
    rm -f ~/.pip/pip.conf
    log "Pip proxy config removed"
    
    # Unset conda proxy
    if command -v conda &> /dev/null; then
        conda config --remove-key proxy_servers.http 2>/dev/null || true
        conda config --remove-key proxy_servers.https 2>/dev/null || true
        log "Conda proxy unset"
    fi
    
    log "Proxy unset successfully. Please restart your shell or run 'source ~/.bashrc' or 'source ~/.zshrc'"
}

# Function to test proxy connection
test_proxy() {
    log "Testing proxy connection..."
    
    if [ -z "$HTTP_PROXY" ] && [ -z "$http_proxy" ]; then
        warn "No proxy is currently set"
        return 1
    fi
    
    local test_proxy=${HTTP_PROXY:-$http_proxy}
    log "Testing proxy: $test_proxy"
    
    # Test with curl
    if command -v curl &> /dev/null; then
        if curl -x "$test_proxy" -s --connect-timeout 10 https://www.google.com > /dev/null; then
            log "✓ Proxy connection successful (curl test)"
        else
            error "✗ Proxy connection failed (curl test)"
            return 1
        fi
    fi
    
    # Test with wget
    if command -v wget &> /dev/null; then
        if wget --proxy=on --quiet --timeout=10 --tries=1 -O /dev/null https://www.google.com; then
            log "✓ Proxy connection successful (wget test)"
        else
            warn "✗ Proxy connection failed (wget test)"
        fi
    fi
    
    # Test git clone (if git is available)
    if command -v git &> /dev/null; then
        local temp_dir=$(mktemp -d)
        if git clone --depth 1 https://github.com/octocat/Hello-World.git "$temp_dir/test-repo" &>/dev/null; then
            log "✓ Git proxy working"
            rm -rf "$temp_dir"
        else
            warn "✗ Git proxy test failed"
        fi
    fi
}

# Function to show proxy status
show_status() {
    log "Current proxy status:"
    
    echo "Environment variables:"
    echo "  HTTP_PROXY: ${HTTP_PROXY:-'not set'}"
    echo "  HTTPS_PROXY: ${HTTPS_PROXY:-'not set'}"
    echo "  http_proxy: ${http_proxy:-'not set'}"
    echo "  https_proxy: ${https_proxy:-'not set'}"
    echo "  NO_PROXY: ${NO_PROXY:-'not set'}"
    
    echo ""
    echo "Configuration files:"
    
    # Check proxy config file
    if [ -f ~/.proxy_config ]; then
        echo "  ~/.proxy_config: exists"
    else
        echo "  ~/.proxy_config: not found"
    fi
    
    # Check git proxy
    if command -v git &> /dev/null; then
        local git_http_proxy=$(git config --global --get http.proxy 2>/dev/null || echo "not set")
        local git_https_proxy=$(git config --global --get https.proxy 2>/dev/null || echo "not set")
        echo "  Git HTTP proxy: $git_http_proxy"
        echo "  Git HTTPS proxy: $git_https_proxy"
    fi
    
    # Check npm proxy
    if command -v npm &> /dev/null; then
        local npm_proxy=$(npm config get proxy 2>/dev/null || echo "not set")
        local npm_https_proxy=$(npm config get https-proxy 2>/dev/null || echo "not set")
        echo "  NPM proxy: $npm_proxy"
        echo "  NPM HTTPS proxy: $npm_https_proxy"
    fi
    
    # Check pip proxy
    if [ -f ~/.pip/pip.conf ]; then
        echo "  Pip proxy config: exists"
        grep "proxy" ~/.pip/pip.conf 2>/dev/null || true
    else
        echo "  Pip proxy config: not found"
    fi
    
    # Check conda proxy
    if command -v conda &> /dev/null; then
        echo "  Conda proxy config:"
        conda config --show proxy_servers 2>/dev/null || echo "    not set"
    fi
}

# Function to detect proxy automatically
auto_detect_proxy() {
    log "Attempting to auto-detect proxy..."
    
    # Common proxy ports to check
    local common_ports=(7890 8080 3128 1080 8888)
    local proxy_found=false
    
    for port in "${common_ports[@]}"; do
        local test_url="http://127.0.0.1:$port"
        
        # Test if port is listening
        if command -v nc &> /dev/null; then
            if nc -z 127.0.0.1 "$port" 2>/dev/null; then
                log "Found proxy at $test_url"
                
                # Test if it actually works as a proxy
                if curl -x "$test_url" -s --connect-timeout 5 https://www.google.com > /dev/null 2>&1; then
                    log "✓ Proxy at $test_url is working"
                    echo "$test_url"
                    proxy_found=true
                    break
                else
                    warn "Port $port is open but not working as HTTP proxy"
                fi
            fi
        fi
    done
    
    if [ "$proxy_found" = false ]; then
        warn "No working proxy found automatically"
        return 1
    fi
}

# Main script logic
case "${1:-}" in
    -s|--set)
        if [ -n "${2:-}" ]; then
            set_proxy "$2" "$2"
        else
            # Try to auto-detect or use default
            if auto_proxy=$(auto_detect_proxy 2>/dev/null); then
                set_proxy "$auto_proxy" "$auto_proxy"
            else
                set_proxy
            fi
        fi
        ;;
    -u|--unset)
        unset_proxy
        ;;
    -t|--test)
        test_proxy
        ;;
    -st|--status)
        show_status
        ;;
    -ad|--auto)
        auto_detect_proxy
        ;;
    -h|--help)
        show_usage
        ;;
    "")
        show_status
        ;;
    *)
        error "Unknown option: $1"
        show_usage
        exit 1
        ;;
esac
