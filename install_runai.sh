#!/bin/bash

set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to download and install RunAI CLI
install_runai() {
    local url="$1"
    local binary_name="$2"
    
    echo "Downloading $binary_name..."
    if command_exists wget; then
        wget --content-disposition "$url" -O "$binary_name"
    elif command_exists curl; then
        curl -L "$url" -o "$binary_name"
    else
        echo "Error: Neither wget nor curl is installed. Please install one of them and try again."
        exit 1
    fi
    
    if [[ "$os" == "windows" ]]; then
        # For Windows, rename the file with .exe extension
        mv "$binary_name" "${binary_name}.exe"
        binary_name="${binary_name}.exe"
        echo "Renamed to $binary_name"
        
        # Check if a directory in PATH exists and is writable
        IFS=':' read -ra PATH_DIRS <<< "$PATH"
        for dir in "${PATH_DIRS[@]}"; do
            if [[ -d "$dir" && -w "$dir" ]]; then
                echo "Moving $binary_name to $dir..."
                mv "$binary_name" "$dir/$binary_name"
                echo "$binary_name installed successfully in $dir"
                break
            fi
        done
        
        if [[ ! -f "$dir/$binary_name" ]]; then
            echo "Could not find a writable directory in PATH. Please manually move $binary_name to a directory in your PATH."
        fi
    else
        # For Unix-like systems (Linux and macOS)
        chmod +x "$binary_name"
        echo "Moving $binary_name to /usr/local/bin (requires sudo)..."
        sudo mv "$binary_name" "/usr/local/bin/$binary_name"
        echo "$binary_name installed successfully."
    fi
}

# Function to set kubectl config
set_kubectl_config() {
    local cluster_name="$1"
    local server_url="$2"
    local user_name="$3"
    local context_name="$4"
    local namespace="$5"
    local cert_auth_data="$6"

    kubectl config set-cluster "$cluster_name" --server="$server_url"
    
    if [ -n "$cert_auth_data" ]; then
        kubectl config set clusters."$cluster_name".certificate-authority-data "$cert_auth_data"
    fi
    
    kubectl config set-context "$context_name" --cluster="$cluster_name" --user="$user_name" --namespace="$namespace"
}

# Detect the operating system and shell
if [[ "$OSTYPE" == "darwin"* ]]; then
    os="darwin"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    os="linux"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    os="windows"
else
    echo "Unsupported operating system: $OSTYPE"
    exit 1
fi
echo "Detected OS: $os"

# if windows -> exit
if [[ "$os" == "windows" ]]; then
    echo "Windows is currently not supported. Please use WSL or Git Bash."
    exit 1
fi

# Determine the appropriate rc file
if [[ "$SHELL" == */zsh ]]; then
    if [ -f "$HOME/.zshrc" ]; then
        rc_file="$HOME/.zshrc"
    else
        rc_file="$HOME/.bashrc"
    fi
elif [[ "$SHELL" == */bash ]]; then
    rc_file="$HOME/.bashrc"
else
    echo "Unsupported shell: $SHELL"
    exit 1
fi

echo "Detected shell: $SHELL"

# Check if kubectl is installed
if ! command_exists kubectl; then
    echo "kubectl is not installed. Please install kubectl and run this script again."
    exit 1
fi

# Check if RunAI is already installed
if command_exists runai || command_exists runai-rcp-prod || command_exists runai-rcp-test || command_exists runai-ic; then
    read -p "RunAI is already installed. Do you want to overwrite it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation aborted."
        exit 1
    fi
fi

# Create a backup directory in the repo
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKUP_DIR="$SCRIPT_DIR/runai_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Function to backup a file
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "$BACKUP_DIR/$(basename "$file")"
        echo "Backed up $file to $BACKUP_DIR"
    fi
}

# Backup existing files
backup_file "$HOME/.runai_aliases"
backup_file "$HOME/.kube/config"
backup_file "$rc_file"

# Backup and remove existing RunAI binaries
for binary in runai runai-rcp-prod runai-rcp-test runai-ic; do
    if command -v "$binary" > /dev/null 2>&1; then
        binary_path=$(which "$binary")
        backup_file "$binary_path"
        echo "$binary_path" >> "$BACKUP_DIR/binary_paths.txt"
        # Remove the binary with sudo
        echo "Removing existing $binary binary (requires sudo)..."
        sudo rm "$binary_path"
        echo "Removed existing $binary binary"
    fi
done


# Ask for GASPAR_NAME
read -p "Please enter your GASPAR_NAME: " GASPAR_NAME

# Check if .runai_aliases already exists in the home directory
if [ -f "$HOME/.runai_aliases" ]; then
    read -p ".runai_aliases already exists in your home directory. Do you want to overwrite it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing .runai_aliases file."
    else
        # Copy local .runai_aliases file
        cp .runai_aliases "$HOME/.runai_aliases.tmp"

        # Replace {GASPAR_NAME} placeholder and create final .runai_aliases file
        sed "s/{GASPAR_NAME}/$GASPAR_NAME/g" "$HOME/.runai_aliases.tmp" > "$HOME/.runai_aliases"
        rm "$HOME/.runai_aliases.tmp"

        echo ".runai_aliases file created successfully with your GASPAR_NAME."
    fi
else
    # Copy local .runai_aliases file
    cp .runai_aliases "$HOME/.runai_aliases.tmp"

    # Replace {GASPAR_NAME} placeholder and create final .runai_aliases file
    sed "s/{GASPAR_NAME}/$gaspar_name/g" "$HOME/.runai_aliases.tmp" > "$HOME/.runai_aliases"
    rm "$HOME/.runai_aliases.tmp"

    echo ".runai_aliases file created successfully with your GASPAR_NAME."
fi

echo "The .runai_aliases file has been saved to $HOME/.runai_aliases"

# Download and install RunAI CLIs
if [[ "$os" == "windows" ]]; then
    echo "Windows detected. Please install Git Bash or WSL to use this script."
    echo "After installing, run this script again within the bash environment."
    exit 1
else
    install_runai "https://rcp-caas-prod.rcp.epfl.ch/cli/$os" "runai-rcp-prod"
    install_runai "https://rcp-caas-test.rcp.epfl.ch/cli/$os" "runai-rcp-test"
    install_runai "https://ic-caas.epfl.ch/cli/$os" "runai-ic"
fi

# Add source command to rc file
if ! grep -q "source $HOME/.runai_aliases" "$rc_file"; then
    echo "Adding source command to $rc_file..."
    if [ -w "$rc_file" ]; then
        echo "source $HOME/.runai_aliases" >> "$rc_file"
    else
        echo "Adding source command to $rc_file requires sudo permissions."
        sudo sh -c "echo 'source $HOME/.runai_aliases' >> $rc_file"
    fi
else
    echo "Source command already exists in $rc_file."
fi


# Set kubectl configurations
set_kubectl_config "caas-prod.rcp.epfl.ch" "https://caas-prod.rcp.epfl.ch:443" "runai-rcp-authenticated-user" "rcp-caas-prod" "runai-dlab-$GASPAR_NAME" "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJRHdwSElpTmQrVUV3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TkRBMk1UUXdPVFU1TWpkYUZ3MHpOREEyTVRJeE1EQTBNamRhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUURvOHJDRjNjeXdRRTlxTVpEOHNGTXo2K0FzSEpnWi81WVNwMGNhWHNKd0JWUERneGdwRGZKY0hnYXYKS2tOdVhTNGpBN1VrZkg1amZXQitvdytpamN3OUR4cjV6STB2TUNReWtzYk9kMVFFMis0Q0J1U0JXU01Gc1pYZQp2T01SanltN056SytxWkVldHpxR0M0bU5LdU9qbC92cGd4ZDNuM2Y2L3loRHhockp2bkVWKzZlUE5icWpDZURZCld1VWFZdUYxRmM4QnZHN0hma3FYRlRWWVdlNkpNa3JSbDQxOVo5a2diNnIvUFNZVzZqdDhhNThTSGNHSVhnTFcKOTBta3BFb1JCMENOSG0wQllEQjdjNFJxMmdyaWtZTUlldGM0eXk2L3NSdFp6NzFiTUQrM2ZDNk92NDdvOXUzWgpld0VWeEJ4dG11ZkVvVGduVEVyNXFYMlhxWFZMQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJSazdCMm84a3cxcyt0Ny9ZaGxmV1h1MnR6TkdEQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQXFOdnQrR01lTwp6QnZZZEQ2SExCakFVeWc1czd0TDgzOVltd0RhRXBseG45ZlBRdUV6UW14cnEwUEoxcnVZNnRvRks1SEN4RFVzCmJDN3R3WlMzaVdNNXQ5NEJveHJGVC92c3QrQmtzbWdvTGM2T0N1MitYcngyMUg3UnFLTnNVR01LN2tFdGN6cHgKeXUrYTB6T0tISEUxNWFSVENPbklzQ1pXaTRhVFhIZ00zQ2U4VEhBMXRxaW9pREFHMVFUQXNhNXhTeVM3RWlUSQpDYi9xbktPRlVvM3V3bkRocWljRTU3dE1LTjliRE8rV3hNMzVxT2lBZXVXOUVnc2JlOFA5aDY2NG1tK1QzbjY0ClJNL1l1NHhmcDZwMHMvdGZyZTVjaUFvT0dGekYyRmVKek5PYm1vRkVseUtKc0RwbEorcWFTVXlaL2NtNWRIYUUKQVUxOVMrUWpFc1cvCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
set_kubectl_config "caas-test.rcp.epfl.ch" "https://caas-test.rcp.epfl.ch:443" "runai-rcp-authenticated-user" "rcp-caas-test" "runai-dlab-$GASPAR_NAME" "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMvakNDQWVhZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJek1EUXlOakE0TVRRME5sb1hEVE16TURReU16QTRNVFEwTmxvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTFAxCmtTZ2E4NWRWU0p0VUxGQ1g5VWo1K1lTT2dCbG9MZGVxZVgrM1ByVGtQZkptWFBxeXlsVVBLN0tJUWlvSUplNm8KRTBaS2JZbU03SnEvL0lPaHF4R0VraUNrTHJCamJrYXF5M3NibkNhWGFMa1pQYkhNWjgwdmlMMGNFZHNJTWN4WgozdHpMTzFNTldwZW9mZlJ6L1NvbXpqSTVDQldJbUptTmhvZXpJQUVNOGJuaDJKeFBFNzRwWThTS1BTRk5YVzN0CjgxNmM5cXRvc1lJQjVrTnh1UjRGWVh5bGloZHZ3UmVqVW9wajA2ME1rSkl3QmpXM01YTFUrdkVyandKeFc5Q1cKZ2plUndzOG5kdW5VVHREcy9CVjhGbW5JZy81VVNhZTBzUE5FQWxvZC9TbGhrMnNuWTJvUXZlTHpFNkhrMnluRgpHNXd1VGVXRDZGY2Erd1pNMjM4Q0F3RUFBYU5aTUZjd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZNVVhkVWVnK2xMdTlHWElMQ2VlOVJzOENmUXpNQlVHQTFVZEVRUU8KTUF5Q0NtdDFZbVZ5Ym1WMFpYTXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBR051a2ZUR3E0RTlrckkreVZQbApaem1reSszaUNTMnYvTU9OU3h0S01idWZ2V0ROZFM3QzZaK1RDQTJSd0c1Y2gzZUh5UW9oTSs0K2wrSTJxMTFwCjNJVGRxYVI4RDhpQkFCbXV6Yzl2a3BKanZTTzZ4VVpnTFJZMHRDTUxXZ3g2b2tBcWhxZDV3YTZIYmN6Z1QrSUcKQlVGbERtR0R4K0MxTnFIYVFKUVN1bENqL1ZyS1RROVFlY1NoZGZqVDgvS1NVUjQ4VTlEdlA3dnU0YkRnWW5DKwpoOXEwUlFpUGR4TEtlL2Q5aGd0UnM5TjFQdGRYZXAxdHB3NCs3Y3N4TE1DSXNmYTBwaW8yb3lEems0bTNjSWRNCi9iNElHUEZaM2hYZktOVGtybnUrWmdCUms5Yjk3emNKZVdhendxTXUyd1dkV2JiQjdpaU5ZK2xtWkl1S0dUeFQKWWpRPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
set_kubectl_config "ic-caas" "https://ic-caas.epfl.ch:6443" "ic-caas-user" "ic-caas" "runai-dlab-$GASPAR_NAME"

# Set up OIDC auth providers
kubectl config set-credentials runai-rcp-authenticated-user \
    --auth-provider=oidc \
    --auth-provider-arg=airgapped=true \
    --auth-provider-arg=auth-flow=remote-browser \
    --auth-provider-arg=realm=rcpepfl \
    --auth-provider-arg=client-id=runai-cli \
    --auth-provider-arg=idp-issuer-url=https://app.run.ai/auth/realms/rcpepfl \
    --auth-provider-arg=redirect-uri=https://rcpepfl.run.ai/oauth-code

kubectl config set-credentials ic-caas-user \
    --auth-provider=oidc \
    --auth-provider-arg=airgapped=true \
    --auth-provider-arg=auth-flow=remote-browser \
    --auth-provider-arg=realm=epfl \
    --auth-provider-arg=client-id=runai-cli \
    --auth-provider-arg=idp-issuer-url=https://app.run.ai/auth/realms/epfl \
    --auth-provider-arg=redirect-uri=https://epfl.run.ai/oauth-code

# Set the default context
kubectl config use-context rcp-caas-test

echo "kubectl configurations have been set up successfully."

echo "Installation complete. Please restart your terminal or run 'source $rc_file' to apply changes."
