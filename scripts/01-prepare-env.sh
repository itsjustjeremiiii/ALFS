#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$PROJECT_ROOT/tools/colors.conf"

if [ ! -f "$PROJECT_ROOT/.config" ]; then
    echo "$FAIL No .config found. Run 'make menuconfig' first."
    exit 1
fi

source "$PROJECT_ROOT/.config"

LFS=$CONFIG_LFS_MOUNT

head "Preparing LFS Build Directory"
echo ""
text "Build directory: $LFS"
echo ""

if [ -d "$LFS" ] && mountpoint -q "$LFS"; then
    proc "Checking mounted partition..."
    echo "$PASS $LFS is already mounted"
    
elif [ -d "$LFS" ] && [ ! "$(ls -A $LFS)" ]; then
    proc "Directory exists but is empty (not mounted?)"
    prom "Is this a mount point that needs mounting? [y/N]:"
    read answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        prom "Enter partition (e.g., /dev/sda3):"
        read partition
        sudo mount -v -t ext4 "$partition" "$LFS" || { echo "$FAIL Mount failed"; exit 1; }
        echo "$PASS Partition mounted"
    fi
    
elif [ ! -d "$LFS" ]; then
    proc "Directory doesn't exist"
    prom "Create directory? [y/N]:"
    read answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        sudo mkdir -pv "$LFS" || { echo "$FAIL Could not create directory"; exit 1; }
        echo "$PASS Directory created"
        
        prom "Do you want to mount a partition here? [y/N]:"
        read answer2
        if [[ "$answer2" =~ ^[Yy]$ ]]; then
            prom "Enter partition (e.g., /dev/sda3):"
            read partition
            sudo mount -v -t ext4 "$partition" "$LFS" || { echo "$FAIL Mount failed"; exit 1; }
            echo "$PASS Partition mounted"
        fi
    else
        echo "$FAIL Aborted"
        exit 1
    fi
fi

proc "Setting ownership and permissions..."
sudo chown root:root "$LFS"
sudo chmod 755 "$LFS"
echo "$PASS Ownership set to root:root, permissions 755"

proc "Checking mount options..."
if mount | grep "$LFS" | grep -q "nosuid\|nodev"; then
    echo "$WARN Partition mounted with nosuid or nodev - this may cause issues"
    echo "$WARN Consider remounting without these options"
else
    echo "$PASS Mount options are acceptable"
fi

proc "Checking disk space..."
FREE_SPACE=$(df -BG "$LFS" | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$FREE_SPACE" -lt 10 ]; then
    echo "$WARN Only ${FREE_SPACE}GB free (10GB minimum, 30GB recommended)"
else
    echo "$PASS ${FREE_SPACE}GB free space available"
fi

proc "Setting \$LFS environment variable..."
export LFS="$LFS"
echo "export LFS=$LFS" > "$PROJECT_ROOT/.lfs_env"
echo "$PASS \$LFS set to $LFS"

proc "Setting umask to 022..."
umask 022
echo "umask 022" >> "$PROJECT_ROOT/.lfs_env"
echo "$PASS umask set"

echo ""
head "Build directory ready"
echo ""
echo "$WARN You must load the environment variables before continuing!"
text "Run these commands:"
text "  source ../.lfs_env"
text "  echo \$LFS  # Verify it shows: $LFS"
