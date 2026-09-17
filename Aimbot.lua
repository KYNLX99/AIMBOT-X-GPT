--!strict
-- ============================================================================
--  MOBILE AIM ASSIST SYSTEM
--  Lokasi: StarterPlayer > StarterPlayerScripts  (LocalScript)
-- ============================================================================

-- ============================================================================
-- [1] CONFIGURATION
-- ============================================================================
local Configuration = {
    Enabled      = false,
    FOV          = 150,       -- radius FOV (pixel)
    Smoothness   = 10,        -- 1 = sangat snappy, 100 = sangat halus
    LockTarget   = true,
    Wallcheck    = true,
    AutoSwitch   = true,
    AimMode      = "Toggle",  -- "Toggle" | "Hold"
    MaxDistance  = 600,
    RevalidateInterval = 0.15,
}

-- ============================================================================
-- [2] SERVICES
-- ============================================================================
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local Workspace          = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ============================================================================
-- [3] STATE & CLEANUP
-- ============================================================================
local State = {
    CurrentTarget = nil,
    HoldingAim    = false,
    Revalidate    = 0,
    Connections   = {},
}

local function AddConnection(conn)
    table.insert(State.Connections, conn)
    return conn
end

local function Cleanup()
    for _, c in ipairs(State.Connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(State.Connections)
    State.CurrentTarget = nil
end

-- ============================================================================
-- [4] UTIL TARGET
-- ============================================================================
local function GetAimPart(character)
    if not character then return nil end
    return character:FindFirstChild("Head")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
        or character:FindFirstChild("HumanoidRootPart")
end

local function IsSameTeam(player)
    if not player.Team or not LocalPlayer.Team then return false end
    return player.Team == LocalPlayer.Team
end

local function IsInsideFOV(worldPos)
    if not Camera then return false end
    local sp, onScreen = Camera:WorldToViewportPoint(worldPos)
    if not onScreen or sp.Z <= 0 then return false end
    local center = Camera.ViewportSize * 0.5
    local offset = Vector2.new(sp.X - center.X, sp.Y - center.Y)
    return offset.Magnitude <= Configuration.FOV
end

local function IsVisible(character, aimPart)
    if not Configuration.Wallcheck then return true end
    if not Camera then return true end
    local origin    = Camera.CFrame.Position
    local direction = aimPart.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character, Camera }
    params.IgnoreWater = true
    local result = Workspace:Raycast(origin, direction, params)
    if not result then return false end
    return result.Instance:IsDescendantOf(character)
end

-- ============================================================================
-- [5] TARGET VALIDATION
-- ============================================================================
local function IsValidTarget(player)
    if not player or player == LocalPlayer then return false end
    if IsSameTeam(player) then return false end

    local character = player.Character
    if not character then return false end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end

    local aimPart = GetAimPart(character)
    if not aimPart then return false end

    if Camera then
        local dist = (aimPart.Position - Camera.CFrame.Position).Magnitude
        if dist > Configuration.MaxDistance then return false end
    end

    if not IsInsideFOV(aimPart.Position) then return false end
    if not IsVisible(character, aimPart) then return false end

    return true
end

-- ============================================================================
-- [6] GET CLOSEST TARGET (prioritas: paling dekat ke pusat FOV)
-- ============================================================================
local function GetClosestTarget(excludePlayer)
    if not Camera then return nil end
    local center = Camera.ViewportSize * 0.5
    local bestPlayer, bestDist = nil, math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player ~= excludePlayer then
            if IsValidTarget(player) then
                local aimPart = GetAimPart(player.Character)
                if aimPart then
                    local sp = Camera:WorldToViewportPoint(aimPart.Position)
                    local dx = sp.X - center.X
                    local dy = sp.Y - center.Y
                    local d  = math.sqrt(dx * dx + dy * dy)
                    if d < bestDist then
                        bestDist = d
                        bestPlayer = player
                    end
                end
            end
        end
    end
    return bestPlayer
end

-- ============================================================================
-- [7] AIM CALCULATION (smooth, frame-rate independent)
-- ============================================================================
local function AimAtTarget(dt)
    local target = State.CurrentTarget
    if not target or not IsValidTarget(target) then return end

    local aimPart = GetAimPart(target.Character)
    if not aimPart or not Camera then return end

    local currentCF = Camera.CFrame
    local targetPos = aimPart.Position
    local targetCF  = CFrame.new(currentCF.Position, currentCF.Position + (targetPos - currentCF.Position).Unit)

    local s     = math.clamp(Configuration.Smoothness, 1, 100)
    local alpha = 1 - (s / 100) * 0.95               -- 1..100 -> ~0.99..0.05
    local frameAlpha = 1 - (1 - alpha) ^ (dt * 60)   -- frame-rate independent

    Camera.CFrame = currentCF:Lerp(targetCF, frameAlpha)
end

-- ============================================================================
-- [8] UI BUILDING
-- ============================================================================
local function CreateSlider(parent, name, minVal, maxVal, defaultVal, order, callback)
    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, 0, 0, 42)
    box.BackgroundTransparency = 1
    box.LayoutOrder = order
    box.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 16)
    label.BackgroundTransparency = 1
    label.Text = string.format("%s: %d", name, defaultVal)
    label.TextColor3 = Color3.fromRGB(225, 225, 235)
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = box

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 14)
    track.Position = UDim2.new(0, 0, 0, 20)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    track.BorderSizePixel = 0
    track.Parent = box

    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(1, 0); tc.Parent = track

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(80, 150, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track
    local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1, 0); fc.Parent = fill

    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
    knob.BorderSizePixel = 0
    knob.ZIndex = 3
    knob.Parent = track
    local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1, 0); kc.Parent = knob

    local dragging = false

    local function setFromX(absX)
        local rel = math.clamp((absX - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local value = math.floor(minVal + rel * (maxVal - minVal) + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, 0, 0.5, 0)
        label.Text = string.format("%s: %d", name, value)
        callback(value)
    end

    AddConnection(track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end))

    AddConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end))

    AddConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    return box
end

local function CreateToggle(parent, text, defaultState, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = defaultState and Color3.fromRGB(60, 130, 220) or Color3.fromRGB(45, 45, 60)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order
    btn.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -16, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. ": " .. (defaultState and "ON" or "OFF")
    lbl.TextColor3 = Color3.fromRGB(245, 245, 250)
    lbl.TextSize = 14
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn

    local state = defaultState
    AddConnection(btn.MouseButton1Click:Connect(function()
        state = not state
        lbl.Text = text .. ": " .. (state and "ON" or "OFF")
        btn.BackgroundColor3 = state and Color3.fromRGB(60, 130, 220) or Color3.fromRGB(45, 45, 60)
        callback(state)
    end))

    return btn
end

local function MakeDraggable(frame, handle)
    local dragging, dragStart, startPos = false, nil, nil

    AddConnection(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end))

    AddConnection(handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))

    AddConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

-- ============================================================================
-- [9] MAIN UI CREATION
-- ============================================================================
local UI = {}

local function BuildUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "AimAssistUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    UI.Gui = gui

    ----------------------------------------------------------------
    -- FOV Circle
    ----------------------------------------------------------------
    local fov = Instance.new("Frame")
    fov.Name = "FOVCircle"
    fov.AnchorPoint = Vector2.new(0.5, 0.5)
    fov.BackgroundTransparency = 1
    fov.BorderSizePixel = 0
    fov.ZIndex = 5
    fov.Parent = gui

    local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1, 0); fc.Parent = fov

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(120, 200, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.25
    stroke.Parent = fov

    UI.FOVCircle = fov
    UI.FOVStroke = stroke

    ----------------------------------------------------------------
    -- Main Panel
    ----------------------------------------------------------------
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.AnchorPoint = Vector2.new(0, 0.5)
    panel.Position = UDim2.new(0, 14, 0.5, 0)
    panel.Size = UDim2.new(0, 240, 0, 470)
    panel.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    panel.BackgroundTransparency = 0.08
    panel.BorderSizePixel = 0
    panel.Active = true
    panel.Parent = gui
    UI.Panel = panel

    local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 14); pc.Parent = panel
    local ps = Instance.new("UIStroke")
    ps.Color = Color3.fromRGB(70, 70, 95); ps.Thickness = 1; ps.Parent = panel

    -- Header (drag handle)
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 38)
    header.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    header.BorderSizePixel = 0
    header.Active = true
    header.Parent = panel

    local hc = Instance.new("UICorner"); hc.CornerRadius = UDim.new(0, 14); hc.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -70, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "AIM ASSIST"
    title.TextColor3 = Color3.fromRGB(220, 225, 240)
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 50, 0, 26)
    minimizeBtn.Position = UDim2.new(1, -58, 0.5, -13)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    minimizeBtn.Text = "MIN"
    minimizeBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
    minimizeBtn.TextSize = 12
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.AutoButtonColor = false
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.Parent = header
    local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0, 8); mc.Parent = minimizeBtn

    MakeDraggable(panel, header)

    -- Content list
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Position = UDim2.new(0, 10, 0, 46)
    content.Size = UDim2.new(1, -20, 1, -56)
    content.BackgroundTransparency = 1
    content.Parent = panel

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 6)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = content

    ----------------------------------------------------------------
    -- AIM ASSIST toggle
    ----------------------------------------------------------------
    UI.AimToggle = CreateToggle(content, "AIM ASSIST", Configuration.Enabled, 1, function(v)
        Configuration.Enabled = v
        if not v then
            State.CurrentTarget = nil
            if UI.TargetLabel then UI.TargetLabel.Text = "TARGET: --" end
        end
    end)

    ----------------------------------------------------------------
    -- FOV slider
    ----------------------------------------------------------------
    CreateSlider(content, "FOV", 40, 400, Configuration.FOV, 2, function(v)
        Configuration.FOV = v
    end)

    ----------------------------------------------------------------
    -- Smoothness slider
    ----------------------------------------------------------------
    CreateSlider(content, "Smoothness", 1, 100, Configuration.Smoothness, 3, function(v)
        Configuration.Smoothness = v
    end)

    ----------------------------------------------------------------
    -- Lock Target toggle
    ----------------------------------------------------------------
    CreateToggle(content, "LOCK TARGET", Configuration.LockTarget, 4, function(v)
        Configuration.LockTarget = v
    end)

    ----------------------------------------------------------------
    -- Wallcheck toggle
    ----------------------------------------------------------------
    CreateToggle(content, "WALLCHECK", Configuration.Wallcheck, 5, function(v)
        Configuration.Wallcheck = v
    end)

    ----------------------------------------------------------------
    -- Auto Switch toggle
    ----------------------------------------------------------------
    CreateToggle(content, "AUTO SWITCH", Configuration.AutoSwitch, 6, function(v)
        Configuration.AutoSwitch = v
    end)

    ----------------------------------------------------------------
    -- Aim Mode button (Toggle/Hold)
    ----------------------------------------------------------------
    local modeBtn = Instance.new("TextButton")
    modeBtn.Size = UDim2.new(1, 0, 0, 36)
    modeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    modeBtn.AutoButtonColor = false
    modeBtn.BorderSizePixel = 0
    modeBtn.LayoutOrder = 7
    modeBtn.Text = "MODE: " .. Configuration.AimMode
    modeBtn.TextColor3 = Color3.fromRGB(245, 245, 250)
    modeBtn.TextSize = 14
    modeBtn.Font = Enum.Font.GothamMedium
    modeBtn.Parent = content
    local mbc = Instance.new("UICorner"); mbc.CornerRadius = UDim.new(0, 8); mbc.Parent = modeBtn

    AddConnection(modeBtn.MouseButton1Click:Connect(function()
        Configuration.AimMode = (Configuration.AimMode == "Toggle") and "Hold" or "Toggle"
        modeBtn.Text = "MODE: " .. Configuration.AimMode
        if UI.HoldBtn then
            UI.HoldBtn.Visible = (Configuration.AimMode == "Hold")
        end
    end))

    ----------------------------------------------------------------
    -- Target label
    ----------------------------------------------------------------
    local targetLabel = Instance.new("TextLabel")
    targetLabel.Size = UDim2.new(1, 0, 0, 24)
    targetLabel.BackgroundTransparency = 1
    targetLabel.Text = "TARGET: --"
    targetLabel.TextColor3 = Color3.fromRGB(140, 220, 255)
    targetLabel.TextSize = 13
    targetLabel.Font = Enum.Font.GothamMedium
    targetLabel.TextXAlignment = Enum.TextXAlignment.Left
    targetLabel.LayoutOrder = 8
    targetLabel.Parent = content
    UI.TargetLabel = targetLabel

    ----------------------------------------------------------------
    -- Switch Target button
    ----------------------------------------------------------------
    local switchBtn = Instance.new("TextButton")
    switchBtn.Size = UDim2.new(1, 0, 0, 40)
    switchBtn.BackgroundColor3 = Color3.fromRGB(80, 100, 200)
    switchBtn.AutoButtonColor = false
    switchBtn.BorderSizePixel = 0
    switchBtn.Text = "SWITCH TARGET"
    switchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    switchBtn.TextSize = 14
    switchBtn.Font = Enum.Font.GothamBold
    switchBtn.LayoutOrder = 9
    switchBtn.Parent = content
    local sbc = Instance.new("UICorner"); sbc.CornerRadius = UDim.new(0, 8); sbc.Parent = switchBtn

    AddConnection(switchBtn.MouseButton1Click:Connect(function()
        local prev = State.CurrentTarget
        State.CurrentTarget = nil
        State.CurrentTarget = GetClosestTarget(prev)
        if UI.TargetLabel then
            UI.TargetLabel.Text = State.CurrentTarget
                and ("TARGET: " .. State.CurrentTarget.Name)
                or "TARGET: --"
        end
    end))

    ----------------------------------------------------------------
    -- Reopen button (saat minimize)
    ----------------------------------------------------------------
    local openBtn = Instance.new("TextButton")
    openBtn.Size = UDim2.new(0, 70, 0, 32)
    openBtn.Position = UDim2.new(0, 14, 0, 60)
    openBtn.BackgroundColor3 = Color3.fromRGB(60, 130, 220)
    openBtn.Text = "OPEN"
    openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    openBtn.TextSize = 13
    openBtn.Font = Enum.Font.GothamBold
    openBtn.AutoButtonColor = false
    openBtn.BorderSizePixel = 0
    openBtn.Visible = false
    openBtn.Parent = gui
    local obc = Instance.new("UICorner"); obc.CornerRadius = UDim.new(0, 8); obc.Parent = openBtn
    UI.OpenBtn = openBtn

    AddConnection(minimizeBtn.MouseButton1Click:Connect(function()
        panel.Visible = false
        openBtn.Visible = true
    end))

    AddConnection(openBtn.MouseButton1Click:Connect(function()
        panel.Visible = true
        openBtn.Visible = false
    end))

    ----------------------------------------------------------------
    -- HOLD AIM button (kanan bawah)
    ----------------------------------------------------------------
    local holdBtn = Instance.new("TextButton")
    holdBtn.Size = UDim2.new(0, 110, 0, 110)
    holdBtn.AnchorPoint = Vector2.new(1, 1)
    holdBtn.Position = UDim2.new(1, -20, 1, -20)
    holdBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 200)
    holdBtn.BackgroundTransparency = 0.25
    holdBtn.Text = "AIM"
    holdBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    holdBtn.TextSize = 20
    holdBtn.Font = Enum.Font.GothamBold
    holdBtn.AutoButtonColor = false
    holdBtn.BorderSizePixel = 0
    holdBtn.Visible = (Configuration.AimMode == "Hold")
    holdBtn.Parent = gui
    local hbc = Instance.new("UICorner"); hbc.CornerRadius = UDim.new(1, 0); hbc.Parent = holdBtn
    local hbs = Instance.new("UIStroke")
    hbs.Color = Color3.fromRGB(150, 130, 255); hbs.Thickness = 2; hbs.Parent = holdBtn

    AddConnection(holdBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            State.HoldingAim = true
            holdBtn.BackgroundTransparency = 0.05
        end
    end))

    AddConnection(holdBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            State.HoldingAim = false
            holdBtn.BackgroundTransparency = 0.25
        end
    end))

    UI.HoldBtn = holdBtn
end

-- ============================================================================
-- [10] FOV CIRCLE UPDATE
-- ============================================================================
local function UpdateFOVCircle()
    if not Camera or not UI.FOVCircle then return end
    local vp = Camera.ViewportSize
    UI.FOVCircle.Position = UDim2.fromOffset(vp.X * 0.5, vp.Y * 0.5)
    local d = Configuration.FOV * 2
    UI.FOVCircle.Size = UDim2.fromOffset(d, d)
    -- Warna: aktif vs non-aktif
    if Configuration.Enabled or State.HoldingAim then
        UI.FOVStroke.Color = Color3.fromRGB(120, 220, 255)
    else
        UI.FOVStroke.Color = Color3.fromRGB(180, 180, 180)
    end
end

-- ============================================================================
-- [11] TARGET SELECTION UPDATE
-- ============================================================================
local function UpdateTargetSelection()
    if not Configuration.LockTarget then
        State.CurrentTarget = GetClosestTarget(nil)
        return
    end

    if State.CurrentTarget and IsValidTarget(State.CurrentTarget) then
        return -- pertahankan target
    end

    if Configuration.AutoSwitch or not State.CurrentTarget then
        State.CurrentTarget = GetClosestTarget(nil)
    else
        State.CurrentTarget = nil
    end
end

-- ============================================================================
-- [12] MAIN RENDER LOOP (satu koneksi, dipakai selamanya)
-- ============================================================================
local function OnRenderStep(dt)
    if not UI.FOVCircle then return end

    UpdateFOVCircle()

    local aimActive = false
    if Configuration.Enabled then
        if Configuration.AimMode == "Toggle" then
            aimActive = true
        else
            aimActive = State.HoldingAim
        end
    end

    if not aimActive then
        if State.CurrentTarget then
            State.CurrentTarget = nil
            if UI.TargetLabel then UI.TargetLabel.Text = "TARGET: --" end
        end
        return
    end

    State.Revalidate += dt
    if State.Revalidate >= Configuration.RevalidateInterval then
        State.Revalidate = 0
        UpdateTargetSelection()
        if UI.TargetLabel then
            UI.TargetLabel.Text = State.CurrentTarget
                and ("TARGET: " .. State.CurrentTarget.Name)
                or "TARGET: --"
        end
    end

    if State.CurrentTarget then
        AimAtTarget(dt)
    end
end

-- ============================================================================
-- [13] INIT
-- ============================================================================
BuildUI()

AddConnection(RunService.RenderStepped:Connect(OnRenderStep))

AddConnection(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if Workspace.CurrentCamera then
        Camera = Workspace.CurrentCamera
    end
end))

-- Aman saat respawn
AddConnection(LocalPlayer.CharacterAdded:Connect(function()
    State.CurrentTarget = nil
    if UI.TargetLabel then UI.TargetLabel.Text = "TARGET: --" end
end))

-- Auto cleanup (opsional, dipanggil saat script di-destroy)
LocalPlayer.AncestryChanged:Connect(function()
    if not LocalPlayer:IsDescendantOf(game) then
        Cleanup()
    end
end)

-- Expose Cleanup (untuk debugging manual)
_G.AimAssistCleanup = Cleanup