--!strict
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
