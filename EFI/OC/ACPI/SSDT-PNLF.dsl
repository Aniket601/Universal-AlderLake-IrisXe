/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20200925 (64-bit version)
 * Copyright (c) 2000 - 2020 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of /Users/ajadhav-mac/lenovo2mac/EFI/OC/ACPI/SSDT-PNLF.aml, Sat Oct 31 16:20:10 2026
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00000090 (144)
 *     Revision         0x02
 *     Checksum         0x41
 *     OEM ID           "CORP"
 *     OEM Table ID     "PNLF"
 *     OEM Revision     0x00000000 (0)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20200925 (538970405)
 */
DefinitionBlock ("", "SSDT", 2, "CORP", "PNLF", 0x00000000)
{
    External (_SB_.PC00.GFX0, DeviceObj)

    Scope (\_SB.PC00.GFX0)
    {
        Device (PNLF)
        {
            Name (_HID, EisaId ("APP0002"))  // _HID: Hardware ID
            Name (_CID, "backlight")  // _CID: Compatible ID
            Name (_UID, 0x13)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (Zero)
                }
            }
        }
    }
}

