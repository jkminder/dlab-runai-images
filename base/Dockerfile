ARG BASE_IMAGE="nvidia/cuda:12.2.2-base-ubuntu22.04"

FROM ${BASE_IMAGE}

ARG INCLUDE_PYTHON_DEPS="0"

USER root
RUN apt-get update && \
   apt-get install -y  --no-install-recommends  \
    curl \
    gcc \
    git \
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

# setup ssh
RUN ssh-keygen -A
EXPOSE 22

# handle the NB_USER setup and set home directory to /myhome
RUN id -u ${NB_USER} || useradd -d /myhome -s /bin/bash ${NB_USER} && usermod -a -G ${NB_USER} ${NB_USER}
 
# passwordless sudo
RUN echo "${NB_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# install conda environment
COPY base/environment.yml /tmp/environment.yml
RUN if [ "$INCLUDE_PYTHON_DEPS" = "1" ]; then \
    /opt/conda/bin/mamba env create -f /tmp/environment.yml -n default && \
    /opt/conda/bin/mamba clean -y --all; \
    fi
RUN rm /tmp/environment.yml

COPY user-setup.sh /tmp/user-setup.sh

ENTRYPOINT sudo service ssh start && /tmp/user-setup.sh
