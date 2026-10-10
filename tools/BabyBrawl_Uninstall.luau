-- Baby Brawl PHASE 1 reversible uninstall, run in Roblox Studio Command Bar.
local Workspace = game:GetService('Workspace')
local RS = game:GetService('ReplicatedStorage')
local SS = game:GetService('ServerScriptService')
local SP = game:GetService('StarterPlayer')
for _,o in Workspace:GetDescendants() do
    if o:IsA('SpawnLocation') then
        local wasEnabled = o:GetAttribute('BB_OriginalSpawnEnabled')
        if typeof(wasEnabled)=='boolean' then
            o.Enabled=wasEnabled
            o:SetAttribute('BB_OriginalSpawnEnabled',nil)
        end
    end
end
for _,o in ipairs({Workspace:FindFirstChild('BabyBrawl_V1'), RS:FindFirstChild('BabyBrawl_V1'), SS:FindFirstChild('BabyBrawl_Server'), SP.StarterPlayerScripts:FindFirstChild('BabyBrawl_Client')}) do
    if o then o:Destroy() end
end
print('[BabyBrawl] Phase 1 additions removed. Original map and spawns restored.')
