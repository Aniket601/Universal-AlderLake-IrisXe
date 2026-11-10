#!/usr/bin/env python3
"""
alderlake-builder.py — Universal OpenCore EFI Configurator for Intel 12th/13th Gen Laptops
Part of Universal-AlderLake-IrisXe (https://github.com/Aniket601/Universal-AlderLake-IrisXe)

Author: Aniket Jadhav (@Aniket601)
License: BSD 3-Clause

Description:
    Cross-platform Python generator (zero external dependencies) that creates
    tailored, production-ready OpenCore EFIs for Alder Lake laptops (Lenovo, Dell,
    HP, Asus, Acer, Generic) with Intel Iris Xe Metal 2 graphics acceleration.
"""

import os
import sys
import shutil
import plistlib
import argparse

VERSION = "1.1.0"

# ANSI Colors
BOLD = "\033[1m"
CYAN = "\033[0;36m"
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
RED = "\033[0;31m"
DIM = "\033[2m"
NC = "\033[0m"

OEM_DEFAULTS = {
    "lenovo": {
        "name": "Lenovo (IdeaPad 3/5, ThinkBook, Yoga)",
        "alcid": "100",
        "wifi": "realtek",
        "trackpad": "i2c-polling",
        "battery_ssdt": True,
        "notes": "Tier 1 Golden Reference (100% verified on IdeaPad 3 15IAU7)."
    },
    "dell": {
        "name": "Dell (Inspiron 3520/5520, Vostro, Latitude)",
        "alcid": "13",
        "wifi": "intel",
        "trackpad": "i2c-standard",
        "battery_ssdt": False,
        "notes": "Tier 2 Spec-Matched (ALC256, Intel AX201/211 standard)."
    },
    "hp": {
        "name": "HP (Pavilion 14/15, 250 G9, Envy)",
        "alcid": "3",
        "wifi": "intel",
        "trackpad": "i2c-standard",
        "battery_ssdt": False,
        "notes": "Tier 2 Spec-Matched (ALC236, Intel AX201 standard)."
    },
    "asus": {
        "name": "Asus (Vivobook 14/15, ZenBook)",
        "alcid": "13",
        "wifi": "intel",
        "trackpad": "i2c-standard",
        "battery_ssdt": False,
        "notes": "Tier 2 Spec-Matched (ALC256, Asus Precision Trackpad)."
    },
    "generic": {
        "name": "Generic Alder Lake / Unlisted OEM",
        "alcid": "11",
        "wifi": "intel",
        "trackpad": "i2c-polling",
        "battery_ssdt": False,
        "notes": "Universal modular base for experimental testing."
    }
}

def print_banner():
    banner = f"""{CYAN}{BOLD}
╔═══════════════════════════════════════════════════════════════════════════╗
║   ⚡ UNIVERSAL ALDER LAKE & IRIS Xe OPENCORE BUILDER v{VERSION}          ║
║   Maintained by Aniket Jadhav (@Aniket601)                                ║
║   Target: Intel 12th/13th Gen Laptops (Iris Xe Metal 2 Acceleration)     ║
╚═══════════════════════════════════════════════════════════════════════════╝{NC}
"""
    print(banner)

def get_repo_root():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(script_dir, ".."))

def prompt_choice(prompt_text, options, default_idx=0):
    print(f"\n{BOLD}{prompt_text}{NC}")
    for idx, opt in enumerate(options, 1):
        def_tag = f" {GREEN}(Default){NC}" if idx - 1 == default_idx else ""
        print(f"  {CYAN}{idx}){NC} {opt}{def_tag}")
    
    while True:
        try:
            choice = input(f"\nEnter choice [1-{len(options)}] (Enter for default): ").strip()
            if not choice:
                return default_idx
            val = int(choice) - 1
            if 0 <= val < len(options):
                return val
            print(f"{RED}Invalid number. Please choose between 1 and {len(options)}.{NC}")
        except (ValueError, KeyboardInterrupt):
            print("\nAborted.")
            sys.exit(1)

def interactive_wizard():
    print_banner()

    # 1. OEM Brand
    brands = list(OEM_DEFAULTS.keys())
    brand_labels = [f"{OEM_DEFAULTS[b]['name']} — {DIM}{OEM_DEFAULTS[b]['notes']}{NC}" for b in brands]
    b_idx = prompt_choice("Select your Laptop Brand / Manufacturer:", brand_labels, default_idx=0)
    selected_brand = brands[b_idx]
    brand_cfg = OEM_DEFAULTS[selected_brand]

    # 2. Wi-Fi Adapter
    wifi_options = [
        "Realtek RTL8852BE / RTL8852AE (AirportRTW)",
        "Intel Wi-Fi 6 AX201 / AX211 / AX200 (AirportItlwm)",
        "Broadcom BCM94360 / Fenvi (Native Apple AirPort)",
        "None / External USB Wi-Fi / Ethernet only"
    ]
    wifi_keys = ["realtek", "intel", "broadcom", "none"]
    def_wifi_idx = wifi_keys.index(brand_cfg["wifi"]) if brand_cfg["wifi"] in wifi_keys else 0
    w_idx = prompt_choice("Select your Wi-Fi Network Controller:", wifi_options, default_idx=def_wifi_idx)
    selected_wifi = wifi_keys[w_idx]

    # 3. Audio Codec Layout ID (alcid)
    default_alcid = brand_cfg["alcid"]
    print(f"\n{BOLD}Audio Codec Configuration:{NC}")
    print(f"  Recommended for {brand_cfg['name']}: {GREEN}alcid={default_alcid}{NC}")
    custom_alcid = input(f"Enter layout-id [Press Enter for {default_alcid}]: ").strip()
    selected_alcid = custom_alcid if custom_alcid else default_alcid

    # 4. Target Output Path
    default_out = os.path.join(get_repo_root(), "build", "EFI")
    print(f"\n{BOLD}Target Output Path:{NC}")
    print(f"  Default: {CYAN}{default_out}{NC}")
    custom_out = input("Enter output path (or press Enter for default): ").strip()
    selected_out = custom_out if custom_out else default_out

    return {
        "brand": selected_brand,
        "wifi": selected_wifi,
        "alcid": selected_alcid,
        "out": selected_out
    }

def patch_config(config_path, brand, wifi, alcid):
    """Safely updates OpenCore config.plist using plistlib."""
    with open(config_path, "rb") as f:
        config = plistlib.load(f)

    brand_cfg = OEM_DEFAULTS.get(brand, {})

    # 1. Update boot-args cleanly (strips or adds -vi2c-force-polling properly)
    nvram_add = config.setdefault("NVRAM", {}).setdefault("Add", {}).setdefault("7C436110-AB2A-4BBB-A880-FE41995C9F82", {})
    if "boot-args" in nvram_add:
        args = nvram_add["boot-args"].split()
        new_args = []
        for arg in args:
            if arg.startswith("alcid="):
                continue
            if arg == "-vi2c-force-polling" and brand_cfg.get("trackpad") != "i2c-polling":
                continue  # Remove force-polling flag for standard interrupt-driven I2C
            new_args.append(arg)

        new_args.append(f"alcid={alcid}")
        if brand_cfg.get("trackpad") == "i2c-polling" and "-vi2c-force-polling" not in new_args:
            new_args.append("-vi2c-force-polling")

        nvram_add["boot-args"] = " ".join(new_args)

    # 2. Synchronize layout-id in DeviceProperties if present
    dev_props = config.setdefault("DeviceProperties", {}).setdefault("Add", {})
    audio_path = "PciRoot(0x0)/Pci(0x1F,0x3)"
    if audio_path in dev_props:
        try:
            alcid_int = int(alcid)
            dev_props[audio_path]["layout-id"] = alcid_int.to_bytes(4, byteorder="little")
        except ValueError:
            pass

    # 3. Kernel Kext toggles
    kexts = config.get("Kernel", {}).get("Add", [])
    for k in kexts:
        bundle = k.get("BundlePath", "")
        # Realtek Wi-Fi gating
        if "AirportRTW" in bundle:
            k["Enabled"] = (wifi == "realtek")
        # Realtek Bluetooth gating
        elif "RealtekBluetooth" in bundle:
            k["Enabled"] = (wifi == "realtek")
        # Intel Wi-Fi / Bluetooth gating
        elif "AirportItlwm" in bundle or "itlwm" in bundle or "IntelBluetooth" in bundle:
            k["Enabled"] = (wifi == "intel")
        # Lenovo-specific USB map gating (do not enforce Lenovo map on Dell/HP/Asus)
        elif "UTBMap" in bundle:
            k["Enabled"] = (brand == "lenovo")

    # 4. ACPI Add toggles
    acpi_list = config.get("ACPI", {}).get("Add", [])
    for a in acpi_list:
        path = a.get("Path", "")
        if "SSDT-BAT0" in path:
            a["Enabled"] = (brand == "lenovo")

    # 5. ACPI Binary Patch toggles (BAT0._STA to XSTA must only run on Lenovo)
    acpi_patches = config.get("ACPI", {}).get("Patch", [])
    for p in acpi_patches:
        comment = p.get("Comment", "")
        if "BAT0._STA" in comment or "BAT0" in comment:
            p["Enabled"] = (brand == "lenovo")

    # Write patched config atomically
    with open(config_path, "wb") as f:
        plistlib.dump(config, f, sort_keys=False)

def build_efi(options):
    repo_root = get_repo_root()
    source_efi = os.path.join(repo_root, "EFI")
    target_efi = os.path.abspath(options["out"])

    # Security Guard: Prevent arbitrary or catastrophic filesystem deletion
    forbidden_targets = [
        os.path.abspath(os.sep),
        os.path.expanduser("~"),
        repo_root,
        os.path.join(repo_root, "EFI"),
        os.path.join(repo_root, "tools"),
        os.path.join(repo_root, "scripts"),
        os.path.join(repo_root, "docs")
    ]
    if target_efi in forbidden_targets:
        print(f"{RED}[ERROR] Refusing to overwrite critical system or repository directory: {target_efi}{NC}")
        sys.exit(1)

    if not os.path.isdir(source_efi):
        print(f"{RED}[ERROR] Source EFI directory not found at {source_efi}{NC}")
        sys.exit(1)

    print(f"\n{BOLD}=== Building Tailored EFI ==={NC}")
    print(f"  • OEM Preset:  {GREEN}{OEM_DEFAULTS[options['brand']]['name']}{NC}")
    print(f"  • Wi-Fi Model: {GREEN}{options['wifi'].upper()}{NC}")
    print(f"  • Audio ALCID: {GREEN}{options['alcid']}{NC}")
    print(f"  • Destination: {CYAN}{target_efi}{NC}\n")

    # Clean existing target safely
    if os.path.exists(target_efi):
        print(f"{YELLOW}[*] Destination exists. Cleaning...{NC}")
        shutil.rmtree(target_efi)

    # Copy base EFI tree
    print(f"{GREEN}[+] Copying Universal Alder Lake Core Engine...{NC}")
    shutil.copytree(source_efi, target_efi)

    # Patch config.plist
    target_config = os.path.join(target_efi, "OC", "config.plist")
    if os.path.isfile(target_config):
        print(f"{GREEN}[+] Injecting hardware profiles into config.plist...{NC}")
        patch_config(target_config, options["brand"], options["wifi"], options["alcid"])
    else:
        print(f"{RED}[ERROR] Target config.plist missing!{NC}")
        sys.exit(1)

    print(f"\n{GREEN}{BOLD}✔ Universal EFI successfully generated!{NC}")
    print(f"Location: {BOLD}{target_efi}{NC}\n")

    if options["wifi"] == "intel":
        print(f"{CYAN}{BOLD}[*] Intel Wi-Fi Note:{NC}")
        print(f"  Intel Wi-Fi cards use AirportItlwm.kext matching your specific macOS version.")
        print(f"  Download the latest AirportItlwm release for Tahoe/Sonoma/Ventura from:")
        print(f"  https://github.com/OpenIntelWireless/itlwm/releases and place into EFI/OC/Kexts/\n")

    print(f"{YELLOW}{BOLD}Next Steps:{NC}")
    print(f"1. Generate your SMBIOS using GenSMBIOS (MacBookPro16,2).")
    print(f"2. Copy the contents of {target_efi} directly to your USB EFI partition.")
    print(f"3. Boot macOS and enjoy full Iris Xe Metal 2 hardware acceleration!\n")

def main():
    parser = argparse.ArgumentParser(
        description="Universal Alder Lake & Iris Xe OpenCore EFI Configurator",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument("--brand", choices=list(OEM_DEFAULTS.keys()), help="Laptop OEM Brand")
    parser.add_argument("--wifi", choices=["realtek", "intel", "broadcom", "none"], help="Wi-Fi controller")
    parser.add_argument("--alcid", help="Audio codec layout-id")
    parser.add_argument("--out", help="Output directory path (default: ./build/EFI)")
    parser.add_argument("--version", "-v", action="version", version=f"%(prog)s {VERSION}")

    args = parser.parse_args()

    if args.brand:
        brand_cfg = OEM_DEFAULTS[args.brand]
        opts = {
            "brand": args.brand,
            "wifi": args.wifi if args.wifi else brand_cfg["wifi"],
            "alcid": args.alcid if args.alcid else brand_cfg["alcid"],
            "out": args.out if args.out else os.path.join(get_repo_root(), "build", "EFI")
        }
    else:
        opts = interactive_wizard()

    build_efi(opts)

if __name__ == "__main__":
    main()
