# WORLD LIFE 3D — v1.0.1 (Bug-fix Release Preparation)

Godot 4.3 project | Android GL Compatibility renderer | Bug-fix revision 1.0.1

## v1.0.1 — Bug fixes over v1.0.0

- Vehicle camera aim now uses each vehicle’s world-space position instead of the world origin.
- On-foot camera is explicitly restored when exiting a vehicle.
- Vehicle cameras are explicitly activated and positioned when entering.
- Android CI workflow now matches the project’s Godot 4.3 version and uses v1.0.0 release artifact names.

## v1.0.0 — Phase 6: Final Release Preparation

- **Graphics Profiles:** HUD-এর GFX বোতামে LOW/STD মোড পরিবর্তন করা যায়। LOW মোডে 45 FPS cap, shadow ও fog বন্ধ; STD মোডে 60 FPS cap এবং shadow/fog চালু।
- **Mobile Rendering:** GL Compatibility renderer, 3D MSAA ও screen-space AA বন্ধ রেখে মোবাইল GPU খরচ কমানো হয়েছে।
- **Android Export:** APK ও Google Play AAB preset, version 1.0.1 এবং version code 11।

## Gameplay features retained from v0.10

- **Mission System:** Airport Recon → Supply Run → Harbour Delivery — ধারাবাহিক ৩টি মিশন।
- **Reward System:** মিশন সম্পন্ন করলে Cash ও XP পাওয়া যায়।
- **Player Progress:** XP জমিয়ে Level বাড়ে; পরবর্তী Level-এর XP প্রয়োজন ধাপে ধাপে বাড়ে।
- **Save/Load:** player position, mission progress, completed mission, collected supply, cash, XP ও level JSON আকারে সংরক্ষণ হয়।
- **Mobile HUD:** বর্তমান mission, objective, progress, cash, level ও XP দেখা যায়; SAVE ও LOAD বাটন আছে।
- v0.9-এর NPC, traffic AI, pedestrian behaviour, day/night cycle এবং আগের island/city/vehicle ফিচার রাখা হয়েছে।

## Controls

- Keyboard: WASD, Space, Shift, E
- Mobile: on-screen movement/drive pads, RUN, JUMP, INTERACT, BRAKE, CAM, SAVE ও LOAD

## Mission guide

1. **Airport Recon:** বিমানবন্দরের runway এলাকায় যান।
2. **Supply Run:** INTERACT দিয়ে তিনটি supply crate সংগ্রহ করুন।
3. **Harbour Delivery:** port/harbour এলাকায় যান।

মিশন শেষ হলে Cash ও XP স্বয়ংক্রিয়ভাবে যোগ হবে।

## Save/Load

- SAVE চাপলে `user://world_life_save.json`-এ অগ্রগতি সংরক্ষিত হবে।
- LOAD চাপলে সর্বশেষ সংরক্ষিত অবস্থান, mission ও reward পুনরুদ্ধার হবে।
- Save file ZIP-এর মধ্যে থাকে না; Godot অ্যাপের user data directory-তে তৈরি হয়।

## Open in Godot

1. Godot 4.3 বা compatible Godot 4.x-এ `project.godot` import করুন।
2. Main Scene `res://scenes/main.tscn` চালু করুন।
3. Android export-এর আগে Android build template, SDK/JDK এবং নিজের signing keystore configure করুন।

## Validation notes

এই পরিবেশে Godot editor/runtime বা Android device নেই; তাই scene/runtime validation এবং APK/AAB export করা হয়নি। প্রথমে Godot 4.3-এ project খুলে debugger-এ পরীক্ষা করুন। Export preset-এ নিজের keystore credentials configure করতে হবে।


## Android Release
সম্পূর্ণ Android SDK/JDK, signing এবং device QA নির্দেশিকার জন্য `ANDROID_RELEASE_BN.md` দেখুন। এই ZIP হলো release-preparation source project; APK/AAB export বা physical-device test এই পরিবেশে করা হয়নি।
