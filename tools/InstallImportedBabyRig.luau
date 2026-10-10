-- Baby Brawl | Install an imported, properly rigged 3D baby
-- Run once in Studio EDIT MODE after selecting ONE imported character Model.
-- Does not generate a mesh. DOES NOT touch map, PvP server or GUI.
-- Works with a Sloyd / Blender / Sketchfab GLB or FBX after Roblox Avatar Setup.
-- Requires the selected model to be a functioning humanoid rig.
local RunService = game:GetService("RunService")
assert(not RunService:IsRunning(), "Stop Play first. Run in Studio Edit mode.")
local Selection = game:GetService("Selection")
local StarterPlayer = game:GetService("StarterPlayer")
local ServerScriptService = game:GetService("ServerScriptService")
local sel = Selection:Get()
assert(#sel == 1 and sel[1]:IsA("Model"),
    "Select exactly ONE imported, rigged baby Model in Explorer before running this command.")
local src = sel[1]
local hum = src:FindFirstChildOfClass("Humanoid")
local root = src:FindFirstChild("HumanoidRootPart")
local head = src:FindFirstChild("Head")
assert(hum and root and root:IsA("BasePart") and head and head:IsA("BasePart"),
    "Not a playable rig yet: needs Humanoid, HumanoidRootPart, and Head. Use Avatar > Avatar Setup > Development Avatar first.")
local motors = 0
for _,o in ipairs(src:GetDescendants()) do
    if o:IsA("Motor6D") then motors += 1 end
end
assert(motors >= 6,
    "Not sufficiently rigged for animation ("..motors.." Motor6D joints). Auto-rig in Avatar Setup before installing.")
assert(hum.RigType == Enum.HumanoidRigType.R15,
    "Baby Brawl needs an R15 rig for the planned crawling/attack animations. Run Avatar Setup as R15.")
assert(src:IsDescendantOf(game) and not src:IsDescendantOf(StarterPlayer),
    "Select the IMPORTED model in Workspace, not an existing StarterCharacter.")
assert(ServerScriptService:FindFirstChild("BabyBrawl_BabyVisuals"),
    "Baby Brawl Phase 2 not found. Open the Baby Brawl game first.")

-- Sanitize externally sourced assets: never execute bundled scripts.
local copy = src:Clone()
for _,o in ipairs(copy:GetDescendants()) do
    if o:IsA("LuaSourceContainer") then o:Destroy() end
end
copy.Name = "StarterCharacter"
copy.PrimaryPart = copy:FindFirstChild("HumanoidRootPart") :: BasePart

-- Preserve previous StarterCharacter in a reversible folder.
local backups = game:GetService("ServerStorage"):FindFirstChild("BabyBrawl_Backups")
if not backups then
    backups = Instance.new("Folder")
    backups.Name = "BabyBrawl_Backups"
    backups.Parent = game:GetService("ServerStorage")
end
local prior = StarterPlayer:FindFirstChild("StarterCharacter")
if prior then
    local oldCopy = prior:Clone()
    oldCopy.Name = "StarterCharacter_PreExternalBaby"
    if backups:FindFirstChild(oldCopy.Name) then backups[oldCopy.Name]:Destroy() end
    oldCopy.Parent = backups
end
local visual = ServerScriptService:FindFirstChild("BabyBrawl_BabyVisuals")
local animator = StarterPlayer:FindFirstChild("StarterPlayerScripts")
    and StarterPlayer.StarterPlayerScripts:FindFirstChild("BabyBrawl_BabyAnimator")

-- Source imported model must contain no scripts; character scripts are
-- still injected by StarterPlayer/StarterCharacterScripts as normal.
copy.Parent = StarterPlayer
if prior then prior:Destroy() end
if visual and visual:IsA("Script") then visual.Enabled = false end
if animator and animator:IsA("LocalScript") then animator.Enabled = false end
StarterPlayer.LoadCharacterAppearance = false
print("[BabyBrawl ASSET] Installed imported R15 baby as StarterCharacter.")
print("[BabyBrawl ASSET] Previous procedural baby visuals/animator disabled, not deleted.")
print("[BabyBrawl ASSET] Imported asset scripts stripped. Base combat controls and map remain unchanged.")
print("[BabyBrawl ASSET] SAVE then PLAY. Inspect crawl pose, collision and imported animation compatibility.")
print("[BabyBrawl ASSET] A static or standing baby is NOT a finished crawl rig: add actual crawling animation next.")
