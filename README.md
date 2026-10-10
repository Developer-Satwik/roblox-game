# Baby Brawl — Roblox Prototype

A simple one-map Roblox baby battlegrounds game. Players will eventually use a custom crawling baby rig, headbutt attacks, butt-blocking, fart sprinting, and four starter abilities.

## Project state

**Phase 1: imported-map enhancement and temporary-avatar controls (not yet playtested in Roblox Studio).**

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
