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
