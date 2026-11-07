-- ANCHOR: RunService.RenderStepped (60Hz loop), Drawing API (Hardware accelerated ESP)
-- COMMAND: Paste directly into Synapse X / Fluxus / Solara executor and press Execute
-- NUMBER: FOV = 120px, Aimbot Smoothness = 0.15, ESP Box Thickness = 1.5px
-- PATH: game:GetService("CoreGui") -> NeonFPS_ScreenGui
-- EXPECTED OUTPUT: Rayfield-style dark GUI renders, ESP draws 1.5px boxes, Aimbot snaps within 120px radius

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = {
    Aimbot = { Enabled = false, FOV = 120, Smoothness = 0.15, TeamCheck = true, VisibleCheck = true },
    ESP = { Enabled = false, Boxes = true, Tracers = true, Health = true, Names = true, Thickness = 1.5 },
    Weapon = { NoRecoil = true, NoSpread = true }
}

local function getClosestTarget()
    local closest, dist = nil, math.huge
    local mousePos = UIS:GetMouseLocation()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local head = plr.Character:FindFirstChild("Head")
            if hum and hum.Health > 0 and head then
                if Settings.Aimbot.TeamCheck and plr.Team == LP.Team then continue end
                local screenPos, onScreen = Camera:WorldToScreenPoint(head.Position)
                if onScreen then
                    local d = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if d < Settings.Aimbot.FOV and d < dist then
                        if Settings.Aimbot.VisibleCheck then
                            local ray = Ray.new(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).Unit * 1000)
                            local hit = workspace:FindPartOnRay(ray, LP.Character)
                            if hit and hit:IsDescendantOf(plr.Character) then
                                closest = plr
                                dist = d
                            end
                        else
                            closest = plr
                            dist = d
                        end
                    end
                end
            end
        end
    end
    return closest
end

local ESP_Objects = {}
local function createESP(plr)
    if ESP_Objects[plr] then return end
    local box = Drawing.new("Square")
    box.Thickness = Settings.ESP.Thickness
    box.Filled = false
    local tracer = Drawing.new("Line")
    tracer.Thickness = Settings.ESP.Thickness
    local name = Drawing.new("Text")
    name.Size = 14
    name.Center = true
    name.Outline = true
    ESP_Objects[plr] = { Box = box, Tracer = tracer, Name = name }
end

local function updateESP()
    for plr, objs in pairs(ESP_Objects) do
        if not plr.Character or not plr.Character:FindFirstChildOfClass("Humanoid") or plr.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then
            objs.Box.Visible = false
            objs.Tracer.Visible = false
            objs.Name.Visible = false
            continue
        end
        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
        local root = plr.Character:FindFirstChild("HumanoidRootPart")
        local head = plr.Character:FindFirstChild("Head")
        if not root or not head then continue end

        local headPos, onScreen = Camera:WorldToScreenPoint(head.Position + Vector3.new(0, 0.5, 0))
        local rootPos = Camera:WorldToScreenPoint(root.Position)
        local bottomPos = Camera:WorldToScreenPoint(root.Position - Vector3.new(0, 3, 0))
        
        if onScreen then
            local height = math.abs(bottomPos.Y - headPos.Y)
            local width = height * 0.6
            
            if Settings.ESP.Boxes then
                objs.Box.Size = Vector2.new(width, height)
                objs.Box.Position = Vector2.new(headPos.X - width / 2, headPos.Y)
                objs.Box.Color = plr.Team == LP.Team and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 50, 50)
                objs.Box.Visible = true
            else
                objs.Box.Visible = false
            end

            if Settings.ESP.Tracers then
                objs.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                objs.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                objs.Tracer.Color = objs.Box.Color
                objs.Tracer.Visible = true
            else
                objs.Tracer.Visible = false
            end

            if Settings.ESP.Names then
                objs.Name.Position = Vector2.new(headPos.X, headPos.Y - 20)
                objs.Name.Text = plr.Name .. " [" .. math.floor(hum.Health) .. "]"
                objs.Name.Color = objs.Box.Color
                objs.Name.Visible = true
            else
                objs.Name.Visible = false
            end
        else
            objs.Box.Visible = false
            objs.Tracer.Visible = false
            objs.Name.Visible = false
        end
    end
end

Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() task.wait(1) createESP(p) end) end)
Players.PlayerRemoving:Connect(function(p) if ESP_Objects[p] then for _, obj in pairs(ESP_Objects[p]) do obj:Remove() end ESP_Objects[p] = nil end end)
for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then createESP(p) end end

local oldRecoil = nil
RunService.RenderStepped:Connect(function(dt)
    if Settings.Aimbot.Enabled and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = getClosestTarget()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local targetPos = target.Character.Head.Position
            local currentPos = Camera.CFrame.Position
            local targetCF = CFrame.lookAt(currentPos, targetPos)
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, Settings.Aimbot.Smoothness)
        end
    end

    if Settings.ESP.Enabled then
        updateESP()
    else
        for _, objs in pairs(ESP_Objects) do
            objs.Box.Visible = false
            objs.Tracer.Visible = false
            objs.Name.Visible = false
        end
    end

    if Settings.Weapon.NoRecoil then
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local animator = hum:FindFirstChildOfClass("Animator")
                if animator then
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        if track.Animation and string.find(track.Animation.AnimationId:lower(), "recoil") then
                            track:Stop(0)
                        end
                    end
                end
            end
        end
    end
end)

local function buildUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NeonFPS_ScreenGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 550, 0, 380)
    MainFrame.Position = UDim2.new(0.5, -275, 0.5, -190)
    MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 24)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = MainFrame
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(45, 45, 50)
    mainStroke.Thickness = 1.5
    mainStroke.Parent = MainFrame

    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame
    local topCorner = Instance.new("UICorner")
    topCorner.CornerRadius = UDim.new(0, 8)
    topCorner.Parent = TopBar
    local topFix = Instance.new("Frame")
    topFix.Size = UDim2.new(1, 0, 0, 8)
    topFix.Position = UDim2.new(0, 0, 1, -8)
    topFix.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
    topFix.BorderSizePixel = 0
    topFix.Parent = TopBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0, 200, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "NEON_SIGHT"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar

    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.new(0, 30, 0, 30)
    MinBtn.Position = UDim2.new(1, -75, 0, 5)
    MinBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    MinBtn.Text = "—"
    MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    MinBtn.TextSize = 14
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.Parent = TopBar
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(0, 6)
    minCorner.Parent = MinBtn

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -40, 0, 5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 14
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = TopBar
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = CloseBtn

    local TabContainer = Instance.new("Frame")
    TabContainer.Size = UDim2.new(0, 120, 1, -50)
    TabContainer.Position = UDim2.new(0, 0, 0, 50)
    TabContainer.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = MainFrame
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 8)
    tabCorner.Parent = TabContainer
    local tabFix = Instance.new("Frame")
    tabFix.Size = UDim2.new(0, 8, 1, 0)
    tabFix.Position = UDim2.new(1, -8, 0, 0)
    tabFix.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
    tabFix.BorderSizePixel = 0
    tabFix.Parent = TabContainer

    local ContentContainer = Instance.new("Frame")
    ContentContainer.Size = UDim2.new(1, -130, 1, -60)
    ContentContainer.Position = UDim2.new(0, 125, 0, 55)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame

    local Tabs = {}
    local function createTab(name)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, -10, 0, 35)
        TabBtn.Position = UDim2.new(0, 5, 0, #Tabs * 40 + 5)
        TabBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
        TabBtn.Text = name
        TabBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
        TabBtn.TextSize = 14
        TabBtn.Font = Enum.Font.GothamSemibold
        TabBtn.Parent = TabContainer
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = TabBtn

        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.BorderSizePixel = 0
        TabContent.ScrollBarThickness = 4
        TabContent.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 65)
        TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
        TabContent.Visible = false
        TabContent.Parent = ContentContainer
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.Parent = TabContent

        Tabs[name] = { Button = TabBtn, Content = TabContent }
        
        TabBtn.MouseButton1Click:Connect(function()
            for tName, tData in pairs(Tabs) do
                tData.Button.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
                tData.Button.TextColor3 = Color3.fromRGB(180, 180, 180)
                tData.Content.Visible = false
            end
            TabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            TabBtn.TextColor3 = Color3.fromRGB(123, 94, 255)
            TabContent.Visible = true
        end)
        return TabContent
    end

    local function addToggle(parent, text, default, callback)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, -10, 0, 40)
        Container.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
        Container.BorderSizePixel = 0
        Container.Parent = parent
        local cCorner = Instance.new("UICorner")
        cCorner.CornerRadius = UDim.new(0, 6)
        cCorner.Parent = Container

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -60, 1, 0)
        Label.Position = UDim2.new(0, 15, 0, 0)
        Label.BackgroundTransparency = 1
        Label.Text = text
        Label.TextColor3 = Color3.fromRGB(220, 220, 220)
        Label.TextSize = 14
        Label.Font = Enum.Font.Gotham
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Container

        local ToggleBtn = Instance.new("TextButton")
        ToggleBtn.Size = UDim2.new(0, 40, 0, 20)
        ToggleBtn.Position = UDim2.new(1, -50, 0.5, -10)
        ToggleBtn.BackgroundColor3 = default and Color3.fromRGB(123, 94, 255) or Color3.fromRGB(60, 60, 65)
        ToggleBtn.Text = ""
        ToggleBtn.AutoButtonColor = false
        ToggleBtn.Parent = Container
        local tCorner = Instance.new("UICorner")
        tCorner.CornerRadius = UDim.new(1, 0)
        tCorner.Parent = ToggleBtn
        local Circle = Instance.new("Frame")
        Circle.Size = UDim2.new(0, 16, 0, 16)
        Circle.Position = default and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)
        Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Circle.BorderSizePixel = 0
        Circle.Parent = ToggleBtn
        local ciCorner = Instance.new("UICorner")
        ciCorner.CornerRadius = UDim.new(1, 0)
        ciCorner.Parent = Circle

        local state = default
        ToggleBtn.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(123, 94, 255) or Color3.fromRGB(60, 60, 65)}):Play()
            TweenService:Create(Circle, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)}):Play()
            callback(state)
        end)
    end

    local function addSlider(parent, text, min, max, default, callback)
        local Container = Instance.new("Frame")
        Container.Size = UDim2.new(1, -10, 0, 55)
        Container.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
        Container.BorderSizePixel = 0
        Container.Parent = parent
        local cCorner = Instance.new("UICorner")
        cCorner.CornerRadius = UDim.new(0, 6)
        cCorner.Parent = Container

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(1, -60, 0, 25)
        Label.Position = UDim2.new(0, 15, 0, 5)
        Label.BackgroundTransparency = 1
        Label.Text = text .. ": " .. default
        Label.TextColor3 = Color3.fromRGB(220, 220, 220)
        Label.TextSize = 14
        Label.Font = Enum.Font.Gotham
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.Parent = Container

        local SliderBG = Instance.new("Frame")
        SliderBG.Size = UDim2.new(1, -30, 0, 8)
        SliderBG.Position = UDim2.new(0, 15, 0, 35)
        SliderBG.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        SliderBG.BorderSizePixel = 0
        SliderBG.Parent = Container
        local sbCorner = Instance.new("UICorner")
        sbCorner.CornerRadius = UDim.new(1, 0)
        sbCorner.Parent = SliderBG

        local SliderFill = Instance.new("Frame")
        SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        SliderFill.BackgroundColor3 = Color3.fromRGB(123, 94, 255)
        SliderFill.BorderSizePixel = 0
        SliderFill.Parent = SliderBG
        local sfCorner = Instance.new("UICorner")
        sfCorner.CornerRadius = UDim.new(1, 0)
        sfCorner.Parent = SliderFill

        local dragging = false
        SliderBG.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local percent = math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
                SliderFill.Size = UDim2.new(percent, 0, 1, 0)
                local val = math.floor(min + (max - min) * percent)
                Label.Text = text .. ": " .. val
                callback(val)
            end
        end)
    end

    local aimTab = createTab("Aimbot")
    addToggle(aimTab, "Enable Aimbot", false, function(v) Settings.Aimbot.Enabled = v end)
    addSlider(aimTab, "FOV Radius", 10, 500, 120, function(v) Settings.Aimbot.FOV = v end)
    addSlider(aimTab, "Smoothness", 1, 100, 15, function(v) Settings.Aimbot.Smoothness = v / 100 end)
    addToggle(aimTab, "Team Check", true, function(v) Settings.Aimbot.TeamCheck = v end)
    addToggle(aimTab, "Visibility Check", true, function(v) Settings.Aimbot.VisibleCheck = v end)

    local espTab = createTab("Visuals")
    addToggle(espTab, "Enable ESP", false, function(v) Settings.ESP.Enabled = v end)
    addToggle(espTab, "Bounding Boxes", true, function(v) Settings.ESP.Boxes = v end)
    addToggle(espTab, "Tracers", true, function(v) Settings.ESP.Tracers = v end)
    addToggle(espTab, "Health & Names", true, function(v) Settings.ESP.Health = v; Settings.ESP.Names = v end)

    local wepTab = createTab("Weapon")
    addToggle(wepTab, "No Recoil", true, function(v) Settings.Weapon.NoRecoil = v end)
    addToggle(wepTab, "No Spread", true, function(v) Settings.Weapon.NoSpread = v end)

    Tabs["Aimbot"].Button.MouseButton1Click:Connect(function() end)
    Tabs["Aimbot"].Button.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    Tabs["Aimbot"].Button.TextColor3 = Color3.fromRGB(123, 94, 255)
    Tabs["Aimbot"].Content.Visible = true

    local draggingUI, dragInput, dragStart, startPos
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingUI = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then draggingUI = false end
            end)
        end
    end)
    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and draggingUI then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
	
	local MiniIcon = Instance.new("Frame")
    MiniIcon.Name = "MiniIcon"
    MiniIcon.Size = UDim2.new(0, 40, 0, 40)
    MiniIcon.Position = UDim2.new(0, 20, 0.5, -20)
    MiniIcon.BackgroundColor3 = Color3.fromRGB(22, 22, 24)
    MiniIcon.BorderSizePixel = 0
    MiniIcon.Visible = false
    MiniIcon.Parent = ScreenGui
    local miniCorner = Instance.new("UICorner")
    miniCorner.CornerRadius = UDim.new(1, 0)
    miniCorner.Parent = MiniIcon
    local miniStroke = Instance.new("UIStroke")
    miniStroke.Color = Color3.fromRGB(123, 94, 255)
    miniStroke.Thickness = 2
    miniStroke.Parent = MiniIcon
    local miniText = Instance.new("TextLabel")
    miniText.Size = UDim2.new(1, 0, 1, 0)
    miniText.BackgroundTransparency = 1
    miniText.Text = "N"
    miniText.TextColor3 = Color3.fromRGB(123, 94, 255)
    miniText.TextSize = 18
    miniText.Font = Enum.Font.GothamBold
    miniText.Parent = MiniIcon

    local miniDragging, miniDragInput, miniDragStart, miniStartPos
    MiniIcon.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            miniDragging = true
            miniDragStart = input.Position
            miniStartPos = MiniIcon.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then miniDragging = false end
            end)
        end
    end)
    MiniIcon.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then miniDragInput = input end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == miniDragInput and miniDragging then
            local delta = input.Position - miniDragStart
            MiniIcon.Position = UDim2.new(miniStartPos.X.Scale, miniStartPos.X.Offset + delta.X, miniStartPos.Y.Scale, miniStartPos.Y.Offset + delta.Y)
        end
    end)

    MinBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        MiniIcon.Visible = true
    end)

    miniText.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            MainFrame.Visible = true
            MiniIcon.Visible = false
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
end
	buildUI()
