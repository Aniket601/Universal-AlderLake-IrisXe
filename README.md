# Universal-AlderLake-IrisXe

[![Maintainer](https://img.shields.io/badge/Maintainer-Aniket%20Jadhav-0A66C2?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/meaniikett/)
[![GitHub](https://img.shields.io/badge/GitHub-Aniket601-181717?logo=github&logoColor=white)](https://github.com/Aniket601)
[![VoodooI2C Contributor](https://img.shields.io/badge/VoodooI2C-Contributor%20(PR%20%23588)-purple?logo=github)](https://github.com/VoodooI2C/VoodooI2C/pull/588)
[![WhateverXe Validated](https://img.shields.io/badge/WhateverXe-Validated%20(Issue%20%2364)-blue?logo=github)](https://github.com/b00t0x/WhateverXe/issues/64)
[![OpenCore](https://img.shields.io/badge/OpenCore-1.0.8-black)](https://github.com/acidanthera/OpenCorePkg)
![macOS Tahoe](https://img.shields.io/badge/macOS-Tahoe%2026.x-blue?logo=apple)
![macOS Sonoma](https://img.shields.io/badge/macOS-Sonoma%2014.x-informational?logo=apple)
![macOS Ventura](https://img.shields.io/badge/macOS-Ventura%2013.x-informational?logo=apple)
![Metal 2](https://img.shields.io/badge/Iris%20Xe-Metal%202%20Acceleration-success)
[![License](https://img.shields.io/badge/License-BSD%203--Clause-green)](LICENSE)

The **Universal OpenCore EFI Generator, Preconfigured Base & Definitive Guide** for running macOS on **Intel 12th Gen (Alder Lake)** and **13th Gen (Raptor Lake)** laptops featuring **Intel Iris Xe Graphics (`0x46A8`)** with full Metal 2 hardware graphics acceleration.

Supports **Lenovo, Dell, HP, Asus, Acer**, and custom Alder Lake laptops through a modular architecture and an interactive CLI builder.

---

## 💡 The Core Philosophy: "Alder Lake is NOT Impossible"

For years, the Hackintosh community considered Intel 11th Gen (Tiger Lake) and 12th Gen (Alder Lake) laptops impossible to run with hardware acceleration due to Apple never releasing an Intel Mac with Iris Xe graphics.

**This repository proves that wrong.**

Using the groundbreaking `WhateverXe` graphics stack paired with `SSDT-PLUG-ALT` Big.LITTLE CPU topology scheduling, Intel 12th Gen Alder Lake laptops achieve:
* **Metal 2 Hardware Acceleration** (1536 MB VRAM, smooth window animations, 60fps UI).
* **Native 10-core / 12-core Scheduling** (P-cores + E-cores managed efficiently).
* **Full Apple Ecosystem Services** (iMessage, FaceTime, APNS via LinkQuality watchdog).
* **Instant Lid-Close Sleep** without Modern Standby S0ix kernel stalls.

```
       ┌────────────────────────────────────────────────────────┐
       │   Universal Alder Lake Core Engine (100% Shared)        │
       │   • CPU Topology & Big.LITTLE (SSDT-PLUG-ALT)          │
       │   • Intel Iris Xe Metal 2 Acceleration (WhateverXe)     │
       │   • ACPI Timers, Power & USB Architecture              │
       └──────────────────────────┬─────────────────────────────┘
                                  │
          ┌───────────────────────┼────────────────────────┐
          ▼                       ▼                        ▼
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│  Lenovo Preset   │    │   Dell Preset    │    │    HP Preset     │
│ • ALC257 (100)   │    │ • ALC256 (13/21) │    │ • ALC236 (3)     │
│ • ELAN06FA I2C   │    │ • Dell I2C / PS2 │    │ • Synaptics I2C  │
│ • Realtek 8852BE │    │ • Intel AX201/211│    │ • Intel / Realtek│
│ (Tier 1 Verified)│    │ (Tier 2 Spec)    │    │ (Tier 2 Spec)    │
└──────────────────┘    └──────────────────┘    └──────────────────┘
```

---

## ⚡ Quick Start: Generate Your Tailored EFI in 60 Seconds

No need to manually edit dozens of plist keys. Use our zero-dependency Python builder:

```bash
# 1. Clone the repository
git clone https://github.com/Aniket601/Universal-AlderLake-IrisXe.git
cd Universal-AlderLake-IrisXe

# 2. Run the interactive configurator
python3 tools/alderlake-builder.py
```

### Or Use Direct One-Line Arguments:
```bash
# Generate for Dell Inspiron 15 (ALC256 + Intel AX201):
python3 tools/alderlake-builder.py --brand dell --wifi intel --alcid 13

# Generate for HP Pavilion (ALC236 + Intel AX201):
python3 tools/alderlake-builder.py --brand hp --wifi intel --alcid 3

# Generate for Lenovo IdeaPad (ALC257 + Realtek 8852BE):
python3 tools/alderlake-builder.py --brand lenovo --wifi realtek --alcid 100
```

The tool generates a clean, validated `build/EFI/` ready to copy to your USB or SSD EFI System Partition!

---

## 📋 Hardware Compatibility Matrix

| Tier | Status | Supported Laptops & Specs |
| :--- | :--- | :--- |
| **Tier 1: Golden Reference** | 🟢 **100% Verified** | **Lenovo IdeaPad 3 15IAU7 (Type 82RK)** — Tested live on physical silicon by maintainer [@Aniket601](https://github.com/Aniket601). Metal 2 Iris Xe, 1080p display, internal audio/mic, ELAN trackpad, Wi-Fi 6, battery telemetry verified on **macOS Tahoe 26.7.1**. |
| **Tier 2: OEM Spec-Matched** | 🟡 **Spec-Matched** | **Dell Inspiron 15 (3520/5520)**, **Vostro 3520** (ALC256, AX201)<br>**HP Pavilion 14/15 (eg2000)**, **HP 250 G9** (ALC236, AX201/RTL8852)<br>**Asus Vivobook 14/15 (X1402/X1502)**, **ZenBook 14** (ALC256/ALC294) |
| **Tier 3: Universal Base** | 🔵 **Custom** | Any unlisted Intel 12th/13th Gen laptop using our [Adaptation Guide](docs/HOW_TO_ADAPT.md). |

👉 See the complete [**Hardware Compatibility Matrix & Verified Community Models**](docs/HARDWARE_COMPATIBILITY.md).

---

## 🛠️ Post-Install Stability Suite (`scripts/post-install.sh`)

After booting into macOS, run the automated post-install script to protect your system from silent crashes and breakages:

```bash
sudo ./scripts/post-install.sh all
```

### What It Automates:
1. **APNS & iMessage / FaceTime Fix:** Creates a persistent non-locking launchd watchdog ensuring `LinkQuality = 100` on the active Wi-Fi adapter.
2. **S0ix Modern Standby Sleep Protection:** Enforces `disablesleep 1` so closing the lid turns off the internal display cleanly without freezing or panicking the GPU.
3. **Silent OS Update Guard:** Disables unattended point-release downloads to prevent `/Library/Extensions` graphics acceleration kexts from being overwritten, while keeping Apple's XProtect/MRT definitions active.
4. **VideoToolbox Metal Fallback:** Eliminates Photo Booth and FaceTime `SIGSEGV` crashes.
5. **Live Hardware Telemetry:** Displays Iris Xe Metal acceleration status, battery health, cycle count, and temperature.

👉 Read the full [**Post-Install & Hardening Guide**](docs/POST_INSTALL.md).

---

## 🤝 Contributing & Community Hardware Verification

Do you own an Intel 12th Gen or 13th Gen laptop? Help expand the universal matrix!
* Use our **[Model Verification Issue Template](https://github.com/Aniket601/Universal-AlderLake-IrisXe/issues/new?template=model-verification.yml)** to submit your hardware specs and success report.
* Submissions are tested and promoted to **Tier 1 Verified** with permanent attribution to your name/handle in the README!

---

## 👤 Maintainer

**Aniket Jadhav** ([@Aniket601](https://github.com/Aniket601))
* **LinkedIn:** [linkedin.com/in/meaniikett](https://www.linkedin.com/in/meaniikett/)
* **GitHub:** [@Aniket601](https://github.com/Aniket601)
* **Role:** Security & Systems Engineer | Low-Level Kernel / OS & Threat Research
* **Upstream Contributions:**
  * [VoodooI2C/VoodooI2C #588](https://github.com/VoodooI2C/VoodooI2C/pull/588) (documented `-vi2c-force-polling` & `force-polling`)
  * [b00t0x/WhateverXe #64](https://github.com/b00t0x/WhateverXe/issues/64) (Alder Lake Iris Xe validation & resolution)

---

## 📄 License
This project is licensed under the [BSD 3-Clause License](LICENSE).

## 🙏 Acknowledgements
* [Acidanthera](https://github.com/acidanthera) for OpenCorePkg, Lilu, AppleALC, VirtualSMC, and BlueToolFixup.
* [b00t0x](https://github.com/b00t0x) for `WhateverXe` & `CpuTopologyRebuild` — special validation in [Issue #64](https://github.com/b00t0x/WhateverXe/issues/64).
* [VoodooI2C Team](https://github.com/VoodooI2C/VoodooI2C) for precision touchpad drivers.
* [williambj1](https://github.com/williambj1/AirportRTW) for `AirportRTW`.
* [laobamac](https://github.com/laobamac) for `SimpleHDA` on macOS Tahoe.

