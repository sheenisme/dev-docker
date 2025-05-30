🚀 **Welcome to the Development Docker Environment project!**  
This repository provides a highly customizable Docker-based development environment with pre-installed tools and convenient scripts.  
**We welcome everyone to contribute, improve, and keep this project up to date together!**

🚀 **欢迎来到开发用 Docker 环境项目！**  
本仓库提供了高度可定制的 Docker 开发环境，内置常用工具和便捷脚本。  
**欢迎大家共同参与、完善和持续更新本项目！**

[🇬🇧 English](README.md) | [🇨🇳 中文](README.zh-CN.md)

---

# 🐳 Development Docker Environment

A customized Docker development environment with pre-installed development tools.

---

## 📦 Prerequisites

- Docker installed and properly configured
- User added to the docker group or root privileges

---

## 🚀 Quick Start

The easiest way to set up the environment is to use the provided setup script:

```shell
# Make the script executable
chmod +x setup.sh

# Run the setup script (default: build image, run container, show IP)
./setup.sh
```

### Script Options

You can use the following options with `setup.sh`:

| Option | Description                                 |
|--------|---------------------------------------------|
| `-b`   | Build image, run container, and show IP     |
| `-r`   | Run container and show IP (skip build)      |
| `-i`   | Show container IP only                      |
| `-s`   | Stop and remove the container               |
| `-c`   | Show current configuration                  |
| `-h`   | Display help message                        |

**Example:**

```shell
./setup.sh -b   # Build and run
./setup.sh -s   # Stop and remove container
```

### Environment Variables

- `HTTP_PROXY` and `HTTPS_PROXY` can be set to configure proxy for build and runtime.

## ⚠️ Note

> **Default container password is `123456`.**  
> You can customize the container username, password, image name, and container name by editing the variables at the top of `setup.sh` before building/running the container.

> **SSH Access via Jump Host (Bastion/Host):**
>
> If your development host is behind a jump host (bastion/"Host"), you can connect to the Docker container in two steps:
>
> 1. **SSH to the jump host (Host)**
> 2. **SSH from the jump host to your Docker container**
>
> To simplify this, you can use an SSH config file (usually at `~/.ssh/config`) like this:
>
> ```ssh-config
> Host my-docker
>     HostName <container_ip>
>     User sheen
>     Port 22
>     ProxyJump my-jump
>
> Host my-jump
>     HostName <jump_host_ip>
>     User <your_jump_host_user>
>     Port 22
> ```
>
> - Replace `<container_ip>` with the IP address of your Docker container (see "SSH Connection" section above).
> - Replace `<jump_host_ip>` and `<your_jump_host_user>` with your jump host's IP and username.
> - After saving, you can connect to the container from your local machine with:
>
> ```shell
> ssh my-docker
> ```
>
> This will automatically connect through the jump host to your Docker container. Make sure your jump host can reach the container's IP, and that the container's SSH port is open.
> 
> **Tip:** If you use a private key for authentication, you can add `IdentityFile ~/.ssh/your_key` under the corresponding `Host` section.

---

## 🏗️ Container Details

- **Default container user:** `sheen`
- **Default password:** `123456`
- **Workspace mount:** Host's `~/workspace/dev_container_sheen` is mounted to `/home/sheen/workspace` in the container.
- **SSH enabled:** Port 22 is exposed for SSH access.
- **GPU support:** Automatically enabled if NVIDIA runtime is available.

---

## 🛠️ Common Commands

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
```

### File Transfer

```shell
# Copy files from host to container
docker cp /path/to/local/file $container_name:/home/$container_user_name/

# Copy files from container to host
docker cp $container_name:/home/$container_user_name/file /path/to/local/
```

---

## 🌐 Proxy Configuration

A helper script is provided for proxy management:

```shell
cd scripts
./set_proxy.sh -s [PROXY_URL]   # Set proxy (use default if not provided)
./set_proxy.sh -u               # Unset proxy
./set_proxy.sh -t               # Test proxy connection
./set_proxy.sh -st              # Show current proxy status
./set_proxy.sh -h               # Show help
```

- The script will also configure proxy for `git`, `npm`, `pip`, and `conda` if available.

---

## 🧩 Troubleshooting

### Common Issues

1. **Docker permission issues**
   - Ensure your user is in the docker group: `sudo usermod -aG docker $USER`
   - Log out and log back in for changes to take effect

2. **Network connectivity issues**
   - If the container can't access the internet, try setting HTTP/HTTPS proxies
   - Use the proxy helper script or set environment variables

3. **Container startup failures**
   - Check container logs: `docker logs $container_name`
   - Verify GPU support is available: `docker info | grep -i runtime`

4. **SSH permission issues**
   - If you encounter permission problems after SSH login:
     1. First login to the container via terminal: `docker exec -it $container_name zsh`
     2. Then use sudo to modify home directory permissions: `sudo chmod -R 777 /home/$container_user_name`

---

## 🎨 Customization

- You can customize the `Dockerfile` to add additional packages or configurations based on your development needs.
- Scripts in the `scripts/` directory can be extended for more automation.

---

## 📚 Reference Links
- [Docker Documentation](https://docs.docker.com/)
- [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker)
- [Reference Repository](https://github.com/zhiqiangzz/docker-dev.git)

---

## 📝 Changelog

- **2025-05-29**: Initial release.
