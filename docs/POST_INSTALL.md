# Post-Install Stability & Hardening Guide

After booting macOS with **Universal-AlderLake-IrisXe**, complete these essential post-install configurations to ensure rock-solid stability and prevent silent breakdown vectors.

---

## ⚡ Automated Setup: `scripts/post-install.sh`

The fastest way to harden your system is running the included automated post-install stability CLI suite:

```bash
# Run locally from repository:
sudo ./scripts/post-install.sh all

# Or inspect live hardware telemetry:
./scripts/post-install.sh --diag
```

---

## 🛡️ Critical Post-Install Hardening Modules

### 1. Apple Push Service (APNS) & iMessage LinkQuality Fix
* **The Problem:** Third-party Wi-Fi drivers (like `AirportRTW`) report `LinkQuality : -2` to the Dynamic Store on macOS Sonoma & Tahoe. This causes `apsd` (Apple Push Service Daemon) to suspend connections with the error:
  `Choosing not to resume keep alive in reconnect mode since interface is networking power expensive to use`.
* **The Fix:** A lightweight LaunchDaemon (`com.hackintosh.fix-linkquality.plist`) ensures `LinkQuality = 100` via non-locking atomic transactions, keeping iMessage, FaceTime, and APNS connected 24/7 without needing an iPhone.

---

### 2. S0ix Modern Standby Power Management & Freeze Prevention
* **The Problem:** Modern PC laptops (12th Gen onwards) only implement ACPI S0ix (Modern Standby) in BIOS, omitting legacy S3 deep sleep. Deep idle sleep states can panic the WindowServer or GPU accelerator.
* **The Fix:** Enforce display-off on lid-close without system freeze:
  ```bash
  sudo pmset -a disablesleep 1 sleep 0 hibernatemode 0 standby 0 autopoweroff 0 tcpkeepalive 1
  ```

---

### 3. Safeguard `/Library/Extensions` Against Silent OS Updates
* **The Problem:** `WhateverXe-Graphics` operates companion acceleration kexts in `/Library/Extensions/`. If macOS silently installs an unattended minor point update (e.g. from 26.7.1 to 26.7.2), the graphics stack will be overwritten, causing a black screen on reboot.
* **The Fix:** Disable automatic background downloads while keeping Apple's malware definitions (XProtect/MRT) active:
  ```bash
  sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
  sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false
  sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
  sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true
  ```

---

### 4. VideoToolbox Metal Fallback (Photo Booth / FaceTime Fix)
* **The Problem:** `AppleIntelTGLGraphicsVADriver.bundle` can crash with `SIGSEGV` inside `AVFPixelProcess_PrepareToTransferImages` when hardware GVA pixel transfer is selected.
* **The Fix:** Apply system-wide VideoToolbox Metal fallback:
  ```bash
  sudo defaults write /Library/Preferences/com.apple.coremedia.plist allowHardwareTransferSession -bool false
  sudo defaults write /Library/Preferences/com.apple.coremedia.plist enableGVATransfer -bool false
  sudo chmod 644 /Library/Preferences/com.apple.coremedia.plist
  ```

---

### 5. Battery Longevity: Enable Hardware Conservation Mode
If you leave your laptop plugged into AC power for extended periods, Li-ion batteries degrade rapidly if kept at 100% state-of-charge.
* **Lenovo:** Enable **Conservation Mode** in Lenovo Vantage (caps charge at 60-80% at the Embedded Controller hardware level).
* **Dell:** Enable **Primarily AC Use** in Dell Command | Power Manager or BIOS.
* **Asus:** Enable **Battery Health Charging** (Maximum Lifespan mode) in MyASUS or BIOS.

