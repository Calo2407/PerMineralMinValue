# PerMineralMinValue (Delta-V: Rings of Saturn Mod)

**Per-mineral thresholds for Drones, Manipulator Arm, and On-Board Computer.** This mod replaces the global "Minimum Value" slider with individual tabs, allowing you to set vertical price sliders for every mineral type individually.

## Features
- **Granular Control:** Set unique minimum value thresholds (0–20,000 E$) for every mineral type.
- **System Wide:** Works for **Drones**, the **Docking Arm**, and the **On-Board Computer**.
- **Geologist Sync:** Drones and Autopilot now see the exact same "estimated value" as the player in the HUD. No more discrepancies between what you see and what the drones pick up!
- **Smart Evaluation:** The logic checks the **total displayed value** of an asteroid against your slider.
  - *Example:* If you set Iron (Fe) to 5,000 E$, and an asteroid contains Iron + Water worth 6,000 E$ total, the drone **will** collect it.
- **Native UI:** Adds a clean, tabbed interface to the Geologist panel.

<img width="450" height="300" alt="Global" src="https://github.com/user-attachments/assets/ca40eab1-e90e-4703-a986-faa83ff71e14" />
<img width="450" height="300" alt="Custom" src="https://github.com/user-attachments/assets/e86cf30d-680f-4e07-bf7c-f89fb32c3c38" />

## How it Works
1. **Active Filtering:** Only sliders set above **0 E$** are active. If a slider is at 0, that mineral is treated as "neutral" (vanilla behavior).
2. **Total Value Check:** The mod calculates the **Total Estimated Value** of the asteroid (including water).
3. **Decision Logic:**
   - If an asteroid contains a mineral with an active slider (e.g., Fe > 20k)...
   - ...and the **Total Value** of the rock is higher than 20k...
   - -> **ACCEPTED**.
   - If the rock contains multiple minerals with sliders, it is accepted if it satisfies **at least one** of them.

## Installation (Steam / Retail)
1. Navigate to your game installation directory.
2. Create a folder named `mods` (if it doesn't exist).
3. Download the latest release `.zip` and place it into the `mods` folder.
   - *Note: Do not extract the zip file!*
4. **Steam:**
   - Right-click the game in Steam → **Properties**.
   - In the **General** tab, under "Launch Options", add: `--enable-mods`
5. Launch **ΔV: Rings of Saturn**.

---
*First mod I ever wrote - Feedback and bug reports are welcome*
