# Development Docker Environment

A customized Docker development environment, and development tools pre-installed.

## Prerequisites

- Docker installed and properly configured
- User added to the docker group or root privileges

## Quick Start

The easiest way to set up the environment is to use the provided setup script:

```shell
# Make the script executable
chmod +x setup.sh

# Run the setup script
./setup.sh
```

## Manual Setup

If you prefer to set up manually or customize the parameters:

```shell
# Set build and run parameters
host_user_name=guanghuis           # Set for yourself
image_name=dev_image_guanghuis     # Set for yourself
container_user_name=sheen          # Set for yourself
container_name=dev_container_sheen # Set for yourself
container_passwd=sheen123456       # Set for yourself
http_proxy=http://127.0.0.1:7890   # Set if needed
https_proxy=https://127.0.0.1:7890 # Set if needed

# Build Docker image
docker build \
    --build-arg USER_NAME=$container_user_name \
    --build-arg USER_PASSWD=$container_passwd \
    -t $image_name \
    --network host \
    .

# Run Docker container
docker run \
  -d --privileged \
  --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
  --name=$container_name \
  --runtime=nvidia --gpus all \
  -e HOST_PERMS="$(id -u):$(id -g)" \
  --label user=$container_user_name \
  -v /home/$host_user_name/workspace/$container_name:/home/$container_user_name \
  $image_name
```

## Common Commands

### Container Management

```shell
# List all containers for current user
docker ps --filter "label=user=$container_user_name"

# Start a stopped container
docker start $container_name

# Stop a running container
docker stop $container_name

# Enter container shell
docker exec -it $container_name zsh

# View container logs
docker logs $container_name

# Remove container (when no longer needed)
docker rm -f $container_name
```

### SSH Connection

```shell
# Get container IP address
container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_name)

# Display container IP for SSH connection
echo "Container IP: $container_ip"
echo "SSH command: ssh $container_user_name@$container_ip"

# Log container IP for future reference
echo "$container_user_name@$container_ip" >> /home/$host_user_name/workspace/container_ip.log
```

### File Transfer

```shell
# Copy files from host to container
docker cp /path/to/local/file $container_name:/home/$container_user_name/

# Copy files from container to host
docker cp $container_name:/home/$container_user_name/file /path/to/local/
```

## Troubleshooting

### Common Issues

1. **Docker permission issues**
   - Ensure your user is in the docker group: `sudo usermod -aG docker $USER`
   - Log out and log back in for changes to take effect

2. **Network connectivity issues**
   - If container can't access the internet, try setting HTTP/HTTPS proxies
   - Uncomment the proxy arguments in the build command

3. **Container startup failures**
   - Check container logs: `docker logs $container_name`
   - Verify GPU support is available: `docker info | grep -i runtime`

4. **SSH permission issues**
   - If you encounter permission problems after SSH login:
     1. First login to the container via terminal: `docker exec -it $container_name zsh`
     2. Then use sudo to modify home directory permissions: `sudo chmod -R 777 /home/$container_user_name`

## Customization

You can customize the Dockerfile to add additional packages or configurations based on your development needs.

## Reference Links
- [Docker Documentation](https://docs.docker.com/)
- [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker)
- [Reference Original Repository: https://github.com/zhiqiangzz/docker-dev.git](https://github.com/zhiqiangzz/docker-dev.git)
