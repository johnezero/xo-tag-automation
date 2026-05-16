#!/bin/bash

# ============================================
# Tag-Based-Automation -- install.sh (v1.1)
# One-shot installer for the full bundle
# ============================================

BUNDLE_DIR="$(dirname "$0")"
INSTALL_BIN="/usr/local/bin"
INSTALL_CONF="/usr/local/etc"

echo ""
echo "Tag-Based-Automation -- Installer v1.1"
echo "============================================"
echo ""

# --- VERIFY RUNNING AS ROOT ---
if [ "$(id -u)" != "0" ]; then
    echo "Error: This installer must be run as root."
    exit 1
fi

# --- VERIFY XE IS AVAILABLE ---
if ! command -v xe &>/dev/null; then
    echo "Error: xe command not found."
    echo "This installer must be run on an XCP-ng Pool Master."
    exit 1
fi

# --- STEP 0: STAND-ALONE CLEANUP CHECK ---
echo "Checking for legacy standalone components..."
LEGACY_FOUND=false

# Check for old script
if [ -f "/usr/local/bin/set-performance.sh" ]; then
    echo "  [!] Legacy script found: /usr/local/bin/set-performance.sh"
    LEGACY_FOUND=true
fi

# Check for old config directory
if [ -d "/usr/local/etc/set-performance.conf.d" ]; then
    echo "  [!] Legacy config dir found: /usr/local/etc/set-performance.conf.d"
    LEGACY_FOUND=true
fi

# Check for old crontab entries
if crontab -l 2>/dev/null | grep -q "set-performance.sh"; then
    echo "  [!] Legacy crontab entry detected."
    LEGACY_FOUND=true
fi

# Check for old cron symlinks (using find for reliability)
LEGACY_CRONS=$(find /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly \
    -name "set-performance" 2>/dev/null)
if [ -n "$LEGACY_CRONS" ]; then
    echo "  [!] Legacy cron symlinks detected:"
    echo "$LEGACY_CRONS" | sed 's/^/      - /'
    LEGACY_FOUND=true
fi

if [ "$LEGACY_FOUND" = true ]; then
    echo ""
    echo "-----------------------------------------------------------------------"
    echo "CAUTION: Legacy standalone components detected."
    echo "Please remove them before proceeding:"
    echo ""
    echo "  rm -f /usr/local/bin/set-performance.sh"
    echo "  rm -rf /usr/local/etc/set-performance.conf.d"
    echo "  rm -f /etc/cron.hourly/set-performance"
    echo "  rm -f /etc/cron.daily/set-performance"
    echo "  rm -f /etc/cron.weekly/set-performance"
    echo "  rm -f /etc/cron.monthly/set-performance"
    echo "-----------------------------------------------------------------------"
    echo ""
    read -p "Abort to clean up manually? (Y/n): " choice
    case "$choice" in
      n|N ) echo "Proceeding with caution -- watch for conflicts!"; echo "" ;;
      * )   echo "Installation aborted. Clean up and re-run install.sh."; exit 1 ;;
    esac
else
    echo "[OK] No legacy components found -- clean install!"
    echo ""
fi

# --- STEP 1: CREATE DIRECTORY STRUCTURE ---
echo "Creating directory structure..."
mkdir -p "$INSTALL_BIN/tag-automation/modules"
mkdir -p "$INSTALL_CONF/tag-automation/conf.d"
echo "[OK] Directories created"

# --- STEP 2: INSTALL MAIN ORCHESTRATOR ---
echo "Installing main.sh..."
cp "$BUNDLE_DIR/main.sh" "$INSTALL_BIN/tag-automation/main.sh"
chmod +x "$INSTALL_BIN/tag-automation/main.sh"
echo "[OK] main.sh installed"

# --- STEP 3: INSTALL MODULES ---
echo "Installing modules..."
cp "$BUNDLE_DIR/modules/set-performance.sh" \
   "$INSTALL_BIN/tag-automation/modules/set-performance.sh"
chmod +x "$INSTALL_BIN/tag-automation/modules/set-performance.sh"
echo "[OK] set-performance.sh installed"
echo "[--] set-permissions.sh -- Coming Soon (not installed)"

# --- STEP 4: INSTALL CONFIG FILES ---
echo "Installing configuration files..."
cp "$BUNDLE_DIR/conf.d/default.conf" \
   "$INSTALL_CONF/tag-automation/conf.d/default.conf"
echo "[OK] default.conf installed"

if [ ! -f "$INSTALL_CONF/tag-automation/conf.d/custom.conf" ]; then
    cp "$BUNDLE_DIR/conf.d/custom.conf" \
       "$INSTALL_CONF/tag-automation/conf.d/custom.conf"
    echo "[OK] custom.conf installed (first time)"
else
    echo "[OK] custom.conf already exists -- skipping (your settings preserved)"
fi

# --- STEP 5: VERIFY NFS CODE PATH ---
NFS_CODE_PATH="/mnt/v0/code/tag-automation"
if [ -d "$NFS_CODE_PATH" ]; then
    mkdir -p "$NFS_CODE_PATH/logs"
    echo "[OK] NFS code path verified : $NFS_CODE_PATH"
else
    echo "[--] NFS code path not found: $NFS_CODE_PATH"
    echo "     mkdir -p $NFS_CODE_PATH/logs"
fi

# --- STEP 6: INITIALIZE ---
echo ""
echo "Running initialization..."
echo ""
"$INSTALL_BIN/tag-automation/main.sh" initialize

echo ""
echo "============================================"
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Edit custom.conf for your pool:"
echo "     vi $INSTALL_CONF/tag-automation/conf.d/custom.conf"
echo ""
echo "  2. Re-run initialize after config changes:"
echo "     /usr/local/bin/tag-automation/main.sh initialize"
echo ""
echo "  3. Monitor logs:"
echo "     tail -f /var/log/tag-automation.log"
echo "     tail -f /var/log/tag-automation-summary.log"
echo "============================================"
