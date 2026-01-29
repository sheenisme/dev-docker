ARG BASE_IMAGE=ubuntu:22.04
FROM ${BASE_IMAGE}

# User configuration
ARG USER_NAME=sheen      # Default username if not provided
ARG USER_PASSWD          # Password for the user (required)
ARG HOST_USER_ID=1000    # Host user ID for proper permissions
ARG HOST_GROUP_ID=1000   # Host group ID for proper permissions
ARG BUILD_MODE=full      # Build mode: minimal or full
RUN test -n "${USER_PASSWD}" || { echo "USER_PASSWD not set"; exit 1; }

# Environment variables for distribution information
ARG DISTRO_NAME=ubuntu
ARG DISTRO_VERSION=22.04
ARG DISTRO_CODENAME=jammy
ENV container=docker
ENV distro=${DISTRO_NAME}${DISTRO_VERSION}
ENV distro_codename=${DISTRO_CODENAME}
ENV DEBIAN_FRONTEND=noninteractive

# Configure package manager sources based on distribution
RUN if [ "${DISTRO_NAME}" = "ubuntu" ]; then \
    # Use Tsinghua mirror
    sed -i 's@http://archive.ubuntu.com/@http://mirrors.tuna.tsinghua.edu.cn/@g' /etc/apt/sources.list || \
    sed -i 's@http://archive.ubuntu.com/@http://mirrors.tuna.tsinghua.edu.cn/@g' /etc/apt/sources.list.d/ubuntu.sources; \
    sed -i 's@http://security.ubuntu.com/@http://mirrors.tuna.tsinghua.edu.cn/@g' /etc/apt/sources.list || \
    sed -i 's@http://security.ubuntu.com/@http://mirrors.tuna.tsinghua.edu.cn/@g' /etc/apt/sources.list.d/ubuntu.sources; \
fi

# Install base packages
RUN if [ "${DISTRO_NAME}" = "ubuntu" ]; then \
    apt update && apt install -y ca-certificates && update-ca-certificates; \
elif [ "${DISTRO_NAME}" = "centos" ]; then \
    # CentOS 7 is EOL, use Tsinghua vault repositories
    if grep -q "CentOS Linux release 7" /etc/centos-release 2>/dev/null || [ "${DISTRO_VERSION}" = "7" ]; then \
        sed -i \
            -e 's|^mirrorlist=|#mirrorlist=|g' \
            -e 's|^#baseurl=http://mirror.centos.org/centos/\$releasever|baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/7.9.2009|g' \
            -e 's|^#baseurl=http://mirror.centos.org|baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/7.9.2009|g' \
            /etc/yum.repos.d/CentOS-*.repo; \
    else \
        # CentOS Stream 8 - use Tsinghua vault path
        sed -i \
            -e 's|^mirrorlist=|#mirrorlist=|g' \
            -e 's|^#baseurl=http://mirror.centos.org/\$contentdir/\$stream|baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/8-stream|g' \
            -e 's|^#baseurl=http://mirror.centos.org|baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/8-stream|g' \
            /etc/yum.repos.d/CentOS-Stream-*.repo; \
    fi; \
    yum install -y ca-certificates && update-ca-trust; \
fi

# Install essential tools
RUN if [ "${DISTRO_NAME}" = "ubuntu" ]; then \
    apt update && apt install -y \
        software-properties-common gpg gnupg gnupg2 \
        openssh-server sudo curl wget vim locales; \
elif [ "${DISTRO_NAME}" = "centos" ]; then \
    yum install -y \
        epel-release && \
    yum install -y \
        openssh-server sudo curl wget vim; \
fi

# Install zsh only in full mode
RUN if [ "${BUILD_MODE}" = "full" ]; then \
    if [ "${DISTRO_NAME}" = "ubuntu" ]; then \
        apt install -y zsh; \
    elif [ "${DISTRO_NAME}" = "centos" ]; then \
        yum install -y zsh; \
    fi; \
fi

# Install additional tools
RUN if [ "${DISTRO_NAME}" = "ubuntu" ]; then \
    apt install -y \
        locales \
        tldr \
        net-tools telnet iputils-ping \
        unzip p7zip-full \
        ffmpeg jq poppler-utils imagemagick \
        ripgrep \
        tmux \
        git \
        gettext; \
elif [ "${DISTRO_NAME}" = "centos" ]; then \
    yum install -y \
        net-tools telnet iputils \
        unzip p7zip \
        jq \
        tmux \
        git; \
fi

# Install development tools
RUN if [ "${DISTRO_NAME}" = "ubuntu" ]; then \
    # Select libstdc++ version based on Ubuntu version
    if [ "${DISTRO_VERSION}" = "20.04" ]; then \
        LIBSTDCXX_PKG="libstdc++-9-dev"; \
    elif [ "${DISTRO_VERSION}" = "22.04" ]; then \
        LIBSTDCXX_PKG="libstdc++-12-dev"; \
    elif [ "${DISTRO_VERSION}" = "24.04" ]; then \
        LIBSTDCXX_PKG="libstdc++-13-dev"; \
    else \
        LIBSTDCXX_PKG="libstdc++-12-dev"; \
    fi; \
    apt install -y \
        gcc \
        g++ \
        ${LIBSTDCXX_PKG} \
        cmake \
        make \
        ninja-build \
        automake \
        autoconf \
        libtool \
        pkg-config \
        libomp-dev \
        libgmp-dev \
        libyaml-dev \
        libmpfr-dev; \
elif [ "${DISTRO_NAME}" = "centos" ]; then \
    yum groupinstall -y "Development Tools" && \
    yum install -y \
        gcc gcc-c++ \
        cmake3 \
        make \
        automake \
        autoconf \
        libtool \
        pkgconfig \
        gmp-devel \
        mpfr-devel; \
    if yum list available ninja-build >/dev/null 2>&1; then \
        yum install -y ninja-build; \
    fi; \
    if yum list available libyaml-devel >/dev/null 2>&1; then \
        yum install -y libyaml-devel; \
    fi; \
fi

# Install build essentials and Python
RUN if [ "${DISTRO_NAME}" = "ubuntu" ]; then \
    apt install -y \
        build-essential \
        python3 python3-pip python3-dev \
        libpython3-dev libncurses5 libtinfo5 libxml2-dev \
        libopenblas-dev libffi-dev libssl-dev libjpeg-dev \
        libboost-all-dev htop rsync; \
elif [ "${DISTRO_NAME}" = "centos" ]; then \
    yum install -y \
        python3 python3-pip python3-devel \
        ncurses-devel libxml2-devel \
        libffi-devel openssl-devel libjpeg-devel \
        boost-devel htop rsync; \
    if yum list available openblas-devel >/dev/null 2>&1; then \
        yum install -y openblas-devel; \
    fi; \
fi

# Clean up package cache
RUN if [ "${DISTRO_NAME}" = "ubuntu" ]; then \
    apt clean && rm -rf /var/lib/apt/lists/*; \
elif [ "${DISTRO_NAME}" = "centos" ]; then \
    yum clean all; \
fi

# Set the locale and timezone
ENV TZ=Asia/Shanghai
RUN if [ "${DISTRO_NAME}" = "ubuntu" ]; then \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8; \
fi && \
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Create group with host GID first, then user with host UID/GID
RUN DEFAULT_SHELL=$(if [ "${BUILD_MODE}" = "full" ] && command -v zsh >/dev/null 2>&1; then which zsh; else which bash; fi) && \
    groupadd -g ${HOST_GROUP_ID} ${USER_NAME} && \
    useradd -m -u ${HOST_USER_ID} -g ${HOST_GROUP_ID} -s $DEFAULT_SHELL ${USER_NAME} && \
    echo ${USER_NAME}:${USER_PASSWD} | chpasswd && \
    usermod -aG sudo ${USER_NAME} || usermod -aG wheel ${USER_NAME}

# Configure SSH server
RUN mkdir -p /var/run/sshd && \
    if [ "${DISTRO_NAME}" = "centos" ]; then \
        ssh-keygen -A; \
    fi && \
    echo 'PermitRootLogin no' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config && \
    echo "AllowUsers ${USER_NAME}" >> /etc/ssh/sshd_config

# Install LLVM toolchain (only in full mode)
ENV LLVM_VERSION=18
RUN if [ "${BUILD_MODE}" = "full" ]; then \
    if [ "${DISTRO_NAME}" = "ubuntu" ]; then \
        curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor > /etc/apt/trusted.gpg.d/llvm.gpg && \
        echo "deb [signed-by=/etc/apt/trusted.gpg.d/llvm.gpg] https://mirrors.tuna.tsinghua.edu.cn/llvm-apt/${distro_codename}/ llvm-toolchain-${distro_codename}-${LLVM_VERSION} main" > /etc/apt/sources.list.d/llvm.list && \
        apt update && apt install -y \
            clang-${LLVM_VERSION} \
            lld-${LLVM_VERSION} \
            lldb-${LLVM_VERSION} \
            llvm-${LLVM_VERSION} \
            clangd-${LLVM_VERSION} \
            libclang-${LLVM_VERSION}-dev && \
        update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${LLVM_VERSION} 100 && \
        update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-${LLVM_VERSION} 100 && \
        update-alternatives --install /usr/bin/llvm-config llvm-config /usr/bin/llvm-config-${LLVM_VERSION} 100 && \
        update-alternatives --install /usr/bin/lld lld /usr/bin/lld-${LLVM_VERSION} 100 && \
        update-alternatives --install /usr/bin/lldb lldb /usr/bin/lldb-${LLVM_VERSION} 100 && \
        update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-${LLVM_VERSION} 100; \
    elif [ "${DISTRO_NAME}" = "centos" ]; then \
        yum install -y \
            clang \
            llvm \
            llvm-devel \
            clang-devel; \
    fi; \
fi

# Configure user environment
USER ${USER_NAME}
WORKDIR /home/${USER_NAME}

# Create .ssh directory for the user
RUN mkdir -p /home/${USER_NAME}/.ssh && \
    chmod 700 /home/${USER_NAME}/.ssh && \
    touch /home/${USER_NAME}/.ssh/authorized_keys && \
    chmod 600 /home/${USER_NAME}/.ssh/authorized_keys

# Create scripts directory and copy scripts
RUN mkdir -p /home/${USER_NAME}/scripts
COPY --chown=${USER_NAME}:${USER_NAME} ./scripts/ /home/${USER_NAME}/scripts/
RUN chmod +x /home/${USER_NAME}/scripts/*.sh

# Install Oh My Zsh and plugins (only in full mode with zsh)
RUN if [ "${BUILD_MODE}" = "full" ] && command -v zsh >/dev/null 2>&1; then \
    echo '# Basic zsh configuration\n\
bindkey -e\n\
autoload -Uz compinit\n\
compinit\n\
setopt autocd\n\
setopt extendedglob\n\
setopt prompt_subst\n\
\n\
# Basic prompt\n\
if [[ ! -f ~/.oh-my-zsh/oh-my-zsh.sh ]]; then\n\
  PS1="%F{green}%n@%m:%F{blue}%~%f $ "\n\
  echo "Oh My Zsh not installed. To install manually run:"\n\
  echo "sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""\n\
fi\n\
\n\
# History settings\n\
HISTFILE=~/.zsh_history\n\
HISTSIZE=10000\n\
SAVEHIST=10000\n\
setopt appendhistory\n\
' > /home/${USER_NAME}/.zshrc_basic && \
    set +e && \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; zsh_exit=$?; \
    if [ $zsh_exit -eq 0 ]; then \
      echo "Oh My Zsh installed successfully"; \
      git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || true; \
      git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || true; \
      if [ -f ~/.zshrc ]; then \
        sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc || true; \
        echo 'export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#a0a0a0"' >> ~/.zshrc; \
        echo 'ZSH_DISABLE_COMPFIX="true"' >> ~/.zshrc; \
        echo 'DISABLE_AUTO_UPDATE="true"' >> ~/.zshrc; \
        echo 'ZSH_THEME="robbyrussell"' >> ~/.zshrc; \
      fi; \
    else \
      echo "Oh My Zsh installation failed - using basic zsh configuration"; \
      cp /home/${USER_NAME}/.zshrc_basic /home/${USER_NAME}/.zshrc; \
    fi; \
    set -e; \
fi

# Install Miniconda (only in full mode)
RUN if [ "${BUILD_MODE}" = "full" ]; then \
    set +e && \
    echo "Attempting to install Miniconda..." && \
    curl -L https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o miniconda.sh && \
    bash miniconda.sh -b -p $HOME/miniconda3 && \
    rm miniconda.sh && \
    if command -v zsh >/dev/null 2>&1; then \
        echo 'export PATH="$HOME/miniconda3/bin:$PATH"' >> ~/.zshrc && \
        if [ -d "$HOME/miniconda3/bin" ]; then \
          $HOME/miniconda3/bin/conda init zsh || true; \
          echo "Miniconda installed successfully"; \
        else \
          echo "Miniconda installation failed - path will need to be set manually"; \
        fi; \
    else \
        echo 'export PATH="$HOME/miniconda3/bin:$PATH"' >> ~/.bashrc && \
        if [ -d "$HOME/miniconda3/bin" ]; then \
          $HOME/miniconda3/bin/conda init bash || true; \
          echo "Miniconda installed successfully"; \
        else \
          echo "Miniconda installation failed - path will need to be set manually"; \
        fi; \
    fi; \
    set -e; \
fi

# Add terminal customizations (only in full mode with zsh)
RUN if [ "${BUILD_MODE}" = "full" ] && command -v zsh >/dev/null 2>&1 && [ -f ~/.zshrc ]; then \
    echo '\n# Custom terminal settings' >> ~/.zshrc && \
    echo 'export TERM="xterm-256color"' >> ~/.zshrc && \
    echo 'export LANG="en_US.UTF-8"' >> ~/.zshrc && \
    echo '\n# Installation helper functions' >> ~/.zshrc && \
    echo 'function install_omz() {' >> ~/.zshrc && \
    echo '  echo "Installing Oh My Zsh..."' >> ~/.zshrc && \
    echo '  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"' >> ~/.zshrc && \
    echo '}' >> ~/.zshrc && \
    echo 'function install_zsh_plugins() {' >> ~/.zshrc && \
    echo '  echo "Installing zsh plugins..."' >> ~/.zshrc && \
    echo '  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions' >> ~/.zshrc && \
    echo '  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting' >> ~/.zshrc && \
    echo '  sed -i '\''s/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/'\'' ~/.zshrc' >> ~/.zshrc && \
    echo '  echo "Please restart your shell to apply changes"' >> ~/.zshrc && \
    echo '}' >> ~/.zshrc; \
fi

# Switch back to root for final configuration
USER root

# Set proper ownership for home directory
RUN chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}

# Create workspace directory if it doesn't exist
RUN mkdir -p /home/${USER_NAME}/workspace && \
    chown ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/workspace

# Copy shell config to /etc/skel for SSH sessions (only if exists)
RUN if [ -f /home/${USER_NAME}/.zshrc ]; then \
    cp /home/${USER_NAME}/.zshrc /etc/skel/.zshrc && \
    chown root:root /etc/skel/.zshrc; \
elif [ -f /home/${USER_NAME}/.bashrc ]; then \
    cp /home/${USER_NAME}/.bashrc /etc/skel/.bashrc && \
    chown root:root /etc/skel/.bashrc; \
fi

# Expose SSH port
EXPOSE 22

# Start SSH server as the main process
CMD if [ "${DISTRO_NAME}" = "centos" ]; then \
    /usr/sbin/sshd -D; \
else \
    /usr/sbin/sshd -D; \
fi
