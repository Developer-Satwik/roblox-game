-- Baby Brawl | Combat Feedback Patch (Studio Command Bar, EDIT mode only)
-- Requires Phase 1 and Phase 2. Safe to rerun; it does not edit the map.
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local starterScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
assert(ReplicatedStorage:FindFirstChild("BabyBrawl_V1"),"Phase 1 is missing (ReplicatedStorage/BabyBrawl_V1)")
assert(ServerScriptService:FindFirstChild("BabyBrawl_Server"),"Phase 1 server is missing")
assert(ServerScriptService:FindFirstChild("BabyBrawl_BabyVisuals"),"Install Phase 2 baby visuals first")
assert(starterScripts:FindFirstChild("BabyBrawl_BabyAnimator"),"Install Phase 2 baby animator first")

local files = {
    {starterScripts, "BabyBrawl_Client", "LocalScript", [====[--!strict
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
    -- Play the local baby's bonk pose immediately; server still validates hits.
    local ch = player.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if hum then hum:SetAttribute("BB_AttackPulseUntil", t + .39) end
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
    elseif kind=="PracticeHitFX" and uid==player.UserId then
        notify("PRACTICE BONK! "..tostring(math.max(0,math.ceil(tonumber(flag) or 0))).." HP LEFT")
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
]====]},
    {starterScripts, "BabyBrawl_BabyAnimator", "LocalScript", [====[--!strict
-- Baby Brawl | Phase 2 client-side procedural crawling animation.
-- No uploaded animation IDs needed; reads replicated cosmetic Motor6Ds.
-- Every client animates every visible baby, while the server owns combat.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer

type RigState = {
    player: Player,
    char: Model,
    humanoid: Humanoid,
    root: BasePart,
    body: Motor6D,
    head: Motor6D,
    leftArm: Motor6D,
    rightArm: Motor6D,
    leftLeg: Motor6D,
    rightLeg: Motor6D,
    diaper: BasePart,
    gas: ParticleEmitter?,
    time: number,
    blockWeight: number,
    attackUntil: number,
    impactUntil: number,
}
local rigs: {[Model]: RigState} = {}
local event = ReplicatedStorage:WaitForChild("BabyBrawl_V1"):WaitForChild("CombatAction") :: RemoteEvent

local function makeGas(diaper: BasePart): ParticleEmitter
    local attachment = Instance.new("Attachment")
    attachment.Name = "BB_RemoteFartAttachment"
    attachment.Position = Vector3.new(0,-.08,.5)
    attachment.Parent = diaper
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "BB_RemoteFart"
    emitter.Color = ColorSequence.new(Color3.fromRGB(169,233,113),Color3.fromRGB(79,179,76))
    emitter.Lifetime = NumberRange.new(.25,.55)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0,.32),
        NumberSequenceKeypoint.new(1,1.25),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,.24),
        NumberSequenceKeypoint.new(1,1),
    })
    emitter.Speed = NumberRange.new(.5,2.2)
    emitter.SpreadAngle = Vector2.new(30,30)
    emitter.Rate = 12
    emitter.Enabled = false
    emitter.Parent = attachment
    return emitter
end

local function bind(plr: Player, ch: Model)
    local humanoid = ch:WaitForChild("Humanoid",15)
    local root = ch:WaitForChild("HumanoidRootPart",15)
    local shell = ch:WaitForChild("BabyBrawl_BabyShell",20)
    if not shell or not humanoid or not root then return end
    if not humanoid:IsA("Humanoid") or not root:IsA("BasePart") or not shell:IsA("Model") then return end
    if not ch.Parent then return end

    local bodyPart = shell:FindFirstChild("Body")
    local diaperPart = shell:FindFirstChild("Diaper")
    local bodyMotor = root:FindFirstChild("BB_BodyMotor")
    if not bodyPart or not bodyPart:IsA("BasePart") then return end
    if not diaperPart or not diaperPart:IsA("BasePart") then return end
    if not bodyMotor or not bodyMotor:IsA("Motor6D") then return end
    local function motor(name: string): Motor6D?
        local m = bodyPart:FindFirstChild(name)
        return if m and m:IsA("Motor6D") then m else nil
    end
    local head = motor("BB_HeadMotor")
    local leftArm = motor("BB_LeftArm")
    local rightArm = motor("BB_RightArm")
    local leftLeg = motor("BB_LeftLeg")
    local rightLeg = motor("BB_RightLeg")
    if not head or not leftArm or not rightArm or not leftLeg or not rightLeg then return end
    if rigs[ch] then return end

    local emitter: ParticleEmitter? = nil
    if plr ~= localPlayer then emitter = makeGas(diaperPart) end

    rigs[ch] = {
        player = plr, char = ch, humanoid = humanoid, root = root,
        body = bodyMotor, head = head,
        leftArm = leftArm, rightArm = rightArm, leftLeg = leftLeg, rightLeg = rightLeg,
        diaper = diaperPart, gas = emitter, time = 0,
        blockWeight = 0, attackUntil = 0, impactUntil = 0,
    }
    -- We offset only the local player's camera; other players keep their own.
    if plr == localPlayer then humanoid.CameraOffset = Vector3.new(0,-1.12,0) end
end

local function watch(plr: Player)
    plr.CharacterAdded:Connect(function(ch)
        task.spawn(bind,plr,ch)
    end)
    plr.CharacterRemoving:Connect(function(ch) rigs[ch]=nil end)
    if plr.Character then task.spawn(bind,plr,plr.Character) end
end
for _,p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(function(p)
    for ch, rig in pairs(rigs) do
        if rig.player == p then rigs[ch]=nil end
    end
end)

event.OnClientEvent:Connect(function(kind: any, uid: any)
    if typeof(uid) ~= "number" then return end
    local now = os.clock()
    for _,r in pairs(rigs) do
        if r.player.UserId == uid then
            if kind == "AttackFX" then
                r.attackUntil = now + .29
            elseif kind == "HitFX" then
                r.impactUntil = now + .38
            elseif kind == "BlockedFX" then
                r.impactUntil = now + .17
            end
            break
        end
    end
end)

RunService.PreSimulation:Connect(function(dt: number)
    local now = os.clock()
    for ch,r in pairs(rigs) do
        if not ch.Parent or r.humanoid.Health <= 0 then
            if not ch.Parent then rigs[ch] = nil end
            if r.gas then r.gas.Enabled = false end
            continue
        end
        r.time += dt
        local v = r.root.AssemblyLinearVelocity
        local horizontalSpeed = Vector3.new(v.X,0,v.Z).Magnitude
        local moving = horizontalSpeed > 1.4
        local running = moving and r.humanoid.WalkSpeed > 20
        local stride = moving and math.clamp(horizontalSpeed/16,.5,1.9) or 0
        local phase = r.time * (running and 14 or 9)
        local wave = math.sin(phase)
        local opposite = math.sin(phase+math.pi)

        local blocking = r.humanoid:GetAttribute("BB_Blocking") == true
        r.blockWeight += ( (blocking and 1 or 0) - r.blockWeight ) * math.min(1,dt*12)
        local a = r.blockWeight
        -- Predict the local player's bonk pose immediately, independently of
        -- whether another player is in range; the server remains authoritative.
        if r.player == localPlayer then
            local localPulse = r.humanoid:GetAttribute("BB_AttackPulseUntil")
            if typeof(localPulse) == "number" then
                r.attackUntil = math.max(r.attackUntil, localPulse)
            end
        end
        local attack = math.clamp((r.attackUntil-now)/.39,0,1)
        attack = math.sin(attack*math.pi)
        local impact = math.clamp((r.impactUntil-now)/.38,0,1)
        local bob = moving and (.043*math.abs(math.sin(phase*2))) or (.025*math.sin(r.time*2))

        -- Butt Guard: baby's body turns so the diaper faces the attacker.
        -- Phase 2 still uses Phase 1's omni-directional block validation.
        r.body.Transform =
            CFrame.new(0,bob+.12*a,.08*a-.27*attack)
            * CFrame.Angles(math.rad(-11)*a + math.rad(10)*attack - math.rad(8)*impact,
                math.pi*a, 0)
        r.head.Transform =
            CFrame.new(0,.08*a,-.37*attack)
            * CFrame.Angles(math.rad(-8)*a+math.rad(25)*attack+math.rad(12)*impact,
                math.sin(r.time*1.4)*.035,0)

        -- The baby alternates knees and hands instead of upright walking.
        local amount = stride*(1-a)
        r.leftArm.Transform = CFrame.Angles(wave*.38*amount+attack*.35,0,0)
        r.rightArm.Transform = CFrame.Angles(opposite*.38*amount+attack*.35,0,0)
        r.leftLeg.Transform = CFrame.Angles(opposite*.46*amount,0,0)
        r.rightLeg.Transform = CFrame.Angles(wave*.46*amount,0,0)
        if r.gas then r.gas.Enabled = running and not blocking end
    end
end)
print("[BabyBrawl P2] Client baby crawl, bonk and butt-guard poses ready")
]====]},
    {ServerScriptService, "BabyBrawl_PracticeDummy", "Script", [====[--!strict
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
local RANGE = 6
local state: {[Player]: {model: Model?, lastHit: number}} = {}

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
    local near = root.Position + look*4.7
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
    local hum = Instance.new("Humanoid")
    hum.Name = "Humanoid"
    hum.RequiresNeck = false
    hum.BreakJointsOnDeath = false
    hum.MaxHealth = TARGET_HEALTH
    hum.Health = TARGET_HEALTH
    hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    hum.Parent = model

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
    local function update()
        label.Text = "PRACTICE BABY\n"..math.ceil(math.max(hum.Health,0)).." / "..TARGET_HEALTH.." HP"
    end
    hum.HealthChanged:Connect(update)
    update()

    entry.model = model
    hum.Died:Connect(function()
        label.Text = "BONKED!\nRespawning..."
        task.delay(1.5, function()
            if model == entry.model and plr.Parent and plr.Character == ch then
                spawnTarget(plr,ch)
            end
        end)
    end)
    print("[BabyBrawl QA] Practice baby ready. Face it and LEFT CLICK or tap BONK to test.")
end

local function attach(plr: Player)
    state[plr] = {model=nil,lastHit=0}
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
    if not entry or not entry.model or not entry.model.Parent then return end
    local now = os.clock()
    if now - entry.lastHit < .55 then return end
    local ch = plr.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    local attackerHum = ch and ch:FindFirstChildOfClass("Humanoid")
    local dummy = entry.model
    local target = dummy:FindFirstChild("HumanoidRootPart")
    local targetHum = dummy:FindFirstChildOfClass("Humanoid")
    if not root or not root:IsA("BasePart") or not attackerHum or attackerHum.Health <= 0 then return end
    if not target or not target:IsA("BasePart") or not targetHum or targetHum.Health <= 0 then return end
    if attackerHum:GetAttribute("BB_Blocking") == true then return end

    local delta = target.Position-root.Position
    local planar = Vector3.new(delta.X,0,delta.Z)
    if planar.Magnitude < .05 or planar.Magnitude >= RANGE or math.abs(delta.Y)>4.5 then return end
    if root.CFrame.LookVector:Dot(planar.Unit) <= .45 then return end
    entry.lastHit = now
    targetHum:TakeDamage(16)
    local highlight = Instance.new("Highlight")
    highlight.Adornee = dummy
    highlight.FillColor = Color3.fromRGB(255,232,93)
    highlight.FillTransparency = .18
    highlight.OutlineColor = Color3.fromRGB(255,255,255)
    highlight.Parent = dummy
    Debris:AddItem(highlight,.15)
    combat:FireClient(plr, "PracticeHitFX", plr.UserId, targetHum.Health)
    print("[BabyBrawl QA] Practice hit", plr.Name, math.ceil(targetHum.Health), "HP left")
end)

print("[BabyBrawl QA] Studio-only practice target system ready")
]====]},
}

for _,spec in ipairs(files) do
    local parent, name, className, source = spec[1],spec[2],spec[3],spec[4]
    local existing = parent:FindFirstChild(name)
    if existing and not existing:IsA(className) then
        error(name.." exists but is not a "..className..", please inspect before replacing")
    end
    local newScript = Instance.new(className)
    newScript.Name = name.."_Replacement"
    newScript.Source = source
    newScript.Enabled = false
    newScript.Parent = parent
    if existing then existing:Destroy() end
    newScript.Name = name
    newScript.Enabled = true
end

print("[BabyBrawl CombatFix] Installed. Save, STOP and PLAY to refresh scripts.")
print("[BabyBrawl CombatFix] When testing alone in Studio, a PRACTICE BABY appears ~5 studs ahead.")
print("[BabyBrawl CombatFix] LMB/BONK performs visible headbutt. Real player damage still uses Phase 1 validation.")
print("[BabyBrawl CombatFix] Special abilities 1–4 are not implemented yet.")
