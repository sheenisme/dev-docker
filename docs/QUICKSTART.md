# 快速入门指南 (Quick Start Guide)

[🇬🇧 English](#english) | [🇨🇳 中文](#中文)

---

## English

### Prerequisites
- Docker installed and running
- User in docker group or root access

### Quick Start (3 Steps)

#### 1. Clone and Navigate
```bash
git clone <your-repo-url>
cd dev-docker
chmod +x setup.sh
```

#### 2. Build and Run (Choose One)

**Default (Ubuntu 22.04, Full Mode - Recommended)**
```bash
./setup.sh
```

**Ubuntu 24.04, Full Mode**
```bash
./setup.sh -o ubuntu2404 -m full
```

**Ubuntu 22.04, Minimal Mode (Faster)**
```bash
./setup.sh -o ubuntu2204 -m minimal
```

**CentOS 8, Full Mode**
```bash
./setup.sh -o centos8 -m full
```

#### 3. Connect via SSH
```bash
# The script will show you the IP and SSH command
# Example output:
# Container IP: 172.17.0.2
# SSH command: ssh sheen@172.17.0.2
# Default password: 123456
```

### What's the Difference?

| Feature | Full Mode | Minimal Mode |
|---------|-----------|--------------|
| **Shell** | ZSH + Oh My Zsh | Bash |
| **LLVM/Clang** | ✅ v18 | ❌ |
| **Python** | Miniconda | System Python3 |
| **Build Time** | ~10-15 min | ~5-8 min |
| **Image Size** | ~2-3 GB | ~800 MB |
| **Use Case** | Full development | Quick dev/CI |

### Common Commands

```bash
# List available OS versions
./setup.sh -l

# Show current config
./setup.sh -c

# Stop and remove container
./setup.sh -s

# Get container IP only
./setup.sh -i

# Run existing container (no rebuild)
./setup.sh -r
```

### Need Help?
```bash
./setup.sh -h
```

---

## 中文

### 前置条件
- 已安装并运行 Docker
- 用户在 docker 组或具有 root 权限

### 快速开始（3 步）

#### 1. 克隆并进入目录
```bash
git clone <your-repo-url>
cd dev-docker
chmod +x setup.sh
```

#### 2. 构建并运行（选择一个）

**默认配置（Ubuntu 22.04，完整模式 - 推荐）**
```bash
./setup.sh
```

**Ubuntu 24.04，完整模式**
```bash
./setup.sh -o ubuntu2404 -m full
```

**Ubuntu 22.04，精简模式（更快）**
```bash
./setup.sh -o ubuntu2204 -m minimal
```

**CentOS 8，完整模式**
```bash
./setup.sh -o centos8 -m full
```

#### 3. 通过 SSH 连接
```bash
# 脚本会显示 IP 和 SSH 命令
# 示例输出：
# Container IP: 172.17.0.2
# SSH command: ssh sheen@172.17.0.2
# 默认密码：123456
```

### 有什么区别？

| 功能 | 完整模式 | 精简模式 |
|------|----------|----------|
| **Shell** | ZSH + Oh My Zsh | Bash |
| **LLVM/Clang** | ✅ v18 版本 | ❌ |
| **Python** | Miniconda | 系统 Python3 |
| **构建时间** | ~10-15 分钟 | ~5-8 分钟 |
| **镜像大小** | ~2-3 GB | ~800 MB |
| **使用场景** | 完整开发 | 快速开发/CI |

### 常用命令

```bash
# 列出可用的操作系统版本
./setup.sh -l

# 显示当前配置
./setup.sh -c

# 停止并删除容器
./setup.sh -s

# 仅获取容器 IP
./setup.sh -i

# 运行已存在的容器（不重新构建）
./setup.sh -r
```

### 需要帮助？
```bash
./setup.sh -h
```

---

## Troubleshooting / 故障排除

### Permission Denied
```bash
sudo usermod -aG docker $USER
# Then logout and login again
```

### Container Already Exists
```bash
# Remove old container first
./setup.sh -s
# Then build again
./setup.sh -b
```

### Network Issues
```bash
# Set proxy if needed
export HTTP_PROXY="http://proxy:8080"
export HTTPS_PROXY="http://proxy:8080"
./setup.sh
```

---

For detailed documentation, see:
- [README.md](README.md) - Full documentation
- [EXAMPLES.md](EXAMPLES.md) - More examples
- [README.zh-CN.md](README.zh-CN.md) - 完整中文文档
