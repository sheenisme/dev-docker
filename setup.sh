#!/bin/bash

# -----------------------------------------------
# Development Docker Environment Setup Script
# -----------------------------------------------

# Exit on any error
set -e

# Configuration variables
host_user_name=$(whoami)                              # Set for yourself
image_name="dev_image_${host_user_name}"              # Set for yourself
container_user_name=sheen                             # Set for yourself
container_name="dev_container_${container_user_name}" # Set for yourself
container_passwd=123456                               # Set for yourself
http_proxy=http://127.0.0.1:7890                      # Set if needed
https_proxy=https://127.0.0.1:7890                    # Set if needed

# Function to display usage information
show_usage() {
    echo "Usage: $0 [OPTION]"
    echo "Options:"
    echo "  -b    Build image, run container, and query IP"
    echo "  -r    Run container and query IP (skip build)"
    echo "  -i    Query and print container IP only"
    echo "  -h    Display this help message"
    echo "  No option will execute all operations (default)"
}

# Function to check Docker installation
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Error: Docker is not installed. Please install Docker first."
        exit 1
    fi

    # Check if user is in docker group or is root
    if ! (groups | grep -q docker) && [ "$(id -u)" -ne 0 ]; then
        echo "Error: Current user is not in the docker group and not root."
        echo "Please run 'sudo usermod -aG docker $USER' and log out and back in."
        exit 1
    fi
}

# Function to build Docker image
build_image() {
    echo "Building Docker image: $image_name"

    # Optional: If you need to use HTTP/HTTPS proxy inside the container
    # Uncomment the following lines in the docker build command:
    #   --build-arg HTTP_PROXY=$http_proxy \
    #   --build-arg HTTPS_PROXY=$https_proxy \

    # Build Docker image
    docker build \
        --build-arg USER_NAME=${container_user_name} \
        --build-arg USER_PASSWD=${container_passwd} \
        -t $image_name \
        --network host \
        . || { echo "Error: Docker build failed"; exit 1; }
}

# Function to run Docker container
run_container() {
    # Check if container with the same name already exists
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo "Warning: Container '$container_name' already exists."
        read -p "Do you want to remove it and create a new one? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Removing existing container..."
            docker rm -f $container_name || { echo "Error: Failed to remove container"; exit 1; }
        else
            echo "Exiting without creating a new container."
            exit 0
        fi
    fi

    echo "Running Docker container: $container_name"

    # Run Docker container
    docker run \
      -d --privileged \
      --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
      --name=$container_name \
      -e HOST_PERMS="$(id -u):$(id -g)" \
      --label user=$container_user_name \
      -v /home/$host_user_name/workspace/$container_name:/home/$container_user_name \
      $image_name || { echo "Error: Docker run failed"; exit 1; }

    echo "Container successfully created and started."

    # Display container information
    echo "Container information:"
    docker ps --filter "label=user=$container_user_name"
}

# Function to query and display container IP
query_ip() {
    # Get container IP address
    container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_name)

    # Display container IP for SSH connection
    echo "Container IP: $container_ip"
    echo "SSH command: ssh $container_user_name@$container_ip"

    # Log container info for future reference
    echo "$container_name info: $container_user_name@$container_ip"
}

# Parse command line options
mode="all"
while getopts "brip:h" opt; do
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
        build_image
        run_container
        query_ip
        ;;
    "build")
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
esac
