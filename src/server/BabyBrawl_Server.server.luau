--!strict
-- Baby Brawl | Phase 1: server-authoritative control prototype.
-- Starter Roblox avatar is intentional: custom crawling baby arrives in Phase 2.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local rootFolder = ReplicatedStorage:WaitForChild("BabyBrawl_V1")
local combatEvent = rootFolder:WaitForChild("CombatAction") :: RemoteEvent
local stats: {[Player]: {lastAttack: number, lastRemote: number, lastByAction: {[string]: number}, blocking: boolean, sprinting: boolean, spawnAt: number}} = {}

local function livingCharacter(plr: Player): (Model?, Humanoid?, BasePart?)
    local ch = plr.Character
    if not ch then return nil, nil, nil end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    local part = ch:FindFirstChild("HumanoidRootPart")
    if not hum or not part or not part:IsA("BasePart") or hum.Health <= 0 then return nil, nil, nil end
    return ch, hum, part
end

local function updateMovement(plr: Player)
    local state = stats[plr]
    if not state then return end
    local _,hum = livingCharacter(plr)
    if hum then
        hum.WalkSpeed = state.blocking and 8 or (state.sprinting and 32 or 16)
        hum:SetAttribute("BB_Blocking", state.blocking)
        hum:SetAttribute("BB_Sprinting", state.sprinting and not state.blocking)
        if game:GetService("RunService"):IsStudio() then
            print("[BB SERVER] WalkSpeed", plr.Name, hum.WalkSpeed, "block", state.blocking, "sprint", state.sprinting)
        end
    end
end

local function setupPlayer(plr: Player)
    local state = {lastAttack=0, lastRemote=0, lastByAction={}, blocking=false, sprinting=false, spawnAt=0}
    stats[plr] = state
    local statsFolder = plr:FindFirstChild("leaderstats") or Instance.new("Folder")
    statsFolder.Name = "leaderstats"
    statsFolder.Parent = plr
    if not statsFolder:FindFirstChild("KOs") then
        local kos = Instance.new("IntValue")
        kos.Name = "KOs"
        kos.Parent = statsFolder
    end

    plr.CharacterAdded:Connect(function(char)
        state.blocking = false
        state.sprinting = false
        state.spawnAt = os.clock()
        local hum = char:WaitForChild("Humanoid", 10)
        if not hum or not hum:IsA("Humanoid") then return end
        hum.WalkSpeed = 16
        hum.MaxHealth = 100
        hum.Health = 100
        local shield = Instance.new("ForceField")
        shield.Visible = false
        shield.Parent = char
        Debris:AddItem(shield, 2.5)
        hum.Died:Connect(function()
            local attackerId = hum:GetAttribute("BB_LastAttacker")
            local lastTime = hum:GetAttribute("BB_LastHitTime")
            if typeof(attackerId) == "number" and typeof(lastTime) == "number" and os.clock()-lastTime <= 9 and attackerId ~= plr.UserId then
                local killer = Players:GetPlayerByUserId(attackerId)
                if killer and killer:FindFirstChild("leaderstats") then
                    local ko = killer.leaderstats:FindFirstChild("KOs")
                    if ko and ko:IsA("IntValue") then ko.Value += 1 end
                end
            end
        end)
    end)
end

local function attack(plr: Player)
    local state = stats[plr]
    if not state or state.blocking then return end
    local now = os.clock()
    if now - state.lastAttack < 0.58 then return end
    state.lastAttack = now
    local _, hum, root = livingCharacter(plr)
    if not hum or not root then return end
    if now - state.spawnAt < 2.5 then return end

    -- Validate other players' distance, angle and vertical offset on the server.
    local closestHum: Humanoid? = nil
    local closestRoot: BasePart? = nil
    local closestPlayer: Player? = nil
    local dist = math.huge
    for _,other in Players:GetPlayers() do
        if other ~= plr then
            local _,targetHum, targetRoot = livingCharacter(other)
            local targetState = stats[other]
            if targetHum and targetRoot and targetState and now-targetState.spawnAt > 2.5 then
                local displacement = targetRoot.Position - root.Position
                local flat = Vector3.new(displacement.X, 0, displacement.Z)
                local distance = flat.Magnitude
                if distance >= 0.05 and distance < 6 and math.abs(displacement.Y) < 4.5 and root.CFrame.LookVector:Dot(flat.Unit) > 0.45 and distance < dist then
                    closestHum, closestRoot, closestPlayer, dist = targetHum, targetRoot, other, distance
                end
            end
        end
    end
    combatEvent:FireAllClients("AttackFX", plr.UserId)
    if closestHum and closestRoot and closestPlayer then
        local targetState = stats[closestPlayer]
        local blocking = targetState and targetState.blocking
        -- For V1 the block is omni-directional while testing inputs; rear-facing
        -- 'Butt Guard' directionality will be introduced with the baby rig.
        if blocking then
            combatEvent:FireAllClients("BlockedFX", closestPlayer.UserId)
        else
            closestHum:SetAttribute("BB_LastAttacker", plr.UserId)
            closestHum:SetAttribute("BB_LastHitTime", os.clock())
            closestHum:TakeDamage(16)
            if closestRoot:IsDescendantOf(workspace) then
                local dir = (closestRoot.Position-root.Position)
                if dir.Magnitude > 0.1 then
                    local horizontal = Vector3.new(dir.X,0,dir.Z)
                    if horizontal.Magnitude > 0.1 then
                        closestRoot.AssemblyLinearVelocity = horizontal.Unit*27 + Vector3.new(0, 15, 0)
                    end
                end
            end
            combatEvent:FireAllClients("HitFX", closestPlayer.UserId)
        end
    end
end

combatEvent.OnServerEvent:Connect(function(plr, action, value)
    if typeof(action) ~= "string" then return end
    local state = stats[plr]
    if not state then return end
    if action ~= "Attack" and action ~= "Block" and action ~= "Sprint" then return end
    local now = os.clock()
    -- Throttle each input separately. The old global 35 ms gate dropped
    -- legitimate block->sprint transitions sent in the same frame.
    local lastForAction = state.lastByAction[action] or -math.huge
    -- Never drop a rapid press/release of a held control. Cooldowns for
    -- Attack are enforced separately in attack() itself.
    if action == "Attack" and now - lastForAction < 0.035 then return end
    state.lastByAction[action] = now
    -- Developer QA can distinguish "server received" from "attack hit".
    if game:GetService("RunService"):IsStudio() then
        combatEvent:FireClient(plr, "InputAck", plr.UserId, action)
    end
    if action == "Attack" then
        attack(plr)
    elseif action == "Block" and typeof(value) == "boolean" then
        state.blocking = value
        if value then state.sprinting = false end
        updateMovement(plr)
        combatEvent:FireAllClients("BlockFX", plr.UserId, value)
    elseif action == "Sprint" and typeof(value) == "boolean" then
        state.sprinting = value and not state.blocking
        updateMovement(plr)
        combatEvent:FireAllClients("SprintFX", plr.UserId, state.sprinting)
    end
end)

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(p) stats[p]=nil end)
for _,p in Players:GetPlayers() do setupPlayer(p) end
print("[BabyBrawl V1] Server combat and input validation ready")
