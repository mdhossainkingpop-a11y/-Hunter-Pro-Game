# WORLD LIFE 3D — v1.0.1 Bug-fix Report

## ফাইল পরীক্ষা
পরীক্ষিত Source: `WORLD_LIFE_3D_v1.0.0.zip`

## শনাক্ত ও সংশোধিত সমস্যা

1. **Vehicle camera target ভুল ছিল** — গাড়ি/বিমান/জাহাজের child Camera-কে world origin-এর দিকে তাক করানো হচ্ছিল। এখন vehicle-local target-কে `to_global()` দিয়ে world-space-এ রূপান্তর করে camera aim করা হয়।
2. **Vehicle থেকে বের হওয়ার পর Player camera restore অনির্দিষ্ট ছিল** — Exit flow-তে Player camera স্পষ্টভাবে current করা হয়েছে।
3. **Vehicle-এ ওঠার সময় camera handoff স্পষ্ট ছিল না** — Player camera বন্ধ করে সংশ্লিষ্ট vehicle camera সক্রিয় করা হয়; গাড়ি/বিমান/জাহাজের camera pose পুনরায় সেট হয়।
4. **Android CI workflow version drift** — Workflow Godot 4.7.2 ব্যবহার করছিল, অথচ project feature version 4.3 ঘোষণা করে। Workflow-কে Godot 4.3 stable-এ মিলিয়ে দেওয়া হয়েছে।
5. **Release artifact naming stale** — Workflow-এর v0.6 output names v1.0.0-এ সংশোধন করা হয়েছে।

## যাচাইয়ের সীমাবদ্ধতা

- ZIP archive integrity পরীক্ষা করা হয়েছে।
- Project resource path এবং export preset presence পরীক্ষা করা হয়েছে।
- এই execution environment-এ Godot editor/runtime ইনস্টল নেই; তাই Godot parser, scene launch, gameplay runtime, Android APK/AAB export এবং বাস্তব device QA চালানো যায়নি।
- Keystore credentials না থাকায় signed release build তৈরি করা হয়নি।

এটি source-level bug-fix build; runtime-tested release নয়।
