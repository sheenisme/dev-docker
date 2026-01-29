#!/bin/bash

# -----------------------------------------------
# Development Docker Environment Setup Script
# -----------------------------------------------

# Exit on any error
set -e

# Operating System Configuration
declare -A OS_CONFIGS=(
    ["ubuntu2004"]="ubuntu:20.04 ubuntu 20.04 focal"
    ["ubuntu2204"]="ubuntu:22.04 ubuntu 22.04 jammy"
    ["ubuntu2404"]="ubuntu:24.04 ubuntu 24.04 noble"
    ["centos7"]="centos:7 centos 7 centos7"
    ["centos8"]="quay.io/centos/centos:stream8 centos 8 stream8"
)

# Default configuration
os_version="ubuntu2204"    # Default OS version
build_mode="full"          # Default build mode: minimal or full

# Auto-detect configuration variables
host_user_name=$(whoami)                          # Auto-detect current user
host_user_id=$(id -u)                             # Get current user ID
host_group_id=$(id -g)                            # Get current user group ID
host_home_dir=$(eval echo ~$host_user_name)       # Get home directory
workspace_dir="$host_home_dir/workspace"          # Workspace directory

# Derived configuration
container_user_name="sheen"                            # Container user name
container_passwd="123456"                              # Container user password

# Network and proxy configuration (set if needed)
http_proxy="${HTTP_PROXY:-}"                       # Use env var or empty
https_proxy="${HTTPS_PROXY:-}"                     # Use env var or empty

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

# Function to display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -o OS_VERSION    Specify OS version (default: ubuntu2204)"
    echo "                   Supported: ubuntu2004, ubuntu2204, ubuntu2404, centos7, centos8"
    echo "  -m MODE          Build mode: minimal or full (default: full)"
    echo "  -b               Build image, run container, and query IP"
    echo "  -r               Run container and query IP (skip build)"
    echo "  -i               Query and print container IP only"
    echo "  -s               Stop and remove container"
    echo "  -c               Show current configuration"
    echo "  -l               List available OS versions"
    echo "  -h               Display this help message"
    echo ""
    echo "No action option will execute all operations (default)"
    echo ""
    echo "Environment variables:"
    echo "  HTTP_PROXY       HTTP proxy URL (optional)"
    echo "  HTTPS_PROXY      HTTPS proxy URL (optional)"
    echo ""
    echo "Examples:"
    echo "  $0 -o ubuntu2004 -m minimal -b    # Build Ubuntu 20.04 minimal image"
    echo "  $0 -o centos8 -m full              # Build CentOS 8 full image"
    echo "  $0 -l                              # List available OS versions"
}

# Function to list available OS versions
list_os_versions() {
    echo "Available OS versions:"
    echo "  - ubuntu2004: Ubuntu 20.04 (Focal)"
    echo "  - ubuntu2204: Ubuntu 22.04 (Jammy)"
    echo "  - ubuntu2404: Ubuntu 24.04 (Noble)"
    echo "  - centos7:    CentOS 7"
    echo "  - centos8:    CentOS Stream 8"
}

# Function to show current configuration
show_config() {
    # Parse OS configuration
    local os_config="${OS_CONFIGS[$os_version]}"
    read -r base_image distro_name distro_version distro_codename <<< "$os_config"
    
    # Generate names based on configuration
    image_name="dev_${os_version}_${build_mode}_${host_user_name}"
    container_name="dev_${os_version}_${build_mode}_${container_user_name}"
    
    log "Current Configuration:"
    echo "  OS version: $os_version"
    echo "  Base image: $base_image"
    echo "  Build mode: $build_mode"
    echo "  Host user: $host_user_name (UID: $host_user_id, GID: $host_group_id)"
    echo "  Host home: $host_home_dir"
    echo "  Workspace: $workspace_dir"
    echo "  Image name: $image_name"
    echo "  Container name: $container_name"
    echo "  Container user: $container_user_name"
    echo "  HTTP proxy: ${http_proxy:-'not set'}"
    echo "  HTTPS proxy: ${https_proxy:-'not set'}"
}

# Function to check Docker installation
check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        error "Docker daemon is not running. Please start Docker."
        exit 1
    fi

    # Check if user is in docker group or is root
    if ! (groups | grep -q docker) && [ "$(id -u)" -ne 0 ]; then
        error "Current user is not in the docker group and not root."
        error "Please run 'sudo usermod -aG docker $USER' and log out and back in."
        exit 1
    fi

    log "Docker check passed"
}

# Function to ensure workspace directory exists
ensure_workspace() {
    container_workspace_dir="$workspace_dir/$container_name"
    
    if [ ! -d "$container_workspace_dir" ]; then
        log "Creating workspace directory: $container_workspace_dir"
        mkdir -p "$container_workspace_dir"
    else
        log "Workspace directory exists: $container_workspace_dir"
    fi
}

# Function to build Docker image
build_image() {
    # Parse OS configuration
    local os_config="${OS_CONFIGS[$os_version]}"
    if [ -z "$os_config" ]; then
        error "Invalid OS version: $os_version"
        error "Use -l to list available OS versions"
        exit 1
    fi
    
    read -r base_image distro_name distro_version distro_codename <<< "$os_config"
    
    # Generate image name
    image_name="dev_${os_version}_${build_mode}_${host_user_name}"
    
    log "Building Docker image: $image_name"
    log "Base image: $base_image"
    log "Build mode: $build_mode"

    # Build arguments
    build_args=(
        --build-arg "BASE_IMAGE=${base_image}"
        --build-arg "DISTRO_NAME=${distro_name}"
        --build-arg "DISTRO_VERSION=${distro_version}"
        --build-arg "DISTRO_CODENAME=${distro_codename}"
        --build-arg "BUILD_MODE=${build_mode}"
        --build-arg "USER_NAME=${container_user_name}"
        --build-arg "USER_PASSWD=${container_passwd}" 
        --build-arg "HOST_USER_ID=${host_user_id}"
        --build-arg "HOST_GROUP_ID=${host_group_id}"
        -t "$image_name"
        --network host
    )

    # Add proxy arguments if set
    if [ -n "$http_proxy" ]; then
        build_args+=(--build-arg "HTTP_PROXY=$http_proxy")
    fi
    if [ -n "$https_proxy" ]; then
        build_args+=(--build-arg "HTTPS_PROXY=$https_proxy")
    fi

    # Build Docker image
    if docker build "${build_args[@]}" .; then
        log "Docker image built successfully"
    else
        error "Docker build failed"
        exit 1
    fi
}

# Function to run Docker container
run_container() {
    # Generate container name based on configuration
    image_name="dev_${os_version}_${build_mode}_${host_user_name}"
    container_name="dev_${os_version}_${build_mode}_${container_user_name}"
    
    # Check if container with the same name already exists
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        warn "Container '$container_name' already exists."
        
        # In CI environment, automatically remove
        if [ "${CI}" = "true" ]; then
            log "CI environment detected, automatically removing existing container..."
            docker rm -f "$container_name" || { error "Failed to remove container"; exit 1; }
        else
            read -p "Do you want to remove it and create a new one? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log "Removing existing container..."
                docker rm -f "$container_name" || { error "Failed to remove container"; exit 1; }
            else
                warn "Exiting without creating a new container."
                exit 0
            fi
        fi
    fi

    ensure_workspace
    
    log "Running Docker container: $container_name"

    # Container workspace directory
    container_workspace_dir="$workspace_dir/$container_name"

    # Run Docker container with proper arguments
    run_args=(
        -d --privileged
        --cap-add=SYS_PTRACE --security-opt seccomp=unconfined
        --name="$container_name"
        --hostname="$container_name"
        -e "HOST_PERMS=$host_user_id:$host_group_id"
        --label "user=$container_user_name"
        --label "host_user=$host_user_name"
        --label "os_version=$os_version"
        --label "build_mode=$build_mode"
        -v "$container_workspace_dir:/home/$container_user_name/workspace"
    )

    # Add GPU support if nvidia-docker is available
    if command -v nvidia-docker &> /dev/null || docker info 2>/dev/null | grep -q nvidia; then
        run_args+=(--runtime=nvidia --gpus all)
        log "GPU support enabled"
    fi

    # Run the container
    if docker run "${run_args[@]}" "$image_name"; then
        log "Container successfully created and started"
    else
        error "Docker run failed"
        exit 1
    fi

    # Display container information
    log "Container information:"
    docker ps --filter "name=$container_name" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Function to query and display container IP
query_ip() {
    # Generate container name based on configuration
    container_name="dev_${os_version}_${build_mode}_${container_user_name}"
    
    # Check if container exists and is running
    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        error "Container '$container_name' is not running"
        return 1
    fi

    # Get container IP address
    container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name")

    if [ -n "$container_ip" ]; then
        log "Container IP: $container_ip"
        log "SSH command: ssh $container_user_name@$container_ip"
        
        # Log container info for future reference
        echo "$(date): $container_name info: $container_user_name@$container_ip"
    else
        warn "Could not retrieve container IP address"
    fi
}

# Function to stop and remove container
stop_container() {
    # Generate container name based on configuration
    container_name="dev_${os_version}_${build_mode}_${container_user_name}"
    
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        log "Stopping and removing container: $container_name"
        docker rm -f "$container_name"
        log "Container removed successfully"
    else
        warn "Container '$container_name' does not exist"
    fi
}

# Parse command line options
mode="all"
while getopts "o:m:bricslh" opt; do
    case ${opt} in
        o )
            os_version="$OPTARG"
            if [ -z "${OS_CONFIGS[$os_version]}" ]; then
                error "Invalid OS version: $os_version"
                error "Use -l to list available OS versions"
                exit 1
            fi
            ;;
        m )
            build_mode="$OPTARG"
            if [ "$build_mode" != "minimal" ] && [ "$build_mode" != "full" ]; then
                error "Invalid build mode: $build_mode (must be 'minimal' or 'full')"
                exit 1
            fi
            ;;
        b )
            mode="build"
            ;;
        r )
            mode="run"
            ;;
        i )
            mode="ip"
            ;;
        s )
            mode="stop"
            ;;
        c )
            mode="config"
            ;;
        l )
            list_os_versions
            exit 0
            ;;
        h )
            show_usage
            exit 0
            ;;
        \? )
            show_usage
            exit 1
            ;;
    esac
done

# Main execution based on mode
check_docker

case $mode in
    "all")
        show_config
        build_image
        run_container
        query_ip
        ;;
    "build")
        show_config
        build_image
        run_container
        query_ip
        ;;
    "run")
        run_container
        query_ip
        ;;
    "ip")
        query_ip
        ;;
    "stop")
        stop_container
        ;;
    "config")
        show_config
        ;;
esac
