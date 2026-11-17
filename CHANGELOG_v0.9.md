# WORLD LIFE 3D v0.9 — Changelog

## Phase 4: Living World
- Added 12 low-poly pedestrian NPCs with looping sidewalk/park routes, short idle pauses and basic player-proximity avoidance.
- Replaced the previous decorative moving traffic blocks with 6 route-following AI traffic cars on city roads.
- Added a continuous day/night cycle that updates sun rotation, sunlight color/energy, ambient light and sky colors.
- Preserved the v0.8 island, city expansion, airport, port, river, bridge, player and player-controlled vehicles.
- Updated project name and Android export metadata to version 0.9.0 / version code 9.

## Known limitations
- Godot runtime/editor validation and Android device testing are pending.
- Traffic AI is visual/lightweight and does not yet implement full collision avoidance, traffic lights or lane changes.
- Pedestrian routes are authored loops rather than NavigationAgent3D pathfinding.
- APK/AAB are not prebuilt; configure Android SDK/JDK, export templates and signing credentials in Godot before export.
