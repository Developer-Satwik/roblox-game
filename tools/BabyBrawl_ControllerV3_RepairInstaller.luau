-- Baby Brawl: Stable Controller v3 Repair (EDIT MODE Command Bar)
-- Re-runnable. Preserves map, baby character, practice target and animations.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
assert(ReplicatedStorage:FindFirstChild("BabyBrawl_V1"), "Phase 1 remotes missing. Stop here; do not reinstall everything.")
local server = ServerScriptService:FindFirstChild("BabyBrawl_Server")
assert(server and server:IsA("Script"), "Expected existing ServerScriptService/BabyBrawl_Server")
local old = scripts:FindFirstChild("BabyBrawl_Client")
assert(not old or old:IsA("LocalScript"), "Existing BabyBrawl_Client is not a LocalScript")
local versioned = scripts:FindFirstChild("BabyBrawl_ControllerV3")
assert(not versioned or versioned:IsA("LocalScript"), "Unexpected object named BabyBrawl_ControllerV3")

local clientSource = [=====[--!strict
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
    if gas then gas.Enabled=on end
    refreshButtons()
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
        local att=Instance.new("Attachment")
        att.Name="BB3_GasAttachment"
        att.Position=Vector3.new(0,-1,1)
        att.Parent=root
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
    elseif kind=="BlockedFX" then
        notify("BLOCKED!")
    elseif kind=="BlockFX" then
        print("[BB v3] Server confirmed block:",flag)
    elseif kind=="SprintFX" then
        print("[BB v3] Server confirmed sprint:",flag)
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
]=====]
local serverSource = [=====[--!strict
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
        hum.WalkSpeed = state.blocking and 8 or (state.sprinting and 25 or 16)
        hum:SetAttribute("BB_Blocking", state.blocking)
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
    if now - lastForAction < 0.035 then return end
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
]=====]

-- Install replacements first; only disable old code after the new scripts exist.
local newController = Instance.new("LocalScript")
newController.Name = "BabyBrawl_ControllerV3_Staging"
newController.Enabled = false
newController.Source = clientSource
newController.Parent = scripts

local newServer = Instance.new("Script")
newServer.Name = "BabyBrawl_Server_Staging"
newServer.Enabled = false
newServer.Source = serverSource
newServer.Parent = ServerScriptService

-- One disabled backup is retained for rollback (do not overwrite it).
if not ServerScriptService:FindFirstChild("BabyBrawl_Server_BackupBeforeV3") then
    local backup = server:Clone()
    backup.Name = "BabyBrawl_Server_BackupBeforeV3"
    backup.Enabled = false
    backup.Parent = ServerScriptService
end
if old then
    old.Enabled = false
    if not scripts:FindFirstChild("BabyBrawl_Client_LegacyDisabled") then
        old.Name = "BabyBrawl_Client_LegacyDisabled"
    else
        old:Destroy()
    end
end
if versioned then versioned:Destroy() end
server:Destroy()
newServer.Name = "BabyBrawl_Server"
newServer.Enabled = true
newController.Name = "BabyBrawl_ControllerV3"
newController.Enabled = true

print("[BabyBrawl V3] FIX INSTALLED in Edit mode.")
print("[BabyBrawl V3] Disabled old BabyBrawl_Client, added stable ControllerV3 and updated combat server.")
print("[BabyBrawl V3] SAVE, STOP, then BLUE PLAY. You should see 4 bottom-center abilities and KOs at top-right.")
print("[BabyBrawl V3] In Studio QA: INPUT should update; SERVER should show InputAck for F, Shift, and LMB.")
