🚀 **Welcome to the Development Docker Environment project!**  
This repository provides a highly customizable Docker-based development environment with pre-installed tools and convenient scripts.  
**We welcome everyone to contribute, improve, and keep this project up to date together!**

🚀 **欢迎来到开发用 Docker 环境项目！**  
本仓库提供了高度可定制的 Docker 开发环境，内置常用工具和便捷脚本。  
**欢迎大家共同参与、完善和持续更新本项目！**

[🇬🇧 English](README.md) | [🇨🇳 中文](README.zh-CN.md)

---

# 🐳 Development Docker Environment

A customized Docker development environment with pre-installed development tools, designed to be resilient and easy to set up.

**📚 Documentation:**
- [Quick Start Guide](docs/QUICKSTART.md) - Get started in 3 steps
- [Configuration Examples](docs/EXAMPLES.md) - Detailed configuration examples
- [中文文档](README.zh-CN.md) - Chinese documentation

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

# Run the setup script with default settings (Ubuntu 22.04, full mode)
./setup.sh

# Or specify OS version and build mode
./setup.sh -o ubuntu2404 -m full       # Ubuntu 24.04, full mode
./setup.sh -o ubuntu2004 -m minimal    # Ubuntu 20.04, minimal mode
./setup.sh -o centos8 -m full          # CentOS Stream 8, full mode
```

### Build Modes

The project supports two build modes:

- **full** (default): Includes all development tools
  - LLVM/Clang toolchain (version 18)
  - ZSH with Oh My Zsh and plugins
  - Miniconda Python distribution
  - Complete development environment

- **minimal**: Lightweight installation
  - Essential tools only (gcc, git, vim, etc.)
  - Bash shell (no ZSH)
  - No LLVM/Clang
  - No Miniconda
  - Faster build time and smaller image size

### Supported OS Versions

| OS Version | Base Image | Description |
|------------|------------|-------------|
| `ubuntu2004` | Ubuntu 20.04 | Focal Fossa (LTS) |
| `ubuntu2204` | Ubuntu 22.04 | Jammy Jellyfish (LTS) - **Default** |
| `ubuntu2404` | Ubuntu 24.04 | Noble Numbat (LTS) |
| `centos7` | CentOS 7 | CentOS 7 |
| `centos8` | CentOS Stream 8 | CentOS Stream 8 |

### Script Options

You can use the following options with `setup.sh`:

| Option | Description                                 |
|--------|---------------------------------------------|
| `-o OS_VERSION` | Specify OS version (see table above) |
| `-m MODE` | Build mode: `minimal` or `full` (default: full) |
| `-b`   | Build image, run container, and show IP     |
| `-r`   | Run container and show IP (skip build)      |
| `-i`   | Show container IP only                      |
| `-s`   | Stop and remove the container               |
| `-c`   | Show current configuration                  |
| `-l`   | List available OS versions                  |
| `-h`   | Display help message                        |

**Example:**

```shell
# List available OS versions
./setup.sh -l

# Build Ubuntu 24.04 with full mode (default)
./setup.sh -o ubuntu2404 -b

# Build CentOS 8 with minimal mode
./setup.sh -o centos8 -m minimal -b

# Build and run with default settings
./setup.sh

# Stop and remove container
./setup.sh -s
```

### Environment Variables

- `HTTP_PROXY` and `HTTPS_PROXY` can be set to configure proxy for build and runtime.

## ⚠️ Note

> **Default container password is `123456`.**  
> You can customize the container username, password, image name, and container name by editing the variables at the top of `setup.sh` before building/running the container.

> **SSH Access via Jump Host (Bastion Host):**
>
> If your development host is behind a jump host, you can connect to the Docker container in two steps:
>
> 1. **SSH to the jump host**
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
> - Replace `<container_ip>` with the IP address of your Docker container (see "SSH Connection" section below).
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
- **Workspace mount:** Host's `~/workspace/dev_<os_version>_<mode>_<username>` is mounted to `/home/sheen/workspace` in the container
  - Example: `~/workspace/dev_ubuntu2204_full_sheen` for Ubuntu 22.04 in full mode
- **Container naming:** Containers are named based on OS version and build mode
  - Format: `dev_<os_version>_<mode>_<username>`
  - Example: `dev_ubuntu2204_full_sheen`
- **SSH enabled:** Port 22 is exposed for SSH access
- **GPU support:** Automatically enabled if NVIDIA runtime is available
- **Shell:** ZSH (full mode) or Bash (minimal mode)

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
# Get container IP address (using setup script)
./setup.sh -i

# Manual method to get container IP
container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_name)
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

## 🧩 ZSH and Development Tools

### Build Mode Comparison

| Feature | Full Mode | Minimal Mode |
|---------|-----------|--------------|
| Shell | ZSH with Oh My Zsh | Bash |
| LLVM/Clang | ✅ Version 18 | ❌ |
| Python Distribution | Miniconda | System Python 3 |
| Development Tools | Complete set | Essential only (gcc, git, cmake) |
| Image Size | Larger (~2-3GB) | Smaller (~800MB-1GB) |
| Build Time | Longer (~10-15 min) | Faster (~5-8 min) |

### Full Mode Features

The full mode container includes:

#### ZSH Configuration
- **Oh My Zsh:** Pre-installed with useful plugins (if installation succeeds)
- **Fallback Configuration:** Basic ZSH setup works even if Oh My Zsh installation fails
- **Helper Functions:** Manual installation commands available

#### Development Tools
- **LLVM/Clang:** Complete toolchain (version 18) with clangd, lld, lldb
- **Python:** Miniconda distribution with conda package manager
- **Build Tools:** gcc, cmake, ninja, make, autotools
- **Additional Tools:** ripgrep, tmux, jq, and more

### Helper Commands (Full Mode Only)

If Oh My Zsh didn't install (you'll see a message when you log in), you can use these commands:

```shell
# Install Oh My Zsh manually
install_omz

# Install ZSH plugins (after Oh My Zsh is installed)
install_zsh_plugins
```

### Minimal Mode Features

The minimal mode is designed for:
- Quick development environments
- CI/CD pipelines
- Resource-constrained environments
- Basic compilation and testing tasks

Includes:
- Essential build tools (gcc, make, cmake)
- Version control (git)
- Text editors (vim)
- Basic utilities (curl, wget, ssh)

---

## 🧩 Troubleshooting

### Common Issues

1. **Docker permission issues**
   - Ensure your user is in the docker group: `sudo usermod -aG docker $USER`
   - Log out and log back in for changes to take effect

2. **Network connectivity issues**
   - If the container can't access the internet, try setting HTTP/HTTPS proxies
   - Use the proxy helper script or set environment variables
   - Oh My Zsh and plugins may not install if there's no internet connection, but the container will still work

3. **Container startup failures**
   - Check container logs: `docker logs $container_name`
   - Verify GPU support if attempting to use it: `docker info | grep -i runtime`

4. **SSH permission issues**
   - If you encounter permission problems after SSH login:
     1. First login to the container via terminal: `docker exec -it $container_name zsh`
     2. Then use sudo to modify home directory permissions: `sudo chmod -R 700 /home/$container_user_name/.ssh`

5. **ZSH configuration issues**
   - If Oh My Zsh didn't install properly, use the `install_omz` helper function
   - If plugins aren't working, use the `install_zsh_plugins` function
   - Make sure to restart your shell after installing plugins

---

## 🎨 Customization

- You can customize the `Dockerfile` to add additional packages or configurations based on your development needs.
- Scripts in the `scripts/` directory can be extended for more automation.

---

## 📚 Reference Links
- [Docker Documentation](https://docs.docker.com/)
- [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker)
- [Oh My Zsh](https://ohmyz.sh/)
- [Reference Repository](https://github.com/zhiqiangzz/docker-dev.git)

---

## 📝 Changelog

- **2026-01-29**: (V0.2.0) Added multi-OS support and build modes
  - Support for Ubuntu 20.04, 22.04, 24.04
  - Support for CentOS 7, Stream 8
  - Two build modes: minimal and full
  - Flexible configuration via command-line options
- **2025-05-30**: (V0.1.1) Fixed workspace mounting and added resilient ZSH configuration
- **2025-05-29**: (V0.1.0) Initial release
