--[[
    =======================================================
    LIYHUB AIMBOT  —  Clean Edition (No Key System)
    Design Language: LiyHub Midnight (Dark + Purple Accent)
    =======================================================
]]

-- ==== Services ====
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

-- ==== Config Default ====
local Config = {
    Enabled       = true,
    StickyLock    = true,
    Wallcheck     = true,
    Smoothness    = 0.5,   -- 0 = instan, 1 = sangat smooth
    FovRadius     = 120,   -- pixel radius
    TeamCheck     = true,  -- jangan target rekan setim
    VisibleOnly   = true,  -- hanya target yang on-screen
}

-- ==== GUI Parent Resolution ====
local function getGuiParent()
    local parent = nil
    pcall(function()
        if gethui then
            parent = gethui()
        elseif CoreGui then
            local test = Instance.new("Folder")
            test.Parent = CoreGui
            test:Destroy()
            parent = CoreGui
        end
    end)
    if not parent then
        pcall(function()
            parent = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 2)
        end)
    end
    return parent
end

local guiParent = getGuiParent()
if not guiParent then
    warn("[Aimbot] Tidak bisa resolve GUI parent.")
    return
end

if guiParent:FindFirstChild("LiyHubAimbotGui") then
    guiParent.LiyHubAimbotGui:Destroy()
end

-- ==== Theme ====
local Theme = {
    Background       = Color3.fromRGB(10, 11, 20),
    Surface          = Color3.fromRGB(18, 20, 36),
    SurfaceSecondary = Color3.fromRGB(26, 29, 52),
    Border           = Color3.fromRGB(38, 42, 70),
    Text             = Color3.fromRGB(248, 250, 252),
    TextSecondary    = Color3.fromRGB(148, 163, 184),
    Accent           = Color3.fromRGB(139, 92, 246),
    AccentHover      = Color3.fromRGB(168, 85, 247),
    Success          = Color3.fromRGB(16, 185, 129),
    Warning          = Color3.fromRGB(245, 158, 11),
    Error            = Color3.fromRGB(244, 63, 94),
}

-- ==== ScreenGui ====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LiyHubAimbotGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then
    pcall(syn.protect_gui, ScreenGui)
elseif typeof(protect_gui) == "function" then
    pcall(protect_gui, ScreenGui)
end

-- ==== FOV Circle (world-space visual) ====
local FovCircle = Instance.new("Frame")
FovCircle.Name = "FovCircle"
FovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FovCircle.Size = UDim2.fromOffset(Config.FovRadius * 2, Config.FovRadius * 2)
FovCircle.BackgroundTransparency = 1
FovCircle.BorderSizePixel = 0
FovCircle.ZIndex = 5
FovCircle.Parent = ScreenGui

local FovCorner = Instance.new("UICorner")
FovCorner.CornerRadius = UDim.new(1, 0)
FovCorner.Parent = FovCircle

local FovStroke = Instance.new("UIStroke")
FovStroke.Color = Theme.Accent
FovStroke.Thickness = 1.5
FovStroke.Transparency = 0.35
FovStroke.Parent = FovCircle

-- ==== Main Frame ====
local vp = Camera and Camera.ViewportSize or Vector2.new(800, 600)
local isSmall = vp.X < 700
local FRAME_W = isSmall and math.clamp(vp.X - 40, 260, 300) or 300
local FRAME_H = 380

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.fromOffset(FRAME_W, FRAME_H)
MainFrame.Position = UDim2.new(0.5, -FRAME_W / 2, 0.5, -FRAME_H / 2)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Theme.Border
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

-- ==== TopBar ====
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 36)
TopBar.BackgroundColor3 = Theme.Surface
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarLine = Instance.new("Frame")
TopBarLine.Size = UDim2.new(1, 0, 0, 1)
TopBarLine.Position = UDim2.new(0, 0, 1, -1)
TopBarLine.BackgroundColor3 = Theme.Border
TopBarLine.BorderSizePixel = 0
TopBarLine.Parent = TopBar

-- Logo
local LogoContainer = Instance.new("Frame")
LogoContainer.Size = UDim2.fromOffset(22, 22)
LogoContainer.Position = UDim2.new(0, 10, 0.5, -11)
LogoContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
LogoContainer.BorderSizePixel = 0
LogoContainer.Parent = TopBar
Instance.new("UICorner", LogoContainer).CornerRadius = UDim.new(0, 11)

local LogoStroke = Instance.new("UIStroke")
LogoStroke.Color = Theme.Accent
LogoStroke.Thickness = 1
LogoStroke.Transparency = 0.3
LogoStroke.Parent = LogoContainer

local LogoImage = Instance.new("ImageLabel")
LogoImage.Size = UDim2.fromScale(1, 1)
LogoImage.BackgroundTransparency = 1
LogoImage.Image = "rbxassetid://123085513549252"
LogoImage.ScaleType = Enum.ScaleType.Fit
LogoImage.Parent = LogoContainer
Instance.new("UICorner", LogoImage).CornerRadius = UDim.new(0, 11)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 80, 1, 0)
Title.Position = UDim2.new(0, 36, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "LIYHUB"
Title.TextColor3 = Theme.Accent
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(0, 160, 1, 0)
Subtitle.Position = UDim2.new(0, 106, 0, 0)
Subtitle.BackgroundTransparency = 1
Subtitle.Font = Enum.Font.Gotham
Subtitle.Text = "•  Aim Assist"
Subtitle.TextColor3 = Theme.TextSecondary
Subtitle.TextSize = 11
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = TopBar

-- Mac-style controls
local Controls = Instance.new("Frame")
Controls.Size = UDim2.new(0, 42, 1, 0)
Controls.Position = UDim2.new(1, -50, 0, 0)
Controls.BackgroundTransparency = 1
Controls.Parent = TopBar

local CtrlLayout = Instance.new("UIListLayout")
CtrlLayout.FillDirection = Enum.FillDirection.Horizontal
CtrlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
CtrlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
CtrlLayout.Padding = UDim.new(0, 8)
CtrlLayout.Parent = Controls

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.fromOffset(13, 13)
MinBtn.BackgroundColor3 = Color3.fromRGB(242, 201, 76)
MinBtn.Text = ""
MinBtn.AutoButtonColor = false
MinBtn.Parent = Controls
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 7)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(13, 13)
CloseBtn.BackgroundColor3 = Color3.fromRGB(235, 87, 87)
CloseBtn.Text = ""
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Controls
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 7)

-- ==== Draggable ====
local dragging, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)
TopBar.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ==== Minimize / Close ====
local isMinimized = false
local FLOATING_BTN_SIZE = 36

local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Name = "ReopenButton"
FloatingBtn.Size = UDim2.fromOffset(FLOATING_BTN_SIZE, FLOATING_BTN_SIZE)
FloatingBtn.Position = UDim2.new(1, -FLOATING_BTN_SIZE - 16, 0, 60)
FloatingBtn.BackgroundColor3 = Theme.Surface
FloatingBtn.Text = "🎯"
FloatingBtn.TextSize = 16
FloatingBtn.Font = Enum.Font.GothamBold
FloatingBtn.AutoButtonColor = false
FloatingBtn.Visible = false
FloatingBtn.Parent = ScreenGui
Instance.new("UICorner", FloatingBtn).CornerRadius = UDim.new(0, 10)

local FloatingStroke = Instance.new("UIStroke")
FloatingStroke.Color = Theme.Accent
FloatingStroke.Thickness = 1
FloatingStroke.Transparency = 0.3
FloatingStroke.Parent = FloatingBtn

FloatingBtn.MouseButton1Click:Connect(function()
    isMinimized = false
    MainFrame.Visible = true
    FloatingBtn.Visible = false
end)

MinBtn.MouseButton1Click:Connect(function()
    isMinimized = true
    MainFrame.Visible = false
    FloatingBtn.Visible = true
end)

CloseBtn.MouseButton1Click:Connect(function()
    -- "Close" hanya menyembunyikan (agar script tetap jalan), buka lagi via floating btn
    MainFrame.Visible = false
    FloatingBtn.Visible = true
    isMinimized = true
end)

-- ==== Content Layout ====
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -20, 1, -52)
Content.Position = UDim2.new(0, 10, 0, 44)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.FillDirection = Enum.FillDirection.Vertical
ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.Padding = UDim.new(0, 8)
ContentLayout.Parent = Content

local ContentPad = Instance.new("UIPadding")
ContentPad.PaddingTop = UDim.new(0, 4)
ContentPad.Parent = Content

-- ==== UI Helpers ====
local function makeRow(order, height)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, height or 30)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order
    row.Parent = Content
    return row
end

local function makeLabel(parent, text, side)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Position = side == "right" and UDim2.new(0.5, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = text
    lbl.TextColor3 = Theme.Text
    lbl.TextSize = 12
    lbl.TextXAlignment = side == "right" and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

-- Toggle button factory (pill style)
local function makeToggle(order, labelText, defaultState, onChanged)
    local row = makeRow(order, 32)
    makeLabel(row, labelText, "left")

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 46, 0, 22)
    btn.Position = UDim2.new(1, -46, 0.5, -11)
    btn.BackgroundColor3 = defaultState and Theme.Accent or Theme.SurfaceSecondary
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(16, 16)
    knob.Position = defaultState and UDim2.new(1, -20, 0.5, -8) or UDim2.new(0, 4, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = btn
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local state = defaultState
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(btn, TweenInfo.new(0.18), {
            BackgroundColor3 = state and Theme.Accent or Theme.SurfaceSecondary
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.18), {
            Position = state and UDim2.new(1, -20, 0.5, -8) or UDim2.new(0, 4, 0.5, -8)
        }):Play()
        if onChanged then onChanged(state) end
    end)

    return {
        Set = function(v)
            if state ~= v then btn.MouseButton1Click() end
        end,
        Get = function() return state end
    }
end

-- Slider factory
local function makeSlider(order, labelText, minV, maxV, defaultV, onChanged)
    local row = makeRow(order, 46)

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, 18)
    top.BackgroundTransparency = 1
    top.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = labelText
    lbl.TextColor3 = Theme.Text
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = top

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0.4, 0, 1, 0)
    valLbl.Position = UDim2.new(0.6, 0, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = Enum.Font.GothamBold
    valLbl.Text = tostring(defaultV)
    valLbl.TextColor3 = Theme.Accent
    valLbl.TextSize = 12
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = top

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(1, 0, 0, 6)
    track.Position = UDim2.new(0, 0, 0, 26)
    track.BackgroundColor3 = Theme.SurfaceSecondary
    track.Text = ""
    track.AutoButtonColor = false
    track.BorderSizePixel = 0
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defaultV - minV) / (maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(14, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new((defaultV - minV) / (maxV - minV), 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local value = defaultV

    local function setFromX(absX)
        local trackAbsX = track.AbsolutePosition.X
        local trackW = track.AbsoluteSize.X
        local pct = math.clamp((absX - trackAbsX) / trackW, 0, 1)
        local newV = minV + pct * (maxV - minV)
        value = newV
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        valLbl.Text = (maxV <= 1) and string.format("%.2f", newV) or tostring(math.floor(newV + 0.5))
        if onChanged then onChanged(value) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            setFromX(input.Position.X)
        end
    end)
    track.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            setFromX(input.Position.X)
        end
    end)

    return {
        Set = function(v)
            local pct = math.clamp((v - minV) / (maxV - minV), 0, 1)
            value = v
            fill.Size = UDim2.new(pct, 0, 1, 0)
            knob.Position = UDim2.new(pct, 0, 0.5, 0)
            valLbl.Text = (maxV <= 1) and string.format("%.2f", v) or tostring(math.floor(v + 0.5))
        end,
        Get = function() return value end
    }
end

-- Divider
local function makeDivider(order)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1, 0, 0, 1)
    d.BackgroundColor3 = Theme.Border
    d.BorderSizePixel = 0
    d.LayoutOrder = order
    d.Parent = Content
    return d
end

-- Section title
local function makeSectionTitle(order, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 16)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = string.upper(text)
    lbl.TextColor3 = Theme.TextSecondary
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    lbl.Parent = Content
    return lbl
end

-- ==== Build UI ====
makeSectionTitle(1, "Core")

makeToggle(2, "Aimbot", Config.Enabled, function(v) Config.Enabled = v end)
makeToggle(3, "Sticky Lock", Config.StickyLock, function(v) Config.StickyLock = v end)
makeToggle(4, "Wallcheck", Config.Wallcheck, function(v) Config.Wallcheck = v end)
makeToggle(5, "Team Check", Config.TeamCheck, function(v) Config.TeamCheck = v end)

makeDivider(6)
makeSectionTitle(7, "Tuning")

makeSlider(8, "Smoothness", 0, 1, Config.Smoothness, function(v) Config.Smoothness = v end)
makeSlider(9, "FOV Radius", 40, 400, Config.FovRadius, function(v)
    Config.FovRadius = v
    FovCircle.Size = UDim2.fromOffset(v * 2, v * 2)
end)

makeDivider(10)

-- Switch Target Button
local switchRow = makeRow(11, 34)
local SwitchBtn = Instance.new("TextButton")
SwitchBtn.Size = UDim2.new(1, 0, 1, 0)
SwitchBtn.BackgroundColor3 = Theme.Accent
SwitchBtn.Text = "🔄  Switch Target"
SwitchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SwitchBtn.TextSize = 13
SwitchBtn.Font = Enum.Font.GothamBold
SwitchBtn.AutoButtonColor = false
SwitchBtn.BorderSizePixel = 0
SwitchBtn.Parent = switchRow
Instance.new("UICorner", SwitchBtn).CornerRadius = UDim.new(0, 8)

SwitchBtn.MouseEnter:Connect(function()
    TweenService:Create(SwitchBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.AccentHover }):Play()
end)
SwitchBtn.MouseLeave:Connect(function()
    TweenService:Create(SwitchBtn, TweenInfo.new(0.15), { BackgroundColor3 = Theme.Accent }):Play()
end)

-- Status Footer
local footerRow = makeRow(12, 22)
local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(1, 0, 1, 0)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Font = Enum.Font.Gotham
StatusLbl.Text = "Status: Idle"
StatusLbl.TextColor3 = Theme.TextSecondary
StatusLbl.TextSize = 11
StatusLbl.TextXAlignment = Enum.TextXAlignment.Left
StatusLbl.Parent = footerRow

-- ==== Aimbot Core Logic ====
local currentTarget = nil
local stickyLocked = false

local function hasLineOfSight(targetChar)
    local head = targetChar:FindFirstChild("Head")
    if not head then return false end
    local origin = Camera.CFrame.Position
    local dir = (head.Position - origin)
    local dist = dir.Magnitude
    if dist <= 0 then return false end
    dir = dir.Unit

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, targetChar}
    params.IgnoreWater = true

    local result = Workspace:Raycast(origin, dir * dist, params)
    return result == nil
end

local function isSameTeam(plr)
    if not Config.TeamCheck then return false end
    if not LocalPlayer.Team then return false end
    return plr.Team == LocalPlayer.Team
end

local function getTargetInFov()
    local best, bestDist = nil, math.huge
    local center = Camera.ViewportSize / 2
    local camPos = Camera.CFrame.Position

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local head = plr.Character:FindFirstChild("Head")
            if hum and hum.Health > 0 and head and not isSameTeam(plr) then
                local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dx = sp.X - center.X
                    local dy = sp.Y - center.Y
                    local screenDist = math.sqrt(dx * dx + dy * dy)
                    if screenDist <= Config.FovRadius then
                        if not Config.Wallcheck or hasLineOfSight(plr.Character) then
                            local worldDist = (head.Position - camPos).Magnitude
                            if worldDist < bestDist then
                                bestDist = worldDist
                                best = plr
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function isValidTarget(plr)
    if not plr or not plr.Character then return false end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    local head = plr.Character:FindFirstChild("Head")
    if not hum or hum.Health <= 0 or not head then return false end
    if isSameTeam(plr) then return false end

    local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
    if not onScreen then return false end
    local center = Camera.ViewportSize / 2
    local dx = sp.X - center.X
    local dy = sp.Y - center.Y
    if math.sqrt(dx*dx + dy*dy) > Config.FovRadius then return false end
    if Config.Wallcheck and not hasLineOfSight(plr.Character) then return false end
    return true
end

local function aimAt(plr)
    if not plr or not plr.Character then return end
    local head = plr.Character:FindFirstChild("Head")
    if not head then return end

    local camPos = Camera.CFrame.Position
    local goalCF = CFrame.lookAt(camPos, head.Position)

    -- Smoothness 0 => snap, 1 => sangat lambat
    local alpha = 1 - math.pow(Config.Smoothness, 0.5)
    alpha = math.clamp(alpha, 0.05, 1)
    Camera.CFrame = Camera.CFrame:Lerp(goalCF, alpha)
end

-- Main render loop
RunService.RenderStepped:Connect(function()
    if not Config.Enabled then
        currentTarget = nil
        stickyLocked = false
        StatusLbl.Text = "Status: Disabled"
        StatusLbl.TextColor3 = Theme.TextSecondary
        return
    end

    if stickyLocked and currentTarget then
        if not isValidTarget(currentTarget) then
            stickyLocked = false
            currentTarget = nil
        end
    end

    if not (stickyLocked and Config.StickyLock and currentTarget) then
        local found = getTargetInFov()
        if found then
            currentTarget = found
            stickyLocked = true
        else
            currentTarget = nil
            stickyLocked = false
        end
    end

    if currentTarget and stickyLocked then
        aimAt(currentTarget)
        StatusLbl.Text = "Status: Locked → " .. currentTarget.Name
        StatusLbl.TextColor3 = Theme.Success
    else
        StatusLbl.Text = "Status: Searching..."
        StatusLbl.TextColor3 = Theme.TextSecondary
    end
end)

-- Switch Target (manual: paksa cari target lain, tidak mengunci yg sama)
SwitchBtn.MouseButton1Click:Connect(function()
    if not Config.Enabled then return end
    local prev = currentTarget
    local best, bestDist = nil, math.huge
    local center = Camera.ViewportSize / 2
    local camPos = Camera.CFrame.Position

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr ~= prev and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local head = plr.Character:FindFirstChild("Head")
            if hum and hum.Health > 0 and head and not isSameTeam(plr) then
                local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dx, dy = sp.X - center.X, sp.Y - center.Y
                    if math.sqrt(dx*dx + dy*dy) <= Config.FovRadius then
                        if not Config.Wallcheck or hasLineOfSight(plr.Character) then
                            local d = (head.Position - camPos).Magnitude
                            if d < bestDist then
                                bestDist = d
                                best = plr
                            end
                        end
                    end
                end
            end
        end
    end

    if best then
        currentTarget = best
        stickyLocked = true
    end
end)

-- Responsive FOV circle positioning
local function updateFovCircle()
    FovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
    FovCircle.Size = UDim2.fromOffset(Config.FovRadius * 2, Config.FovRadius * 2)
end
updateFovCircle()

if Camera then
    Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateFovCircle)
end

-- FOV circle visibility mengikuti toggle aimbot
task.spawn(function()
    while task.wait(0.2) do
        FovCircle.Visible = Config.Enabled and MainFrame.Visible
    end
end)

-- ==== Done ====
ScreenGui.Parent = guiParent
print("[LiyHub Aimbot] Loaded successfully.")