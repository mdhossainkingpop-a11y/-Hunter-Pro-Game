# WORLD LIFE 3D — v0.10

## Phase 5: Gameplay

- Mission manager with three sequential missions:
  1. Airport Recon — reach the airport runway area.
  2. Supply Run — collect the three supply crates.
  3. Harbour Delivery — reach the port area.
- Cash and XP rewards on mission completion.
- Player level progression; XP thresholds scale with level.
- Mission title, objective, progress, cash, level and XP displayed in the HUD.
- Save/Load using a JSON save file at `user://world_life_save.json`.
- Save data includes player position, mission progress, completed missions, collected pickups, cash, XP and level.
- Mobile SAVE and LOAD buttons.

## Notes

- Save data is stored in the app's user data directory, not inside the project ZIP.
- This package has not been run in the Godot editor or on a physical Android device in this environment. Validate in Godot 4.3 before release.
- v0.9 Living World systems and earlier world/vehicle systems are retained.
