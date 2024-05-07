ARG BASE_IMAGE="nvidia/cuda:12.2.2-base-ubuntu22.04"

FROM ${BASE_IMAGE}

ARG NB_USER="login"

USER root
RUN apt-get update && \
   apt-get install -y  --no-install-recommends  \
    curl \
    gcc \
    git \
    gosu \
    git-lfs \
    htop \
    libgl1 \
    libglib2.0-0 \
    ncdu \
    openssh-client \
    openssh-server \
    psmisc \
    rsync \
    screen \
    sudo \
    tmux \
    unzip \
    vim \
    ldap-utils \
    wget && \
    wget -q  https://github.com/justjanne/powerline-go/releases/download/v1.24/powerline-go-linux-"$(dpkg --print-architecture)" -O /usr/local/bin/powerline-shell && \
    chmod a+x /usr/local/bin/powerline-shell

# install Miniforge
RUN wget -O /tmp/Miniforge3.sh "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh" && \
    bash /tmp/Miniforge3.sh -b -p "/opt/conda" &&  rm /tmp/Miniforge3.sh
RUN . /opt/conda/etc/profile.d/conda.sh

# setup ssh
RUN ssh-keygen -A
EXPOSE 22

RUN mkdir -p /login/

COPY base/user-entrypoint.sh /login/user-entrypoint.sh
RUN chmod +x /login/user-entrypoint.sh

RUN id -u ${NB_USER} || useradd -s /bin/bash ${NB_USER} -d /login/
RUN echo "login ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# set password for user
RUN echo "login:login" | chpasswd

USER ${NB_USER}
ENTRYPOINT ["sudo", "/bin/bash", "/login/user-entrypoint.sh"]