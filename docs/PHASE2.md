# Baby Brawl — Phase 2: Crawling Baby Prototype

## What's changed

The original map, spawns, KO logic, headbutt hit detection, mobile button layout and bottom-center ability bar remain as in Phase 1.

This upgrade adds **two separate scripts**: a server script that assembles a baby-shaped cosmetic shell and visually hides the existing avatar, and a client script that procedurally animates crawling, headbutt reactions, butt-guard stance, and fart-run particle effects for nearby players. The base baby has large cheeks, a round head, little arms/legs, a white patterned diaper, and simple facial features.

**This is a 3D blockout/prototype, not the final model**. It uses smooth primitive parts instead of an imported/skin-weighted baby mesh. The invisible original Humanoid and character collision remain in place. Actual face and crawl animation quality will improve once we replace the shell with a professionally rigged/skin-weighted character.

## How to install

1. Open the same Roblox Studio place where you installed Phase 1. Save a backup first.
2. Open [BabyBrawl_Phase2_Installer.luau](../../tools/BabyBrawl_Phase2_Installer.luau) in GitHub and choose **Raw**, then copy the entire Luau text.
3. In **Roblox Studio > View > Command Bar**, paste and run it **in edit mode**.
4. Check for the message `[BabyBrawl P2] ... installed.` in Output.
5. Save, stop any running Play session, and press **Play** again. Test with at least two players using Studio > Test > Start Server / Start Players.
6. Test mouse attack, F to block, Shift sprint, and the mobile combat controls using Device Emulator.

This installer is **safe to rerun** and only replaces the two new Phase 2 scripts. It preserves the imported geometry. If Phase 1 is missing, it errors instead of overwriting anything.

## Expected behavior

- Everyone spawns as a crawling baby-shaped visual character.
- Crawling body and limbs animate while moving.
- Pressing attack produces a head-lunge pose for nearby players to see.
- Holding block swivels the baby body to present its diaper/butt; combat still uses the V1 omnidirectional block validation, so visual direction is not yet authoritative.
- Holding sprint increases WalkSpeed (Phase 1) and emits simple green gas particles.
- The 4 centered special-ability slots are **still placeholders**.

## Important limitations to test

- Character **collision is still based on the hidden Roblox avatar**, not on the low baby silhouette. Don't try tight crawling tunnels yet.
- Effects and posing are procedural previews, not uploaded Roblox animation assets.
- Screenshots of body proportion, camera height, mobile HUD overlap, and block direction will guide a proper rig pass.
- No real Baby Lab, RNG system or shop in Phase 2.

## Revert just Phase 2

In the Roblox Studio Explorer delete these two objects, then save and restart Play:
- `ServerScriptService/BabyBrawl_BabyVisuals`
- `StarterPlayer/StarterPlayerScripts/BabyBrawl_BabyAnimator`

Phase 1 controls and arena remain.

## Next phase

Build an improved rigged baby model and align collision/camera, then implement starter ability 1 (Tongue Tag) with a properly telegraphed skillshot and short stun.
