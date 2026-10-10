--!strict
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
