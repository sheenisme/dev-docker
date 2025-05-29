FROM ubuntu:jammy

# User configuration
ARG USER_NAME=sheen      # Default username if not provided
ARG USER_PASSWD          # Password for the user (required)
RUN test -n "${USER_PASSWD}" || { echo "USER_PASSWD not set"; exit 1; }

# Environment variables for distribution information
ENV container=docker
ENV distro=ubuntu2204
ENV distro_codename=jammy
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt source
RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list
RUN sed -i s@/security.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list

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

# Create user with sudo privileges and set password
RUN useradd -m -s $(which zsh) ${USER_NAME} && \
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
# RUN wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor > /etc/apt/trusted.gpg.d/llvm.gpg
# RUN echo "deb http://apt.llvm.org/${distro_codename}/ llvm-toolchain-${distro_codename}-${LLVM_VERSION} main\n" \
#          "deb-src http://apt.llvm.org/${distro_codename}/ llvm-toolchain-${distro_codename}-${LLVM_VERSION} main" \
#          > /etc/apt/sources.list.d/llvm.list
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

# Copy scripts to user home dir
COPY ./scripts/set_proxy.sh /home/${USER_NAME}/scripts/

# # Install Oh My Zsh and plugins
# RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
#     git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
#     git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Install Miniconda
RUN curl -L https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o miniconda.sh && \
    bash miniconda.sh -b -p $HOME/miniconda3 && \
    rm miniconda.sh && \
    echo 'export PATH="$HOME/miniconda3/bin:$PATH"' >> ~/.zshrc && \
    $HOME/miniconda3/bin/conda init zsh

# Switch back to root for final configuration
USER root

# open home dir to everyone
RUN chmod 777 /home/${USER_NAME}/

# Expose SSH port
EXPOSE 22

# Start SSH server as the main process
CMD ["/usr/sbin/sshd", "-D"]
