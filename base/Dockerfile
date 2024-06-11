ARG BASE_IMAGE="nvidia/cuda:12.2.2-base-ubuntu22.04"

FROM ${BASE_IMAGE}

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
    tree \
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
    nvtop \
    wget && \
    wget -q  https://github.com/justjanne/powerline-go/releases/download/v1.24/powerline-go-linux-"$(dpkg --print-architecture)" -O /usr/local/bin/powerline-shell && \
    chmod a+x /usr/local/bin/powerline-shell

# install Miniforge
RUN wget -O /tmp/Miniforge3.sh "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh" && \
    bash /tmp/Miniforge3.sh -b -p "/opt/conda" &&  rm /tmp/Miniforge3.sh
RUN . /opt/conda/etc/profile.d/conda.sh
# make conda install writable
RUN chmod -R 777 /opt/conda

# setup ssh
RUN ssh-keygen -A
EXPOSE 22

COPY base/user-entrypoint.sh /tmp/user-entrypoint.sh
COPY base/.bashrc /tmp/.bashrc
RUN chmod +x /tmp/user-entrypoint.sh

ENTRYPOINT ["/tmp/user-entrypoint.sh"]
CMD ["/bin/bash"]
