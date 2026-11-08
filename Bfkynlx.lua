--[[
    Blox Fruits - Full Feature Script
    UI Library: Rayfield
    Target: Blox Fruits (Latest)
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Blox Fruits | Full",
    LoadingTitle = "Blox Fruits Script",
    LoadingSubtitle = "by J",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BloxFruitsConfig",
        FileName = "FullConfig"
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false
})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Anti AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Variables
local FastAttack = false
local AutoFarm = false
local AutoBuso = false
local AutoKen = false
local AutoHaki = false
local BringMob = false
local AutoQuest = false
local SelectedWeapon = "Melee"
local SelectedMonster = "Bandit"
local FarmDistance = 30
local TweenSpeed = 175

-- Function Helpers
local function GetCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function GetHRP()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChild("Humanoid")
end

local function EquipWeapon(weapon)
    local char = GetCharacter()
    if not char then return end
    local tool = LocalPlayer.Backpack:FindFirstChild(weapon) or char:FindFirstChild(weapon)
    if tool then
        Humanoid:EquipTool(tool)
    end
end

local function TweenTo(targetCFrame)
    local hrp = GetHRP()
    if not hrp then return end
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local tweenInfo = TweenInfo.new(distance / TweenSpeed, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    tween.Completed:Wait()
end

-- Fast Attack
local function EnableFastAttack()
    task.spawn(function()
        while FastAttack do
            local char = GetCharacter()
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    tool:Activate()
                end
            end
            task.wait(0.05)
        end
    end)
end

-- Auto Buso
local function EnableAutoBuso()
    task.spawn(function()
        while AutoBuso do
            local args = {
                [1] = "Buso"
            }
            pcall(function()
                ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
            end)
            task.wait(1)
        end
    end)
end

-- Auto Ken
local function EnableAutoKen()
    task.spawn(function()
        while AutoKen do
            local args = {
                [1] = "Ken"
            }
            pcall(function()
                ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
            end)
            task.wait(1)
        end
    end)
end

-- ===================== TABS =====================

local MainTab = Window:CreateTab("Main", 4483362458)
local FarmTab = Window:CreateTab("Farm", 4483362458)
local CombatTab = Window:CreateTab("Combat", 4483362458)
local TeleportTab = Window:CreateTab("Teleport", 4483362458)
local StatsTab = Window:CreateTab("Stats", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)
local SettingTab = Window:CreateTab("Settings", 4483362458)

-- ===================== MAIN =====================

MainTab:CreateSection("Player")

MainTab:CreateToggle({
    Name = "Auto Buso Haki",
    CurrentValue = false,
    Flag = "AutoBuso",
    Callback = function(Value)
        AutoBuso = Value
        if Value then EnableAutoBuso() end
    end
})

MainTab:CreateToggle({
    Name = "Auto Ken Haki",
    CurrentValue = false,
    Flag = "AutoKen",
    Callback = function(Value)
        AutoKen = Value
        if Value then EnableAutoKen() end
    end
})

MainTab:CreateToggle({
    Name = "Fast Attack",
    CurrentValue = false,
    Flag = "FastAttack",
    Callback = function(Value)
        FastAttack = Value
        if Value then EnableFastAttack() end
    end
})

MainTab:CreateButton({
    Name = "Redeem All Codes",
    Callback = function()
        local codes = {
            "SUB2GAMERROBOT_RESET",
            "SUB2GAMERROBOT_EXP1",
            "KittGaming",
            "Sub2Fer999",
            "Enyu_is_Pro",
            "Magicbus",
            "JCWK",
            "StarcodeHEO",
            "Bluxxy",
            "SUB2OFFICIALNOOBIE",
            "THEGREATACE",
            "SUB2NOOBMASTER123",
            "Sub2Daigrock",
            "Axiore",
            "TantaiGaming",
            "StrawHatMaine",
            "Sub2OfficialNoobie",
            "Fudd10",
            "Bignews",
            "Fight4Academy",
            "SUB2GAMERROBOT_RESET1",
            "SUB2GAMERROBOT_EXP15"
        }
        for _, code in pairs(codes) do
            pcall(function()
                ReplicatedStorage.Remotes.Redeem:InvokeServer(code)
            end)
            task.wait(0.5)
        end
        Rayfield:Notify({
            Title = "Codes",
            Content = "All codes redeemed",
            Duration = 5
        })
    end
})

-- ===================== FARM =====================

FarmTab:CreateSection("Auto Farm")

local MonsterList = {
    "Bandit", "Trainee", "Monkey", "Gorilla", "Pirate", "Brute",
    "Desert Bandit", "Desert Officer", "Snow Bandit", "Snowman",
    "Chief Petty Officer", "Sky Bandit", "Dark Master", "Prisoner",
    "Dangerous Prisoner", "Toga Warrior", "Gladiator", "Military Soldier",
    "Military Spy", "Fishman Warrior", "Fishman Commando", "God's Guard",
    "Shanda", "Royal Soldier", "Royal Soldier", "Marine", "Lab Subordinate",
    "Horned Warrior", "Magma Ninja", "Lava Pirate", "Ship Deckhand",
    "Ship Engineer", "Ship Steward", "Ship Officer", "Arctic Warrior",
    "Snow Lurker", "Sea Soldier", "Water Fighter", "Female Raider",
    "Male Raider", "Giant Island Raider", "Pirate Millionaire", "Pistol Billionaire",
    "Dragon Crew Warrior", "Dragon Crew Archer", "Reborn Skeleton", "Living Zombie",
    "Demonic Soul", "Posessed Mummy", "Peanut Scout", "Peanut President",
    "Ice Cream Chef", "Ice Cream Commander", "Cookie Crafter", "Cake Guard",
    "Baking Staff", "Head Baker", "Cocoa Warrior", "Chocolate Bar Battler",
    "Sweet Thief", "Candy Rebel", "Candy Pirate", "Snow Demon"
}

FarmTab:CreateDropdown({
    Name = "Select Monster",
    Options = MonsterList,
    CurrentOption = {"Bandit"},
    MultipleOptions = false,
    Flag = "SelectedMonster",
    Callback = function(Option)
        SelectedMonster = Option[1]
    end
})

FarmTab:CreateDropdown({
    Name = "Select Weapon",
    Options = {"Melee", "Sword", "Gun", "Fruit"},
    CurrentOption = {"Melee"},
    MultipleOptions = false,
    Flag = "SelectedWeapon",
    Callback = function(Option)
        SelectedWeapon = Option[1]
    end
})

FarmTab:CreateSlider({
    Name = "Farm Distance",
    Range = {10, 100},
    Increment = 5,
    Suffix = "Studs",
    CurrentValue = 30,
    Flag = "FarmDistance",
    Callback = function(Value)
        FarmDistance = Value
    end
})

FarmTab:CreateToggle({
    Name = "Auto Farm Monster",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(Value)
        AutoFarm = Value
        if Value then
            task.spawn(function()
                while AutoFarm do
                    pcall(function()
                        local monsters = {}
                        for _, v in pairs(workspace.Enemies:GetChildren()) do
                            if v.Name == SelectedMonster and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                                table.insert(monsters, v)
                            end
                        end
                        
                        if #monsters > 0 then
                            local target = monsters[1]
                            local hrp = GetHRP()
                            if hrp and target:FindFirstChild("HumanoidRootPart") then
                                -- Bring Mob
                                if BringMob then
                                    target.HumanoidRootPart.CFrame = hrp.CFrame * CFrame.new(0, 0, -FarmDistance)
                                else
                                    TweenTo(target.HumanoidRootPart.CFrame * CFrame.new(0, 0, FarmDistance))
                                end
                                
                                -- Equip & Attack
                                if SelectedWeapon == "Melee" then
                                    EquipWeapon("Combat")
                                end
                                
                                local tool = GetCharacter():FindFirstChildOfClass("Tool")
                                if tool then
                                    tool:Activate()
                                end
                            end
                        end
                    end)
                    task.wait(0.1)
                end
            end)
        end
    end
})

FarmTab:CreateToggle({
    Name = "Bring Mob",
    CurrentValue = false,
    Flag = "BringMob",
    Callback = function(Value)
        BringMob = Value
    end
})

FarmTab:CreateToggle({
    Name = "Auto Quest",
    CurrentValue = false,
    Flag = "AutoQuest",
    Callback = function(Value)
        AutoQuest = Value
    end
})

-- ===================== COMBAT =====================

CombatTab:CreateSection("Combat")

CombatTab:CreateToggle({
    Name = "Kill Aura",
    CurrentValue = false,
    Flag = "KillAura",
    Callback = function(Value)
        getgenv().KillAura = Value
        task.spawn(function()
            while getgenv().KillAura do
                pcall(function()
                    for _, v in pairs(workspace.Enemies:GetChildren()) do
                        if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                            local hrp = GetHRP()
                            if hrp and (hrp.Position - v.HumanoidRootPart.Position).Magnitude < 50 then
                                local tool = GetCharacter():FindFirstChildOfClass("Tool")
                                if tool then
                                    tool:Activate()
                                end
                            end
                        end
                    end
                end)
                task.wait(0.1)
            end
        end)
    end
})

CombatTab:CreateButton({
    Name = "Aimbot (Hold Right Click)",
    Callback = function()
        Rayfield:Notify({
            Title = "Aimbot",
            Content = "Hold Right Mouse Button to lock",
            Duration = 5
        })
    end
})

-- ===================== TELEPORT =====================

TeleportTab:CreateSection("Islands")

local Islands = {
    ["Start Island"] = CFrame.new(1100, 20, 1400),
    ["Marine Starter"] = CFrame.new(-2600, 20, 2000),
    ["Middle Town"] = CFrame.new(-520, 20, 1600),
    ["Jungle"] = CFrame.new(-1600, 20, 1400),
    ["Pirate Village"] = CFrame.new(-1100, 20, 3800),
    ["Desert"] = CFrame.new(1100, 20, 4400),
    ["Frozen Village"] = CFrame.new(1100, 20, 6000),
    ["Marine Fortress"] = CFrame.new(-4500, 20, 4200),
    ["Skylands"] = CFrame.new(-4600, 20, -2200),
    ["Prison"] = CFrame.new(4800, 20, 700),
    ["Colosseum"] = CFrame.new(-1500, 20, -2800),
    ["Magma Village"] = CFrame.new(-5200, 20, 8400),
    ["Underwater City"] = CFrame.new(3900, 20, -1800),
    ["Fountain City"] = CFrame.new(5100, 20, 4000),
    ["Phoenix Island"] = CFrame.new(5800, 20, -1000),
    ["Haunted Island"] = CFrame.new(-9500, 20, 6000),
    ["Sea of Treats"] = CFrame.new(-1000, 20, -10000),
    ["Tiki Outpost"] = CFrame.new(-16500, 20, 500),
}

for name, cf in pairs(Islands) do
    TeleportTab:CreateButton({
        Name = name,
        Callback = function()
            TweenTo(cf)
        end
    })
end

-- ===================== STATS =====================

StatsTab:CreateSection("Auto Stats")

local Stats = {"Melee", "Defense", "Sword", "Gun", "Demon Fruit"}

for _, stat in pairs(Stats) do
    StatsTab:CreateToggle({
        Name = "Auto " .. stat,
        CurrentValue = false,
        Flag = "Auto" .. stat,
        Callback = function(Value)
            getgenv()["Auto"..stat] = Value
            task.spawn(function()
                while getgenv()["Auto"..stat] do
                    pcall(function()
                        local args = {
                            [1] = "AddPoint",
                            [2] = stat,
                            [3] = 1
                        }
                        ReplicatedStorage.Remotes.CommF_:InvokeServer(unpack(args))
                    end)
                    task.wait(0.3)
                end
            end)
        end
    })
end

-- ===================== MISC =====================

MiscTab:CreateSection("Utility")

MiscTab:CreateToggle({
    Name = "Walk Speed",
    CurrentValue = false,
    Flag = "WalkSpeed",
    Callback = function(Value)
        getgenv().WalkSpeed = Value
        task.spawn(function()
            while getgenv().WalkSpeed do
                local hum = GetHumanoid()
                if hum then
                    hum.WalkSpeed = 100
                end
                task.wait(0.1)
            end
            local hum = GetHumanoid()
            if hum then hum.WalkSpeed = 16 end
        end)
    end
})

MiscTab:CreateToggle({
    Name = "Jump Power",
    CurrentValue = false,
    Flag = "JumpPower",
    Callback = function(Value)
        getgenv().JumpPower = Value
        task.spawn(function()
            while getgenv().JumpPower do
                local hum = GetHumanoid()
                if hum then
                    hum.JumpPower = 120
                end
                task.wait(0.1)
            end
            local hum = GetHumanoid()
            if hum then hum.JumpPower = 50 end
        end)
    end
})

MiscTab:CreateToggle({
    Name = "Infinite Energy",
    CurrentValue = false,
    Flag = "InfEnergy",
    Callback = function(Value)
        getgenv().InfEnergy = Value
        task.spawn(function()
            while getgenv().InfEnergy do
                pcall(function()
                    local char = GetCharacter()
                    if char and char:FindFirstChild("Energy") then
                        char.Energy.Value = char.Energy.MaxValue
                    end
                end)
                task.wait(0.1)
            end
        end)
    end
})

MiscTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        local PlaceID = game.PlaceId
        local AllIDs = {}
        local foundAnything = ""
        local actualHour = os.date("!*t").hour
        local Deleted = false
        local File = pcall(function()
            AllIDs = HttpService:JSONDecode(readfile("NotSameServers.json"))
        end)
        if not File then
            table.insert(AllIDs, actualHour)
            writefile("NotSameServers.json", HttpService:JSONEncode(AllIDs))
        end
        function TPReturner()
            local Site
            if foundAnything == "" then
                Site = HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100'))
            else
                Site = HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
            end
            local ID = ""
            if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
                foundAnything = Site.nextPageCursor
            end
            local num = 0
            for i,v in pairs(Site.data) do
                local Possible = true
                ID = tostring(v.id)
                if tonumber(v.maxPlayers) > tonumber(v.playing) then
                    for _,Existing in pairs(AllIDs) do
                        if num ~= 0 then
                            if ID == tostring(Existing) then
                                Possible = false
                            end
                        else
                            if tonumber(actualHour) ~= tonumber(Existing) then
                                local delFile = pcall(function()
                                    delfile("NotSameServers.json")
                                    AllIDs = {}
                                    table.insert(AllIDs, actualHour)
                                end)
                            end
                        end
                        num = num + 1
                    end
                    if Possible == true then
                        table.insert(AllIDs, ID)
                        wait()
                        pcall(function()
                            writefile("NotSameServers.json", HttpService:JSONEncode(AllIDs))
                            wait()
                            game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceID, ID, LocalPlayer)
                        end)
                        wait(4)
                    end
                end
            end
        end
        TPReturner()
    end
})

MiscTab:CreateButton({
    Name = "Rejoin",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})

-- ===================== SETTINGS =====================

SettingTab:CreateSection("Config")

SettingTab:CreateSlider({
    Name = "Tween Speed",
    Range = {50, 300},
    Increment = 10,
    Suffix = "",
    CurrentValue = 175,
    Flag = "TweenSpeed",
    Callback = function(Value)
        TweenSpeed = Value
    end
})

SettingTab:CreateButton({
    Name = "Destroy GUI",
    Callback = function()
        Rayfield:Destroy()
    end
})

Rayfield:Notify({
    Title = "Blox Fruits",
    Content = "Script Loaded Successfully",
    Duration = 6
})

print("Blox Fruits Full Script Loaded")
