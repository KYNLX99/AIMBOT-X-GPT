-- [Cancer666] Blox Fruits Instrumentation Overlay
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

local State = {
    AutoFarm = false,
    AutoBoss = false,
    AutoFruit = false,
    ESP = false,
    FarmRadius = 250,
    AttackDelay = 0.4
}

-- UI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CF_Overlay"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer.PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Size = UDim2.new(0, 220, 0, 300)
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -150)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Text = "CF OVERLAY"
Title.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.Parent = MainFrame

-- Button factory
local function createButton(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Text = text
    btn.AutoButtonColor = false
    btn.Parent = MainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Logic
local function getTarget(isBoss)
    local closest, minDist = nil, math.huge
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") then
            local name = v.Name:lower()
            local isEnemy = name:find("enemy") or name:find("boss") or v:FindFirstChild("Enemy")
            if isBoss then
                if name:find("boss") or v.Humanoid.MaxHealth > 5000 then
                    local dist = (v.HumanoidRootPart.Position - RootPart.Position).Magnitude
                    if dist < minDist and dist < State.FarmRadius then closest, minDist = v, dist end
                end
            else
                if not name:find("boss") and v.Humanoid.Health > 0 then
                    local dist = (v.HumanoidRootPart.Position - RootPart.Position).Magnitude
                    if dist < minDist and dist < State.FarmRadius then closest, minDist = v, dist end
                end
            end
        end
    end
    return closest
end

local function updateESP()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v ~= Character then
            local hl = v:FindFirstChild("CF_ESP")
            if State.ESP then
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "CF_ESP"
                    hl.FillColor = Color3.fromRGB(255, 0, 0)
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.Parent = v
                end
            elseif hl then
                hl:Destroy()
            end
        end
    end
end

-- Loops
RunService.Heartbeat:Connect(function()
    if State.AutoFarm or State.AutoBoss then
        local target = getTarget(State.AutoBoss)
        if target and target:FindFirstChild("HumanoidRootPart") then
            RootPart.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
            local tool = Character:FindFirstChildWhichIsA("Tool")
            if tool then tool:Activate() end
        end
    end
    if State.AutoFruit then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("Tool") and v.Name:find("Fruit") then
                RootPart.CFrame = v.Handle.CFrame
                break
            end
        end
    end
    if State.ESP then updateESP() end
end)

-- Bindings
createButton("Auto Farm [Toggle]", function()
    State.AutoFarm = not State.AutoFarm
    State.AutoBoss = false
end)
createButton("Auto Boss [Toggle]", function()
    State.AutoBoss = not State.AutoBoss
    State.AutoFarm = false
end)
createButton("Snipe Fruit [Toggle]", function()
    State.AutoFruit = not State.AutoFruit
end)
createButton("ESP All [Toggle]", function()
    State.ESP = not State.ESP
    if not State.ESP then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:FindFirstChild("CF_ESP") then v.CF_ESP:Destroy() end
        end
    end
end)
createButton("Destroy GUI", function()
    ScreenGui:Destroy()
end)