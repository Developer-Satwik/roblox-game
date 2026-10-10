## Latest patch — sprint + practice target (V4)

Use [BabyBrawl_SprintTraining_V4_Installer.luau](tools/BabyBrawl_SprintTraining_V4_Installer.luau) in Roblox Studio's **Command Bar (Edit mode)** after V3. It updates four scripts only: the server combat controller, Studio-only practice dummy, client combat controller, and Studio-only input monitor. It does not replace the map or crawling baby rig. Safe to rerun; creates disabled backups.

**Test in blue Play:** get near the practice baby (within roughly 7 studs), face it, then BONK. The label should change from 96 HP to 80 HP. Hold Shift *while moving*; WalkSpeed in the QA panel should rise from 16 to 32 and green gas should appear near the diaper. Release Shift to return to speed 16. F still blocks. The four special abilities remain placeholders.

This is a code patch validated against the GitHub source, **not yet verified in a running Roblox Studio playtest**.

# Baby Brawl — Roblox Prototype

A simple one-map Roblox baby battlegrounds game. Players will eventually use a custom crawling baby rig, headbutt attacks, butt-blocking, fart sprinting, and four starter abilities.

## Latest update

**Phase 2 baby character prototype is ready to install.** It layers a chubby crawling baby with procedural bonk, butt-block and fart-run poses over the Phase 1 controls. The existing map remains unchanged. It is a primitive-part visual shell, not yet a finished skinned character.

[Install Phase 2](docs/PHASE2.md) · [Phase 2 Command Bar installer](tools/BabyBrawl_Phase2_Installer.luau)

## Combat feedback patch (after Phase 2)

If your baby appears but basic attacks seem inactive, run the [Combat Feedback installer](tools/BabyBrawl_CombatFeedback_Installer.luau) from the **Roblox Studio Command Bar in Edit mode**. It updates the client input and baby animation, then installs a **Studio-only Practice Baby** around five studs in front of your character. The target displays HP; left-click or BONK to test headbutt hits when facing it. Run Play again after installing. The patch does not change imported map geometry or production matchmaking.

**The four centered specials (Tongue Tag, Belly Flop, Mega Burp, Tantrum) are still placeholders.** Holding F blocks and holding Shift activates fart sprint. In a multiplayer test, Phase 1 headbutts only damage other players in front and within ~6 studs; spawn protection lasts ~2.5 seconds.

## Current fix — combat inputs (Phase 2)

Use [BabyBrawl_ControllerV3_RepairInstaller.luau](tools/BabyBrawl_ControllerV3_RepairInstaller.luau) from the **Studio Command Bar in Edit mode** if the Studio QA panel detects keys but **SERVER** stays on "waiting" and the normal Baby Brawl HUD is absent. This replaces the unresponsive `BabyBrawl_Client` with a separate `BabyBrawl_ControllerV3`, keeps a disabled copy of the legacy controller, upgrades the combat server with per-action throttling and a Studio-only `InputAck` event, and does not touch the imported map or baby assets. Install once, save, then use the top blue **Play** button. The four numbered abilities remain nonfunctional placeholders.

## Latest controls diagnostic (October 2026)

If Baby Brawl's keyboard or mouse controls appear inactive, install [the PC input fix and Studio-only control monitor](tools/BabyBrawl_InputFix_Installer.luau) in **Edit mode** using Roblox Studio's Command Bar. Save, then choose the top blue **Play** action (not Command Bar Run or Test > Run), and click inside the **Client** viewport before pressing LMB, F or Shift.

The small top-center **BABY BRAWL QA** panel reports when the client script is running, which key/mouse events it receives (including whether they were processed by the UI), and which corresponding server events arrive. Use this to distinguish a viewport focus problem, inactive LocalScript, or server validation. The four numbered ability slots are still placeholders. The QA panel is Studio-only and does not appear in a published game.

## Project state

**Phase 1: installed and reported working in Studio. Phase 2: visual baby prototype awaiting playtest.**

The Phase 1 package includes a Studio Command Bar installer for the existing downloaded map, a server combat prototype, a client controller and HUD, an uninstall script, and instructions. The original third-party map itself is **not** included in this public repository.

### Intended controls

| Input | Desktop | Mobile |
|---|---|---|
| Basic headbutt placeholder | Left mouse | BONK |
| Block | Hold F | BLOCK toggle |
| Fart Sprint | Hold Shift | FART RUN toggle |
| Jump | Space | Roblox native jump |
| Movement | WASD | Roblox native joystick |
| Abilities 1–4 | Number keys | Bottom-center buttons (placeholders) |

The four bottom-center slots are reserved for **Tongue Tag**, **Belly Flop**, **Mega Burp**, and **Tantrum**. Those abilities and the baby character are not implemented in Phase 1.

## Install Phase 1

1. Open your copy of the existing `map sell tds.rbxl` in Roblox Studio.
2. Save a **new copy** of the place (for example `BabyBrawl_V1.rbxl`).
3. Extract `BabyBrawl_Phase1.zip` from the `releases/phase1/` folder.
4. Open `BabyBrawl_Phase1_Installer.luau` and paste its entire contents into **Studio's Command Bar** (not a normal Script object).
5. Run the command and save the place.
6. Press **Play** and test on desktop and with Studio's Device Emulator.

To remove the generated additions, run the included `BabyBrawl_Uninstall.luau` from Studio's Command Bar. The installer does not replace the imported geometry or existing scripts.

## Limitations

- This code has **not** been run and verified inside Roblox Studio; it needs a live multiplayer/mobile playtest.
- Headbutt, fart sprint, and blocking are initial control prototypes, not final animations.
- The index, toy spawns, RNG, cosmetics, baby character, and the four special abilities will come in later phases.
- Do not publish this as a finished multiplayer game without testing hit validation, spawns, respawns, and mobile behavior.

## Source control

Keep gameplay code as **multiple Luau scripts**, not one monolithic live script. An installer can still be supplied as a single convenient setup file. In future iterations, we can use Roblox Script Sync or Rojo to edit files in GitHub and synchronize their changes into Studio.

Official docs:
- https://create.roblox.com/docs/scripting/sync
- https://create.roblox.com/docs/projects/external-tools
