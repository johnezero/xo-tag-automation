# Tag-Based-Automation Bundle

**Current Version:** v1.0 (Bundle Release)
**Target Platform:** XCP-ng Pool Master
**Repository:** https://github.com/johnezero/xo-tag-automation

---

## Overview

The Tag-Based-Automation bundle is a modular, install.sh based framework designed to ensure that **Metadata (Tags) drive Infrastructure State.**

It automates performance tuning and VM management tasks across your XCP-ng environment -- preventing configuration drift, simplifying bulk VM management, and laying the foundation for full tag-driven permission management via Xen Orchestra.

> The goal is simple: Metadata (Tags) should drive Infrastructure State.

---

## Standard Disclaimer

This software is provided "AS-IS" without any express or implied warranty. While these scripts are being used in a production environment managing VMs, you should always review the code and test it in a non-production environment before full deployment.

Note: The scripts are designed to ONLY take action on VMs with specific tags assigned -- untagged VMs are never touched.

That said, as always -- your mileage may vary...

---

## What Is in the Bundle?

### [ACTIVE] set-performance.sh
Automated enforcement of CPU weights and I/O priorities based on assigned VM tags.
Runs via cron. Prevents configuration drift across your entire pool.

### [COMING SOON] sync-vm-metadata.sh
Bulk VM metadata management using a CSV as Source of Truth workflow.
Export your VM list, edit tags in Excel, sync back to the pool in one command.

### [COMING SOON] set-permissions.sh
Automated management of Xen Orchestra Resource Sets and user permissions --
driven entirely by your existing VM tags. No manual Resource Set updates ever again.

---

## Bundle Files

1. install.sh         -- One-shot installer: handles directories, permissions, and legacy cleanup detection
2. main.sh            -- Orchestrator: loads config, manages module execution, handles cron scheduling
3. modules/set-performance.sh  -- Enforces CPU weights and I/O priorities based on VM tags
4. conf.d/default.conf         -- Global defaults (DO NOT edit)
5. conf.d/custom.conf          -- Pool-specific overrides (edit this one)

---

## Installation

### STEP 1: Download and Extract

wget https://github.com/johnezero/xo-tag-automation/releases/download/v1.0/tag-automation-v1.0.tar.gz
tar -xzvf tag-automation-v1.0.tar.gz
cd tag-automation-bundle/

OR download to your workstation and upload via SCP or WinSCP:

scp tag-automation-v1.0.tar.gz root@your-pool-master:/root/

Then on your Pool Master:

tar -xzvf tag-automation-v1.0.tar.gz
cd tag-automation-bundle/

### STEP 2: Run the Installer

chmod +x install.sh
./install.sh

The installer will:
- Detect and warn about any legacy standalone components
- Create all required directories
- Deploy all scripts and config files
- Preserve any existing custom.conf on re-install
- Verify your NFS code path if applicable

### STEP 3: Edit Your Pool-Specific Config

*** ACTION REQUIRED -- DO NOT SKIP ***

vi /usr/local/etc/tag-automation/conf.d/custom.conf

Set your TAG_SUFFIX to match your pool:
  POOL-1  -->  TAG_SUFFIX="-1"
  POOL-2  -->  TAG_SUFFIX="-2"
  Single pool  -->  TAG_SUFFIX=""

### STEP 4: Initialize the Bundle

*** ACTION REQUIRED -- DO NOT SKIP ***

/usr/local/bin/tag-automation/main.sh initialize

Expected output:
  [OK] Symlink created : /etc/cron.hourly/tag-automation
  [OK] Schedule        : hourly
  [OK] Tag suffix      : (none)
  [OK] Active tags     : 0-core, 1-high, 2-normal, 3-low
  [OK] Performance     : true
  [--] Permissions     : Coming Soon

*** Bundle will NOT run until initialize is completed ***

### STEP 5: Verify It Is Working

/usr/local/bin/tag-automation/main.sh
tail /var/log/tag-automation.log
tail /var/log/tag-automation-summary.log

---

## Removing the Old Standalone Version (If Installed)

If you installed the original standalone script, run these first:

rm -f /usr/local/bin/set-performance.sh
rm -rf /usr/local/etc/set-performance.conf.d
rm -f /etc/cron.hourly/set-performance
rm -f /etc/cron.daily/set-performance
rm -f /etc/cron.weekly/set-performance
rm -f /etc/cron.monthly/set-performance

---

## Directory Structure

/usr/local/
  bin/
    tag-automation/
      main.sh
      modules/
        set-performance.sh
  etc/
    tag-automation/
      conf.d/
        default.conf
        custom.conf

/var/log/
  tag-automation.log
  tag-automation-summary.log

---

## VM Tag Reference

Tag          | CPU Weight | I/O Priority | Use Case
-------------|------------|--------------|-----------------------------
0-core       | 2048       | 7            | Mission-critical VMs
1-high       | 1024       | 7            | High-priority workloads
2-normal     | 256        | 4            | Standard VMs (default tier)
3-low        | 128        | 1            | Dev, test, low-priority VMs

For multi-pool deployments, append your TAG_SUFFIX:
  0-core-1, 1-high-1, 2-normal-1, 3-low-1  (POOL-1)
  0-core-2, 1-high-2, 2-normal-2, 3-low-2  (POOL-2)

---

## Change-Log

v1.1 (Planned)
- sync-vm-metadata.sh: Bulk VM tagging via editable CSV (export / dry-run / sync modes)
- custom.conf: Consolidated all override options into one file (commented by default)
- Module toggle overrides: ENABLE_PERFORMANCE, ENABLE_PERMISSIONS added to custom.conf

v1.0 - 2026-05-16 (Bundle Release)
- Modular Architecture: Repackaged as a modular bundle for easier updates and future plugin development
- One-Shot Installer: install.sh handles directory creation, permissions, and legacy standalone cleanup detection
- Orchestrator: main.sh manages module execution and cron scheduling via symlink -- no manual crontab editing required
- Dual Config System: default.conf (never edit) + custom.conf (your pool settings) -- your settings are preserved on re-install
- NFS Integration: Optional log aggregation for centralized reporting across multiple pools
- Master Host Check: Robust UUID comparison ensures script only runs on the Pool Master -- safe to deploy on all hosts
- Foundation for upcoming Xen Orchestra plugin

v3.2 - 2026-05-14 (Final Standalone Release)
- Fixed Master Host Check: Replaced invalid xe host-is-master with correct UUID comparison method

v3.1 - 2026-05-14
- Config Separation: Moved to conf.d/ override pattern -- split into default.conf and custom.conf

v3.0 - 2026-05-14
- TAG_SUFFIX support for multi-pool deployments
- Auto-scheduling via initialize -- no manual crontab needed

v2.0 - 2026-05-14
- External configuration file
- Master Host Check (first attempt)
- Main log + summary log
- Per-tier summary counters

v1.0 - Initial Release
- Tag-based CPU weight and I/O priority enforcement
- Four tiers: 0-core, 1-high, 2-normal, 3-low
- Network QoS cap (100Mbps) for 3-low tagged VMs

---

"Anything and Everything to make XCP-ng Better" -- it's the Name of the Game!
