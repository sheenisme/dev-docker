FROM ubuntu:jammy

# User configuration
ARG USER_NAME=sheen      # Default username if not provided
ARG USER_PASSWD          # Password for the user (required)
ARG HOST_USER_ID=1000    # Host user ID for proper permissions
ARG HOST_GROUP_ID=1000   # Host group ID for proper permissions
RUN test -n "${USER_PASSWD}" || { echo "USER_PASSWD not set"; exit 1; }

# Environment variables for distribution information
ENV container=docker
ENV distro=ubuntu2204
ENV distro_codename=jammy
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt source
RUN sed -i 's@http://archive.ubuntu.com/@http://mirrors.tuna.tsinghua.edu.cn/@g' /etc/apt/sources.list && \
    sed -i 's@http://security.ubuntu.com/@http://mirrors.tuna.tsinghua.edu.cn/@g' /etc/apt/sources.list

# Install some applications
RUN apt update 
RUN apt install -y \
    ca-certificates && update-ca-certificates

RUN apt update && apt install -y \
    software-properties-common gpg gnupg gnupg2 \
    openssh-server sudo zsh curl wget vim locales

RUN apt install -y \
    locales \
    tldr \
    net-tools telnet iputils-ping \
    unzip p7zip-full 7zip \
    ffmpeg jq poppler-utils imagemagick \
    ripgrep \
    tmux \
    git \
    gettext

RUN apt install -y \
    gcc \
    libstdc++-12-dev \
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
    libmpfr-dev

RUN apt install -y \
    build-essential \
    python3 python3-pip python3-dev \
    libpython3-dev libncurses5 libtinfo5 libxml2-dev \
    libopenblas-dev libffi-dev libssl-dev libjpeg-dev \
    libboost-all-dev htop rsync

RUN apt clean && rm -rf /var/lib/apt/lists/*

# Set the locale and timezone
ENV TZ=Asia/Shanghai
RUN locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8 && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Create group with host GID first, then user with host UID/GID
RUN groupadd -g ${HOST_GROUP_ID} ${USER_NAME} && \
    useradd -m -u ${HOST_USER_ID} -g ${HOST_GROUP_ID} -s $(which zsh) ${USER_NAME} && \
    echo ${USER_NAME}:${USER_PASSWD} | chpasswd && \
    usermod -aG sudo ${USER_NAME}

# Configure SSH server
RUN mkdir /var/run/sshd && \
    echo 'PermitRootLogin no' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config && \
    echo "AllowUsers ${USER_NAME}" >> /etc/ssh/sshd_config

# Configure LLVM repository
ENV LLVM_VERSION=18
# Configure LLVM repository by mirrors.tuna.tsinghua.edu.cn
RUN curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor > /etc/apt/trusted.gpg.d/llvm.gpg && \
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/llvm.gpg] https://mirrors.tuna.tsinghua.edu.cn/llvm-apt/${distro_codename}/ llvm-toolchain-${distro_codename}-${LLVM_VERSION} main" > /etc/apt/sources.list.d/llvm.list

# Install LLVM toolchain
RUN apt update && apt install -y \
    clang-${LLVM_VERSION} \
    lld-${LLVM_VERSION} \
    lldb-${LLVM_VERSION} \
    llvm-${LLVM_VERSION} \
    clangd-${LLVM_VERSION} \
    libclang-${LLVM_VERSION}-dev && \
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${LLVM_VERSION} 100 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-${LLVM_VERSION} 100 && \
    update-alternatives --install /usr/bin/lld lld /usr/bin/lld-${LLVM_VERSION} 100 && \
    update-alternatives --install /usr/bin/lldb lldb /usr/bin/lldb-${LLVM_VERSION} 100 && \
    update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-${LLVM_VERSION} 100

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

# Create basic zshrc in case Oh My Zsh installation fails
RUN echo '# Basic zsh configuration\n\
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
' > /home/${USER_NAME}/.zshrc_basic

# Try to install Oh My Zsh and plugins, but continue on failure
RUN set +e && \
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
    set -e

# Install Miniconda (with error handling)
RUN set +e && \
    echo "Attempting to install Miniconda..." && \
    curl -L https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o miniconda.sh && \
    bash miniconda.sh -b -p $HOME/miniconda3 && \
    rm miniconda.sh && \
    echo 'export PATH="$HOME/miniconda3/bin:$PATH"' >> ~/.zshrc && \
    if [ -d "$HOME/miniconda3/bin" ]; then \
      $HOME/miniconda3/bin/conda init zsh || true; \
      echo "Miniconda installed successfully"; \
    else \
      echo "Miniconda installation failed - path will need to be set manually"; \
    fi; \
    set -e

# Add nice terminal prompt customization
RUN echo '\n# Custom terminal settings' >> ~/.zshrc && \
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
    echo '}' >> ~/.zshrc

# Switch back to root for final configuration
USER root

# Set proper ownership for home directory
RUN chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}

# Create workspace directory if it doesn't exist
RUN mkdir -p /home/${USER_NAME}/workspace && \
    chown ${USER_NAME}:${USER_NAME} /home/${USER_NAME}/workspace

# Copy zshrc to /etc/skel to ensure it's used for new SSH sessions
RUN cp /home/${USER_NAME}/.zshrc /etc/skel/.zshrc && \
    chown root:root /etc/skel/.zshrc

# Expose SSH port
EXPOSE 22

# Start SSH server as the main process
CMD ["/usr/sbin/sshd", "-D"]