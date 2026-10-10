# MIT-Licensed Baby Mesh — Candidate Only

**Asset:** `MIT_Baby_mgiuca.glb` (597,528 bytes; glTF 2.0)
**Source:** [mgiuca/two-hands — meshes/baby.glb](https://github.com/mgiuca/two-hands/blob/main/meshes/baby.glb)
**Creator:** Matthew Giuca
**License:** MIT (full text in `LICENSE.mgiuca.txt`)
**Source commit / blob:** Git blob `fb8b7087eac82d4a640f9ad8922c33d053414c0d`.

The source repository README says original assets other than explicitly credited external assets are MIT licensed, and the model is not listed among exceptions in `meta/credits.md`.

## Inspection completed
- Binary GLB v2, 597,528 bytes, self-contained textures as embedded image buffers.
- 5 meshes: Body, Head, Eye.L, Eye.R, Diaper.
- 3 embedded PNG images, 4 materials.
- **No glTF skins / armature and no animations**. This is NOT a ready-to-play Roblox character rig.

## Before using as the player character
1. Preview in a 3D model viewer and assess whether its silhouette looks good from the game's third-person camera.
2. Import GLB to Studio, use Avatar Setup / Development Avatar / Body to attempt R15 rigging and skinning, then verify joints and animation.
3. Refine the face using an original texture/material, not the previous awkward sphere attachments.
4. Add a low crawling locomotion animation, headbutt and butt block. Keep V4 server authority and HUD unchanged.
5. Once the mesh is rigged, follow [the imported rig installer](../../../tools/InstallImportedBabyRig.luau).

Do not ship this static GLB as a replacement for the existing playable baby until those checks pass. **The current game file has not been modified to use it.**
