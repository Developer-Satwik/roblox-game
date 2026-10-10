--!strict
-- Baby Brawl | Studio-only input diagnostics. Not active in published game.
-- This probe NEVER sends input or damage: it only shows what reached the client
-- and what the server acknowledged through the existing CombatAction event.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local previous = playerGui:FindFirstChild("BabyBrawlInputQA")
if previous then previous:Destroy() end
local screen = Instance.new("ScreenGui")
screen.Name = "BabyBrawlInputQA"
screen.DisplayOrder = 80
screen.IgnoreGuiInset = false
screen.ResetOnSpawn = false
screen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
screen.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "ReadOnlyInputMonitor"
panel.AnchorPoint = Vector2.new(0.5,0)
panel.Position = UDim2.new(0.5,0,0,4)
panel.Size = UDim2.fromOffset(350,96)
panel.BackgroundColor3 = Color3.fromRGB(14,25,29)
panel.BackgroundTransparency = .12
panel.BorderSizePixel = 0
panel.Parent = screen
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,10)
corner.Parent = panel

local function label(name: string, textValue: string, y: number, color: Color3)
    local text = Instance.new("TextLabel")
    text.Name = name
    text.Size = UDim2.new(1,-18,0,21)
    text.Position = UDim2.fromOffset(9,y)
    text.Text = textValue
    text.Font = Enum.Font.GothamSemibold
    text.TextSize = 13
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextColor3 = color
    text.BackgroundTransparency = 1
    text.Parent = panel
    return text
end

local white = Color3.fromRGB(240,247,247)
local muted = Color3.fromRGB(201,216,227)
local green = Color3.fromRGB(130,235,164)
local head = label("State", "BABY BRAWL QA   |   CLIENT: RUNNING", 5, green)
local keyLine = label("Input", "INPUT: waiting for click / F / Shift", 27, white)
local serverLine = label("Server", "SERVER: waiting for combat event", 49, muted)
local modeLine = label("Info", "Click GAME viewport first. F5=Play, F8=Run.", 71, muted)

local rootFolder = ReplicatedStorage:WaitForChild("BabyBrawl_V1",8)
local remote = rootFolder and rootFolder:FindFirstChild("CombatAction")
if not remote or not remote:IsA("RemoteEvent") then
    serverLine.Text = "SERVER: missing BabyBrawl_V1/CombatAction"
else
    remote.OnClientEvent:Connect(function(kind, uid, flag)
        serverLine.Text = "SERVER: "..tostring(kind).."  id="..tostring(uid)
        print("[BB INPUT QA] Server event:",kind,uid,flag)
    end)
end

local function watched(input: InputObject): boolean
    return input.UserInputType == Enum.UserInputType.MouseButton1 or
        input.KeyCode == Enum.KeyCode.F or
        input.KeyCode == Enum.KeyCode.LeftShift or
        input.KeyCode == Enum.KeyCode.RightShift or
        input.KeyCode == Enum.KeyCode.One or
        input.KeyCode == Enum.KeyCode.Two or
        input.KeyCode == Enum.KeyCode.Three or
        input.KeyCode == Enum.KeyCode.Four
end

UIS.InputBegan:Connect(function(input, processed)
    if not watched(input) then return end
    local keyName = if input.UserInputType == Enum.UserInputType.MouseButton1 then "LEFT CLICK" else input.KeyCode.Name
    local textValue = "INPUT: "..keyName.."  |  processed="..tostring(processed)
    keyLine.Text = textValue
    print("[BB INPUT QA]", textValue)
end)

local function inspectCharacter()
    task.wait(2.8)
    local ch = localPlayer.Character
    local h = ch and ch:FindFirstChildOfClass("Humanoid")
    local baby = ch and ch:FindFirstChild("BabyBrawl_BabyShell")
    modeLine.Text = "BABY: "..(baby and "YES" or "NO").."  |  HUMANOID: "..(h and "YES" or "NO")
    print("[BB INPUT QA] Baby shell:",baby~=nil,"Character:",ch~=nil,"Controls:",UIS.KeyboardEnabled and "keyboard" or "touch")
end

localPlayer.CharacterAdded:Connect(function()
    task.spawn(inspectCharacter)
end)
if localPlayer.Character then task.spawn(inspectCharacter) end
print("[BB INPUT QA] Client probe running. Press LMB/F/Shift in PLAY CLIENT viewport.")
