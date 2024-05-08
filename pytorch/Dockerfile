ARG BASE_IMAGE="ghcr.io/jkminder/dlab-runai-images/base:master"

FROM ${BASE_IMAGE}

# install conda environment
COPY pytorch/environment.yml /tmp/environment.yml
COPY pytorch/requirements.txt /tmp/requirements.txt
RUN /opt/conda/bin/mamba env create -f /tmp/environment.yml -n default && \
    /opt/conda/bin/mamba clean -y --all
RUN rm /tmp/environment.yml

RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate default && \
    mamba clean -y --all && \
    pip install -r /tmp/requirements.txt --no-cache-dir &&\
    rm /tmp/requirements.txt

