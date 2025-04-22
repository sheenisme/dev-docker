# my_dev_docker

## Build and Run

```shell
# Set build and run parameters
host_user_name=guanghuis
image_name=dev_image_guanghui
container_user_name=sheen
container_name=dev_container
container_passwd=sheen123456
http_proxy=
https_proxy=

# if meet network problem, please add the following two lines
    # --build-arg HTTP_PROXY=$http_proxy \
    # --build-arg HTTPS_PROXY=$https_proxy \
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
# Filter containers by username
docker ps --filter "label=user=$container_user_name"

# Start a stopped container
docker start $container_name

# Stop a running container
docker stop $container_name

# Enter container shell
docker exec -it $container_name zsh
```

### SSH Connection

```shell
# Get container IP address
container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_name)

# SSH connect to container
# ssh $container_user_name@$container_ip
echo $container_user_name@$container_ip >> /home/$host_user_name/workspace/container_ip.log
```

### File Transfer

```shell
# Copy files from host to container
docker cp /path/to/local/file $container_name:/home/$container_user_name/

# Copy files from container to host
docker cp $container_name:/home/$container_user_name/file /path/to/local/
```

## Reference Links
https://github.com/zhiqiangzz/docker-dev.git
