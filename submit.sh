#!/bin/bash

# This script is used to submit a job to the RUNAI platform.
# Replace {GASPAR_USERNAME} with your username and {IMAGE} with the image you want to run, e.g. ghcr.io/jkminder/dlab-runai-images/base:master
GASPAR_USERNAME='...'
IMAGE='ghcr.io/jkminder/dlab-runai-images/base:master'

# Example Usage:
# ./submit.sh --interactive --gpu 1 --cpu 2 --memory 4G -- sleep 3600


runai submit -i $IMAGE --pvc runai-dlab-${GASPAR_USERNAME}-scratch:/mnt $@
