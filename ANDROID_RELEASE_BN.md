# Android Release Guide — WORLD LIFE 3D v1.0.1

## ১) প্রয়োজনীয় সফটওয়্যার
- Godot 4.3 stable (অথবা একই major version-এর compatible Godot 4.x)
- Export Templates: Editor → Manage Export Templates
- Android SDK, Platform Tools ও Build Tools
- JDK 17 (আপনার Godot/Gradle setup-এর সঙ্গে compatible)

## ২) প্রথমে project যাচাই
1. `project.godot` Godot-এ import করুন।
2. `F6`/Play দিয়ে Main Scene চালান।
3. Debugger-এর Errors ও Warnings পরীক্ষা করুন।
4. Mission, Save/Load, NPC, traffic, vehicle enter/exit এবং LOW/STD graphics toggle পরীক্ষা করুন।

## ৩) Android signing
1. নিজের release keystore তৈরি করুন। Keystore/password কখনো ZIP বা source control-এ রাখবেন না।
2. Editor → Editor Settings → Export → Android-এ SDK/JDK path দিন।
3. Project → Export → Android APK এবং Google Play AAB preset খুলুন।
4. Release keystore path, user ও password নিজের environment-এ সেট করুন।
5. Package ID `com.worldlife3d.game` প্রকাশের আগে নিশ্চিত করুন যে এটি আপনার নিয়ন্ত্রণে এবং আগে অন্য অ্যাপে ব্যবহৃত হয়নি।

## ৪) Export
- APK: `build/WORLD_LIFE_3D_v1.0.1.apk`
- AAB: `build/WORLD_LIFE_3D_v1.0.1.aab`
- Google Play-তে upload-এর জন্য AAB preset ব্যবহার করুন।

## ৫) বাস্তব ডিভাইস QA checklist
- [ ] কমপক্ষে একটি 64-bit Android ফোনে install ও launch
- [ ] Touch movement, jump, run, interact এবং camera
- [ ] Car, plane, ship enter/exit ও controls
- [ ] NPC এবং traffic চলাচল
- [ ] Day/night cycle
- [ ] তিনটি mission, cash ও XP
- [ ] Save → force close → relaunch → Load
- [ ] LOW/STD graphics পরিবর্তন এবং দীর্ঘক্ষণ thermal test
- [ ] FPS, memory, battery drain ও crash log পরীক্ষা
- [ ] Release APK install এবং AAB internal testing track-এ যাচাই

**গুরুত্বপূর্ণ:** এই build environment-এ Godot editor/runtime, Android SDK/JDK এবং physical Android device পাওয়া যায়নি। তাই এই ZIP-এ APK/AAB অন্তর্ভুক্ত নেই এবং উপরের QA checklist সম্পন্ন বলে দাবি করা হচ্ছে না।
