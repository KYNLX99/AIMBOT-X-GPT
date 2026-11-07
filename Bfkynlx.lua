-- [Cancer666] Blox Fruits Rayfield Instrumentation
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

local State = {
    AutoFarm = false,
    AutoBoss = false,
    AutoFruit = false,
    AutoCollectMoney = false,
    ESP = false,
    FarmRadius = 250,
    AttackDelay = 0.4,
    TargetBoss = "Diamond"
}

local Window = Rayfield:CreateWindow({
   Name = "CF OVERLAY | Cancer666",
   LoadingTitle = "Blox Fruits Instrumentation",
   LoadingSubtitle = "by Cancer666",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "CF_Overlay",
      FileName = "Config"
   },
   KeySystem = false,
})

local CombatTab = Window:CreateTab("Combat", 4483362458)
local VisualTab = Window:CreateTab("Visual", 3944610415)
local TeleportTab = Window:CreateTab("Teleport", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

-- Combat Section
local FarmSection = CombatTab:CreateSection("Farming")

local AutoFarmToggle = FarmSection:CreateToggle({
   Name = "Auto Farm Enemies",
   CurrentValue = false,
   Flag = "AutoFarm",
   Callback = function(Value)
      State.AutoFarm = Value
      if Value then State.AutoBoss = false end
   end,
})

local AutoBossToggle = FarmSection:CreateToggle({
   Name = "Auto Farm Boss",
   CurrentValue = false,
   Flag = "AutoBoss",
   Callback = function(Value)
      State.AutoBoss = Value
      if Value then State.AutoFarm = false end
   end,
})

local BossDropdown = FarmSection:CreateDropdown({
   Name = "Target Boss",
   CurrentOption = {"Diamond"},
   Options = {"Diamond", "Saber Expert", "Gorilla King", "Smoke Admiral", "Katakuri", "Big Mom", "Kaido"},
   Callback = function(Option)
      State.TargetBoss = Option[1]
   end,
})

local AutoFruitToggle = FarmSection:CreateToggle({
   Name = "Auto Snipe Fruit",
   CurrentValue = false,
   Flag = "AutoFruit",
   Callback = function(Value)
      State.AutoFruit = Value
   end,
})

local RadiusSlider = FarmSection:CreateSlider({
   Name = "Farm Radius",
   Range = {50, 500},
   Increment = 10,
   Suffix = " studs",
   CurrentValue = 250,
   Flag = "FarmRadius",
   Callback = function(Value)
      State.FarmRadius = Value
   end,
})

-- Visual Section
local ESPSection = VisualTab:CreateSection("ESP")

local ESPToggle = ESPSection:CreateToggle({
   Name = "ESP All Entities",
   CurrentValue = false,
   Flag = "ESP",
   Callback = function(Value)
      State.ESP = Value
      if not Value then
         for _, v in pairs(Workspace:GetDescendants()) do
            if v:FindFirstChild("CF_ESP") then v.CF_ESP:Destroy() end
         end
      end
   end,
})

local ESPColorPicker = ESPSection:CreateColorPicker({
   Name = "ESP Color",
   Color = Color3.fromRGB(255, 0, 0),
   Flag = "ESPColor",
   Callback = function(Value)
      for _, v in pairs(Workspace:GetDescendants()) do
         if v:FindFirstChild("CF_ESP") then
            v.CF_ESP.FillColor = Value
         end
      end
   end,
})

-- Teleport Section
local TeleSection = TeleportTab:CreateSection("Quick Teleport")

TeleSection:CreateButton({
   Name = "TP to Nearest Fruit",
   Callback = function()
      for _, v in pairs(Workspace:GetDescendants()) do
         if v:IsA("Tool") and v.Name:find("Fruit") and v:FindFirstChild("Handle") then
            RootPart.CFrame = v.Handle.CFrame
            Rayfield:Notify({Title = "Teleport", Content = "Teleported to " .. v.Name, Duration = 3})
            break
         end
      end
   end,
})

TeleSection:CreateButton({
   Name = "TP to Marine Base",
   Callback = function()
      local marine = Workspace:FindFirstChild("Marine", true)
      if marine then RootPart.CFrame = marine.CFrame + Vector3.new(0, 5, 0) end
   end,
})

TeleSection:CreateButton({
   Name = "TP to Pirate Base",
   Callback = function()
      local pirate = Workspace:FindFirstChild("Pirate", true)
      if pirate then RootPart.CFrame = pirate.CFrame + Vector3.new(0, 5, 0) end
   end,
})

-- Settings Section
local SettingsSection = SettingsTab:CreateSection("Script Settings")

SettingsSection:CreateButton({
   Name = "Destroy Script",
   Callback = function()
      Rayfield:Destroy()
   end,
})

-- Core Logic
local function getTarget(isBoss)
    local closest, minDist = nil, math.huge
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") then
            local name = v.Name:lower()
            local isEnemy = name:find("enemy") or name:find("boss") or v:FindFirstChild("Enemy")
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

Rayfield:Notify({Title = "Loaded", Content = "CF Overlay by Cancer666", Duration = 5})
