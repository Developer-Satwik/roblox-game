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
