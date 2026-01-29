# dev-docker 配置示例 / Configuration Examples

## 快速开始示例 / Quick Start Examples

### 1. 默认配置（推荐） / Default Configuration (Recommended)
```bash
# Ubuntu 22.04 + 完整模式 / Ubuntu 22.04 + Full mode
./setup.sh
```

### 2. 不同操作系统版本 / Different OS Versions

#### Ubuntu 20.04（精简模式） / Ubuntu 20.04 (Minimal)
```bash
./setup.sh -o ubuntu2004 -m minimal -b
```

#### Ubuntu 24.04（完整模式） / Ubuntu 24.04 (Full)
```bash
./setup.sh -o ubuntu2404 -m full -b
```

#### CentOS 7（完整模式） / CentOS 7 (Full)
```bash
./setup.sh -o centos7 -m full -b
```

#### CentOS Stream 8（精简模式） / CentOS Stream 8 (Minimal)
```bash
./setup.sh -o centos8 -m minimal -b
```

### 3. 构建模式对比 / Build Mode Comparison

#### 完整模式（full）- 适合完整开发 / Full Mode - For Complete Development
```bash
./setup.sh -m full -b
```
- 包含 LLVM/Clang 18 / Includes LLVM/Clang 18
- ZSH + Oh My Zsh
- Miniconda
- 所有开发工具 / All development tools
- 镜像大小：~2-3GB / Image size: ~2-3GB
- 构建时间：~10-15分钟 / Build time: ~10-15 minutes

#### 精简模式（minimal）- 适合快速开发/CI / Minimal Mode - For Quick Development/CI
```bash
./setup.sh -m minimal -b
```
- 基础开发工具（gcc、git、cmake） / Basic dev tools (gcc, git, cmake)
- Bash shell
- 无 LLVM/Clang / No LLVM/Clang
- 无 Miniconda / No Miniconda
- 镜像大小：~800MB-1GB / Image size: ~800MB-1GB
- 构建时间：~5-8分钟 / Build time: ~5-8 minutes

### 4. 常用操作 / Common Operations

```bash
# 列出可用的 OS 版本 / List available OS versions
./setup.sh -l

# 查看当前配置 / View current configuration
./setup.sh -c

# 仅运行容器（不重新构建） / Run container only (without rebuilding)
./setup.sh -r

# 查询容器 IP / Query container IP
./setup.sh -i

# 停止并删除容器 / Stop and remove container
./setup.sh -s
```

### 5. 代理配置 / Proxy Configuration

```bash
# 构建时使用代理 / Use proxy during build
export HTTP_PROXY="http://proxy.example.com:8080"
export HTTPS_PROXY="http://proxy.example.com:8080"
./setup.sh -b

# 或者在容器内配置代理 / Or configure proxy inside container
docker exec -it dev_ubuntu2204_full_sheen bash
cd ~/scripts
./set_proxy.sh -s http://proxy.example.com:8080
```

### 6. 多容器管理 / Multi-Container Management

你可以同时运行不同配置的容器： / You can run containers with different configurations simultaneously:

```bash
# 构建 Ubuntu 22.04 完整模式 / Build Ubuntu 22.04 full mode
./setup.sh -o ubuntu2204 -m full -b
# 容器名 / Container name: dev_ubuntu2204_full_sheen

# 构建 Ubuntu 22.04 精简模式 / Build Ubuntu 22.04 minimal mode
./setup.sh -o ubuntu2204 -m minimal -b
# 容器名 / Container name: dev_ubuntu2204_minimal_sheen

# 构建 CentOS 8 完整模式 / Build CentOS 8 full mode
./setup.sh -o centos8 -m full -b
# 容器名 / Container name: dev_centos8_full_sheen
```

每个配置会创建独立的镜像和容器,互不冲突。 / Each configuration creates independent images and containers without conflicts.

### 7. 工作区目录结构 / Workspace Directory Structure

```
~/workspace/
├── dev_ubuntu2204_full_sheen/      # Ubuntu 22.04 完整模式工作区 / Full mode workspace
├── dev_ubuntu2204_minimal_sheen/   # Ubuntu 22.04 精简模式工作区 / Minimal mode workspace
├── dev_ubuntu2404_full_sheen/      # Ubuntu 24.04 完整模式工作区 / Full mode workspace
└── dev_centos8_full_sheen/         # CentOS 8 完整模式工作区 / Full mode workspace
```

### 8. 实际应用场景 / Real-World Use Cases

#### 场景 1：C++ 开发（推荐完整模式） / Scenario 1: C++ Development (Full Mode Recommended)
```bash
./setup.sh -o ubuntu2204 -m full -b
# 使用 LLVM/Clang 进行现代 C++ 开发 / Use LLVM/Clang for modern C++ development
```

#### 场景 2：Python 数据科学（推荐完整模式） / Scenario 2: Python Data Science (Full Mode Recommended)
```bash
./setup.sh -o ubuntu2404 -m full -b
# 使用 Miniconda 管理 Python 环境 / Use Miniconda to manage Python environments
```

#### 场景 3：CI/CD 流水线（推荐精简模式） / Scenario 3: CI/CD Pipeline (Minimal Mode Recommended)
```bash
./setup.sh -o ubuntu2204 -m minimal -b
# 快速构建，体积小，适合 CI/CD / Fast build, small size, suitable for CI/CD
```

#### 场景 4：传统企业环境（CentOS） / Scenario 4: Traditional Enterprise Environment (CentOS)
```bash
./setup.sh -o centos7 -m full -b
# 兼容企业级 CentOS 环境 / Compatible with enterprise CentOS environments
```

### 9. SSH 连接 / SSH Connection

```bash
# 获取容器 IP / Get container IP
./setup.sh -i

# SSH 连接（输出会显示具体命令） / SSH connection (output will show the exact command)
ssh sheen@<container_ip>
# 默认密码 / Default password：123456
```

### 10. 自定义配置 / Customization

编辑 `setup.sh` 顶部的变量： / Edit variables at the top of `setup.sh`:

```bash
# 修改容器用户名 / Change container username
container_user_name="your_username"

# 修改密码 / Change password
container_passwd="your_secure_password"

# 修改工作区目录 / Change workspace directory
workspace_dir="/path/to/your/workspace"
```

## 支持的操作系统版本详情 / Supported OS Version Details

| OS 版本 / OS Version | 支持的构建模式 / Supported Build Modes | 特殊说明 / Notes |
|---------|---------------|---------|
| ubuntu2004 | minimal, full | LTS 长期支持 / LTS long-term support |
| ubuntu2204 | minimal, full | 默认版本，LTS / Default version, LTS |
| ubuntu2404 | minimal, full | 最新 LTS / Latest LTS |
| centos7 | minimal, full | 企业级稳定版 / Enterprise stable version |
| centos8 | minimal, full | CentOS Stream |

## 注意事项 / Important Notes

1. **精简模式限制 / Minimal Mode Limitations**：
   - 不支持 LLVM/Clang / No LLVM/Clang support
   - 不支持 ZSH（使用 Bash） / No ZSH support (uses Bash)
   - 不包含 Miniconda / Does not include Miniconda

2. **CentOS 特殊说明 / CentOS Special Notes**：
   - CentOS 7 使用 CentOS 官方源 / CentOS 7 uses CentOS official sources
   - CentOS 8 使用 CentOS Stream 8 / CentOS 8 uses CentOS Stream 8
   - 某些包名可能与 Ubuntu 不同 / Some package names may differ from Ubuntu

3. **镜像和容器命名 / Image and Container Naming**：
   - 镜像名 / Image name：`dev_<os_version>_<mode>_<host_user>`
   - 容器名 / Container name：`dev_<os_version>_<mode>_<container_user>`

4. **多版本共存 / Multi-Version Coexistence**：
   - 不同配置的容器可以同时运行 / Containers with different configurations can run simultaneously
   - 每个容器有独立的工作区目录 / Each container has its own workspace directory
   - 注意不要混淆不同容器的配置 / Be careful not to confuse configurations of different containers
