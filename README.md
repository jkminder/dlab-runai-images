# DLAB RUNAI Images and CLI Installer

This repository stores the RUNAI images for DLABs compute resources and provides installation scripts for the RunAI CLI and kubectl configurations.

## Prerequisites

Before running the installation script, ensure you have the following:

1. **kubectl**: The Kubernetes command-line tool must be installed on your system.
   - For installation instructions, visit: [Install and Set Up kubectl](https://kubernetes.io/docs/tasks/tools/)
   - (For Windows Users) You need install kubectl on WSL, not on Windows.

2. **For Windows Users**: Windows Subsystem for Linux (WSL) is required.
   - Install WSL by following the instructions at: [Install WSL](https://docs.microsoft.com/en-us/windows/wsl/install)
   - After installing WSL, install a Linux distribution (e.g., Ubuntu) from the Microsoft Store.

## Installation

1. Clone this repository:
   ```
   git clone https://github.com/your-repo/dlab-runai-images.git
   cd dlab-runai-images
   ```

2. Run the installation script:
   ```
   ./install_runai.sh
   ```

   The script will:
   - Backup existing RunAI configurations and binaries
   - Install the RunAI CLI for RCP and IC clusters
   - Configure kubectl for the RunAI environments
   - Set up necessary aliases and environment variables

3. Follow the prompts during installation, including entering your GASPAR name when requested.

4. After installation, restart your terminal or run `source ~/.bashrc` (or the appropriate rc file for your shell) to apply the changes.

5. Set up SSH access for RunAI containers:
   - Start a container or use SSH to connect directly to the IC cluster.
   - Create the file `.ssh/authorized_keys` in your scratch folder (`/dlabscratch1/{GASPAR_USERNAME}`).
   - Paste your public SSH key into this file. (For help generating SSH keys, see [GitHub's SSH key guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent))

6. Configure local SSH settings:
   - On your local computer, append the following to your `~/.ssh/config` file (create it if it doesn't exist):
     ```YAML
     Host runai
         HostName localhost
         User {GASPAR_USERNAME}
         ForwardAgent yes
         IdentityFile {PATH_TO_YOUR_PRIVATE_KEY}
         StrictHostKeyChecking no
         UserKnownHostsFile=/dev/null
         Port 2222
     ```
   - Replace `{GASPAR_USERNAME}` and `{PATH_TO_YOUR_PRIVATE_KEY}` with your actual values.
   - This configuration allows easy SSH connections to RunAI containers without warnings.
   - After setting up port forwarding (use `rpf container-name` with [RUNAI ALIASES](#runai-aliases)), you can:
     - Connect via SSH using `ssh runai`
     - Use VS Code's [SSH extension](https://code.visualstudio.com/docs/remote/ssh) for direct container development
     - Run Jupyter notebooks on the container through VS Code

Note: If you prefer manual installation or encounter issues with the script, you can follow the steps in the script manually. Refer to the `install_runai.sh` file for detailed instructions on each step of the installation process.

## Reverting Changes

If you need to revert the installation:

1. Run the revert script with the backup directory path (provided at the end of the installation):
   ```
   ./revert_installation.sh /path/to/backup/directory
   ```

2. This will restore your system to the state before the RunAI CLI installation.

## Available Images

There are currently two images available:
- **base**: `ghcr.io/jkminder/dlab-runai-images/base:master`
    - Logs you in with your GASPAR UID/GUID and sets the correct permissions
    - Installs basic packages (conda, htop, vim, ssh, etc.). 
    - Should `dlabscratch` be mapped, it sets your $HOME to `/dlabscratch1/{GASPAR_USERNAME}`.
    - Has CUDA 12.2.2 installed. 
    - Has [Powershell GO](https://github.com/justjanne/powerline-go/) installed, a shell wrapper that makes life a bit easier.
    - Automatically generates a `.bashrc` file in your $HOME if you don't have one.
- **pytorch**: `ghcr.io/jkminder/dlab-runai-images/pytorch:master` 
    - Creates `default` conda environment with pytorch and other default ML python libraries installed. See `pytorch/environment.yml` and `pytorch/requirements.txt` for an exhaustive list.

## How to submit jobs
(This section assumes you have installed runai using the install_runai.sh script. If you installed runai manually, be sure to replace `runai` with the correct binary.)

Use the `runai submit {JOB_NAME} -i {IMAGE} -- {COMMAND}` command. To map the scratch partition add the flag `--pvc runai-dlab-{GASPAR_USERNAME}-scratch:/mnt`. For the RCP-prod use `--pvc dlab-scatch:/mnt` instead of the `--pvc runai-dlab-{GASPAR_USERNAME}-scratch:/mnt` flag. If you plan on iteractively using the container add the `--interactive` flag. 
This will give you priority in the queue, but be sure to only add it if you need interactive jobs. With `-g {num}` you can select the number of GPUS, with `--cpu {num}` the number of CPUs. The flag `--memory 10G` will allocate you at least 10G of RAM. Should you run into shared memory issues, add the flag `--large-shm` (sometimes required for massively parallel dataloaders). With `--node-type G10` you select the node type. 

A few examples:

**Submit an interactive job which runs for 1 hour with the name `test` with 1 GPU.**
```
runai submit -i ghcr.io/jkminder/dlab-runai-images/pytorch:master --pvc runai-dlab-{GASPAR_USERNAME}-scratch:/mnt --interactive -g 1.0 test -- sleep 3600
```
**Submit a training job with the name `train` with 0.5 GPU.**
```
runai submit -i ghcr.io/jkminder/dlab-runai-images/pytorch:master --pvc runai-dlab-{GASPAR_USERNAME}-scratch:/mnt -g 0.5 train -- python ~/trainer/train.py --my-training-arg 2
```
**Submit an interactive job which runs for 2 hour with the name `test` with 0.5 GPU and at least 12 CPUs**
```
runai submit -i ghcr.io/jkminder/dlab-runai-images/pytorch:master --pvc runai-dlab-{GASPAR_USERNAME}-scratch:/mnt -g 0.5 --cpu 12 test -- sleep 3600
```
**Submit a job with a specific node type**
Node types
* ICC: [S8|G9|G10]  "S8" (CPU only), "G9" (Nvidia V100) or "G10" (Nvidia A100)
* RCP: there is only one node type

```
runai submit -i ghcr.io/jkminder/dlab-runai-images/pytorch:master --pvc runai-dlab-{GASPAR_USERNAME}-scratch:/mnt --interactive -g 1.0 --node-type G10 test -- sleep 3600
```

I strongly recommend using the aliases provided by the installation script. See [RUNAI ALIASES](#runai-aliases). Should your shell not support aliases, use the [`submit.sh`](submit.sh) script (replace the binaries and ENVS in the file first).

For a detailed instruction manual on the `runai submit` command, see [here](https://docs.run.ai/v2.9/Researcher/cli-reference/runai-submit/#-pvc-storage_class_namesizecontainer_mount_pathro).

## RUNAI Aliases

The installation script sets up several useful aliases. These are stored in the `.runai_aliases` file in your home directory and are loaded when you open a new terminal. Some key aliases include:

- `runai`: Autodetects the cluster you are on and switches context. 
- `rl`: Short for `runai list`
- `rb`: Short for `runai bash`
- `rdj`: Short for `runai delete job`
- `rpf`: Portforward to your container
- `rs`: Short for `runai submit` with predefined options (pytorch image, scratch mapped)
- `rsg`: Short for `rs --gpu 1.0 --interactive`
- `ric`: Switches the context to the IC cluster
- `rrcp`: Switches the context to the RCP prod cluster
- `rrcpt`: Switches the context to the RCP test cluster

## Caveats

- Don't add the `--command` flag to runai submit. This will overwrite the script that sets up your GASPAR user. 
- You can't login to a root bash session (with `su -`). You have password less `sudo` rights on your GASPAR user, use this. 
- If you already have a `.bashrc` file in `/dlabscratch1/{GASPAR_USERNAME}`, please copy the contents of [`base/.bashrc`](base/.bashrc) to your file. This is necessary because the script does not create it if one already exists.

## First Time Instructions

The following steps have to be done once.

- Check out [RUNAI ALIASES](#runai-aliases)
- If you want to customize the images, look at [Customization](#customization)


## Connecting to VScode

In order to connect to vscode you need to run:
```
rpf %name%
```
where name is your runai job name. Should you not have the [RUNAI ALIASES](#runai-aliases) installed, this is equal to `kubectl port-forward %name%-0-0 2222:22
`.

Then you can launch VScode and connect to your `runai` ssh host or run:
```
code --remote ssh-remote+runai /dlabscratch1/path/to/your/project
```

## Customization

You can easily customize these images to your desire. No need to manually build docker images because GitHub will do that for you. 

1. Fork this repository.
2. Either create a new folder with a `Dockerfile` that uses `ghcr.io/jkminder/dlab-runai-images/base:master` as base image or modify the existing ones. If you just want to install other packages, you can simply modify the `pytorch/environment.yml` (for conda install) and `pytorch/requirements.txt` (for pip install) files. 
    - Should you create/modify your own `Dockerfile`, make sure that you don't overwrite the `ENTRYPOINT`. If you need to overwrite `ENTRYPOINT` make sure that it ends with: 
        ```
        ..., "/tmp/user-entrypoint.sh"]
        CMD ["/bin/bash"]
        ```
3. (Optional) If you have created a new folder with a new Dockerfile, you need to also create a new Github Action that builds and uploads the image. For that duplicate the `.github/workflows/docker-base.yml` file, rename it to `docker-{yourimagename}.yml` and search-replace `base` with `{yourimagename}`. This will automatically build and publish the image under `ghcr.io/{github_shortname}/dlab-runai-images/{yourimagename}:master`.

## Support

For any questions or issues, please open an issue in this repository or contact me (Julian Minder).