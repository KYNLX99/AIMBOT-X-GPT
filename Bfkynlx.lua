-- [Cancer666] Blox Fruits Self-Contained Overlay
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")

local State = {
    AutoFarm = false,
    AutoBoss = false,
    AutoFruit = false,
    ESP = false,
    FarmRadius = 250,
    TargetBoss = "Diamond"
}

-- === UI CORE ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CF_RayfieldClone"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Size = UDim2.new(0, 500, 0, 350)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- Dragging
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then update(input) end
end)

-- Sidebar
local SideBar = Instance.new("Frame")
SideBar.Size = UDim2.new(0, 120, 1, 0)
SideBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
SideBar.BorderSizePixel = 0
SideBar.Parent = MainFrame
Instance.new("UICorner", SideBar).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Text = "CF OVERLAY"
Title.Parent = SideBar
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 5)
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.Parent = SideBar

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -130, 1, -50)
ContentArea.Position = UDim2.new(0, 125, 0, 45)
ContentArea.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
ContentArea.BorderSizePixel = 0
ContentArea.Parent = MainFrame
Instance.new("UICorner", ContentArea).CornerRadius = UDim.new(0, 6)

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 10)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Parent = ContentArea

-- UI Components Builder
local function CreateTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.Text = name
    btn.AutoButtonColor = false
    btn.Parent = SideBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local tabFrame = Instance.new("ScrollingFrame")
    tabFrame.Size = UDim2.new(1, -10, 1, 0)
    tabFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    tabFrame.BorderSizePixel = 0
    tabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabFrame.Visible = false
    tabFrame.Parent = ContentArea
    Instance.new("UICorner", tabFrame).CornerRadius = UDim.new(0, 6)
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = tabFrame
    
    btn.MouseButton1Click:Connect(function()
        for _, child in pairs(ContentArea:GetChildren()) do
            if child:IsA("ScrollingFrame") then child.Visible = false end
        end
        tabFrame.Visible = true
    end)
    
    return tabFrame, layout
end

local function CreateToggle(parent, name, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 40)
    container.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    container.BorderSizePixel = 0
    container.Parent = parent
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = name
    label.Parent = container
    
    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 40, 0, 20)
    toggleBg.Position = UDim2.new(1, -45, 0.5, -10)
    toggleBg.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
    toggleBg.Parent = container
    Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(1, 0)
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 16, 0, 16)
    toggleCircle.Position = UDim2.new(0, 2, 0.5, -8)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleCircle.Parent = toggleBg
    Instance.new("UICorner", toggleCircle).CornerRadius = UDim.new(1, 0)
    
    local state = default
    local function updateVisual()
        toggleBg.BackgroundColor3 = state and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(60, 60, 65)
        TweenService:Create(toggleCircle, TweenInfo.new(0.2), {Position = UDim2.new(0, state and 22 or 2, 0.5, -8)}):Play()
    end
    updateVisual()
    
    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            state = not state
            updateVisual()
            callback(state)
        end
    end)
end

local function CreateSlider(parent, name, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, 50)
    container.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    container.BorderSizePixel = 0
    container.Parent = parent
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = name .. ": " .. default
    label.Parent = container
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -20, 0, 8)
    sliderBg.Position = UDim2.new(0, 10, 1, -20)
    sliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
    sliderBg.Parent = container
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
    sliderFill.Parent = sliderBg
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    local function updateSlider(input)
        local percent = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * percent)
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        label.Text = name .. ": " .. value
        callback(value)
    end
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function CreateButton(parent, name, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Text = name
    btn.AutoButtonColor = false
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    btn.MouseButton1Click:Connect(callback)
end

-- === TABS & FEATURES ===
local CombatTab, CombatLayout = CreateTab("Combat", "")
local VisualTab, VisualLayout = CreateTab("Visual", "")
local TeleportTab, TeleportLayout = CreateTab("Teleport", "")

CreateToggle(CombatTab, "Auto Farm Enemies", false, function(val) State.AutoFarm = val; if val then State.AutoBoss = false end end)
CreateToggle(CombatTab, "Auto Farm Boss", false, function(val) State.AutoBoss = val; if val then State.AutoFarm = false end end)
CreateToggle(CombatTab, "Auto Snipe Fruit", false, function(val) State.AutoFruit = val end)
CreateSlider(CombatTab, "Farm Radius", 50, 500, 250, function(val) State.FarmRadius = val end)

CreateToggle(VisualTab, "ESP All Entities", false, function(val) 
    State.ESP = val 
    if not val then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:FindFirstChild("CF_ESP") then v.CF_ESP:Destroy() end
        end
    end
end)

CreateButton(TeleportTab, "TP to Nearest Fruit", function()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Tool") and v.Name:find("Fruit") and v:FindFirstChild("Handle") then
            RootPart.CFrame = v.Handle.CFrame
            break
        end
    end
end)
CreateButton(TeleportTab, "TP to Marine Base", function()
    local marine = Workspace:FindFirstChild("Marine", true)
    if marine then RootPart.CFrame = marine.CFrame + Vector3.new(0, 5, 0) end
end)

-- === CORE LOGIC ===
local function getTarget(isBoss)
    local closest, minDist = nil, math.huge
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") then
            local name = v.Name:lower()
            if isBoss then
                if name:find(State.TargetBoss:lower()) or v.Humanoid.MaxHealth > 5000 then
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
            if v:IsA("Tool") and v.Name:find("Fruit") and v:FindFirstChild("Handle") then
                RootPart.CFrame = v.Handle.CFrame
                break
            end
        end
    end
    if State.ESP then updateESP() end
end)

-- Default tab
for _, child in pairs(ContentArea:GetChildren()) do
    if child:IsA("ScrollingFrame") then 
        child.Visible = false 
    end
end
CombatTab.Visible = true
