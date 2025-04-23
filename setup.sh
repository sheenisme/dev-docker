#!/bin/bash

# -----------------------------------------------
# Development Docker Environment Setup Script
# -----------------------------------------------

# Exit on any error
set -e

# Configuration variables
host_user_name=guanghuis           # Set for yourself
image_name=dev_image_guanghuis     # Set for yourself
container_user_name=sheen          # Set for yourself
container_name=dev_container_sheen # Set for yourself
container_passwd=sheen123456       # Set for yourself
http_proxy=http://127.0.0.1:7890   # Set if needed
https_proxy=https://127.0.0.1:7890 # Set if needed

# Check if Docker is installed
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
  --runtime=nvidia --gpus all \
  -e HOST_PERMS="$(id -u):$(id -g)" \
  --label user=$container_user_name \
  -v /home/$host_user_name/workspace/$container_name:/home/$container_user_name \
  $image_name || { echo "Error: Docker run failed"; exit 1; }

echo "Container successfully created and started."

# Display container information
echo "Container information:"
docker ps --filter "label=user=$container_user_name"

# Get container IP address
container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_name)

# Display container IP for SSH connection
echo "Container IP: $container_ip"
echo "SSH command: ssh $container_user_name@$container_ip"

# Log container info for future reference
echo "$container_name info: $container_user_name@$container_ip" >> /home/$host_user_name/workspace/container_ip.log
