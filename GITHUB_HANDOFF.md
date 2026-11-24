# One-archive handoff

1. Upload `Runebound_Arena_Stage14_Full_Project.zip` to the root of `https://github.com/Xradiuzz/Runebound-arena`, replacing the archive with the same name if GitHub asks.
2. Open the repository's **Actions** tab and run **Expand Stage14 project** on `main`. This imports the archive contents into the repository root.
3. After that workflow finishes successfully, run **Build Runebound Arena Android APK**.
4. Open the build workflow run, download the `RuneboundArena-Android-debug` artifact, extract it and install `RuneboundArena-debug.apk` on Android.
5. Test one match first. If it crashes, send the GitHub Actions log or Android crash log; do not edit project files manually.

The archive's static validators are run by the validation workflow. The Android export workflow is the first authoritative Godot parser/import/export check for this package. A successful static validator is not itself proof that an APK builds or runs on a device.
