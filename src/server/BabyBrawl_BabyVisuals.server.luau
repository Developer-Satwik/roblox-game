--!strict
-- Baby Brawl | Phase 2 baby shell (visual prototype).
-- Build one replicated chubby crawling baby over each player's existing Humanoid.
-- The original Humanoid remains the movement/collision controller. We are
-- NOT yet shipping a custom skinned MeshPart rig or low-profile collision body.
local Players = game:GetService("Players")

local SKIN = Color3.fromRGB(247,195,159)
local SKIN_SHADE = Color3.fromRGB(232,166,136)
local CHEEK = Color3.fromRGB(245,148,144)
local DIAPER = Color3.fromRGB(248,250,252)
local DIAPER_ACCENT = Color3.fromRGB(145,198,239)
local EYE = Color3.fromRGB(37,43,51)

local function piece(model: Model, name: string, size: Vector3, color: Color3, shape: Enum.PartType?): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Shape = shape or Enum.PartType.Ball
    p.Material = Enum.Material.SmoothPlastic
    p.Color = color
    p.Transparency = 0
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = true
    p.Massless = true
    p.Anchored = false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = model
    return p
end

local function joint(parent: Instance, name: string, from: BasePart, child: BasePart, offset: CFrame): Motor6D
    child.CFrame = from.CFrame * offset
    local m = Instance.new("Motor6D")
    m.Name = name
    m.Part0 = from
    m.Part1 = child
    m.C0 = offset
    m.C1 = CFrame.identity
    m.Parent = parent
    return m
end

local function detail(model: Model, name: string, parentPart: BasePart, size: Vector3, color: Color3, offset: CFrame, shape: Enum.PartType?): Part
    local p = piece(model, name, size, color, shape)
    p.CFrame = parentPart.CFrame * offset
    local weld = Instance.new("WeldConstraint")
    weld.Name = "BB_DetailWeld"
    weld.Part0 = parentPart
    weld.Part1 = p
    weld.Parent = p
    return p
end

local function makeBaby(ch: Model)
    local root = ch:WaitForChild("HumanoidRootPart", 12)
    local hum = ch:WaitForChild("Humanoid", 12)
    if not root or not root:IsA("BasePart") or not hum or not hum:IsA("Humanoid") then
        return
    end
    if not ch.Parent or ch:FindFirstChild("BabyBrawl_BabyShell") then return end

    local shell = Instance.new("Model")
    shell.Name = "BabyBrawl_BabyShell"
    shell:SetAttribute("Version", 2)
    shell.Parent = ch

    -- Keep the baby's palms/knees near the floor while the invisible humanoid
    -- keeps its normal collision. The previous constant -1.32 left babies
    -- hovering because Roblox places the HumanoidRootPart well above ground.
    -- Roblox documents different root-height formulas for R15 and R6 rigs.
    local standingRootHeight = hum.HipHeight + root.Size.Y * 0.5
    if hum.RigType == Enum.HumanoidRigType.R6 then
        local leg = ch:FindFirstChild("Left Leg")
        standingRootHeight += (leg and leg:IsA("BasePart")) and leg.Size.Y or 2
    end
    -- The visual palms and knees reach about 0.88 studs below the body center.
    -- Thus, a 0.95 stud body center puts them ~0.07 studs above ground.
    local bodyDrop = math.max(0.5, standingRootHeight - 0.95)
    shell:SetAttribute("VisualBodyDrop", bodyDrop)
    local body = piece(shell, "Body", Vector3.new(1.45,1.24,1.74), SKIN)
    joint(root, "BB_BodyMotor", root, body, CFrame.new(0,-bodyDrop,-0.03))
    shell.PrimaryPart = body

    local head = piece(shell, "Head", Vector3.new(1.53,1.46,1.47), SKIN)
    joint(body, "BB_HeadMotor", body, head, CFrame.new(0,0.51,-0.89))
    -- Face looks forward, which is local -Z in Roblox.
    for _,sgn in ipairs({-1,1}) do
        local side = sgn
        detail(shell, "Ear", head, Vector3.new(.28,.35,.20), SKIN, CFrame.new(side*.76,-.11,0))
        detail(shell, "Cheek", head, Vector3.new(.42,.30,.12), CHEEK, CFrame.new(side*.46,-.25,-.625))
        detail(shell, "EyeWhite", head, Vector3.new(.37,.42,.115), Color3.fromRGB(255,255,252), CFrame.new(side*.32,.14,-.672))
        detail(shell, "Iris", head, Vector3.new(.235,.29,.075), Color3.fromRGB(104,65,43), CFrame.new(side*.32,.115,-.745))
        detail(shell, "Pupil", head, Vector3.new(.155,.22,.055), EYE, CFrame.new(side*.32,.11,-.782))
        detail(shell, "EyeShine", head, Vector3.new(.068,.08,.030), DIAPER, CFrame.new(side*.355,.195,-.815))
        detail(shell, "Eyebrow", head, Vector3.new(.34,.078,.08), SKIN_SHADE,
            CFrame.new(side*.32,.425,-.681)*CFrame.Angles(0,0,side*math.rad(-12)), Enum.PartType.Block)
    end
    detail(shell, "Nose", head, Vector3.new(.19,.14,.16), SKIN_SHADE, CFrame.new(0,-.11,-.738))
    detail(shell, "Mouth", head, Vector3.new(.36,.27,.065), Color3.fromRGB(112,48,61), CFrame.new(0,-.385,-.655))
    detail(shell, "Tongue", head, Vector3.new(.20,.075,.035), Color3.fromRGB(251,146,157), CFrame.new(0,-.49,-.704))
    detail(shell, "HairCurl", head, Vector3.new(.20,.20,.24), Color3.fromRGB(106,70,50), CFrame.new(.11,.77,-.13))

    local diaper = piece(shell, "Diaper", Vector3.new(1.48,1.05,1.17), DIAPER)
    joint(body, "BB_DiaperMotor", body, diaper, CFrame.new(0,-.12,.63))
    local flap = detail(shell, "DiaperWaist", diaper, Vector3.new(1.40,.18,.93), DIAPER_ACCENT, CFrame.new(0,.36,-.04))
    flap.Transparency = .12
    for _,side in ipairs({-1,1}) do
        detail(shell, "DiaperTab", diaper, Vector3.new(.19,.23,.35), DIAPER_ACCENT, CFrame.new(side*.71,.14,-.12), Enum.PartType.Block)
        detail(shell, "DiaperDots", diaper, Vector3.new(.15,.15,.045), DIAPER_ACCENT, CFrame.new(side*.34,.05,.578))
    end

    for _,side in ipairs({-1,1}) do
        local arm = piece(shell, "Arm_"..side, Vector3.new(.48,.82,.56), SKIN)
        joint(body, side == -1 and "BB_LeftArm" or "BB_RightArm", body, arm,
            CFrame.new(side*.64,-.33,-.63)*CFrame.Angles(0,0,side*math.rad(10)))
        detail(shell, "Hand_"..side, arm, Vector3.new(.53,.24,.49), SKIN, CFrame.new(0,-.43,-.09))
        local leg = piece(shell, "Leg_"..side, Vector3.new(.54,.71,.60), SKIN)
        joint(body, side == -1 and "BB_LeftLeg" or "BB_RightLeg", body, leg,
            CFrame.new(side*.56,-.34,.72)*CFrame.Angles(math.rad(-14),0,side*math.rad(-9)))
        detail(shell, "Foot_"..side, leg, Vector3.new(.48,.28,.53), SKIN, CFrame.new(0,-.40,.10))
    end

    hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    -- Original avatar is visually hidden, but its collision/humanoid controls
    -- are kept until the final baby rig is skinned and tested.
    local function hideOriginal(obj: Instance)
        if obj:IsDescendantOf(shell) then return end
        if obj:IsA("BasePart") then
            obj.Transparency = 1
            if obj:IsA("MeshPart") then
                -- Transparency also hides accessory handles.
            end
        elseif obj:IsA("Decal") then
            obj.Transparency = 1
        end
    end
    for _,d in ipairs(ch:GetDescendants()) do hideOriginal(d) end
    local connection = ch.DescendantAdded:Connect(hideOriginal)
    ch.Destroying:Once(function() connection:Disconnect() end)
    print("[BabyBrawl P2] Crawling baby shell grounded for", ch.Name, "visual body drop:", math.round(bodyDrop * 100) / 100)
end

local function listen(plr: Player)
    plr.CharacterAdded:Connect(function(ch)
        task.spawn(makeBaby, ch)
    end)
    if plr.Character then task.spawn(makeBaby, plr.Character) end
end
Players.PlayerAdded:Connect(listen)
for _,plr in ipairs(Players:GetPlayers()) do listen(plr) end
