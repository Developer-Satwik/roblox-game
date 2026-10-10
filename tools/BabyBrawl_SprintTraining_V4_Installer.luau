-- Baby Brawl | Sprint + Training Fix V4 — Run in Roblox Studio COMMAND BAR in Edit mode
-- Requires Phase 1 + Baby Visuals (Phase 2) + Controller V3.
-- Rerunnable. Preserves imported map, all decorations, and baby visuals/animator.
local RunService = game:GetService("RunService")
assert(not RunService:IsRunning(), "STOP Play first; run this command in Studio Edit mode.")
local ServerScriptService = game:GetService("ServerScriptService")
local scripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
assert(game:GetService("ReplicatedStorage"):FindFirstChild("BabyBrawl_V1"), "Missing BabyBrawl_V1 remote folder")
assert(ServerScriptService:FindFirstChild("BabyBrawl_BabyVisuals"), "Phase 2 baby visuals are missing")
assert(scripts:FindFirstChild("BabyBrawl_BabyAnimator"), "Phase 2 baby animator is missing")
assert(scripts:FindFirstChild("BabyBrawl_ControllerV3"), "Controller V3 not found: run the previous V3 installer first")

-- Source is embedded so no HTTP requests or Studio AI are needed.
local packages = {
    {ServerScriptService, "BabyBrawl_Server", "Script", [=====[--!strict
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
]=====]},
    {ServerScriptService, "BabyBrawl_PracticeDummy", "Script", [=====[--!strict
-- Baby Brawl | Studio-only practice target for testing Phase 1 combat.
-- This script intentionally does nothing in published/live servers.
-- Your regular PvP hits still come from BabyBrawl_Server.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local combat = ReplicatedStorage:WaitForChild("BabyBrawl_V1"):WaitForChild("CombatAction") :: RemoteEvent

local targets = Instance.new("Folder")
targets.Name = "BabyBrawl_StudioPractice"
targets.Parent = workspace
local TARGET_HEALTH = 96
local RANGE = 7.5
local state: {[Player]: {model: Model?, lastHit: number, health: number, readout: TextLabel?}} = {}

local function part(parent: Instance, name: string, size: Vector3, color: Color3, basis: CFrame, offset: Vector3, shape: Enum.PartType?): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Shape = shape or Enum.PartType.Ball
    p.Color = color
    p.Material = Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CFrame = basis * CFrame.new(offset)
    p.Parent = parent
    return p
end

local function spawnTarget(plr: Player, ch: Model)
    task.wait(2.2) -- let spawn protection and the baby shell finish initializing
    if not ch.Parent or not plr.Parent or plr.Character ~= ch then return end
    local root = ch:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then return end
    local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
    if look.Magnitude < .5 then look = Vector3.new(0,0,-1) end
    look = look.Unit
    local near = root.Position + look*3.8
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {ch, targets}
    local hit = workspace:Raycast(near + Vector3.new(0,7,0), Vector3.new(0,-50,0), params)
    if not hit then
        warn("[BabyBrawl QA] Practice target not spawned: no nearby floor")
        return
    end
    local pos = Vector3.new(near.X, hit.Position.Y + 0.87, near.Z)
    local basis = CFrame.lookAt(pos, Vector3.new(root.Position.X, pos.Y, root.Position.Z))

    local entry = state[plr]
    if not entry then return end
    if entry.model then entry.model:Destroy() end

    local model = Instance.new("Model")
    model.Name = "PracticeBaby_"..plr.UserId
    model:SetAttribute("BabyBrawl_Practice", true)
    model.Parent = targets

    local center = part(model, "HumanoidRootPart", Vector3.new(1.5,1.4,1.3), Color3.fromRGB(252,199,165), basis, Vector3.zero)
    center.Transparency = 1
    model.PrimaryPart = center
    part(model,"Body",Vector3.new(1.55,1.20,1.65),Color3.fromRGB(249,203,165),basis,Vector3.new(0,0,0))
    local head = part(model,"Head",Vector3.new(1.40,1.35,1.37),Color3.fromRGB(254,204,173),basis,Vector3.new(0,.6,-.62))
    part(model,"Diaper",Vector3.new(1.5,1,1),Color3.fromRGB(244,250,255),basis,Vector3.new(0,-.1,.60))
    for _,side in ipairs({-1,1}) do
        part(model,"Eye",Vector3.new(.19,.24,.08),Color3.fromRGB(46,50,64),basis,Vector3.new(.28*side,.77,-1.26))
        part(model,"Cheek",Vector3.new(.27,.15,.08),Color3.fromRGB(255,145,149),basis,Vector3.new(.46*side,.42,-1.21))
        part(model,"Hand",Vector3.new(.42,.30,.43),Color3.fromRGB(250,202,162),basis,Vector3.new(side*.64,-.46,-.53))
        part(model,"Foot",Vector3.new(.44,.30,.50),Color3.fromRGB(250,202,162),basis,Vector3.new(side*.55,-.53,.62))
    end
    -- Use an explicit numeric practice HP counter. The prototype dummy is
    -- assembled from separate ANCHORED parts, not a valid rigged Humanoid;
    -- relying on Humanoid:TakeDamage made hits look unreliable.
    model:SetAttribute("PracticeHP", TARGET_HEALTH)
    entry.health = TARGET_HEALTH
    entry.lastHit = 0
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TrainingLabel"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(170,65)
    billboard.StudsOffset = Vector3.new(0,1.55,0)
    billboard.Adornee = head
    billboard.Parent = head
    local label = Instance.new("TextLabel")
    label.Name = "Readout"
    label.Size = UDim2.fromScale(1,1)
    label.BackgroundTransparency = 1
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextStrokeTransparency = .18
    label.Parent = billboard
    entry.model = model
    entry.readout = label
    label.Text = "PRACTICE BABY\n96 / 96 HP"
    print("[BabyBrawl QA] Practice baby ready 3.8 studs ahead. Move close, face baby, and BONK.")
end

local function attach(plr: Player)
    state[plr] = {model=nil,lastHit=0,health=TARGET_HEALTH,readout=nil}
    plr.CharacterAdded:Connect(function(ch)
        task.spawn(spawnTarget,plr,ch)
    end)
    if plr.Character then task.spawn(spawnTarget,plr,plr.Character) end
end
Players.PlayerAdded:Connect(attach)
Players.PlayerRemoving:Connect(function(plr)
    local item=state[plr]
    if item and item.model then item.model:Destroy() end
    state[plr]=nil
end)
for _,p in ipairs(Players:GetPlayers()) do attach(p) end

combat.OnServerEvent:Connect(function(plr: Player, action: any)
    if action ~= "Attack" then return end
    local entry = state[plr]
    if not entry or not entry.model or not entry.model.Parent or entry.health <= 0 then return end
    local now = os.clock()
    if now-entry.lastHit < .55 then return end
    local ch = plr.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    local attackerHum = ch and ch:FindFirstChildOfClass("Humanoid")
    local dummy = entry.model
    local target = dummy:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") or not attackerHum or attackerHum.Health <= 0 then return end
    if not target or not target:IsA("BasePart") then return end
    if attackerHum:GetAttribute("BB_Blocking") == true then return end

    local delta = target.Position-root.Position
    local planar = Vector3.new(delta.X,0,delta.Z)
    local distance = planar.Magnitude
    local facing = if distance > .05 then root.CFrame.LookVector:Dot(planar.Unit) else 1
    entry.lastHit = now
    -- Studio target is deliberately forgiving; real player hit rules are
    -- unchanged in BabyBrawl_Server. Don't reward punches from far away.
    if distance >= RANGE or math.abs(delta.Y) > 5 or (distance > 2.5 and facing < .10) then
        combat:FireClient(plr, "PracticeMissFX", plr.UserId,
            if distance >= RANGE then "GET CLOSER" else "FACE THE BABY")
        print("[BabyBrawl QA] Miss", plr.Name, "distance", math.round(distance*10)/10, "facing", math.round(facing*100)/100)
        return
    end

    entry.health = math.max(0,entry.health-16)
    dummy:SetAttribute("PracticeHP",entry.health)
    if entry.readout then
        entry.readout.Text = "PRACTICE BABY\n"..entry.health.." / "..TARGET_HEALTH.." HP"
    end
    local highlight = Instance.new("Highlight")
    highlight.Adornee = dummy
    highlight.FillColor = Color3.fromRGB(255,232,93)
    highlight.FillTransparency = .18
    highlight.OutlineColor = Color3.fromRGB(255,255,255)
    highlight.Parent = dummy
    Debris:AddItem(highlight,.17)
    combat:FireClient(plr, "PracticeHitFX", plr.UserId, entry.health)
    print("[BabyBrawl QA] Practice hit", plr.Name, entry.health, "HP left")
    if entry.health <= 0 then
        if entry.readout then entry.readout.Text = "BONKED!\nRESPAWNING..." end
        task.delay(1.3,function()
            if plr.Parent and plr.Character==ch and entry.model==dummy then
                task.spawn(spawnTarget,plr,ch)
            end
        end)
    end
end)

print("[BabyBrawl QA v2] Studio practice target uses numeric HP; close BONKs are now reliable.")
]=====]},
    {scripts, "BabyBrawl_ControllerV3", "LocalScript", [=====[--!strict
-- Baby Brawl | Phase 2 stable controller (replaces the malfunctioning V1 client).
-- Combat server, character, arena and Studio practice target are separate.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local mobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
print("[BabyBrawl Controller v3] Starting on", mobile and "touch" or "keyboard")

local folder = RS:WaitForChild("BabyBrawl_V1", 15)
assert(folder, "[BB v3] Missing ReplicatedStorage/BabyBrawl_V1")
local remote = folder:WaitForChild("CombatAction", 15)
assert(remote and remote:IsA("RemoteEvent"), "[BB v3] CombatAction RemoteEvent missing")
print("[BabyBrawl Controller v3] Connected to server RemoteEvent")

local pg = player:WaitForChild("PlayerGui")
local oldGui = pg:FindFirstChild("BabyBrawlHUD")
if oldGui then oldGui:Destroy() end
local olderV3 = pg:FindFirstChild("BabyBrawlHUD_V3")
if olderV3 then olderV3:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "BabyBrawlHUD_V3"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 12
gui.Parent = pg

local bg = Color3.fromRGB(19,26,34)
local surface = Color3.fromRGB(43,52,64)
local white = Color3.fromRGB(246,249,250)
local muted = Color3.fromRGB(182,195,210)
local yellow = Color3.fromRGB(255,207,79)
local green = Color3.fromRGB(96,214,136)

local function frame(parent: Instance, name: string, pos: UDim2, size: UDim2, anchor: Vector2, color: Color3, alpha: number, radius: number): Frame
    local f=Instance.new("Frame")
    f.Name=name
    f.AnchorPoint=anchor
    f.Position=pos
    f.Size=size
    f.BackgroundColor3=color
    f.BackgroundTransparency=alpha
    f.BorderSizePixel=0
    f.Parent=parent
    local corner=Instance.new("UICorner")
    corner.CornerRadius=UDim.new(0,radius)
    corner.Parent=f
    return f
end
local function text(parent: Instance, name: string, content: string, size: number, color: Color3): TextLabel
    local l=Instance.new("TextLabel")
    l.Name=name
    l.Size=UDim2.fromScale(1,1)
    l.BackgroundTransparency=1
    l.Text=content
    l.TextColor3=color
    l.TextSize=size
    l.Font=Enum.Font.GothamBold
    l.TextWrapped=true
    l.Parent=parent
    return l
end
local function button(parent: Instance, name: string, caption: string, pos: UDim2, size: UDim2, color: Color3, alpha: number): TextButton
    local b=Instance.new("TextButton")
    b.Name=name
    b.Position=pos
    b.Size=size
    b.BackgroundColor3=color
    b.BackgroundTransparency=alpha
    b.Text=caption
    b.TextColor3=white
    b.TextSize=13
    b.Font=Enum.Font.GothamBold
    b.TextWrapped=true
    b.AutoButtonColor=true
    b.BorderSizePixel=0
    b.Parent=parent
    local corner=Instance.new("UICorner")
    corner.CornerRadius=UDim.new(0,10)
    corner.Parent=b
    return b
end

local koFrame = frame(gui,"KOPanel", UDim2.new(1,-18,0,14), UDim2.fromOffset(98,34), Vector2.new(1,0),bg,.19,11)
local koLabel=text(koFrame,"KOs","KOs: 0",15,white)
local bar=frame(gui,"Abilities_BottomCenter",UDim2.new(.5,0,1,-15),UDim2.fromOffset(386,108),Vector2.new(.5,1),bg,.16,12)
local scale=Instance.new("UIScale")
scale.Parent=bar
local title=text(bar,"CharacterName","DEFAULT BABY",12,white)
title.Size=UDim2.new(1,0,0,22)
title.Position=UDim2.fromOffset(0,2)
local back=frame(bar,"HealthBackground",UDim2.fromOffset(13,30),UDim2.new(1,-26,0,8),Vector2.zero,Color3.fromRGB(79,79,86),0,4)
local hp=frame(back,"HealthFill",UDim2.fromOffset(0,0),UDim2.fromScale(1,1),Vector2.zero,green,0,4)

local hint=frame(gui,"Notification",UDim2.new(.5,0,1,-132),UDim2.fromOffset(320,27),Vector2.new(.5,1),bg,.18,9)
hint.Visible=false
local hintText=text(hint,"Message","",12,white)
local toastIndex=0
local function notify(msg: string)
    toastIndex+=1
    local current=toastIndex
    hintText.Text=msg
    hint.Visible=true
    task.delay(1.45,function()
        if current==toastIndex and hint.Parent then hint.Visible=false end
    end)
end

local names={"TONGUE TAG","BELLY FLOP","MEGA BURP","TANTRUM"}
local slots={}
for i,name in ipairs(names) do
    local slot=button(bar,"Ability"..i,tostring(i).."\n"..name,UDim2.fromOffset(11+(i-1)*94,48),UDim2.fromOffset(88,52),surface,0)
    slot.TextSize=11
    slot.Activated:Connect(function()notify("Ability "..i.." coming in Phase 3") end)
    table.insert(slots,slot)
end
print("[BabyBrawl Controller v3] HUD rendered: KO counter and four centered ability slots")

local isBlocking=false
local isSprinting=false
local lastAttack=0
local mobileBlock: TextButton?=nil
local mobileSprint: TextButton?=nil
local character: Model?=nil
local gas: ParticleEmitter?=nil

local function refreshButtons()
    if mobileBlock then mobileBlock.BackgroundColor3=isBlocking and Color3.fromRGB(76,155,205) or surface end
    if mobileSprint then mobileSprint.BackgroundColor3=isSprinting and Color3.fromRGB(53,168,100) or surface end
end
local function setBlock(on: boolean)
    if isBlocking==on then return end
    isBlocking=on
    if on then
        isSprinting=false
        if gas then gas.Enabled=false end
    end
    remote:FireServer("Block",on)
    refreshButtons()
    print("[BB v3] Sent Block",on)
end
local function setSprint(on: boolean)
    if isSprinting==on then return end
    if on and isBlocking then
        isBlocking=false
        remote:FireServer("Block",false)
    end
    isSprinting=on
    remote:FireServer("Sprint",on)
    if gas then
        gas.Enabled=on
        if on then gas:Emit(14) end -- instant visible fart puff, even while stationary
    end
    refreshButtons()
    notify(on and "FART RUN ON — MOVE TO BOOST!" or "FART RUN OFF")
    print("[BB v3] Sent Sprint",on)
end
local function bonk()
    if isBlocking then return end
    local now=os.clock()
    if now-lastAttack<.58 then return end
    lastAttack=now
    -- Animate locally as soon as the input is received, even when solo.
    local ch=player.Character
    local hum=ch and ch:FindFirstChildOfClass("Humanoid")
    if hum then hum:SetAttribute("BB_AttackPulseUntil",now+.39) end
    remote:FireServer("Attack")
    notify("BONK!")
    print("[BB v3] Sent Attack")
end

if mobile then
    local controls=frame(gui,"MobileCombat",UDim2.new(1,-12,1,-148),UDim2.fromOffset(154,170),Vector2.new(1,1),bg,1,0)
    local attack=button(controls,"BonkButton","BONK",UDim2.fromOffset(83,94),UDim2.fromOffset(67,66),yellow,0)
    attack.TextColor3=Color3.fromRGB(68,47,16)
    mobileBlock=button(controls,"BlockButton","BUTT\nBLOCK",UDim2.fromOffset(9,91),UDim2.fromOffset(65,55),surface,.05)
    mobileSprint=button(controls,"SprintButton","FART\nRUN",UDim2.fromOffset(26,19),UDim2.fromOffset(66,62),surface,.05)
    attack.Activated:Connect(bonk)
    mobileBlock.Activated:Connect(function()setBlock(not isBlocking)end)
    mobileSprint.Activated:Connect(function()setSprint(not isSprinting)end)
else
    local priority=Enum.ContextActionPriority.High.Value+6
    CAS:UnbindAction("BabyBrawlBonk")
    CAS:UnbindAction("BabyBrawlGuard")
    CAS:UnbindAction("BabyBrawlFartRun")
    for i=1,4 do CAS:UnbindAction("BabyBrawlAbility"..i) end
    CAS:BindActionAtPriority("BB3_Bonk",function(_,phase)
        if phase==Enum.UserInputState.Begin then
            if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
            bonk()
        end
        return Enum.ContextActionResult.Sink
    end,false,priority,Enum.UserInputType.MouseButton1)
    CAS:BindActionAtPriority("BB3_Block",function(_,phase)
        if phase==Enum.UserInputState.Begin then
            if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
            setBlock(true)
        elseif phase==Enum.UserInputState.End or phase==Enum.UserInputState.Cancel then
            setBlock(false)
        end
        return Enum.ContextActionResult.Sink
    end,false,priority,Enum.KeyCode.F)
    CAS:BindActionAtPriority("BB3_Sprint",function(_,phase)
        if phase==Enum.UserInputState.Begin then
            if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
            setSprint(true)
        elseif phase==Enum.UserInputState.End or phase==Enum.UserInputState.Cancel then
            setSprint(false)
        end
        return Enum.ContextActionResult.Sink
    end,false,priority,Enum.KeyCode.LeftShift,Enum.KeyCode.RightShift)
    for i,key in ipairs({Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four}) do
        CAS:BindActionAtPriority("BB3_Ability"..i,function(_,phase)
            if phase==Enum.UserInputState.Begin then
                if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
                notify("Ability "..i.." coming in Phase 3")
            end
            return Enum.ContextActionResult.Sink
        end,false,priority,key)
    end
    -- Supplemental Shift hook for Studio/game versions where built-in
    -- shift-lock consumes the action before a custom action binding receives it.
    -- setSprint is idempotent, so this cannot double-send a sprint.
    UIS.InputBegan:Connect(function(input)
        if UIS:GetFocusedTextBox() then return end
        if input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift then
            setSprint(true)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift then
            setSprint(false)
        end
    end)
    print("[BabyBrawl Controller v3] Desktop actions bound (LMB/F/Shift/1-4)")
end

local function characterAdded(ch: Model)
    character=ch
    isBlocking=false
    isSprinting=false
    if gas then gas.Enabled=false end
    gas=nil
    refreshButtons()
    local hum=ch:WaitForChild("Humanoid",12)
    if hum and hum:IsA("Humanoid") then
        local function updateHealth()
            hp.Size=UDim2.fromScale(math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1),1)
        end
        hum.HealthChanged:Connect(updateHealth)
        updateHealth()
    end
    local root=ch:WaitForChild("HumanoidRootPart",12)
    if root and root:IsA("BasePart") then
        -- The root belongs to the invisible standing avatar. Position the
        -- fart particles on the baby's diaper, not inside the spawn platform.
        local shell=ch:WaitForChild("BabyBrawl_BabyShell", 4)
        local diaper = shell and shell:FindFirstChild("Diaper")
        local parentPart = if diaper and diaper:IsA("BasePart") then diaper else root
        local att=Instance.new("Attachment")
        att.Name="BB3_GasAttachment"
        att.Position=if parentPart == root then Vector3.new(0,-1,1) else Vector3.new(0,-.08,.66)
        att.Parent=parentPart
        local puff=Instance.new("ParticleEmitter")
        puff.Name="BB3_FartRunParticles"
        puff.Color=ColorSequence.new(Color3.fromRGB(160,235,111),Color3.fromRGB(76,184,82))
        puff.Transparency=NumberSequence.new({
            NumberSequenceKeypoint.new(0,.25),
            NumberSequenceKeypoint.new(1,1),
        })
        puff.Size=NumberSequence.new({
            NumberSequenceKeypoint.new(0,.25),
            NumberSequenceKeypoint.new(1,1.2),
        })
        puff.Lifetime=NumberRange.new(.2,.55)
        puff.Speed=NumberRange.new(.7,1.7)
        puff.Rate=17
        puff.Enabled=false
        puff.Parent=att
        gas=puff
    end
end
player.CharacterAdded:Connect(function(ch)task.spawn(characterAdded,ch)end)
if player.Character then task.spawn(characterAdded,player.Character) end

task.spawn(function()
    local stats=player:WaitForChild("leaderstats",20)
    if not stats then return end
    local kos=stats:WaitForChild("KOs",20)
    if kos and kos:IsA("IntValue") then
        local function update()koLabel.Text="KOs: "..tostring(kos.Value)end
        kos.Changed:Connect(update)
        update()
    end
end)

remote.OnClientEvent:Connect(function(kind: any,uid: any,flag: any)
    if uid~=player.UserId then return end
    if kind=="AttackFX" then
        print("[BB v3] Server confirmed attack attempt")
    elseif kind=="HitFX" then
        notify("OUCH!")
    elseif kind=="PracticeHitFX" then
        notify("PRACTICE HIT! "..tostring(math.ceil(tonumber(flag) or 0)).." HP LEFT")
    elseif kind=="PracticeMissFX" then
        notify(tostring(flag))
    elseif kind=="BlockedFX" then
        notify("BLOCKED!")
    elseif kind=="BlockFX" then
        print("[BB v3] Server confirmed block:",flag)
    elseif kind=="SprintFX" then
        local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if flag==true then
            notify("FART RUN ACTIVE")
            if gas then gas.Enabled=true; gas:Emit(10) end
        else
            if gas then gas.Enabled=false end
        end
        print("[BB v3] Server confirmed sprint:",flag,"WalkSpeed:",hum and hum.WalkSpeed)
    end
end)

UIS.WindowFocusReleased:Connect(function()
    if not mobile then
        setBlock(false)
        setSprint(false)
    end
end)
local function rescale()
    local cam=workspace.CurrentCamera
    if not cam then return end
    local width=cam.ViewportSize.X
    scale.Scale=mobile and math.clamp(width/790,.64,.95) or math.clamp(width/1050,.75,1.04)
end
rescale()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
end
print("[BabyBrawl Controller v3] READY. Attack/Block/Fart Run active; specials are placeholders.")
]=====]},
    {scripts, "BabyBrawl_InputProbe", "LocalScript", [=====[--!strict
-- Baby Brawl | Studio-only input diagnostics. Not active in published game.
-- This probe NEVER sends input or damage: it only shows what reached the client
-- and what the server acknowledged through the existing CombatAction event.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local previous = playerGui:FindFirstChild("BabyBrawlInputQA")
if previous then previous:Destroy() end
local screen = Instance.new("ScreenGui")
screen.Name = "BabyBrawlInputQA"
screen.DisplayOrder = 80
screen.IgnoreGuiInset = false
screen.ResetOnSpawn = false
screen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
screen.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "ReadOnlyInputMonitor"
panel.AnchorPoint = Vector2.new(0.5,0)
panel.Position = UDim2.new(0.5,0,0,4)
panel.Size = UDim2.fromOffset(350,96)
panel.BackgroundColor3 = Color3.fromRGB(14,25,29)
panel.BackgroundTransparency = .12
panel.BorderSizePixel = 0
panel.Parent = screen
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,10)
corner.Parent = panel

local function label(name: string, textValue: string, y: number, color: Color3)
    local text = Instance.new("TextLabel")
    text.Name = name
    text.Size = UDim2.new(1,-18,0,21)
    text.Position = UDim2.fromOffset(9,y)
    text.Text = textValue
    text.Font = Enum.Font.GothamSemibold
    text.TextSize = 13
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextColor3 = color
    text.BackgroundTransparency = 1
    text.Parent = panel
    return text
end

local white = Color3.fromRGB(240,247,247)
local muted = Color3.fromRGB(201,216,227)
local green = Color3.fromRGB(130,235,164)
local head = label("State", "BABY BRAWL QA   |   CLIENT: RUNNING", 5, green)
local keyLine = label("Input", "INPUT: waiting for click / F / Shift", 27, white)
local serverLine = label("Server", "SERVER: waiting for combat event", 49, muted)
local modeLine = label("Info", "Click GAME viewport first. F5=Play, F8=Run.", 71, muted)

local rootFolder = ReplicatedStorage:WaitForChild("BabyBrawl_V1",8)
local remote = rootFolder and rootFolder:FindFirstChild("CombatAction")
if not remote or not remote:IsA("RemoteEvent") then
    serverLine.Text = "SERVER: missing BabyBrawl_V1/CombatAction"
else
    remote.OnClientEvent:Connect(function(kind, uid, flag)
        serverLine.Text = "SERVER: "..tostring(kind).."  id="..tostring(uid)
        print("[BB INPUT QA] Server event:",kind,uid,flag)
    end)
end

local function watched(input: InputObject): boolean
    return input.UserInputType == Enum.UserInputType.MouseButton1 or
        input.KeyCode == Enum.KeyCode.F or
        input.KeyCode == Enum.KeyCode.LeftShift or
        input.KeyCode == Enum.KeyCode.RightShift or
        input.KeyCode == Enum.KeyCode.One or
        input.KeyCode == Enum.KeyCode.Two or
        input.KeyCode == Enum.KeyCode.Three or
        input.KeyCode == Enum.KeyCode.Four
end

UIS.InputBegan:Connect(function(input, processed)
    if not watched(input) then return end
    local keyName = if input.UserInputType == Enum.UserInputType.MouseButton1 then "LEFT CLICK" else input.KeyCode.Name
    local textValue = "INPUT: "..keyName.."  |  processed="..tostring(processed)
    keyLine.Text = textValue
    print("[BB INPUT QA]", textValue)
end)

local function inspectCharacter()
    task.wait(2.8)
    local ch = localPlayer.Character
    local h = ch and ch:FindFirstChildOfClass("Humanoid")
    local baby = ch and ch:FindFirstChild("BabyBrawl_BabyShell")
    modeLine.Text = "BABY: "..(baby and "YES" or "NO").."  |  HUMANOID: "..(h and "YES" or "NO")
    print("[BB INPUT QA] Baby shell:",baby~=nil,"Character:",ch~=nil,"Controls:",UIS.KeyboardEnabled and "keyboard" or "touch")
    if h then
        h:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            modeLine.Text = "BABY: "..(baby and "YES" or "NO").." | SPEED: "..tostring(h.WalkSpeed).." | SPRINT: "..tostring(h:GetAttribute("BB_Sprinting"))
        end)
        h:GetAttributeChangedSignal("BB_Sprinting"):Connect(function()
            modeLine.Text = "BABY: "..(baby and "YES" or "NO").." | SPEED: "..tostring(h.WalkSpeed).." | SPRINT: "..tostring(h:GetAttribute("BB_Sprinting"))
        end)
        modeLine.Text = "BABY: "..(baby and "YES" or "NO").." | SPEED: "..tostring(h.WalkSpeed).." | SPRINT: "..tostring(h:GetAttribute("BB_Sprinting"))
    end
end

localPlayer.CharacterAdded:Connect(function()
    task.spawn(inspectCharacter)
end)
if localPlayer.Character then task.spawn(inspectCharacter) end
print("[BB INPUT QA] Client probe running. Press LMB/F/Shift in PLAY CLIENT viewport.")
]=====]},
}
local staged = {}
for _, spec in ipairs(packages) do
    local parent, name, className, code = spec[1], spec[2], spec[3], spec[4]
    local old = parent:FindFirstChild(name)
    assert(not old or old:IsA(className), "Unexpected object: "..name)
    local oldStage = parent:FindFirstChild(name.."_StageV4")
    if oldStage then oldStage:Destroy() end
    local obj = Instance.new(className)
    obj.Name = name.."_StageV4"
    obj.Enabled = false
    obj.Source = code
    obj.Parent = parent
    table.insert(staged, {parent, name, old, obj})
end
for _, item in ipairs(staged) do
    local parent, name, old, obj = item[1], item[2], item[3], item[4]
    if old then
        old.Enabled = false
        if not parent:FindFirstChild(name.."_BackupBeforeV4") then
            local backup = old:Clone()
            backup.Name = name.."_BackupBeforeV4"
            backup.Enabled = false
            backup.Parent = parent
        end
        old:Destroy()
    end
    obj.Name = name
    obj.Enabled = true
end
print("[BabyBrawl V4] PATCH INSTALLED: training baby + fart run + combat diagnostics.")
print("[BabyBrawl V4] Save the place, then press the top BLUE PLAY button to test.")
print("[BabyBrawl V4] BONK within 7 studs of training baby: 96 -> 80 HP.")
print("[BabyBrawl V4] Hold Shift while moving: WalkSpeed should change 16 -> 32 and green smoke appears.")
print("[BabyBrawl V4] The 4 numbered special abilities are still placeholders.")
