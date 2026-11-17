# WORLD LIFE 3D — v1.0.1

## Bug fixes over v1.0.0

- Vehicle cameras now aim at their own vehicle in world space rather than the world origin.
- Player camera is explicitly restored when exiting a vehicle.
- Vehicle camera pose is re-applied when entering a vehicle.
- Android CI uses the project-declared Godot 4.3 stable version.
- Release workflow artifact names and Android version metadata updated to v1.0.1 / version code 11.

## Release status

Source-level fixes are applied. Godot runtime validation, Android APK/AAB export, signing and physical-device QA remain unverified in this environment.

---

# WORLD LIFE 3D — v1.0.0

## Phase 6: Final Release preparation

- Added runtime graphics profile toggle (LOW / STD) to the mobile HUD.
- LOW profile targets battery/thermal-friendly play: 45 FPS cap, directional shadows off, shorter shadow distance, fog off.
- STD profile targets up to 60 FPS with shadows and fog enabled.
- Android GL Compatibility renderer retained for broader device support.
- Disabled 3D MSAA and screen-space AA to reduce GPU cost on mobile.
- Android package version set to 1.0.0 (version code 10).
- Added Android APK and Google Play AAB export presets.

## Release status

This is a release-preparation project ZIP, not a verified store-ready binary. Godot runtime validation, physical Android device testing, signing keystore setup, APK export, and AAB export must be completed by the developer using their own SDK/JDK and signing credentials.
