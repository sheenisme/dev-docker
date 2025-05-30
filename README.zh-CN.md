🚀 **Welcome to the Development Docker Environment project!**  
This repository provides a highly customizable Docker-based development environment with pre-installed tools and convenient scripts.  
**We welcome everyone to contribute, improve, and keep this project up to date together!**

🚀 **欢迎来到开发用 Docker 环境项目！**  
本仓库提供了高度可定制的 Docker 开发环境，内置常用工具和便捷脚本。  
**欢迎大家共同参与、完善和持续更新本项目！**

[🇬🇧 English](README.md) | [🇨🇳 中文](README.zh-CN.md)

---

# 🐳 开发用 Docker 环境

一个定制化的 Docker 开发环境，预装了常用开发工具。

---

## 📦 前置条件

- 已正确安装并配置 Docker
- 当前用户已加入 docker 用户组或具备 root 权限

---

## 🚀 快速开始

最简单的方式是使用提供的 setup 脚本：

```shell
# 赋予脚本可执行权限
chmod +x setup.sh

# 运行脚本（默认：构建镜像、启动容器并显示 IP）
./setup.sh
```

### 脚本参数说明

你可以使用如下参数运行 `setup.sh`：

| 参数 | 说明                           |
|------|--------------------------------|
| `-b` | 构建镜像、启动容器并显示 IP    |
| `-r` | 仅启动容器并显示 IP（跳过构建）|
| `-i` | 仅显示容器 IP                  |
| `-s` | 停止并删除容器                 |
| `-c` | 显示当前配置信息               |
| `-h` | 显示帮助信息                   |

**示例：**

```shell
./setup.sh -b   # 构建并启动
./setup.sh -s   # 停止并删除容器
```

### 环境变量

- 可通过设置 `HTTP_PROXY` 和 `HTTPS_PROXY` 环境变量为构建和运行配置代理。

## ⚠️ 注意

> **默认容器用户密码为 `123456`。**  
> 你可以在构建/运行容器前，编辑 `setup.sh` 顶部的变量，自定义容器用户名、密码、镜像名、容器名等参数。

> **通过跳板机（宿主机）SSH 访问 Docker 容器：**
>
> 如果你的开发主机在跳板机（也叫 bastion/宿主机）之后，可以分两步连接到 Docker 容器：
>
> 1. **先 SSH 到跳板机（宿主机）**
> 2. **再从跳板机 SSH 到你的 Docker 容器**
>
> 推荐在本地 `~/.ssh/config` 文件中添加如下配置，简化操作：
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
> - `<container_ip>` 替换为你的 Docker 容器 IP（见上文“SSH 连接”部分获取）。
> - `<jump_host_ip>` 和 `<your_jump_host_user>` 替换为跳板机的 IP 和用户名。
> - 保存后，你可以直接在本地终端输入：
>
> ```shell
> ssh my-docker
> ```
>
> 这样会自动通过跳板机转发连接到 Docker 容器。请确保跳板机能访问容器 IP，且容器 22 端口已开放。
>
> **小贴士：** 如果你用密钥认证，可以在对应 `Host` 下加一行 `IdentityFile ~/.ssh/your_key`。

---

## 🏗️ 容器细节

- **默认容器用户：** `sheen`
- **默认密码：** `sheen123456`
- **工作区挂载：** 宿主机 `~/workspace/dev_container_sheen` 挂载到容器 `/home/sheen/workspace`
- **SSH 支持：** 容器暴露 22 端口，可通过 SSH 访问
- **GPU 支持：** 如检测到 NVIDIA runtime 自动启用 GPU

---

## 🛠️ 常用命令

### 容器管理

```shell
# 列出当前用户的所有容器
docker ps --filter "label=user=$container_user_name"

# 启动已停止的容器
docker start $container_name

# 停止正在运行的容器
docker stop $container_name

# 进入容器 shell
docker exec -it $container_name zsh

# 查看容器日志
docker logs $container_name

# 删除容器（不再需要时）
docker rm -f $container_name
```

### SSH 连接

```shell
# 获取容器 IP 地址
container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_name)

# 显示 SSH 连接命令
echo "Container IP: $container_ip"
echo "SSH command: ssh $container_user_name@$container_ip"
```

### 文件传输

```shell
# 从主机复制文件到容器
docker cp /path/to/local/file $container_name:/home/$container_user_name/

# 从容器复制文件到主机
docker cp $container_name:/home/$container_user_name/file /path/to/local/
```

---

## 🌐 代理配置

项目提供了代理管理脚本：

```shell
cd scripts
./set_proxy.sh -s [PROXY_URL]   # 设置代理（不指定则用默认）
./set_proxy.sh -u               # 取消代理
./set_proxy.sh -t               # 测试代理连通性
./set_proxy.sh -st              # 显示当前代理状态
./set_proxy.sh -h               # 显示帮助
```

- 脚本会自动为 `git`、`npm`、`pip`、`conda` 配置代理（如已安装）。

---

## 🧩 常见问题排查

### 常见问题

1. **Docker 权限问题**
   - 确保当前用户已加入 docker 组：`sudo usermod -aG docker $USER`
   - 注销并重新登录以生效

2. **网络连接问题**
   - 容器无法联网时，请尝试设置 HTTP/HTTPS 代理
   - 可用代理脚本或直接设置环境变量

3. **容器启动失败**
   - 查看容器日志：`docker logs $container_name`
   - 检查 GPU 支持：`docker info | grep -i runtime`

4. **SSH 权限问题**
   - SSH 登录后如遇权限问题：
     1. 先通过终端进入容器：`docker exec -it $container_name zsh`
     2. 用 sudo 修改 home 目录权限：`sudo chmod -R 777 /home/$container_user_name`

---

## 🎨 个性化定制

- 你可以根据开发需求自定义 `Dockerfile`，添加额外软件包或配置。
- `scripts/` 目录下的脚本可扩展自动化流程。

---

## 📚 参考链接
- [Docker 官方文档](https://docs.docker.com/)
- [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker)
- [参考仓库](https://github.com/zhiqiangzz/docker-dev.git)

---

## 📝 更新日志

- **2025-05-29**：首次发布。