# DLAB RUNAI Images

This repository stores the RUNAI images for DLABs compute resources. The usage is trivial, simply pass the image uri as parameter to RUNAI. If your setting this up for the first time, check out [First Time Instructions](#First-Time-Instructions).

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
Use the `runai submit {JOB_NAME} -i {IMAGE} -- {COMMAND}` command. To map the scratch partition add the flag `--pvc runai-dlab-{GASPAR_USERNAME}-scratch:/mnt`. If you plan on iteractively using the container add the `--interactive` flag. This will give you priority in the queue, but be sure to only add it if you need interactive jobs. With `-g {num}` you can select the number of GPUS, with `--cpu {num}` the number of CPUs. The flag `--memory 10G` will allocate you at least 10G of RAM. Should you run into shared memory issues, add the flag `--large-shm` (sometimes required for massively parallel dataloaders). With `--node-type G10` you select the node type. 

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

 

I strongly recommend creating some aliases/shell scripts to make your life easier, e.g. `alias rs="runai submit -i ghcr.io/jkminder/dlab-runai-images/pytorch:master --pvc runai-dlab-{GASPAR_USERNAME}-scratch:/mnt"`. See [RUNAI ALIASES](#runai-aliases). Should your shell not support aliases, use the [`submit.sh`](submit.sh) script (replace the ENVS in the file first).

For a detailed instruction manual on the `runai submit` command, see [here](https://docs.run.ai/v2.9/Researcher/cli-reference/runai-submit/#-pvc-storage_class_namesizecontainer_mount_pathro).


## Caveats
- Don't add the `--command` flag to runai submit. This will overwrite the script that sets up your GASPAR user. 
- You can't login to a root bash session (with `su -`). You have password less `sudo` rights on your GASPAR user, use this. 
- If you already have a `.bashrc` file in `/dlabscratch1/{GASPAR_USERNAME}`, please copy the contents of [`base/.bashrc`](base/.bashrc) to your file. This is necessary because the script does not create it if one already exists.


## First Time Instructions
The following steps have to be done once.
- Start a container or use ssh to connect directly to the IC cluster and create the file `.ssh/authorized_keys` in your folder on scratch (`/dlabscratch1/{GASPAR_USERNAME}`). Paste your public ssh key (see [here](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) for a tutorial on creating ssh keys).
- On your local computer append the following lines to your `~/.ssh/config` file:
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
    Should it not exist, create the file. This will allow you to easily connect VS Code or via SSH to your runai containers without any annoying warnings. Be sure to replace the placeholders `{...}` with the appropriate values. After portforwarding from your container (install the [RUNAI ALIASES](#runai-aliases) and run `rpf container-name`), you can connect to it with `ssh runai` or use the [SSH extension of VS Code](https://code.visualstudio.com/docs/remote/ssh) to directly develop in the container. You can also use this to run jupyter notebooks on the container via VS Code. 
- Check out [RUNAI ALIASES](#runai-aliases)
- If you want to customize the images, look at [Customization](#customization)


## Connecting to VScode
In order to connect to vscode you need to run:
```
kubectl port-forward %name%-0-0 2222:22
```
where name is your runai job name. Should you have the [RUNAI ALIASES](#runai-aliases) installed, this is shortened to `rpf %name%`.

Then you can launch VScode and connect to your `runai` ssh host or run:
```
code --remote ssh-remote+runai /dlabscratch1/path/to/your/project
```

## RUNAI Aliases

I added a few aliases that makes life a bit easier. Source them in your `.bashrc` (or whatever shell your using) by adding the line `source {pathtothisrepo}/.runai_aliases` to it. 

Available Aliases:
- `rl`: Short for `runai list`
- `rb`: Short for `runai bash`

    **Usage:** `rb container-name`
- `rdj`: Short for `runai delete job`

    **Usage:** `rdj container-name`
- `rpf`: Portforward to your container. Especially useful for VS Code usage.
   
   **Usage:** `rpf container-name`
- `rs`: Short for `runai submit -i {image} --pvc runai-dlab-{GASPAR_NAME}-scratch:/mnt`. Make sure you adapt this to your needs by replacing the image and the ´{GASPAR_USERNAME}´ in the `.runai_aliases` file.
   
   **Usage:** `rs --interactive -g 1.0 eval -- sleep 3600`
- `ric`: Switches the context to the IC cluster. Short for `runai config cluster ic-caas`
- `rrcp`: Switches the context to the RCP cluster. Short for `runai config cluster rcp-caas-test`


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

3. Push your repository. Github Actions will automatically build your image. This may take a minute, check the progress under the `Actions` tab. Once it's done 
