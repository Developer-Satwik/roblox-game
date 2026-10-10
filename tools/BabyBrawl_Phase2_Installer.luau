-- Baby Brawl | PHASE 2 UPGRADE (run from Studio Command Bar)
-- Requires Phase 1 to be installed. DOES NOT touch your downloaded map.
-- Rerunnable: replaces only the two BabyBrawl Phase 2 scripts.
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local starterScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

assert(ReplicatedStorage:FindFirstChild("BabyBrawl_V1"), "Install Phase 1 first (missing ReplicatedStorage/BabyBrawl_V1)")
assert(ServerScriptService:FindFirstChild("BabyBrawl_Server"), "Install Phase 1 first (missing BabyBrawl_Server)")
assert(starterScripts:FindFirstChild("BabyBrawl_Client"), "Install Phase 1 first (missing BabyBrawl_Client)")

local serverSource = [====[--!strict
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


-- The "Uncanny Baby" starter face: slightly unsettling self-confidence on a
-- soft, crawling baby body. Inspired by exaggerated Roblox avatar expressions,
-- but all features are generated as original geometry (no copied decals/assets).
-- Geometry follows an approximate ellipsoid projection so it does not appear
-- as a floating, flat face card when the baby turns.
local function buildUncannyFace(shell: Model, head: BasePart)
    local BROW = Color3.fromRGB(41, 32, 43)
    local LINER = Color3.fromRGB(28, 25, 35)
    local WHITE = Color3.fromRGB(250, 245, 239)
    local IRIS = Color3.fromRGB(91, 61, 75)
    local PUPIL = Color3.fromRGB(26, 23, 30)
    local SHINE = Color3.fromRGB(255, 252, 247)
    local BLUSH = Color3.fromRGB(238, 160, 154)
    local LIP_DARK = Color3.fromRGB(109, 49, 70)
    local LIP = Color3.fromRGB(173, 87, 116)
    local LIP_LIGHT = Color3.fromRGB(211, 130, 146)

    local rx, ry, rz = head.Size.X/2, head.Size.Y/2, head.Size.Z/2
    local function stamp(name: string, size: Vector3, color: Color3,
        x: number, y: number, forward: number, tilt: number?, shape: Enum.PartType?): Part
        -- Project the center of each mark onto the forehead/cheek curvature.
        local u = x/rx
        local v = y/ry
        local surfaceZ = -rz * math.sqrt(math.max(.09, 1-u*u-v*v))
        return detail(shell, name, head, size, color,
            CFrame.new(x, y, surfaceZ-forward) *
            CFrame.Angles(0, 0, tilt or 0), shape)
    end

    -- Bald, round head; slight cheeks, but no big glowing "anime" eye whites.
    for _, side in ipairs({-1,1}) do
        local sideName = if side == -1 then "L" else "R"
        detail(shell, "UncannyEar_"..sideName, head,
            Vector3.new(.28,.31,.22), SKIN, CFrame.new(side*.76,-.14,.02))
        stamp("UncannyBlush_"..sideName, Vector3.new(.32,.16,.026),
            BLUSH, side*.49,-.24,.025, side*math.rad(5))

        -- Heavy, winged almond eyes with a half-lidded, sideways stare.
        stamp("UncannyEyeOutline_"..sideName, Vector3.new(.50,.28,.075),
            LINER, side*.315,.12,.045, side*math.rad(11))
        stamp("UncannySclera_"..sideName, Vector3.new(.405,.17,.050),
            WHITE, side*.315,.116,.095, side*math.rad(10))
        stamp("UncannyIris_"..sideName, Vector3.new(.225,.165,.047),
            IRIS, side*.34,.105,.135)
        stamp("UncannyPupil_"..sideName, Vector3.new(.142,.157,.045),
            PUPIL, side*.345,.10,.16)
        stamp("UncannyEyeShine_"..sideName, Vector3.new(.06,.065,.026),
            SHINE, side*.31,.158,.193)

        -- Draw the upper lid thicker than the lower one; it changes the
        -- entire expression from "cute doll" to mischievously smug.
        stamp("UncannyUpperLiner_"..sideName, Vector3.new(.49,.09,.055),
            LINER, side*.324,.223,.13, side*math.rad(10))
        stamp("UncannyWing_"..sideName, Vector3.new(.23,.074,.055),
            LINER, side*.56,.23,.11, side*math.rad(26), Enum.PartType.Block)
        stamp("UncannyLash_"..sideName, Vector3.new(.14,.055,.042),
            LINER, side*.557,.29,.13, side*math.rad(57), Enum.PartType.Block)

        -- The signature "way too confident for a baby" angled eyebrows.
        stamp("UncannyBrow_"..sideName, Vector3.new(.48,.115,.09),
            BROW, side*.335,.44,.06, side*math.rad(16))
        stamp("UncannyBrowTail_"..sideName, Vector3.new(.18,.09,.072),
            BROW, side*.53,.50,.078, side*math.rad(33))
    end

    -- Small original nose, full lips, and an off-center smirk.
    stamp("UncannyNose", Vector3.new(.16,.12,.13),
        SKIN_SHADE, 0,-.115,.065)
    stamp("UncannyMouthCrease", Vector3.new(.45,.105,.043),
        LIP_DARK, .025,-.417,.054, math.rad(-5))
    stamp("UncannyTopLip", Vector3.new(.43,.096,.047),
        LIP, .025,-.393,.092, math.rad(-5))
    stamp("UncannyBottomLip", Vector3.new(.385,.095,.053),
        LIP_LIGHT, .025,-.477,.082, math.rad(-4))
    stamp("UncannySmirkCorner", Vector3.new(.11,.045,.038),
        LIP_DARK, .243,-.375,.113, math.rad(-24), Enum.PartType.Block)
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
    shell:SetAttribute("Version", 3)
    shell:SetAttribute("FaceStyle", "UncannyBabyV1")
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

    local head = piece(shell, "Head", Vector3.new(1.55,1.60,1.51), SKIN)
    joint(body, "BB_HeadMotor", body, head, CFrame.new(0,0.51,-0.89))
    -- The shared body/animation motors remain identical to Phase 2.
    buildUncannyFace(shell, head)

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
    print("[BabyBrawl FACE V1] Uncanny baby ready for", ch.Name, "face style:", shell:GetAttribute("FaceStyle"), "body drop:", math.round(bodyDrop * 100) / 100)
end

local function listen(plr: Player)
    plr.CharacterAdded:Connect(function(ch)
        task.spawn(makeBaby, ch)
    end)
    if plr.Character then task.spawn(makeBaby, plr.Character) end
end
Players.PlayerAdded:Connect(listen)
for _,plr in ipairs(Players:GetPlayers()) do listen(plr) end
]====]
local clientSource = [====[--!strict
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
]====]

local function replaceScript(parent, name, className, source)
    local old = parent:FindFirstChild(name)
    if old then old:Destroy() end
    local scriptObject = Instance.new(className)
    scriptObject.Name = name
    scriptObject.Source = source
    scriptObject.Parent = parent
end
replaceScript(ServerScriptService, "BabyBrawl_BabyVisuals", "Script", serverSource)
replaceScript(starterScripts, "BabyBrawl_BabyAnimator", "LocalScript", clientSource)

-- A small nonessential label cleanup in our Phase 1 GUI script.
local hud = starterScripts:FindFirstChild("BabyBrawl_Client")
if hud and hud:IsA("LocalScript") then
    local updated = hud.Source:gsub("DEFAULT BABY   •   V1 CONTROL TEST","DEFAULT BABY")
    if updated ~= hud.Source then hud.Source = updated end
end
print("[BabyBrawl P2] Baby cosmetic shell + crawl/bonk/butt-block animations installed.")
print("[BabyBrawl P2] Save the place, then STOP and PLAY to refresh characters.")
print("[BabyBrawl P2] Imported map and Phase 1 combat remain unchanged.")
