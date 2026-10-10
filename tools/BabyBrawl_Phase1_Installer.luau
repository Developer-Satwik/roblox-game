-- Baby Brawl Phase 1 Studio Installer
-- Paste the entire file into Roblox Studio's Command Bar with your map open.
-- Builds map markers and installs the server and client scripts; preserves imported map assets.

local Workspace=game:GetService("Workspace")
local Players=game:GetService("Players")
local Lighting=game:GetService("Lighting")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerScriptService")
local SP=game:GetService("StarterPlayer")
local sps=SP:WaitForChild("StarterPlayerScripts")

local function remove(parent,name)
    local found=parent:FindFirstChild(name)
    if found then found:Destroy() end
end
remove(Workspace,"BabyBrawl_V1")
remove(RS,"BabyBrawl_V1")
remove(SS,"BabyBrawl_Server")
remove(sps,"BabyBrawl_Client")
local f=Instance.new("Folder")
f.Name="BabyBrawl_V1";f.Parent=Workspace
local arena=Instance.new("Folder");arena.Name="ArenaMarkers";arena.Parent=f
local spawns=Instance.new("Folder");spawns.Name="SpawnPoints";spawns.Parent=f
local decor=Instance.new("Folder");decor.Name="PlaygroundDecor";decor.Parent=f

local originals={}
for _,obj in Workspace:GetDescendants() do
    if obj:IsA("SpawnLocation") and not obj:IsDescendantOf(f) then
        table.insert(originals,obj)
    end
end
local y0=0
if #originals>0 then
    local p=originals[1]
    y0=p.Position.Y-p.Size.Y/2
end
local function ground(x,z)
    local rp=RaycastParams.new()
    rp.FilterType=Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances={f}
    local hit=Workspace:Raycast(Vector3.new(x,y0+45,z),Vector3.new(0,-140,0),rp)
    if hit and hit.Normal.Y>0.65 then return hit.Position.Y end
    return y0
end
local function part(parent,name,size,cf,color,material)
    local p=Instance.new("Part")
    p.Name=name;p.Size=size;p.CFrame=cf;p.Anchored=true
    p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
    p.Material=material or Enum.Material.SmoothPlastic
    p.Color=color;p.CastShadow=false
    p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=parent
    return p
end
local centerX,centerZ=8,5
for i=1,36 do
    local a=(i-.5)*math.pi*2/36
    local x,z=centerX+math.sin(a)*48,centerZ+math.cos(a)*48
    local color=i%2==0 and Color3.fromRGB(248,208,103) or Color3.fromRGB(247,243,232)
    local p=part(arena,"ArenaOutline_"..i,Vector3.new(.9,.12,8.6),
        CFrame.new(x,ground(x,z)+.08,z)*CFrame.Angles(0,a,0),color)
    p.Transparency=.07
end
for i=1,4 do
    local a=(i-1)*math.pi/2+math.pi/4
    local x,z=centerX+math.sin(a)*31,centerZ+math.cos(a)*31
    local p=Instance.new("SpawnLocation")
    p.Name="BabyBrawlSpawn_"..i
    p.Size=Vector3.new(6,.35,6)
    p.CFrame=CFrame.new(x,ground(x,z)+.18,z)
    p.Anchored=true;p.CanCollide=false;p.Neutral=true;p.Duration=0
    p.Transparency=.3;p.Material=Enum.Material.Neon
    p.BrickColor=BrickColor.new("Pastel light blue")
    p.Parent=spawns
end
for _,p in originals do
    if p:GetAttribute("BB_OriginalSpawnEnabled")==nil then
        p:SetAttribute("BB_OriginalSpawnEnabled",p.Enabled)
    end
    p.Enabled=false
end
local spots={{-46,0},{41,39},{31,-49}}
local colors={Color3.fromRGB(248,192,208),Color3.fromRGB(153,207,253),Color3.fromRGB(255,223,135)}
for i,offset in ipairs(spots) do
    local x,z=centerX+offset[1],centerZ+offset[2]
    local p=part(decor,"ToyBlock_"..i,Vector3.new(3.5,3.5,3.5),
        CFrame.new(x,ground(x,z)+2,z)*CFrame.Angles(0,math.rad(i*15),0),colors[i])
    local face=Instance.new("SurfaceGui")
    face.Face=Enum.NormalId.Front;face.CanvasSize=Vector2.new(256,256);face.Parent=p
    local txt=Instance.new("TextLabel")
    txt.BackgroundTransparency=1;txt.Size=UDim2.fromScale(1,1)
    txt.Text=({"B","A","B"})[i];txt.Font=Enum.Font.GothamBlack
    txt.TextScaled=true;txt.TextColor3=Color3.new(1,1,1);txt.Parent=face
end
Lighting.ClockTime=14
Lighting.Brightness=2
Lighting.EnvironmentDiffuseScale=.65
Lighting.ShadowSoftness=.5
SP.EnableMouseLockOption=false
Players.RespawnTime=2

local net=Instance.new("Folder")
net.Name="BabyBrawl_V1";net.Parent=RS
local event=Instance.new("RemoteEvent")
event.Name="CombatAction";event.Parent=net

local server=Instance.new("Script")
server.Name="BabyBrawl_Server"
server.Source=[====[
--!strict
-- Baby Brawl | Phase 1: server-authoritative control prototype.
-- Starter Roblox avatar is intentional: custom crawling baby arrives in Phase 2.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local rootFolder = ReplicatedStorage:WaitForChild("BabyBrawl_V1")
local combatEvent = rootFolder:WaitForChild("CombatAction") :: RemoteEvent
local stats: {[Player]: {lastAttack: number, lastRemote: number, blocking: boolean, sprinting: boolean, spawnAt: number}} = {}

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
    local state = {lastAttack=0, lastRemote=0, blocking=false, sprinting=false, spawnAt=0}
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
    local now = os.clock()
    if now-state.lastRemote < 0.035 then return end -- basic remote spam bound
    state.lastRemote = now
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

]====]
server.Parent=SS

local client=Instance.new("LocalScript")
client.Name="BabyBrawl_Client"
client.Source=[====[
--!strict
-- Baby Brawl | Phase 1: familiar battlegrounds UI and keyboard/touch controls.
-- Uses Roblox's default joystick and jump button. Four ability slots are
-- intentionally nonfunctional until the custom baby and animations ship.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local action = RS:WaitForChild("BabyBrawl_V1"):WaitForChild("CombatAction") :: RemoteEvent
local mobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local pg = player:WaitForChild("PlayerGui")
local currentGui = pg:FindFirstChild("BabyBrawlHUD")
if currentGui then currentGui:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "BabyBrawlHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 5
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Parent = pg

local function rounded(inst: GuiObject, radius: number)
    local u = Instance.new("UICorner")
    u.CornerRadius = UDim.new(0, radius)
    u.Parent = inst
end
local function text(parent: Instance, content: string, size: number, color: Color3): TextLabel
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold
    t.Text = content
    t.TextColor3 = color
    t.TextSize = size
    t.TextScaled = false
    t.TextWrapped = true
    t.Parent = parent
    return t
end
local white = Color3.fromRGB(255,255,255)
local bg = Color3.fromRGB(17,23,31)
local muted = Color3.fromRGB(185,194,210)
local accent = Color3.fromRGB(255,209,90)
local function button(parent: Instance, caption: string, size: UDim2, pos: UDim2, anchor: Vector2, color: Color3): TextButton
    local b = Instance.new("TextButton")
    b.Name = caption:gsub("[^%w]","") .. "Button"
    b.Size=size; b.Position=pos; b.AnchorPoint=anchor
    b.BackgroundColor3=color; b.BorderSizePixel=0
    b.Font=Enum.Font.GothamBold; b.Text=caption; b.TextSize=14
    b.TextColor3=white; b.AutoButtonColor=true
    rounded(b,12); b.Parent=parent
    return b
end

-- Central abilities: same exact placement on desktop and mobile.
local scale = Instance.new("UIScale")
local bar = Instance.new("Frame")
bar.Name="Abilities_BottomCenter"
bar.AnchorPoint=Vector2.new(0.5,1)
bar.Position=UDim2.new(0.5,0,1,-12)
bar.Size=UDim2.fromOffset(380,98)
bar.BackgroundColor3=bg
bar.BackgroundTransparency=0.22
bar.BorderSizePixel=0
rounded(bar,12)
bar.Parent=gui
scale.Parent=bar

local title=text(bar,"DEFAULT BABY   •   V1 CONTROL TEST",11,muted)
title.Size=UDim2.new(1,0,0,19)
title.Position=UDim2.fromOffset(0,6)
local healthBack=Instance.new("Frame")
healthBack.Name="HealthTrack"; healthBack.Size=UDim2.new(1,-24,0,7)
healthBack.Position=UDim2.fromOffset(12,28)
healthBack.BackgroundColor3=Color3.fromRGB(66,74,85)
healthBack.BorderSizePixel=0; healthBack.Parent=bar; rounded(healthBack,6)
local healthFill=Instance.new("Frame")
healthFill.Name="HealthFill"; healthFill.Size=UDim2.fromScale(1,1)
healthFill.BackgroundColor3=Color3.fromRGB(101,215,148)
healthFill.BorderSizePixel=0; healthFill.Parent=healthBack; rounded(healthFill,6)
local spells={{"1","TONGUE TAG"},{"2","BELLY FLOP"},{"3","MEGA BURP"},{"4","TANTRUM"}}
local boxes: {TextButton} = {}
for i,data in ipairs(spells) do
    local b=button(bar,data[1].."\n"..data[2],UDim2.fromOffset(86,48),UDim2.fromOffset(11+(i-1)*92,42),Vector2.new(0,0),Color3.fromRGB(45,53,65))
    b.Name="Ability"..i
    b.TextSize=10
    b.TextColor3=Color3.fromRGB(222,229,239)
    table.insert(boxes,b)
end
local toast = text(gui,"",12,white)
toast.Name="FeedbackToast"
toast.AnchorPoint=Vector2.new(0.5,1)
toast.Position=UDim2.new(0.5,0,1,-124)
toast.Size=UDim2.fromOffset(340,30)
toast.BackgroundColor3=bg; toast.BackgroundTransparency=0.26
rounded(toast,8)
toast.Visible=false
local toastSeq=0
local function notify(message: string)
    toastSeq += 1
    local ticket=toastSeq
    toast.Text=message;toast.Visible=true
    task.delay(1.6,function()
        if toastSeq==ticket then toast.Visible=false end
    end)
end
for i,b in ipairs(boxes) do
    b.Activated:Connect(function()
        notify("Ability "..i.." arrives with the baby rig")
    end)
end

-- Lightweight KO indicator, upper right, clear of native Roblox topbar.
local counter=text(gui,"KOs: 0",15,white)
counter.Name="KOCounter"
counter.AnchorPoint=Vector2.new(1,0)
counter.Position=UDim2.new(1,-14,0,15)
counter.Size=UDim2.fromOffset(92,36)
counter.BackgroundColor3=bg;counter.BackgroundTransparency=0.24
rounded(counter,12)
local function setupStats()
    local leader = player:WaitForChild("leaderstats",15)
    if not leader then return end
    local kos = leader:WaitForChild("KOs",15)
    if kos and kos:IsA("IntValue") then
        local function update() counter.Text="KOs: "..kos.Value end
        update(); kos.Changed:Connect(update)
    end
end
task.spawn(setupStats)

local blocking=false
local sprinting=false
local lastLocalAttack=0
local function sendAttack()
    if blocking then return end
    local t=os.clock()
    if t-lastLocalAttack < .55 then return end
    lastLocalAttack=t
    action:FireServer("Attack")
end
local blockButton: TextButton?=nil
local sprintButton: TextButton?=nil
local function setBlock(v: boolean)
    blocking=v
    if v then sprinting=false end
    action:FireServer("Block",v)
    if blockButton then blockButton.BackgroundColor3=v and Color3.fromRGB(84,154,198) or bg end
    if sprintButton then sprintButton.BackgroundColor3=bg end
end
local function setSprint(v: boolean)
    if v and blocking then setBlock(false) end
    sprinting=v
    action:FireServer("Sprint",v)
    if sprintButton then sprintButton.BackgroundColor3=v and Color3.fromRGB(65,167,106) or bg end
end

if mobile then
    -- Keep all native Roblox movement/jump controls intact; place our combat
    -- controls above them, in the usual right-thumb area.
    local right=Instance.new("Frame")
    right.Name="Mobile_Combat_Buttons"; right.BackgroundTransparency=1
    right.AnchorPoint=Vector2.new(1,1)
    right.Position=UDim2.new(1,-14,1,-135)
    right.Size=UDim2.fromOffset(150,150)
    right.Parent=gui
    local bonk=button(right,"BONK",UDim2.fromOffset(66,66),UDim2.fromOffset(79,76),Vector2.new(0,0),accent)
    bonk.TextColor3=Color3.fromRGB(65,45,15)
    bonk.Activated:Connect(sendAttack)
    blockButton=button(right,"BLOCK",UDim2.fromOffset(61,48),UDim2.fromOffset(10,90),Vector2.new(0,0),bg)
    blockButton.Activated:Connect(function() setBlock(not blocking) end)
    sprintButton=button(right,"FART\nRUN",UDim2.fromOffset(60,58),UDim2.fromOffset(8,24),Vector2.new(0,0),bg)
    sprintButton.TextSize=12
    sprintButton.Activated:Connect(function() setSprint(not sprinting) end)
else
    -- Keyboard and mouse: left click, F to block, Shift to fart sprint, 1–4.
    UIS.InputBegan:Connect(function(input, processed)
        if processed or UIS:GetFocusedTextBox() then return end
        if input.UserInputType==Enum.UserInputType.MouseButton1 then sendAttack() end
        if input.KeyCode==Enum.KeyCode.F then setBlock(true) end
        if input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift then setSprint(true) end
        local numberKeys={Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four}
        for i,k in ipairs(numberKeys) do
            if input.KeyCode==k then notify("Ability "..i.." arrives with the baby rig") end
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.KeyCode==Enum.KeyCode.F then setBlock(false) end
        if input.KeyCode==Enum.KeyCode.LeftShift or input.KeyCode==Enum.KeyCode.RightShift then setSprint(false) end
    end)
end

-- Simple local gas trail (visual ONLY) for the Fart Run input; other client
-- visuals and custom baby animations will be built after the rig exists.
local emitter: ParticleEmitter?=nil
local function onCharacter(ch: Model)
    blocking=false;sprinting=false
    local root=ch:WaitForChild("HumanoidRootPart",10)
    if root and root:IsA("BasePart") then
        local attach=Instance.new("Attachment")
        attach.Name="BabyBrawl_GasAttachment"
        attach.Position=Vector3.new(0,-1,1)
        attach.Parent=root
        local gas=Instance.new("ParticleEmitter")
        gas.Name="FartSprintTrail"
        gas.Enabled=false
        gas.Color=ColorSequence.new(Color3.fromRGB(151,240,118),Color3.fromRGB(76,181,84))
        gas.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.25),NumberSequenceKeypoint.new(1,1)})
        gas.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.35),NumberSequenceKeypoint.new(1,1.6)})
        gas.Lifetime=NumberRange.new(.25,.55)
        gas.Speed=NumberRange.new(1,3)
        gas.Rate=19
        gas.SpreadAngle=Vector2.new(30,30)
        gas.Parent=attach
        emitter=gas
    end
    local hum=ch:WaitForChild("Humanoid",10)
    if hum and hum:IsA("Humanoid") then
        local function update() healthFill.Size=UDim2.fromScale(math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1),1) end
        update();hum.HealthChanged:Connect(update)
    end
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then task.spawn(onCharacter,player.Character) end
UIS.WindowFocusReleased:Connect(function()
    if not mobile then setBlock(false); setSprint(false) end
end)
action.OnClientEvent:Connect(function(kind,uid,flag)
    if kind=="SprintFX" and uid==player.UserId and emitter then
        emitter.Enabled=flag==true
    elseif kind=="HitFX" and uid==player.UserId then
        notify("BONK!")
    elseif kind=="BlockedFX" and uid==player.UserId then
        notify("BLOCKED!")
    end
end)
local function updateScale()
    camera=workspace.CurrentCamera
    if not camera then return end
    local viewport=camera.ViewportSize
    if mobile then
        scale.Scale=math.clamp(viewport.X/810,.68,1)
    else
        scale.Scale=math.clamp(viewport.X/1100,.84,1.08)
    end
end
updateScale()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale) end
print("[BabyBrawl V1] Controls ready: PC LMB/F/Shift/1–4; mobile BONK/BLOCK/FART RUN + 1–4")

]====]
client.Parent=sps
print("[BabyBrawl] Phase 1 installed. Original map kept; test using Play and Device Emulator.")
