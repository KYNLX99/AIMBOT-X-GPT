--[[
    ==============================================================
    LIYHUB AIMBOT — FULL EDITION
    Design Language: LiyHub Midnight (Dark + Purple Accent)
    No Key System • Private Test Only
    ==============================================================
]]

-- ==================== SAFE FUNCTION CAPTURES ====================
local __raw_type      = type
local __raw_pcall     = pcall
local __raw_tostring  = tostring
local __raw_pairs     = pairs
local __raw_ipairs    = ipairs
local __raw_unpack    = table.unpack or unpack

-- ==================== SERVICES ====================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local HttpService       = game:GetService("HttpService")
local TeleportService   = game:GetService("TeleportService")
local GuiService        = game:GetService("GuiService")
local StarterGui        = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

-- ==================== THEME ====================
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

-- ==================== CONFIG (default) ====================
local Config = {
    Enabled         = true,
    StickyLock      = true,
    Wallcheck       = true,
    TeamCheck       = true,
    VisibleOnly     = true,
    AutoSwitch      = true,
    RainbowFov      = false,

    Smoothness      = 0.5,
    FovRadius       = 120,
    Prediction      = 0.15,     -- 0 - 1 multiplier
    TargetPart      = "Head",   -- Head / UpperTorso / Nearest
    AimMode         = "Hold",   -- Hold / Toggle / Always
    SilentAim       = false,
    FovColor        = Color3.fromRGB(139, 92, 246),
}

-- ==================== ENV HELPERS ====================
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

local function protectGui(gui)
    pcall(function()
        if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then
            syn.protect_gui(gui)
        elseif typeof(protect_gui) == "function" then
            protect_gui(gui)
        elseif typeof(protectgui) == "function" then
            protectgui(gui)
        end
    end)
end

local function getExecutorName()
    local name = "Unknown"
    pcall(function()
        if identifyexecutor then name = identifyexecutor()
        elseif getexecutorname then name = getexecutorname() end
    end)
    return name
end

local function getHwid()
    local hwid = "ANONYMOUS"
    pcall(function()
        if gethwid then hwid = gethwid()
        else
            local ok, cid = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
            if ok and cid then hwid = cid end
        end
    end)
    return hwid
end

-- ==================== NOTIFICATION HELPER ====================
local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "LiyHub Aimbot",
            Text = tostring(text or ""):sub(1, 200),
            Duration = duration or 4,
        })
    end)
end

-- ==================== CONFIG PERSISTENCE ====================
local CONFIG_FILE = "liyhub_aimbot_config.json"

local function saveConfig()
    pcall(function()
        if writefile then
            local toSave = {}
            for k, v in __raw_pairs(Config) do
                if __raw_type(v) == "Color3" then
                    toSave[k] = { __color = true, r = v.R, g = v.G, b = v.B }
                elseif __raw_type(v) ~= "table" then
                    toSave[k] = v
                end
            end
            writefile(CONFIG_FILE, HttpService:JSONEncode(toSave))
        end
    end)
end

local function loadConfig()
    pcall(function()
        if isfile and readfile and isfile(CONFIG_FILE) then
            local raw = readfile(CONFIG_FILE)
            if raw and raw ~= "" then
                local decoded = HttpService:JSONDecode(raw)
                for k, v in __raw_pairs(decoded) do
                    if __raw_type(v) == "table" and v.__color then
                        Config[k] = Color3.new(v.r, v.g, v.b)
                    elseif Config[k] ~= nil then
                        Config[k] = v
                    end
                end
            end
        end
    end)
end
loadConfig()

-- ==================== LOADING OVERLAY (LiyHub Style) ====================
local function createLoadingOverlay(titleText)
    local guiParent = getGuiParent()
    if not guiParent then return nil end

    if guiParent:FindFirstChild("LiyHubAimbotLoading") then
        pcall(function() guiParent.LiyHubAimbotLoading:Destroy() end)
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "LiyHubAimbotLoading"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 9999
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    protectGui(ScreenGui)

    local camera = Workspace.CurrentCamera
    local vp = camera and camera.ViewportSize or Vector2.new(800, 600)
    local isSmall = vp.X < 600 or vp.Y < 450
    local targetW = isSmall and math.clamp(vp.X - 32, 260, 320) or 360
    local targetH = 90

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.fromOffset(targetW, targetH)
    MainFrame.Position = UDim2.new(0.5, -targetW / 2, 0.5, -targetH / 2)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Theme.Border
    MainStroke.Thickness = 1
    MainStroke.Parent = MainFrame

    -- TopBar
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 36)
    TopBar.BackgroundColor3 = Theme.Surface
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame

    local TopLine = Instance.new("Frame")
    TopLine.Size = UDim2.new(1, 0, 0, 1)
    TopLine.Position = UDim2.new(0, 0, 1, -1)
    TopLine.BackgroundColor3 = Theme.Border
    TopLine.BorderSizePixel = 0
    TopLine.Parent = TopBar

    local Logo = Instance.new("Frame")
    Logo.Size = UDim2.fromOffset(22, 22)
    Logo.Position = UDim2.new(0, 10, 0.5, -11)
    Logo.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    Logo.BorderSizePixel = 0
    Logo.Parent = TopBar
    Instance.new("UICorner", Logo).CornerRadius = UDim.new(0, 11)

    local LogoStroke = Instance.new("UIStroke")
    LogoStroke.Color = Theme.Accent
    LogoStroke.Thickness = 1
    LogoStroke.Transparency = 0.3
    LogoStroke.Parent = Logo

    local LogoImg = Instance.new("ImageLabel")
    LogoImg.Size = UDim2.fromScale(1, 1)
    LogoImg.BackgroundTransparency = 1
    LogoImg.Image = "rbxassetid://123085513549252"
    LogoImg.ScaleType = Enum.ScaleType.Fit
    LogoImg.Parent = Logo
    Instance.new("UICorner", LogoImg).CornerRadius = UDim.new(0, 11)

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
    Subtitle.Size = UDim2.new(0, 200, 1, 0)
    Subtitle.Position = UDim2.new(0, 106, 0, 0)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.Text = "•  " .. (titleText or "Loading")
    Subtitle.TextColor3 = Theme.TextSecondary
    Subtitle.TextSize = 11
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    Subtitle.Parent = TopBar

    -- Controls (dots)
    local Controls = Instance.new("Frame")
    Controls.Size = UDim2.new(0, 42, 1, 0)
    Controls.Position = UDim2.new(1, -50, 0, 0)
    Controls.BackgroundTransparency = 1
    Controls.Parent = TopBar

    local CtrlL = Instance.new("UIListLayout")
    CtrlL.FillDirection = Enum.FillDirection.Horizontal
    CtrlL.HorizontalAlignment = Enum.HorizontalAlignment.Right
    CtrlL.VerticalAlignment = Enum.VerticalAlignment.Center
    CtrlL.Padding = UDim.new(0, 8)
    CtrlL.Parent = Controls

    for _, c in ipairs({ Color3.fromRGB(242, 201, 76), Color3.fromRGB(80, 85, 110) }) do
        local d = Instance.new("Frame")
        d.Size = UDim2.fromOffset(11, 11)
        d.BackgroundColor3 = c
        d.Parent = Controls
        Instance.new("UICorner", d).CornerRadius = UDim.new(0, 6)
    end

    -- Progress bar
    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, -24, 0, 4)
    Track.Position = UDim2.new(0, 12, 0, 56)
    Track.BackgroundColor3 = Theme.SurfaceSecondary
    Track.BorderSizePixel = 0
    Track.Parent = MainFrame
    Instance.new("UICorner", Track).CornerRadius = UDim.new(0, 2)

    local TrackStroke = Instance.new("UIStroke")
    TrackStroke.Color = Theme.Border
    TrackStroke.Thickness = 1
    TrackStroke.Parent = Track

    local FillBar = Instance.new("Frame")
    FillBar.Size = UDim2.new(0, 0, 1, 0)
    FillBar.BackgroundColor3 = Theme.Accent
    FillBar.BorderSizePixel = 0
    FillBar.Parent = Track
    Instance.new("UICorner", FillBar).CornerRadius = UDim.new(0, 2)

    local Grad = Instance.new("UIGradient")
    Grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(99, 102, 241)),
    })
    Grad.Rotation = 90
    Grad.Parent = FillBar

    ScreenGui.Parent = guiParent

    return {
        Update = function(_, pct)
            pcall(function()
                pct = math.clamp(pct, 0, 100)
                TweenService:Create(FillBar, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                    Size = UDim2.new(pct / 100, 0, 1, 0),
                }):Play()
            end)
        end,
        Destroy = function(_)
            pcall(function() ScreenGui:Destroy() end)
        end,
    }
end

-- ==================== MAIN AIMBOT GUI ====================
local guiParent = getGuiParent()
if not guiParent then
    warn("[Aimbot] Tidak bisa resolve GUI parent.")
    return
end

if guiParent:FindFirstChild("LiyHubAimbotGui") then
    guiParent.LiyHubAimbotGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LiyHubAimbotGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
protectGui(ScreenGui)

-- FOV Circle
local FovCircle = Instance.new("Frame")
FovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FovCircle.Size = UDim2.fromOffset(Config.FovRadius * 2, Config.FovRadius * 2)
FovCircle.BackgroundTransparency = 1
FovCircle.BorderSizePixel = 0
FovCircle.ZIndex = 5
FovCircle.Parent = ScreenGui

Instance.new("UICorner", FovCircle).CornerRadius = UDim.new(1, 0)
local FovStroke = Instance.new("UIStroke")
FovStroke.Color = Config.FovColor
FovStroke.Thickness = 1.5
FovStroke.Transparency = 0.35
FovStroke.Parent = FovCircle

-- Main Frame
local vp = Camera and Camera.ViewportSize or Vector2.new(800, 600)
local isSmall = vp.X < 700 or vp.Y < 600
local FRAME_W = isSmall and math.clamp(vp.X - 40, 280, 320) or 320
local FRAME_H = isSmall and math.clamp(vp.Y - 100, 380, 520) or 520

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

-- TopBar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 36)
TopBar.BackgroundColor3 = Theme.Surface
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopLine = Instance.new("Frame")
TopLine.Size = UDim2.new(1, 0, 0, 1)
TopLine.Position = UDim2.new(0, 0, 1, -1)
TopLine.BackgroundColor3 = Theme.Border
TopLine.BorderSizePixel = 0
TopLine.Parent = TopBar

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
Subtitle.Text = "•  Aim Assist v2"
Subtitle.TextColor3 = Theme.TextSecondary
Subtitle.TextSize = 11
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = TopBar

-- Mac dots
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

-- Draggable
local dragging, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
TopBar.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Floating reopen button
local FloatingBtn = Instance.new("TextButton")
FloatingBtn.Name = "ReopenButton"
FloatingBtn.Size = UDim2.fromOffset(36, 36)
FloatingBtn.Position = UDim2.new(1, -52, 0, 60)
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

local function setMinimized(v)
    MainFrame.Visible = not v
    FloatingBtn.Visible = v
end

FloatingBtn.MouseButton1Click:Connect(function() setMinimized(false) end)
MinBtn.MouseButton1Click:Connect(function() setMinimized(true) end)
CloseBtn.MouseButton1Click:Connect(function()
    setMinimized(true)
    notify("👋 LiyHub Aimbot", "GUI ditutup. Klik tombol 🎯 di kanan atas untuk membuka kembali.", 5)
end)

-- Content (scrollable)
local Scroll = Instance.new("ScrollingFrame")
Scroll.Name = "Content"
Scroll.Size = UDim2.new(1, -20, 1, -52)
Scroll.Position = UDim2.new(0, 10, 0, 44)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Theme.Accent
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.FillDirection = Enum.FillDirection.Vertical
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 8)
Layout.Parent = Scroll

local Pad = Instance.new("UIPadding")
Pad.PaddingTop = UDim.new(0, 4)
Pad.PaddingBottom = UDim.new(0, 8)
Pad.Parent = Scroll

-- ==================== UI WIDGET FACTORIES ====================
local function makeRow(order, height)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, height or 30)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order
    row.Parent = Scroll
    return row
end

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
    lbl.Parent = Scroll
    return lbl
end

local function makeDivider(order)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1, 0, 0, 1)
    d.BackgroundColor3 = Theme.Border
    d.BorderSizePixel = 0
    d.LayoutOrder = order
    d.Parent = Scroll
    return d
end

local function makeToggle(order, labelText, defaultState, onChanged)
    local row = makeRow(order, 32)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = labelText
    lbl.TextColor3 = Theme.Text
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

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
    local function apply(newState)
        state = newState
        TweenService:Create(btn, TweenInfo.new(0.18), {
            BackgroundColor3 = state and Theme.Accent or Theme.SurfaceSecondary,
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.18), {
            Position = state and UDim2.new(1, -20, 0.5, -8) or UDim2.new(0, 4, 0.5, -8),
        }):Play()
        if onChanged then onChanged(state) end
    end

    btn.MouseButton1Click:Connect(function() apply(not state) end)

    return {
        Set = function(v) if state ~= v then apply(v) end end,
        Get = function() return state end,
    }
end

local function makeSlider(order, labelText, minV, maxV, defaultV, isFloat, onChanged)
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
    valLbl.Text = isFloat and string.format("%.2f", defaultV) or tostring(math.floor(defaultV))
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
        value = minV + pct * (maxV - minV)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, 0.5, 0)
        valLbl.Text = isFloat and string.format("%.2f", value) or tostring(math.floor(value + 0.5))
        if onChanged then onChanged(value) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            setFromX(input.Position.X)
        end
    end)
    track.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch)
            and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            setFromX(input.Position.X)
        end
    end)

    return {
        Set = function(v)
            local pct = math.clamp((v - minV) / (maxV - minV), 0, 1)
            value = v
            fill.Size = UDim2.new(pct, 0, 1, 0)
            knob.Position = UDim2.new(pct, 0, 0.5, 0)
            valLbl.Text = isFloat and string.format("%.2f", v) or tostring(math.floor(v + 0.5))
        end,
        Get = function() return value end,
    }
end

-- Dropdown (cycle button)
local function makeDropdown(order, labelText, options, defaultIndex, onChanged)
    local row = makeRow(order, 32)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = labelText
    lbl.TextColor3 = Theme.Text
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.5, 0, 1, 0)
    btn.Position = UDim2.new(0.5, 0, 0, 0)
    btn.BackgroundColor3 = Theme.SurfaceSecondary
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = options[defaultIndex] or options[1]
    btn.TextColor3 = Theme.Accent
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Border
    stroke.Thickness = 1
    stroke.Parent = btn

    local idx = defaultIndex
    btn.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        btn.Text = options[idx]
        if onChanged then onChanged(options[idx], idx) end
    end)

    return {
        Get = function() return options[idx] end,
    }
end

-- Action button (full width)
local function makeActionButton(order, labelText, color, onClick)
    local row = makeRow(order, 34)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = color or Theme.Accent
    btn.Text = labelText
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.BorderSizePixel = 0
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = color == Theme.Error and Color3.fromRGB(220, 50, 80) or Theme.AccentHover,
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = color or Theme.Accent }):Play()
    end)

    btn.MouseButton1Click:Connect(onClick)
    return btn
end

-- ==================== BUILD UI ====================
local toggleRefs = {}

-- Section: Core
makeSectionTitle(1, "Core")
toggleRefs.Enabled = makeToggle(2, "Aimbot Master", Config.Enabled, function(v)
    Config.Enabled = v
    saveConfig()
    notify(v and "✅ Aimbot ON" or "⛔ Aimbot OFF", v and "Aim assist aktif." or "Aim assist dinonaktifkan.", 2)
end)
toggleRefs.StickyLock = makeToggle(3, "Sticky Lock", Config.StickyLock, function(v) Config.StickyLock = v; saveConfig() end)
toggleRefs.Wallcheck  = makeToggle(4, "Wallcheck (Raycast)", Config.Wallcheck, function(v) Config.Wallcheck = v; saveConfig() end)
toggleRefs.TeamCheck  = makeToggle(5, "Team Check", Config.TeamCheck, function(v) Config.TeamCheck = v; saveConfig() end)
toggleRefs.AutoSwitch = makeToggle(6, "Auto-Switch on Kill", Config.AutoSwitch, function(v) Config.AutoSwitch = v; saveConfig() end)

makeDivider(7)

-- Section: Aim Behavior
makeSectionTitle(8, "Aim Behavior")
makeSlider(9, "Smoothness", 0, 1, Config.Smoothness, true, function(v) Config.Smoothness = v; saveConfig() end)
makeSlider(10, "Prediction", 0, 1, Config.Prediction, true, function(v) Config.Prediction = v; saveConfig() end)

local aimModeDropdown = makeDropdown(11, "Aim Mode", { "Hold", "Toggle", "Always" },
    ({ Hold = 1, Toggle = 2, Always = 3 })[Config.AimMode] or 1,
    function(v) Config.AimMode = v; saveConfig() end
)

makeDropdown(12, "Target Part", { "Head", "UpperTorso", "Torso", "Nearest" },
    ({ Head = 1, UpperTorso = 2, Torso = 3, Nearest = 4 })[Config.TargetPart] or 1,
    function(v) Config.TargetPart = v; saveConfig() end
)

makeDivider(13)

-- Section: Visuals
makeSectionTitle(14, "Visuals")
makeSlider(15, "FOV Radius", 40, 400, Config.FovRadius, false, function(v)
    Config.FovRadius = v
    FovCircle.Size = UDim2.fromOffset(v * 2, v * 2)
    saveConfig()
end)
toggleRefs.RainbowFov = makeToggle(16, "Rainbow FOV", Config.RainbowFov, function(v) Config.RainbowFov = v; saveConfig() end)

makeDivider(17)

-- Section: Actions
makeSectionTitle(18, "Actions")
makeActionButton(19, "🔄  Switch Target Now", Theme.Accent, function()
    -- diisi setelah fungsi getTargetInFov didefinisikan di bawah
    if _G.__LiyHubSwitchTarget then _G.__LiyHubSwitchTarget() end
end)
makeActionButton(20, "💾  Save Config", Theme.SurfaceSecondary, function()
    saveConfig()
    notify("💾 Config Saved", "Pengaturan berhasil disimpan.", 3)
end)
makeActionButton(21, "♻️  Reset Config", Theme.Warning, function()
    pcall(function()
        if delfile and isfile(CONFIG_FILE) then delfile(CONFIG_FILE) end
    end)
    notify("♻️ Config Reset", "Restart script untuk memuat default.", 4)
end)

-- Status footer
local statusRow = makeRow(22, 22)
local StatusLbl = Instance.new("TextLabel")
StatusLbl.Size = UDim2.new(1, 0, 1, 0)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Font = Enum.Font.Gotham
StatusLbl.Text = "Status: Idle"
StatusLbl.TextColor3 = Theme.TextSecondary
StatusLbl.TextSize = 11
StatusLbl.TextXAlignment = Enum.TextXAlignment.Left
StatusLbl.Parent = statusRow

-- ==================== AIMBOT CORE LOGIC ====================
local currentTarget = nil
local stickyLocked = false
local aimHeld = false   -- Hold mode
local aimToggled = false -- Toggle mode
local headVelocities = {} -- [player] = {pos, time, velocity}

local function isAiming()
    if Config.AimMode == "Always" then return true end
    if Config.AimMode == "Toggle" then return aimToggled end
    return aimHeld -- Hold
end

local function hasLineOfSight(targetChar)
    local targetPart
    if Config.TargetPart == "Head" then
        targetPart = targetChar:FindFirstChild("Head")
    elseif Config.TargetPart == "UpperTorso" then
        targetPart = targetChar:FindFirstChild("UpperTorso")
    elseif Config.TargetPart == "Torso" then
        targetPart = targetChar:FindFirstChild("Torso")
    else
        targetPart = targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("UpperTorso")
    end
    if not targetPart then return false end

    local origin = Camera.CFrame.Position
    local dir = targetPart.Position - origin
    local dist = dir.Magnitude
    if dist <= 0 then return false end
    dir = dir.Unit

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { LocalPlayer.Character, targetChar }
    params.IgnoreWater = true

    local result = Workspace:Raycast(origin, dir * dist, params)
    return result == nil
end

local function isSameTeam(plr)
    if not Config.TeamCheck then return false end
    if not LocalPlayer.Team then return false end
    return plr.Team == LocalPlayer.Team
end

local function getTargetPart(char)
    if not char then return nil end
    if Config.TargetPart == "Head" then
        return char:FindFirstChild("Head")
    elseif Config.TargetPart == "UpperTorso" then
        return char:FindFirstChild("UpperTorso")
    elseif Config.TargetPart == "Torso" then
        return char:FindFirstChild("Torso")
    end
    -- Nearest: pilih part terdekat dari kamera
    local best, bestD = nil, math.huge
    local camPos = Camera.CFrame.Position
    for _, name in ipairs({ "Head", "UpperTorso", "Torso", "HumanoidRootPart" }) do
        local p = char:FindFirstChild(name)
        if p then
            local d = (p.Position - camPos).Magnitude
            if d < bestD then bestD = d; best = p end
        end
    end
    return best
end

-- Prediction: hitung velocity dari delta posisi antar-frame
local function updateVelocity(plr, part)
    local now = tick()
    local cache = headVelocities[plr]
    if cache then
        local dt = now - cache.time
        if dt > 0.001 then
            cache.velocity = (part.Position - cache.pos) / dt
        end
        cache.pos = part.Position
        cache.time = now
    else
        headVelocities[plr] = { pos = part.Position, time = now, velocity = Vector3.zero }
    end
end

local function getPredictedPosition(plr, part)
    updateVelocity(plr, part)
    local cache = headVelocities[plr]
    if not cache then return part.Position end
    local camPos = Camera.CFrame.Position
    local dist = (part.Position - camPos).Magnitude
    local travelTime = dist / 1000 -- proyeksi kasar (assume speed projectile ~1000 studs/s)
    return part.Position + (cache.velocity * travelTime * Config.Prediction)
end

local function getTargetInFov(exclude)
    local best, bestDist = nil, math.huge
    local center = Camera.ViewportSize / 2
    local camPos = Camera.CFrame.Position

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr ~= exclude and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local part = getTargetPart(plr.Character)
            if hum and hum.Health > 0 and part and not isSameTeam(plr) then
                local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dx, dy = sp.X - center.X, sp.Y - center.Y
                    if math.sqrt(dx * dx + dy * dy) <= Config.FovRadius then
                        if not Config.Wallcheck or hasLineOfSight(plr.Character) then
                            local d = (part.Position - camPos).Magnitude
                            if d < bestDist then
                                bestDist, best = d, plr
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
    local part = getTargetPart(plr.Character)
    if not hum or hum.Health <= 0 or not part then return false end
    if isSameTeam(plr) then return false end

    local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen then return false end
    local center = Camera.ViewportSize / 2
    local dx, dy = sp.X - center.X, sp.Y - center.Y
    if math.sqrt(dx * dx + dy * dy) > Config.FovRadius then return false end
    if Config.Wallcheck and not hasLineOfSight(plr.Character) then return false end
    return true
end

local function aimAt(plr)
    if not plr or not plr.Character then return end
    local part = getTargetPart(plr.Character)
    if not part then return end

    local targetPos = Config.Prediction > 0 and getPredictedPosition(plr, part) or part.Position
    local camPos = Camera.CFrame.Position
    local goalCF = CFrame.lookAt(camPos, targetPos)

    if Config.SilentAim then
        -- Silent aim: tanpa ubah CFrame, hanya reference (butuh hook metatable, di sini placeholder)
        -- Kamu bisa gunakan hook NameCall ke "Fire" / gun remote untuk mengarahkan peluru
        return
    end

    local alpha = 1 - math.pow(Config.Smoothness, 0.5)
    alpha = math.clamp(alpha, 0.05, 1)
    Camera.CFrame = Camera.CFrame:Lerp(goalCF, alpha)
end

-- Manual switch target
_G.__LiyHubSwitchTarget = function()
    if not Config.Enabled then return end
    local prev = currentTarget
    local newT = getTargetInFov(prev)
    if newT then
        currentTarget = newT
        stickyLocked = true
        notify("🎯 Target Switched", "Mengunci: " .. newT.Name, 2)
    else
        notify("🎯 No Target", "Tidak ada musuh lain dalam FOV.", 2)
    end
end

-- Input binding untuk aim key (default: RMB)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if Config.AimMode == "Hold" then
            aimHeld = true
        elseif Config.AimMode == "Toggle" then
            aimToggled = not aimToggled
        end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        if Config.AimMode == "Hold" then aimHeld = false end
    end
end)

-- Handle respawn (CharacterAdded)
LocalPlayer.CharacterAdded:Connect(function()
    currentTarget = nil
    stickyLocked = false
    headVelocities = {}
    if Config.Enabled then
        notify("♻️ Respawn", "Aimbot auto-resume setelah respawn.", 3)
    end
end)

-- Main render loop
RunService.RenderStepped:Connect(function()
    if not Config.Enabled then
        currentTarget = nil
        stickyLocked = false
        StatusLbl.Text = "Status: Disabled"
        StatusLbl.TextColor3 = Theme.TextSecondary
        return
    end

    if not isAiming() then
        StatusLbl.Text = "Status: Standby (hold aim key)"
        StatusLbl.TextColor3 = Theme.Warning
        currentTarget = nil
        stickyLocked = false
        return
    end

    if stickyLocked and currentTarget then
        if not isValidTarget(currentTarget) then
            if Config.AutoSwitch then
                local newT = getTargetInFov(currentTarget)
                if newT then
                    currentTarget = newT
                else
                    stickyLocked = false
                    currentTarget = nil
                end
            else
                stickyLocked = false
                currentTarget = nil
            end
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

-- Rainbow FOV + visibility
task.spawn(function()
    local hue = 0
    while task.wait(0.03) do
        FovCircle.Visible = Config.Enabled and MainFrame.Visible
        if Config.RainbowFov then
            hue = (hue + 0.01) % 1
            FovStroke.Color = Color3.fromHSV(hue, 0.8, 1)
        else
            FovStroke.Color = Config.FovColor
        end
    end
end)

-- Responsive FOV positioning
local function updateFov()
    FovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
    FovCircle.Size = UDim2.fromOffset(Config.FovRadius * 2, Config.FovRadius * 2)
end
updateFov()
if Camera then
    Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateFov)
end

-- ==================== PERSISTENCE / TELEPORT-SAFE ====================
local function setupPersistence()
    pcall(function()
        local queueFn = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
        if queueFn then
            local reExec = string.format([[
                task.spawn(function()
                    repeat task.wait() until game:IsLoaded()
                    pcall(function()
                        loadstring(game:HttpGet("%s"))()
                    end)
                end)
            ]], "https://pastebin.com/raw/PLACEHOLDER") -- ganti dengan URL raw script kamu
            queueFn(reExec)
        end
    end)

    -- Auto rejoin saat error/kick
    pcall(function()
        GuiService.ErrorMessageChanged:Connect(function()
            task.delay(1.5, function()
                local placeId = game.PlaceId
                local jobId = game.JobId
                pcall(function()
                    if #Players:GetPlayers() <= 1 or not jobId or jobId == "" then
                        TeleportService:Teleport(placeId, LocalPlayer)
                    else
                        TeleportService:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
                    end
                end)
            end)
        end)
    end)
end

-- ==================== CLEANUP ====================
local function cleanup()
    pcall(function()
        if ScreenGui then ScreenGui:Destroy() end
        if guiParent:FindFirstChild("LiyHubAimbotLoading") then
            guiParent.LiyHubAimbotLoading:Destroy()
        end
    end)
end

if getgenv then
    getgenv()._LIYHUB_AIMBOT_CLEANUP = cleanup
end

-- ==================== INIT (Loader Flow) ====================
task.spawn(function()
    local loader = createLoadingOverlay("Initializing Aim Assist")
    if loader then loader:Update(15) end

    -- Step 1: Env check
    task.wait(0.15)
    if loader then loader:Update(35) end

    -- Step 2: Build UI (sudah dilakukan di atas)
    task.wait(0.2)
    if loader then loader:Update(60) end

    -- Step 3: Validate camera
    if not Camera then
        local ok
        for _ = 1, 20 do
            task.wait(0.1)
            ok = Workspace.CurrentCamera
            if ok then Camera = ok; break end
        end
    end
    if loader then loader:Update(85) end

    -- Step 4: Persistence
    pcall(setupPersistence)
    if loader then loader:Update(100) end

    task.wait(0.3)
    if loader then loader:Destroy() end

    -- Final: Attach GUI, notify
    ScreenGui.Parent = guiParent

    local execName = getExecutorName()
    notify("🎯 LiyHub Aimbot Loaded", string.format("Executor: %s • All features ready.", execName), 6)

    print("[LiyHub Aimbot] Loaded on executor: " .. execName)
end)

return true