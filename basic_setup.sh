host_user_name=guanghuis
image_name=dev_image_guanghui
container_user_name=sheen
container_name=dev_container
container_passwd=sheen123456
http_proxy=http://127.0.0.1:7890
https_proxy=https://127.0.0.1:7890

# if meet network problem, please add the following two lines
    # --build-arg HTTP_PROXY=$http_proxy \
    # --build-arg HTTPS_PROXY=$https_proxy \

# Build Docker image
docker build \
    --build-arg USER_NAME=${container_user_name} \
    --build-arg USER_PASSWD=${container_passwd} \
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

