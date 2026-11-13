# Ghidra-RH850 (Zeekr_RH850)

Renesas RH850 processor module (SLEIGH) for Ghidra.
Fork of [ZEEKRZERO/Ghidra-RH850](https://github.com/ZEEKRZERO/Ghidra-RH850), packaged so it installs
cleanly on Ghidra 12.

Language ID: `RH850:LE:32:default`

## Install (ติดตั้ง)

1. Download the zip that matches **your exact Ghidra version** from
   [Releases](https://github.com/AlexDev-TH/Ghidra-RH850/releases)
   (for example `ghidra_12.1.4_PUBLIC_..._Zeekr_RH850.zip` for Ghidra 12.1.4).
   ดาวน์โหลดไฟล์ zip ที่ตรงกับเวอร์ชัน Ghidra ของคุณ (ต้องตรงทุกหลัก)
2. Ghidra: **File > Install Extensions > +** and pick the zip, then restart Ghidra.
   หรือแตกไฟล์ zip ไปไว้ที่ `<Ghidra>\Ghidra\Extensions\` (จะได้โฟลเดอร์ `Zeekr_RH850`)
3. Import a firmware file and choose Language `RH850:LE:32:default`.
   ตอน Import ให้กด Language `...` แล้วค้นหา `RH850`

Ghidra refuses extensions built for a different version, and the compiled `.sla` format is tied to
the Ghidra release. If there is no zip for your version, build one (below).

## Build (สร้างไฟล์ release เอง)

Requires the target Ghidra installation and a JDK 21+.

```powershell
.\build-release.ps1 -GhidraDir "C:\path\to\ghidra_12.1.4_PUBLIC"
# -> dist\ghidra_12.1.4_PUBLIC_<date>_Zeekr_RH850.zip
```

The script stages the module, sets `extension.properties` to the Ghidra version, compiles
`RH850.slaspec` with that Ghidra's `support\sleigh.bat`, and zips it in the layout the
Install Extensions dialog expects.

## Changes from upstream

- `extension.properties`: real extension name (`Zeekr_RH850`); version is filled in at build time.
- `data/manuals/RH850.idx`: added where `RH850.ldefs` looks for it (`../manuals/RH850.idx`).
- Removed the prebuilt `RH850.sla` (compiled by a 2022 Ghidra, rejected by Ghidra 11+); `.sla`
  files are now always produced by the build.
- Added `build-release.ps1`.

## Notes

The upstream project covers a large part of the RH850 instruction set but is not complete.
Check unexpected decoding against the RH850 software manual for your core (G3K/G3M/G3KH/G4MH).

Upstream repository: https://github.com/ZEEKRZERO/Ghidra-RH850 (all credit for the SLEIGH
specification goes to its author).
