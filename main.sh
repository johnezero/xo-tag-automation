#!/bin/bash

# ============================================
# Tag-Based-Automation -- main.sh (v1.1)
# Orchestrator: loads config, runs modules
# ============================================

CONF_DIR="/usr/local/etc/tag-automation/conf.d"
DEFAULT_CONF="$CONF_DIR/default.conf"
CUSTOM_CONF="$CONF_DIR/custom.conf"
SCRIPT_PATH="/usr/local/bin/tag-automation/main.sh"

# --- LOAD CONFIGURATION ---
if [ -f "$DEFAULT_CONF" ]; then
    source "$DEFAULT_CONF"
else
    echo "Error: default.conf not found at $DEFAULT_CONF"
    exit 1
fi
[ -f "$CUSTOM_CONF" ] && source "$CUSTOM_CONF"

# --- CONSTRUCT FINAL TAG NAMES ---
CORE_TAG="${CORE_BASE}${TAG_SUFFIX}"
HIGH_TAG="${HIGH_BASE}${TAG_SUFFIX}"
NORMAL_TAG="${NORMAL_BASE}${TAG_SUFFIX}"
LOW_TAG="${LOW_BASE}${TAG_SUFFIX}"

# ============================================
# INITIALIZE FUNCTION
# ============================================
initialize_plugin() {
    echo ""
    echo "Tag-Based-Automation -- Initialization"
    echo "============================================"

    if [ ! -d "$CONF_DIR" ]; then
        echo "Error: Config directory not found: $CONF_DIR"
        exit 1
    fi

    if [ ! -f "$DEFAULT_CONF" ]; then
        echo "Error: default.conf not found."
        exit 1
    fi

    [ ! -f "$CUSTOM_CONF" ] && echo "Warning: custom.conf not found. Using defaults only."

    TARGET_DIR="/etc/cron.${SCHEDULE}"
    SYMLINK_PATH="${TARGET_DIR}/tag-automation"

    if [ ! -d "$TARGET_DIR" ]; then
        echo "Error: Cron directory not found: $TARGET_DIR"
        echo "Valid SCHEDULE options: hourly, daily, weekly, monthly"
        exit 1
    fi

    for interval in hourly daily weekly monthly; do
        rm -f "/etc/cron.${interval}/tag-automation"
    done

    ln -sf "$SCRIPT_PATH" "$SYMLINK_PATH"

    if [ -L "$SYMLINK_PATH" ]; then
        echo "[OK] Symlink created : $SYMLINK_PATH"
        echo "[OK] Schedule        : $SCHEDULE"
        echo "[OK] Tag suffix      : ${TAG_SUFFIX:-(none)}"
        echo "[OK] Active tags     : $CORE_TAG, $HIGH_TAG, $NORMAL_TAG, $LOW_TAG"
        echo "[OK] Performance     : ${ENABLE_PERFORMANCE:-true}"
        echo "[--] Permissions     : Coming Soon"
        echo ""
        echo "Initialization complete. Bundle will run $SCHEDULE via cron."
    else
        echo "Error: Failed to create symlink."
        exit 1
    fi
}

[ "$1" == "initialize" ] && initialize_plugin && exit 0

# ============================================
# NORMAL EXECUTION (called by cron)
# ============================================

# --- MASTER HOST CHECK ---
POOL_MASTER=$(xe pool-list params=master --minimal)
LOCAL_HOST=$(xe host-list name-label=$(hostname) --minimal)
[ "$POOL_MASTER" != "$LOCAL_HOST" ] && exit 0

# --- REDIRECT ALL OUTPUT TO MAIN LOG ---
exec >> "$MAIN_LOG" 2>&1
echo "--- Tag-Automation Starting: $(date) ---"
echo "    Tags: $CORE_TAG | $HIGH_TAG | $NORMAL_TAG | $LOW_TAG"

# --- RUN PERFORMANCE MODULE ---
if [ "${ENABLE_PERFORMANCE:-true}" == "true" ]; then
    echo "--- Running set-performance module ---"
    source /usr/local/bin/tag-automation/modules/set-performance.sh
fi

# --- set-permissions MODULE (COMING SOON) ---
# if [ "${ENABLE_PERMISSIONS:-false}" == "true" ]; then
#     echo "--- Running set-permissions module ---"
#     source /usr/local/bin/tag-automation/modules/set-permissions.sh
# fi

# --- NFS LOG PUSH (graceful -- no auto-remount) ---
NFS_CODE_PATH="/mnt/v0/code/tag-automation"
if mountpoint -q "/mnt/v0" && [ -d "$NFS_CODE_PATH" ]; then
    cp "$SUMMARY_LOG" "$NFS_CODE_PATH/logs/" 2>/dev/null
    echo "[OK] Logs pushed to NFS"
else
    echo "[--] NFS not available -- skipping log push"
fi

echo "--- Tag-Automation Complete: $(date) ---"
echo "$(date '+%Y-%m-%d %H:%M:%S') $(hostname) Suffix:${TAG_SUFFIX:-(none)} Performance:${ENABLE_PERFORMANCE:-true}" >> "$SUMMARY_LOG"
