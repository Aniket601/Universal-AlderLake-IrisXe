# How to Adapt this EFI for Any Alder Lake Laptop

Intel 12th Gen (Alder Lake) and 13th Gen (Raptor Lake) laptops share the **exact same fundamental CPU architecture and Iris Xe integrated GPU silicon die** (`0x46A8`). 

Because the core graphics acceleration and CPU power management engines are completely universal, adapting this EFI for an unlisted laptop requires adjusting only **3 hardware-specific subsystems**:

---

## 3-Step Adaptation Process

```
Step 1: Audio Codec (alcid) ──> Step 2: Trackpad (I2C/PS2) ──> Step 3: Wi-Fi / Bluetooth
```

---

### Step 1: Find & Set Your Audio Layout ID (`alcid`)
Different laptop manufacturers wire the Realtek High Definition Audio codec pins differently.

1. **Find your Audio Codec:**
   - Under Windows: Open Device Manager ➔ Sound controllers ➔ Hardware IDs (e.g. `VEN_10EC&DEV_0256` = Realtek ALC256).
   - Under Linux: Run `cat /proc/asound/card0/codec#0 | grep Codec`.
2. **Find Recommended `alcid`:**
   - Common Layouts:
     - **ALC256 / ALC3246 (Dell/Asus):** `11`, `13`, `21`, `28`
     - **ALC236 (HP):** `3`, `5`, `11`
     - **ALC257 (Lenovo):** `100`, `99`, `11`
     - **ALC295 (HP Envy / Dell XPS):** `15`, `28`, `77`
3. **Apply via CLI Builder:**
   ```bash
   python3 tools/alderlake-builder.py --brand generic --alcid 13
   ```

---

### Step 2: Trackpad Controller Configuration
Most modern 12th Gen laptops connect the precision touchpad over **Intel LPSS I2C** (`pci8086,51e9` or `51ea`).

- **Force Polling Boot-Arg:**
  Alder Lake PCH chipsets often do not route GPIO hardware interrupts cleanly to macOS. As documented by Aniket Jadhav in [VoodooI2C PR #588](https://github.com/VoodooI2C/VoodooI2C/pull/588), add `-vi2c-force-polling` to `boot-args` in `config.plist`.
- **Kexts Required:**
  - `VoodooI2C.kext` + `VoodooI2CHID.kext` (for standard Windows Precision touchpads).
  - `VoodooPS2Controller.kext` (for keyboard & physical clickpads).

---

### Step 3: Wi-Fi & Bluetooth Controller
Match your pre-installed M.2 or soldered Wi-Fi card:

- **Intel Wi-Fi 6 (AX201 / AX211 / AX200):**
  - Use `AirportItlwm.kext` (matching your macOS version) or `itlwm.kext` + HeliPort.
  - Enable `IntelBluetoothFirmware.kext` + `BlueToolFixup.kext`.
- **Realtek Wi-Fi 6 (RTL8852BE / RTL8852AE):**
  - Use `AirportRTW.kext` (Ventura) or `AirportRTW-Tahoe.kext` (Tahoe).
  - Use `RealtekBluetoothFirmware.kext` + `BlueToolFixup.kext` with `-btlfxboardid`.
- **Broadcom (Native / OCLP patched):**
  - Disable third-party Wi-Fi kexts.

---

## Testing & Verifying Your Build

1. Build your custom EFI:
   ```bash
   python3 tools/alderlake-builder.py
   ```
2. Generate your SMBIOS using [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) with model **`MacBookPro16,2`**.
3. Copy to USB EFI partition and boot!

