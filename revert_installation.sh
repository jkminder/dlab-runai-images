#!/bin/bash

set -e

BACKUP_DIR="$1"

if [ -z "$BACKUP_DIR" ]; then
    echo "Please provide the backup directory as an argument."
    exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
    echo "Backup directory does not exist: $BACKUP_DIR"
    exit 1
fi

# Function to restore a file
restore_file() {
    local file="$1"
    local dest="$2"
    if [ -f "$file" ]; then
        cp "$file" "$dest"
        echo "Restored $file to $dest"
    fi
}

# Restore .runai_aliases
restore_file "$BACKUP_DIR/.runai_aliases" "$HOME/.runai_aliases"

# Restore .kube/config
restore_file "$BACKUP_DIR/config" "$HOME/.kube/config"

# Restore RunAI binaries
if [ -f "$BACKUP_DIR/binary_paths.txt" ]; then
    while IFS= read -r line; do
        binary_name=$(basename "$line")
        if [ -f "$BACKUP_DIR/$binary_name" ]; then
            sudo cp "$BACKUP_DIR/$binary_name" "$line"
            sudo chmod +x "$line"
            echo "Restored $binary_name to $line"
        fi
    done < "$BACKUP_DIR/binary_paths.txt"
else
    echo "No binary paths file found. Unable to restore RunAI binaries to their original locations."
fi

# Remove source command from rc file
rc_file="$HOME/.bashrc"
if [ -f "$HOME/.zshrc" ]; then
    rc_file="$HOME/.zshrc"
elif [ -f "$HOME/.bash_profile" ]; then
    rc_file="$HOME/.bash_profile"
fi

sed -i.bak '/source.*\.runai_aliases/d' "$rc_file"
echo "Removed source command from $rc_file"

echo "Revert complete. Please restart your terminal or run 'source $rc_file' to apply changes."