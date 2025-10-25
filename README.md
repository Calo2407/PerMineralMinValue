# PerMineralMinValue (Delta-V: Rings of Saturn Mod)

Per-mineral thresholds for drones, manipulator, and on-board computer.  
Adds vertical sliders per mineral and toggles in the **OMS → Geologist** tab.

## Features
- Per-mineral minimum value thresholds (0–20,000 E$ UI; internal scaling handled automatically)
- Drones, Docking Arm, and OBC respect per-mineral thresholds
- Tabbed UI for each system
- *Unmarked* automatically excluded from sliders

<img width="450" height="300" alt="Global" src="https://github.com/user-attachments/assets/ca40eab1-e90e-4703-a986-faa83ff71e14" />
<img width="450" height="300" alt="Custom" src="https://github.com/user-attachments/assets/e86cf30d-680f-4e07-bf7c-f89fb32c3c38" />

## Installation (Steam)
1. Open your game install directory  
2. Create a new folder called `mods`  
3. Place the `.zip` you downloaded into it (don't extract it!)  
4. Right-click on your game in Steam → **Properties...**  
5. In the **General** tab, add this to launch options: `--enable-mods`
6. Launch ΔV: Rings of Saturn

## Known Issues
1. The mod currently uses **actual mineral values** instead of the **geologist’s estimated values**.  
(This means thresholds may not perfectly align with the values shown in the HUD.)  
2. Sliders are **initialized at 0 visually**, but internally start at **1,000 E$**.  
The first interaction with the slider updates the display to match the internal value.

---

*First mod I ever wrote — feedback is very welcome!*
