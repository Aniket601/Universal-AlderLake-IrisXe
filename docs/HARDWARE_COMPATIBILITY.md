# Hardware Compatibility Matrix

This document tracks verified and spec-matched Intel 12th Gen (Alder Lake) and 13th Gen (Raptor Lake) laptops running macOS with full hardware acceleration under **Universal-AlderLake-IrisXe**.

---

## 🏆 Tier 1: Golden Reference (100% Physically Verified)

These models have been tested live on physical silicon by the project maintainers with complete hardware functionality verified.

| Model | CPU & iGPU | Audio Codec | Wi-Fi / BT | Trackpad | macOS Tested | Maintainer / Tester | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Lenovo IdeaPad 3 15IAU7** (Type 82RK) | Intel Core i5-1235U (10C)<br>Iris Xe `0x46A8` | Realtek ALC257 (`alcid=100`) | Realtek RTL8852BE Wi-Fi 6 + BT 5.2 | ELAN06FA I2C Precision (`-vi2c-force-polling`) | **Tahoe 26.7.1**<br>Ventura 13.7.8 | [@Aniket601](https://github.com/Aniket601) | 🟢 **100% Working** |

### Verified Hardware Subsystems on Reference Model:
- **GPU:** Intel Iris Xe (`0x46A8`), Metal 2 Acceleration, 1536 MB VRAM, 1080p 60Hz internal display.
- **CPU:** 10 Cores (2 Performance + 8 Efficiency, 12 Threads) via `SSDT-PLUG-ALT.aml` + `CpuTscSync`.
- **Audio:** Internal Speakers, Microphone, and 3.5mm Combo Jack via `AppleALC` + `SimpleHDA`.
- **Wi-Fi:** 802.11ax 1200 Mbps via `AirportRTW-Tahoe.kext`.
- **Bluetooth:** Native pairing & audio streaming via `RealtekBluetoothFirmware` + `BlueToolFixup`.
- **Trackpad:** Full macOS multi-touch gestures, tap-to-click, and physical click via `VoodooI2C` [PR #588](https://github.com/VoodooI2C/VoodooI2C/pull/588).
- **Power & Sleep:** Instant lid-close display sleep, 20-second fast-boot, Celxpert battery telemetry.
- **Apple Services:** iMessage, FaceTime, APNS, and App Store via LinkQuality keepalive watchdog.

---

## 🟡 Tier 2: OEM Spec-Matched Models (Ready for Community Testing)

The Universal Alder Lake Core Engine (CPU topology + Iris Xe Metal 2 acceleration) is silicon-identical across all 12th Gen processors. These OEM models are pre-configured with factory hardware mappings and are ready for community verification.

| Model Family | CPU Options | Factory Audio | Factory Wi-Fi | Recommended Preset | Testing Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Dell Inspiron 15 (3520 / 3530)** | i3-1215U / i5-1235U / i7-1255U | Realtek ALC256 (`alcid=13` or `21`) | Intel Wi-Fi 6 AX201 / Realtek | `dell` | 🟡 Spec-Matched |
| **Dell Vostro 3520 / 3420** | i5-1235U / i7-1255U | Realtek ALC256 (`alcid=13`) | Intel AX201 | `dell` | 🟡 Spec-Matched |
| **HP Pavilion 14 / 15 (eg2000)** | i5-1235U / i7-1255U | Realtek ALC236 (`alcid=3`) | Intel AX201 / Realtek RTL8821 | `hp` | 🟡 Spec-Matched |
| **HP 250 G9 / 15s** | i3-1215U / i5-1235U | Realtek ALC236 (`alcid=3`) | Realtek RTL8822CE / RTL8852BE | `hp` | 🟡 Spec-Matched |
| **Asus Vivobook 14 / 15 (X1402 / X1502)** | i5-1235U / i7-1255U | Realtek ALC256 (`alcid=13` or `11`) | Intel AX201 / MediaTek | `asus` | 🟡 Spec-Matched |
| **Asus ZenBook 14 (UX3402)** | i5-1240P / i7-1260P | Realtek ALC294 (`alcid=22`) | Intel AX211 Wi-Fi 6E | `asus` | 🟡 Spec-Matched |
| **Acer Aspire 5 (A515-57)** | i5-1235U / i7-1260P | Realtek ALC255 (`alcid=11` or `28`) | Intel AX201 | `generic` | 🟡 Spec-Matched |

---

## 🤝 How to Submit Your Tested Model

If you have booted macOS on an Alder Lake or Raptor Lake laptop using this universal repository:
1. Open a new verification report using the **[Model Verification Template](https://github.com/Aniket601/Universal-AlderLake-IrisXe/issues/new?template=model-verification.yml)**.
2. Attach your `IORegistry` dump or `About This Mac` screenshot showing Iris Xe Metal acceleration.
3. Your hardware will be promoted to **Tier 1 Verified** with full attribution to your GitHub profile!

