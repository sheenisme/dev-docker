#!/bin/bash

# -----------------------------------------------
# Development Docker Environment Setup Script
# -----------------------------------------------

# Exit on any error
set -e

# Auto-detect configuration variables
host_user_name=$(whoami)                           # Auto-detect current user
host_user_id=$(id -u)                             # Get current user ID
host_group_id=$(id -g)                            # Get current user group ID
host_home_dir=$(eval echo ~$host_user_name)       # Get home directory
workspace_dir="$host_home_dir/workspace"          # Workspace directory

# Derived configuration
image_name="dev_image_${host_user_name}"           # Image name based on host user
container_user_name="sheen"                       # Container user name
container_name="dev_container_${container_user_name}"  # Container name based on host user
container_passwd="sheen123456"                     # Container user password

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
    echo "Usage: $0 [OPTION]"
    echo "Options:"
    echo "  -b    Build image, run container, and query IP"
    echo "  -r    Run container and query IP (skip build)"
    echo "  -i    Query and print container IP only"
    echo "  -s    Stop and remove container"
    echo "  -c    Show current configuration"
    echo "  -h    Display this help message"
    echo "  No option will execute all operations (default)"
    echo ""
    echo "Environment variables:"
    echo "  HTTP_PROXY   - HTTP proxy URL (optional)"
    echo "  HTTPS_PROXY  - HTTPS proxy URL (optional)"
}

# Function to show current configuration
show_config() {
    log "Current Configuration:"
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
    log "Building Docker image: $image_name"

    # Build arguments
    build_args=(
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
    docker ps --filter "label=host_user=$host_user_name" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Function to query and display container IP
query_ip() {
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
while getopts "bricsh" opt; do
    case ${opt} in
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
