--!strict
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
        local attack = math.clamp((r.attackUntil-now)/.29,0,1)
        attack = math.sin(attack*math.pi)
        local impact = math.clamp((r.impactUntil-now)/.38,0,1)
        local bob = moving and (.043*math.abs(math.sin(phase*2))) or (.025*math.sin(r.time*2))

        -- Butt Guard: baby's body turns so the diaper faces the attacker.
        -- Phase 2 still uses Phase 1's omni-directional block validation.
        r.body.Transform =
            CFrame.new(0,bob+.12*a,.08*a-.09*attack)
            * CFrame.Angles(math.rad(-11)*a + math.rad(10)*attack - math.rad(8)*impact,
                math.pi*a, 0)
        r.head.Transform =
            CFrame.new(0,.08*a,-.22*attack)
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
