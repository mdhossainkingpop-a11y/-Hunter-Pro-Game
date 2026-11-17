# WORLD LIFE 3D v1.0.1 — QA Test Report (Bangla)

তারিখ: 2026-11-16

## পরীক্ষার পরিধি

এই ধাপে সরবরাহ করা `WORLD_LIFE_3D_v1.0.1_BUGFIX.zip`-এর প্রজেক্ট ফাইল, GDScript source structure, resource path এবং Android release workflow-এর static audit করা হয়েছে।

## সম্পন্ন static checks

- ZIP archive integrity: PASS (`testzip()`-এ কোনো corrupt member পাওয়া যায়নি)
- GDScript files found: 11
- GDScript delimiter balance: PASS
- GDScript indentation consistency (4-space blocks): PASS
- `res://` resource references: PASS (missing reference পাওয়া যায়নি)
- `project.godot` main scene path: PASS (`res://scenes/main.tscn` আছে)
- GitHub Actions workflow YAML parse: PASS
- Workflow-এর embedded Bash script syntax (`bash -n`): PASS
- Project version / renderer config: Godot 4.3 project config পাওয়া গেছে

## Runtime পরীক্ষার অবস্থা

**BLOCKED — Godot runtime available নয়।**

এই পরীক্ষার পরিবেশে Godot 4.x executable পাওয়া যায়নি। বাইনারি ডাউনলোডের চেষ্টাও নেটওয়ার্ক/DNS সীমাবদ্ধতার কারণে সম্পন্ন হয়নি। ফলে নিচের পরীক্ষাগুলো চালানো যায়নি:

- Godot 4.3 headless editor import / GDScript parser validation
- Project launch এবং runtime error log capture
- Player movement, interaction, vehicle enter/exit ও camera handoff
- Mission progression, pickup collection, save/load
- Day/night, traffic ও pedestrian runtime behavior
- Android APK/AAB export এবং physical-device test

## গুরুত্বপূর্ণ সীমাবদ্ধতা

Static checks সফল হওয়া মানে GDScript-এর সব type/API/runtime error নেই—এমন নিশ্চয়তা নয়। Godot 4.3 editor/headless run ছাড়া এই build-কে runtime-tested বা APK-ready হিসেবে ঘোষণা করা যাবে না।

## পরবর্তী প্রয়োজনীয় ধাপ

1. Godot 4.3 Stable editor বা headless executable-এ project import করুন।
2. প্রথমে editor parse/import errors শূন্য নিশ্চিত করুন।
3. `godot --headless --path <project-folder> --editor --quit` চালিয়ে import/parser output সংরক্ষণ করুন।
4. এরপর `godot --headless --path <project-folder> --quit-after 300` দিয়ে startup/runtime log পরীক্ষা করুন।
5. GUI build-এ gameplay checklist চালিয়ে Android export এবং device test করুন।

এই রিপোর্টে PASS কেবলমাত্র উল্লিখিত static checks-এর জন্য প্রযোজ্য।
