# dev-docker 配置示例

## 快速开始示例

### 1. 默认配置（推荐）
```bash
# Ubuntu 22.04 + 完整模式
./setup.sh
```

### 2. 不同操作系统版本

#### Ubuntu 20.04（精简模式）
```bash
./setup.sh -o ubuntu2004 -m minimal -b
```

#### Ubuntu 24.04（完整模式）
```bash
./setup.sh -o ubuntu2404 -m full -b
```

#### CentOS 7（完整模式）
```bash
./setup.sh -o centos7 -m full -b
```

#### CentOS Stream 8（精简模式）
```bash
./setup.sh -o centos8 -m minimal -b
```

### 3. 构建模式对比

#### 完整模式（full）- 适合完整开发
```bash
./setup.sh -m full -b
```
- 包含 LLVM/Clang 18
- ZSH + Oh My Zsh
- Miniconda
- 所有开发工具
- 镜像大小：~2-3GB
- 构建时间：~10-15分钟

#### 精简模式（minimal）- 适合快速开发/CI
```bash
./setup.sh -m minimal -b
```
- 基础开发工具（gcc、git、cmake）
- Bash shell
- 无 LLVM/Clang
- 无 Miniconda
- 镜像大小：~800MB-1GB
- 构建时间：~5-8分钟

### 4. 常用操作

```bash
# 列出可用的 OS 版本
./setup.sh -l

# 查看当前配置
./setup.sh -c

# 仅运行容器（不重新构建）
./setup.sh -r

# 查询容器 IP
./setup.sh -i

# 停止并删除容器
./setup.sh -s
```

### 5. 代理配置

```bash
# 构建时使用代理
export HTTP_PROXY="http://proxy.example.com:8080"
export HTTPS_PROXY="http://proxy.example.com:8080"
./setup.sh -b

# 或者在容器内配置代理
docker exec -it dev_ubuntu2204_full_sheen bash
cd ~/scripts
./set_proxy.sh -s http://proxy.example.com:8080
```

### 6. 多容器管理

你可以同时运行不同配置的容器：

```bash
# 构建 Ubuntu 22.04 完整模式
./setup.sh -o ubuntu2204 -m full -b
# 容器名: dev_ubuntu2204_full_sheen

# 构建 Ubuntu 22.04 精简模式
./setup.sh -o ubuntu2204 -m minimal -b
# 容器名: dev_ubuntu2204_minimal_sheen

# 构建 CentOS 8 完整模式
./setup.sh -o centos8 -m full -b
# 容器名: dev_centos8_full_sheen
```

每个配置会创建独立的镜像和容器，互不冲突。

### 7. 工作区目录结构

```
~/workspace/
├── dev_ubuntu2204_full_sheen/      # Ubuntu 22.04 完整模式工作区
├── dev_ubuntu2204_minimal_sheen/   # Ubuntu 22.04 精简模式工作区
├── dev_ubuntu2404_full_sheen/      # Ubuntu 24.04 完整模式工作区
└── dev_centos8_full_sheen/         # CentOS 8 完整模式工作区
```

### 8. 实际应用场景

#### 场景 1：C++ 开发（推荐完整模式）
```bash
./setup.sh -o ubuntu2204 -m full -b
# 使用 LLVM/Clang 进行现代 C++ 开发
```

#### 场景 2：Python 数据科学（推荐完整模式）
```bash
./setup.sh -o ubuntu2404 -m full -b
# 使用 Miniconda 管理 Python 环境
```

#### 场景 3：CI/CD 流水线（推荐精简模式）
```bash
./setup.sh -o ubuntu2204 -m minimal -b
# 快速构建，体积小，适合 CI/CD
```

#### 场景 4：传统企业环境（CentOS）
```bash
./setup.sh -o centos7 -m full -b
# 兼容企业级 CentOS 环境
```

### 9. SSH 连接

```bash
# 获取容器 IP
./setup.sh -i

# SSH 连接（输出会显示具体命令）
ssh sheen@<container_ip>
# 默认密码：123456
```

### 10. 自定义配置

编辑 `setup.sh` 顶部的变量：

```bash
# 修改容器用户名
container_user_name="your_username"

# 修改密码
container_passwd="your_secure_password"

# 修改工作区目录
workspace_dir="/path/to/your/workspace"
```

## 支持的操作系统版本详情

| OS 版本 | 支持的构建模式 | 特殊说明 |
|---------|---------------|---------|
| ubuntu2004 | minimal, full | LTS 长期支持 |
| ubuntu2204 | minimal, full | 默认版本，LTS |
| ubuntu2404 | minimal, full | 最新 LTS |
| centos7 | minimal, full | 企业级稳定版 |
| centos8 | minimal, full | CentOS Stream |

## 注意事项

1. **精简模式限制**：
   - 不支持 LLVM/Clang
   - 不支持 ZSH（使用 Bash）
   - 不包含 Miniconda

2. **CentOS 特殊说明**：
   - CentOS 7 使用 CentOS 官方源
   - CentOS 8 使用 CentOS Stream 8
   - 某些包名可能与 Ubuntu 不同

3. **镜像和容器命名**：
   - 镜像名：`dev_<os_version>_<mode>_<host_user>`
   - 容器名：`dev_<os_version>_<mode>_<container_user>`

4. **多版本共存**：
   - 不同配置的容器可以同时运行
   - 每个容器有独立的工作区目录
   - 注意不要混淆不同容器的配置
