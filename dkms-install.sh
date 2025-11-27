#!/bin/bash
# DKMS installation script for r8168 driver
# This script installs the r8168 driver using DKMS for automatic rebuilds on kernel updates

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root or with sudo"
    exit 1
fi

DRIVER_NAME="r8168"
DRIVER_VERSION="8.055.00"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing r8168 driver via DKMS..."
echo "Driver version: $DRIVER_VERSION"
echo ""

# Check if DKMS is installed
if ! command -v dkms &> /dev/null; then
    echo "Error: DKMS is not installed."
    echo "Please install DKMS first:"
    echo "  Ubuntu/Debian: sudo apt-get install dkms"
    echo "  Fedora/RHEL:   sudo dnf install dkms"
    echo "  Arch:          sudo pacman -S dkms"
    exit 1
fi

# Check if kernel headers are installed
KERNEL_VERSION=$(uname -r)
if [ ! -d "/lib/modules/$KERNEL_VERSION/build" ]; then
    echo "Error: Kernel headers for $KERNEL_VERSION are not installed."
    echo "Please install kernel headers first:"
    echo "  Ubuntu/Debian: sudo apt-get install linux-headers-$(uname -r)"
    echo "  Fedora/RHEL:   sudo dnf install kernel-devel-$(uname -r)"
    echo "  Arch:          sudo pacman -S linux-headers"
    exit 1
fi

# Remove old installation if exists
if dkms status | grep -q "^$DRIVER_NAME"; then
    echo "Removing previous r8168 DKMS installation..."
    OLD_VERSIONS=$(dkms status | grep "^$DRIVER_NAME" | awk -F', ' '{print $2}' | sort -u)
    for ver in $OLD_VERSIONS; do
        echo "  Removing version $ver..."
        dkms remove -m $DRIVER_NAME -v $ver --all 2>/dev/null || true
    done
fi

# Remove old source directory if exists
if [ -d "/usr/src/$DRIVER_NAME-$DRIVER_VERSION" ]; then
    echo "Removing old source directory..."
    rm -rf "/usr/src/$DRIVER_NAME-$DRIVER_VERSION"
fi

# Copy driver source to /usr/src
echo "Copying driver source to /usr/src/$DRIVER_NAME-$DRIVER_VERSION..."
mkdir -p "/usr/src/$DRIVER_NAME-$DRIVER_VERSION"
cp -r "$SCRIPT_DIR/src" "/usr/src/$DRIVER_NAME-$DRIVER_VERSION/"
cp "$SCRIPT_DIR/dkms.conf" "/usr/src/$DRIVER_NAME-$DRIVER_VERSION/"

# Add to DKMS
echo "Adding driver to DKMS..."
dkms add -m $DRIVER_NAME -v $DRIVER_VERSION

# Build the module
echo "Building driver module for kernel $KERNEL_VERSION..."
dkms build -m $DRIVER_NAME -v $DRIVER_VERSION

# Install the module
echo "Installing driver module..."
dkms install -m $DRIVER_NAME -v $DRIVER_VERSION

# Check if r8169 module is loaded and blacklist it
if lsmod | grep -q "^r8169"; then
    echo ""
    echo "Warning: The in-kernel r8169 driver is currently loaded."
    echo "The r8168 driver conflicts with r8169. Blacklisting r8169..."

    # Create blacklist file
    echo "blacklist r8169" > /etc/modprobe.d/blacklist-r8169.conf

    echo ""
    echo "The r8169 module has been blacklisted."
    echo "You need to reboot or manually unload r8169 and load r8168:"
    echo "  sudo rmmod r8169"
    echo "  sudo modprobe r8168"
fi

echo ""
echo "Installation complete!"
echo ""
echo "The driver will be automatically rebuilt when you install new kernels."
echo ""
echo "To load the driver now:"
echo "  sudo modprobe r8168"
echo ""
echo "To check if the driver is loaded:"
echo "  lsmod | grep r8168"
echo ""
echo "To remove the DKMS installation:"
echo "  sudo dkms remove -m $DRIVER_NAME -v $DRIVER_VERSION --all"
echo "  sudo rm -rf /usr/src/$DRIVER_NAME-$DRIVER_VERSION"
