#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$PROJECT_ROOT/tools/colors.conf"

if [ ! -f "$PROJECT_ROOT/.config" ]; then
    echo "$FAIL No .config found. Run 'make menuconfig' first."
    exit 1
fi

source "$PROJECT_ROOT/.config"

LFS=$(eval echo $CONFIG_LFS_MOUNT)

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
        if sudo mount -v -t ext4 "$partition" "$LFS"; then
            echo "$PASS Partition mounted"
        else
            echo "$FAIL Failed to mount $partition to $LFS"
            exit 1
        fi
    fi
    
elif [ ! -d "$LFS" ]; then
    proc "Directory doesn't exist"
    prom "Create directory? [y/N]:"
    read answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        if sudo mkdir -pv "$LFS"; then
            echo "$PASS Directory created"
        else
            echo "$FAIL Failed to create directory $LFS"
            exit 1
        fi
        
        prom "Do you want to mount a partition here? [y/N]:"
        read answer2
        if [[ "$answer2" =~ ^[Yy]$ ]]; then
            prom "Enter partition (e.g., /dev/sda3):"
            read partition
            if sudo mount -v -t ext4 "$partition" "$LFS"; then
                echo "$PASS Partition mounted"
            else
                echo "$FAIL Failed to mount $partition to $LFS"
                exit 1
            fi
        fi
    else
        echo "$FAIL Aborted by user"
        exit 1
    fi
fi

proc "Setting ownership and permissions..."
if sudo chown root:root "$LFS"; then
    if sudo chmod 755 "$LFS"; then
        echo "$PASS Ownership set to root:root, permissions 755"
    else
        echo "$FAIL Failed to set permissions on $LFS"
        exit 1
    fi
else
    echo "$FAIL Failed to change ownership of $LFS"
    exit 1
fi

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
if echo "export LFS=$LFS" > "$PROJECT_ROOT/.lfs_env"; then
    echo "$PASS \$LFS set to $LFS"
else
    echo "$FAIL Failed to write to .lfs_env"
    exit 1
fi

proc "Setting umask to 022..."
umask 022
if echo "umask 022" >> "$PROJECT_ROOT/.lfs_env"; then
    echo "$PASS umask set"
else
    echo "$FAIL Failed to write umask to .lfs_env"
    exit 1
fi

echo ""
head "Build directory ready"
echo ""
echo "$WARN You must load the environment variables before continuing!"

CURRENT_DIR=$(pwd)
REL_PATH=$(realpath --relative-to="$CURRENT_DIR" "$PROJECT_ROOT/.lfs_env")

text "Run these commands:"
text "  source $REL_PATH"
text "  echo \$LFS  # Should show your build directory path"
