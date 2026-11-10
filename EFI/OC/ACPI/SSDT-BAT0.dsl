/*
 * SSDT-BAT0.dsl — Fix Lenovo IdeaPad 3 15IAU7 (BAT0._STA)
 * Fixes AE_AML_UNINITIALIZED_LOCAL in BAT0._STA when ECAV == 0 during early ACPI walk.
 * Preserves original OEM BAT0._STA (renamed to XSTA) for non-Darwin OSes.
 */
DefinitionBlock ("", "SSDT", 2, "CORP", "Bat0Sta", 0x00001000)
{
    External (\ECON, FieldUnitObj)
    External (\_SB.PC00.LPCB.EC0.BA1P, FieldUnitObj)
    External (\_SB.PC00.LPCB.EC0.BAT0, DeviceObj)
    External (\_SB.PC00.LPCB.EC0.BAT0.XSTA, MethodObj)    // 0 Arguments
    External (\_SB.PC00.LPCB.EC0.ECAV, IntObj)
    External (\_SB.PC00.LPCB.EC0.LFCM, MutexObj)

    Scope (\_SB.PC00.LPCB.EC0.BAT0)
    {
        Method (_STA, 0, NotSerialized)  // _STA: Status
        {
            If (_OSI ("Darwin"))
            {
                If ((\ECON == One))
                {
                    If (\_SB.PC00.LPCB.EC0.ECAV)
                    {
                        If ((Acquire (\_SB.PC00.LPCB.EC0.LFCM, 0xA000) == Zero))
                        {
                            Local0 = \_SB.PC00.LPCB.EC0.BA1P
                            Release (\_SB.PC00.LPCB.EC0.LFCM)
                            If ((Local0 & One))
                            {
                                Return (0x1F)
                            }
                            Else
                            {
                                Return (0x0F)
                            }
                        }
                    }

                    Return (0x1F)
                }
                Else
                {
                    Return (Zero)
                }
            }
            Else
            {
                Return (\_SB.PC00.LPCB.EC0.BAT0.XSTA ())
            }
        }
    }
}

