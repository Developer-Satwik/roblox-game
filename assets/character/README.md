# Baby Brawl — external-asset character pipeline

**Status:** asset sourcing and import integration prepared; **no generated or downloaded 3D baby mesh has been imported into the game yet**. Do not mistake the existing procedural baby for the final asset.

## Fast path (recommended)

1. Make or obtain **one complete baby character** as a textured GLB/FBX. Do **not** start from Roblox primitives.
2. For your reference, use the previously approved design: chubby crawling infant silhouette, short limbs, bald head, unnaturally self-confident heavy eyebrows, narrowed eyes, tiny smug smirk, clean padded white diaper. The face must remain original, not a copied Roblox marketplace texture. Use an A-pose/T-pose **when preparing to auto-rig**, then animate crawling afterward.
3. Try Sloyd's [Image to 3D](https://www.sloyd.ai/image-to-3d) for image-to-mesh, followed by Auto Rig, or [Roblox Avatar Creator](https://www.sloyd.ai/avatar-creator) when a pre-rigged mannequin fits the proportions. These are distinct from [Selfie to Roblox](https://www.sloyd.ai/apps/selfie-to-roblox), which starts by generating a *2D image*.
4. In Roblox Studio: Home → Import → GLB or FBX. If you import just a mesh, use Avatar → **Avatar Setup → Development Avatar → Body** to create an animatable model, then review and correct bones/weights. It might fail on unusual proportions; check the full rig.
5. Select the resulting **rigged Model** in Explorer. In the Studio **Edit-mode Command Bar**, run [InstallImportedBabyRig.luau](../tools/InstallImportedBabyRig.luau) **once**. The importer validates Humanoid, HumanoidRootPart, Head, R15 and at least six joints *before* touching the old character. It clones a script-free version as StarterCharacter, disables the old primitive baby shell/animator, and preserves other game systems.
6. Save a fresh place file; Play with a second client to check movement, camera, collisions, attack origin and animation. **The imported rig needs proper crawl and ability animations before it is game-ready.** The installer is not a rigging or animation generator.

## Style/prompt for external image-to-3D

> Single original game character, a very chubby crawling baby with a large but plausible bald head, plump cheeks, round belly, short thick arms and legs, white padded diaper, smooth toy-like textures, expressive narrow half-lidded brown eyes, exaggerated dark sharply angled eyebrows, subtle winged eyelids, and a tiny asymmetrical mischievous smile. Whimsically uncanny, playful and memorable, not frightening. Complete body, hands and feet visible, no props, no text, no hair. Balanced symmetrical anatomy suitable for conversion to a 3D game model, clean topology, soft simplified geometry, coherent textures and silhouette. For rigging create a neutral A-pose version (feet apart, arms slightly out) of exactly the same character. Keep skin and facial details original, not copied from an existing game.

For one-image reconstruction, favor a **full-body three-quarter neutral pose** with a plain background. A face-only screenshot cannot provide the baby body geometry, the diaper, or the arm/leg joints. Preserve the funny face but keep expression geometry simple; a textured face is generally cheaper than dozens of separate welded parts.

## Alternative: reuse an existing rigged baby (licensed sources)

| Candidate | What source reports | Concern |
|---|---|---|
| [Baby (Fully Rigged), omermedia](https://sketchfab.com/3d-models/baby-fully-rigged-7de8127f2fef4db69f71d0f748e58fe3) | CC BY, 28.8k triangles, rigged | Need to inspect animation, face, textures, poly budget, and whether Sketchfab download is accessible |
| [Baby, darksoundlab](https://sketchfab.com/3d-models/baby-452ee1d9783e49f2a480fca806014b91) | CC BY, baby with diaper, about 52.1k triangles, marked rigged | More optimization work |
| [Cartoony Cute Baby, Tavvo](https://sketchfab.com/3d-models/cartoony-cute-baby-ac901ef502524f3a80830a8c8f3f87f8) | CC BY-SA, chubby stylization | 319.7k triangles and share-alike obligations: **not preferred** |

Don't add copyrighted franchise baby models just because they are offered as free downloads. Keep artist attribution and proof of permissions in the final game's credits/source manifest. Validate license terms on the download page before using an asset in a commercial game.

## Asset acceptance checklist

- [ ] Mesh files (.glb/.fbx) supplied, with textures and source URL/license.
- [ ] Original design or permission for commercial use.
- [ ] Review topology / triangle count (aim for mobile efficiency; measure actual performance).
- [ ] Actual R15 Humanoid + HumanoidRootPart + Head and compatible joints.
- [ ] Crawl animation, idle, headbutt, butt block, fart run, hit reaction; smooth limb motion.
- [ ] Same gameplay hitboxes and sprint speed for all cosmetics.
- [ ] No imported third-party scripts, unsafe requires, backdoors, or external asset dependencies.
- [ ] Tested at normal camera distance on desktop and mobile.

## Roblox docs

- https://create.roblox.com/docs/avatar-setup
- https://create.roblox.com/docs/art/characters/import
- https://create.roblox.com/docs/reference/engine/classes/StarterPlayer
- https://create.roblox.com/docs/scripting/security/third-party-vulnerabilities

## Sloyd licensing

Sloyd's current pricing page advertises a **personal-use only** guest tier, with a **commercial-use** license for Plus/Pro. Verify the license attached to an actual generated asset. A CC BY community model can be an alternative when properly attributed. Don't use an asset in a published monetized game until its commercial rights are clear.

We can wire in the final .glb/.fbx as soon as we have the actual model bytes. GitHub source and this installer cannot reconstruct someone else's downloadable mesh by URL alone.
