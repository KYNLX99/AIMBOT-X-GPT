--[[
    ==============================================================
    LIYHUB AIMBOT + ESP — ULTIMATE EDITION
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

-- ==================== CONFIG ====================
local Config = {
    -- Aimbot
    Enabled         = true,
    StickyLock      = true,
    Wallcheck       = true,
    TeamCheck       = true,
    VisibleOnly     = true,
    AutoSwitch      = true,
    RainbowFov      = false,
    Smoothness      = 0.5,
    FovRadius       = 120,
    Prediction      = 0.15,
    TargetPart      = "Head",
    AimMode         = "Hold",
    SilentAim       = false,
    FovColor        = Color3.fromRGB(139, 92, 246),

    -- ESP
    EspEnabled      = true,
    EspBox          = true,
    EspName         = true,
    EspHealth       = true,
    EspDistance     = true,
    EspTracer       = false,
    EspSkeleton     = false,
    EspHeadDot      = true,
    EspMaxDistance  = 1000,
    EspTeamCheck    = true,
    EspShowTeam     = false,
    EspColor        = Color3.fromRGB(139, 92, 246),   -- outline box
    EspVisibleColor = Color3.fromRGB(16, 185, 129),   -- jika target visible
    EspTeamColor    = Color3.fromRGB(245, 158, 11),
    EspFillTransp   = 0.85,
    EspTextSize     = 12,
    EspTracerFrom   = "Bottom", -- Bottom / Center
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

-- ==================== DRAWING API RESOLVER ====================
local DrawingLib = nil
pcall(function()
    if Drawing then
        DrawingLib = Drawing
    elseif getgenv and getgenv().Drawing then
        DrawingLib = getgenv().Drawing
    elseif syn and syn.Drawing then
        DrawingLib = syn.Drawing
    end
end)

local HAS_DRAWING = DrawingLib ~= nil

-- ==================== ESP MODULE ====================
local ESP = {}
ESP.__index = ESP

-- Fallback via BillboardGui (jika Drawing tidak tersedia)
local espFolder = Instance.new("Folder")
espFolder.Name = "LiyHubESP"
espFolder.Parent = Camera

local espCache = {}         -- [player] = { drawings / billboard objects }
local billboardCache = {}   -- [player] = { BillboardGui, parts }

-- Utility: warna berdasarkan visibility & tim
local function resolveColor(plr)
    if Config.EspTeamCheck and LocalPlayer.Team and plr.Team == LocalPlayer.Team then
        return Config.EspTeamColor
    end
    -- Cek LOS
    local char = plr.Character
    if char then
        local head = char:FindFirstChild("Head")
        if head then
            local origin = Camera.CFrame.Position
            local dir = head.Position - origin
            local dist = dir.Magnitude
            if dist > 0 then
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Blacklist
                params.FilterDescendantsInstances = { LocalPlayer.Character, char }
                params.IgnoreWater = true
                local res = Workspace:Raycast(origin, dir.Unit * dist, params)
                if res == nil then
                    return Config.EspVisibleColor
                end
            end
        end
    end
    return Config.EspColor
end

-- ============ DRAWING-BASED ESP ============
local function createDrawing(class, props)
    local ok, obj = pcall(function()
        local d = DrawingLib.new(class)
        if props then
            for k, v in pairs(props) do d[k] = v end
        end
        return d
    end)
    if ok then return obj end
    return nil
end

local function destroyDrawingList(list)
    if not list then return end
    for _, obj in pairs(list) do
        pcall(function() obj:Destroy() end)
    end
end

local function ensureDrawings(plr)
    if espCache[plr] then return espCache[plr] end

    local d = {
        BoxOutline   = createDrawing("Square", { Thickness = 1, Filled = false, Transparency = 1, Visible = false }),
        BoxFill      = createDrawing("Square", { Thickness = 1, Filled = true, Transparency = Config.EspFillTransp, Visible = false }),
        Name         = createDrawing("Text",   { Size = Config.EspTextSize, Center = true, Outline = true, Visible = false }),
        Distance     = createDrawing("Text",   { Size = Config.EspTextSize - 2, Center = true, Outline = true, Visible = false }),
        Tracer       = createDrawing("Line",   { Thickness = 1, Visible = false }),
        HeadDot      = createDrawing("Circle", { Thickness = 2, Filled = true, Transparency = 0.3, Visible = false }),

        -- Health bar (3 elemen: background, fill, outline)
        HealthBg     = createDrawing("Square", { Thickness = 1, Filled = true, Color = Color3.new(0,0,0), Transparency = 0.4, Visible = false }),
        HealthFill   = createDrawing("Square", { Thickness = 1, Filled = true, Color = Color3.fromRGB(16,185,129), Transparency = 0, Visible = false }),

        -- Skeleton (11 bones: head-upper, upper-lower, shoulder-L, L-hand, shoulder-R, R-hand, hip-L, L-foot, hip-R, R-foot)
        Skeleton = {
            headUpper = createDrawing("Line", { Thickness = 1, Visible = false }),
            upperLower = createDrawing("Line", { Thickness = 1, Visible = false }),
            shoulderL = createDrawing("Line", { Thickness = 1, Visible = false }),
            armL = createDrawing("Line", { Thickness = 1, Visible = false }),
            shoulderR = createDrawing("Line", { Thickness = 1, Visible = false }),
            armR = createDrawing("Line", { Thickness = 1, Visible = false }),
            hipL = createDrawing("Line", { Thickness = 1, Visible = false }),
            legL = createDrawing("Line", { Thickness = 1, Visible = false }),
            hipR = createDrawing("Line", { Thickness = 1, Visible = false }),
            legR = createDrawing("Line", { Thickness = 1, Visible = false }),
        },
    }

    espCache[plr] = d
    return d
end

local function updateDrawingESP(plr)
    if not HAS_DRAWING then return end

    local d = espCache[plr]
    if not d then return end

    local char = plr.Character
    if not char then
        for _, obj in pairs(d) do
            if __raw_type(obj) == "table" then
                destroyDrawingList(obj)
            else
                pcall(function() obj.Visible = false end)
            end
        end
        return
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not hum or not hrp or not head or hum.Health <= 0 then
        pcall(function() d.BoxOutline.Visible = false end)
        pcall(function() d.BoxFill.Visible = false end)
        pcall(function() d.Name.Visible = false end)
        pcall(function() d.Distance.Visible = false end)
        pcall(function() d.Tracer.Visible = false end)
        pcall(function() d.HeadDot.Visible = false end)
        pcall(function() d.HealthBg.Visible = false end)
        pcall(function() d.HealthFill.Visible = false end)
        for _, obj in pairs(d.Skeleton) do
            pcall(function() obj.Visible = false end)
        end
        return
    end

    local camPos = Camera.CFrame.Position
    local dist = (hrp.Position - camPos).Magnitude
    if dist > Config.EspMaxDistance then
        pcall(function() d.BoxOutline.Visible = false end)
        pcall(function() d.BoxFill.Visible = false end)
        pcall(function() d.Name.Visible = false end)
        pcall(function() d.Distance.Visible = false end)
        pcall(function() d.Tracer.Visible = false end)
        pcall(function() d.HeadDot.Visible = false end)
        pcall(function() d.HealthBg.Visible = false end)
        pcall(function() d.HealthFill.Visible = false end)
        for _, obj in pairs(d.Skeleton) do
            pcall(function() obj.Visible = false end)
        end
        return
    end

    -- Team check
    if Config.EspTeamCheck and not Config.EspShowTeam and LocalPlayer.Team and plr.Team == LocalPlayer.Team then
        pcall(function() d.BoxOutline.Visible = false end)
        pcall(function() d.BoxFill.Visible = false end)
        pcall(function() d.Name.Visible = false end)
        pcall(function() d.Distance.Visible = false end)
        pcall(function() d.Tracer.Visible = false end)
        pcall(function() d.HeadDot.Visible = false end)
        pcall(function() d.HealthBg.Visible = false end)
        pcall(function() d.HealthFill.Visible = false end)
        for _, obj in pairs(d.Skeleton) do
            pcall(function() obj.Visible = false end)
        end
        return
    end

    local color = resolveColor(plr)

    -- Compute box dari head & HRP
    local headPos, headVis = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
    local hrpPos, hrpVis = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

    if not (headVis and hrpVis) then
        pcall(function() d.BoxOutline.Visible = false end)
        pcall(function() d.BoxFill.Visible = false end)
        pcall(function() d.Name.Visible = false end)
        pcall(function() d.Distance.Visible = false end)
        pcall(function() d.Tracer.Visible = false end)
        pcall(function() d.HeadDot.Visible = false end)
        pcall(function() d.HealthBg.Visible = false end)
        pcall(function() d.HealthFill.Visible = false end)
        for _, obj in pairs(d.Skeleton) do
            pcall(function() obj.Visible = false end)
        end
        return
    end

    -- Lebar box proporsional dengan jarak
    local height = math.abs(hrpPos.Y - headPos.Y)
    local width = height * 0.55
    local boxX = headPos.X - width / 2
    local boxY = headPos.Y
    local boxW = width
    local boxH = height

    -- ===== Box Outline =====
    if Config.EspBox then
        pcall(function()
            d.BoxOutline.Visible = true
            d.BoxOutline.Color = color
            d.BoxOutline.Position = Vector2.new(boxX, boxY)
            d.BoxOutline.Size = Vector2.new(boxW, boxH)
        end)
        pcall(function()
            d.BoxFill.Visible = true
            d.BoxFill.Color = color
            d.BoxFill.Transparency = Config.EspFillTransp
            d.BoxFill.Position = Vector2.new(boxX, boxY)
            d.BoxFill.Size = Vector2.new(boxW, boxH)
        end)
    else
        pcall(function() d.BoxOutline.Visible = false end)
        pcall(function() d.BoxFill.Visible = false end)
    end

    -- ===== Name =====
    if Config.EspName then
        pcall(function()
            d.Name.Visible = true
            d.Name.Color = color
            d.Name.Text = plr.DisplayName
            d.Name.Position = Vector2.new(boxX + boxW / 2, boxY - 14)
        end)
    else
        pcall(function() d.Name.Visible = false end)
    end

    -- ===== Distance =====
    if Config.EspDistance then
        pcall(function()
            d.Distance.Visible = true
            d.Distance.Color = color
            d.Distance.Text = string.format("[%d studs]", math.floor(dist))
            d.Distance.Position = Vector2.new(boxX + boxW / 2, boxY + boxH + 6)
        end)
    else
        pcall(function() d.Distance.Visible = false end)
    end

    -- ===== Tracer =====
    if Config.EspTracer then
        local vp = Camera.ViewportSize
        local fromX, fromY
        if Config.EspTracerFrom == "Bottom" then
            fromX, fromY = vp.X / 2, vp.Y
        else
            fromX, fromY = vp.X / 2, vp.Y / 2
        end
        pcall(function()
            d.Tracer.Visible = true
            d.Tracer.Color = color
            d.Tracer.From = Vector2.new(fromX, fromY)
            d.Tracer.To = Vector2.new(boxX + boxW / 2, boxY + boxH)
        end)
    else
        pcall(function() d.Tracer.Visible = false end)
    end

    -- ===== Head Dot =====
    if Config.EspHeadDot then
        pcall(function()
            d.HeadDot.Visible = true
            d.HeadDot.Color = color
            d.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
            d.HeadDot.Radius = 3
        end)
    else
        pcall(function() d.HeadDot.Visible = false end)
    end

    -- ===== Health Bar =====
    if Config.EspHealth then
        local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local hpX = boxX - 7
        local hpW = 3
        local hpY = boxY
        local hpH = boxH
        local healthColor = Color3.fromRGB(
            math.floor(255 * (1 - pct)),
            math.floor(255 * pct),
            60
        )

        pcall(function()
            d.HealthBg.Visible = true
            d.HealthBg.Position = Vector2.new(hpX, hpY)
            d.HealthBg.Size = Vector2.new(hpW, hpH)
            d.HealthBg.Color = Color3.fromRGB(0, 0, 0)
        end)
        pcall(function()
            d.HealthFill.Visible = true
            d.HealthFill.Position = Vector2.new(hpX, hpY + hpH * (1 - pct))
            d.HealthFill.Size = Vector2.new(hpW, hpH * pct)
            d.HealthFill.Color = healthColor
        end)
    else
        pcall(function() d.HealthBg.Visible = false end)
        pcall(function() d.HealthFill.Visible = false end)
    end

    -- ===== Skeleton =====
    if Config.EspSkeleton then
        local function w2s(part)
            if not part then return nil end
            local sp, vis = Camera:WorldToViewportPoint(part.Position)
            if not vis then return nil end
            return Vector2.new(sp.X, sp.Y)
        end

        local upperTorso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        local lowerTorso = char:FindFirstChild("LowerTorso") or char:FindFirstChild("Torso")
        local headPart = head
        local lArm = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
        local lHand = char:FindFirstChild("LeftLowerArm") or char:FindFirstChild("Left Arm")
        local rArm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
        local rHand = char:FindFirstChild("RightLowerArm") or char:FindFirstChild("Right Arm")
        local lLeg = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")
        local lFoot = char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Leg")
        local rLeg = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")
        local rFoot = char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Leg")

        local pts = {
            head = w2s(headPart),
            upper = w2s(upperTorso),
            lower = w2s(lowerTorso),
            lArm = w2s(lArm), lHand = w2s(lHand),
            rArm = w2s(rArm), rHand = w2s(rHand),
            lLeg = w2s(lLeg), lFoot = w2s(lFoot),
            rLeg = w2s(rLeg), rFoot = w2s(rFoot),
        }

        local function setLine(line, a, b)
            if not line then return end
            if a and b then
                pcall(function()
                    line.Visible = true
                    line.Color = color
                    line.From = a
                    line.To = b
                end)
            else
                pcall(function() line.Visible = false end)
            end
        end

        setLine(d.Skeleton.headUpper, pts.head, pts.upper)
        setLine(d.Skeleton.upperLower, pts.upper, pts.lower)
        setLine(d.Skeleton.shoulderL, pts.upper, pts.lArm)
        setLine(d.Skeleton.armL, pts.lArm, pts.lHand)
        setLine(d.Skeleton.shoulderR, pts.upper, pts.rArm)
        setLine(d.Skeleton.armR, pts.rArm, pts.rHand)
        setLine(d.Skeleton.hipL, pts.lower, pts.lLeg)
        setLine(d.Skeleton.legL, pts.lLeg, pts.lFoot)
        setLine(d.Skeleton.hipR, pts.lower, pts.rLeg)
        setLine(d.Skeleton.legR, pts.rLeg, pts.rFoot)
    else
        for _, obj in pairs(d.Skeleton) do
            pcall(function() obj.Visible = false end)
        end
    end
end

-- ============ BILLBOARD FALLBACK ============
local function ensureBillboard(plr)
    if billboardCache[plr] then return billboardCache[plr] end
    local char = plr.Character
    if not char then return nil end
    local head = char:FindFirstChild("Head")
    if not head then return nil end

    -- Hapus yg lama
    local existing = head:FindFirstChild("LiyHubESP")
    if existing then existing:Destroy() end

    local bg = Instance.new("BillboardGui")
    bg.Name = "LiyHubESP"
    bg.Size = UDim2.new(0, 100, 0, 50)
    bg.StudsOffset = Vector3.new(0, 3, 0)
    bg.AlwaysOnTop = true
    bg.MaxDistance = Config.EspMaxDistance
    bg.Adornee = head
    bg.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0, 14)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = Config.EspTextSize
    nameLabel.TextColor3 = Config.EspColor
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Text = plr.DisplayName
    nameLabel.Parent = bg

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistLabel"
    distLabel.Size = UDim2.new(1, 0, 0, 12)
    distLabel.Position = UDim2.new(0, 0, 1, -12)
    distLabel.BackgroundTransparency = 1
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = Config.EspTextSize - 2
    distLabel.TextColor3 = Config.EspColor
    distLabel.TextStrokeTransparency = 0.5
    distLabel.Text = ""
    distLabel.Parent = bg

    billboardCache[plr] = { Billboard = bg, Name = nameLabel, Dist = distLabel }
    return billboardCache[plr]
end

local function updateBillboardESP(plr)
    local char = plr.Character
    if not char then
        if billboardCache[plr] and billboardCache[plr].Billboard then
            billboardCache[plr].Billboard:Destroy()
        end
        billboardCache[plr] = nil
        return
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not hum or not hrp or not head or hum.Health <= 0 then
        if billboardCache[plr] and billboardCache[plr].Billboard then
            billboardCache[plr].Billboard.Enabled = false
        end
        return
    end

    local data = ensureBillboard(plr)
    if not data then return end

    local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
    local withinRange = dist <= Config.EspMaxDistance

    local isTeam = Config.EspTeamCheck and LocalPlayer.Team and plr.Team == LocalPlayer.Team

    data.Billboard.Enabled = Config.EspEnabled and withinRange and not (isTeam and not Config.EspShowTeam)
    if not data.Billboard.Enabled then return end

    local color = resolveColor(plr)
    data.Name.TextColor3 = color
    data.Dist.TextColor3 = color

    data.Name.Visible = Config.EspName
    data.Dist.Visible = Config.EspDistance
    data.Dist.Text = string.format("[%d studs]", math.floor(dist))
end

-- ============ ESP MASTER UPDATE ============
local function cleanupESP(plr)
    if espCache[plr] then
        for _, obj in pairs(espCache[plr]) do
            if __raw_type(obj) == "table" then
                destroyDrawingList(obj)
            else
                pcall(function() obj:Destroy() end)
            end
        end
        espCache[plr] = nil
    end
    if billboardCache[plr] then
        pcall(function() billboardCache[plr].Billboard:Destroy() end)
        billboardCache[plr] = nil
    end
end

local function renderESP()
    if not Config.EspEnabled then
        -- Sembunyikan semua
        for plr in pairs(espCache) do
            if HAS_DRAWING then
                local d = espCache[plr]
                for _, obj in pairs(d) do
                    if __raw_type(obj) == "table" then
                        for _, o in pairs(obj) do pcall(function() o.Visible = false end) end
                    else
                        pcall(function() obj.Visible = false end)
                    end
                end
            end
        end
        for plr, data in pairs(billboardCache) do
            if data.Billboard then data.Billboard.Enabled = false end
        end
        return
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if HAS_DRAWING then
                ensureDrawings(plr)
                updateDrawingESP(plr)
            else
                updateBillboardESP(plr)
            end
        end
    end
end

-- Handle player leave
Players.PlayerRemoving:Connect(function(plr)
    cleanupESP(plr)
end)

-- ==================== LOADING OVERLAY ====================
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

    local vp = Camera and Camera.ViewportSize or Vector2.new(800, 600)
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

-- ==================== MAIN GUI ====================
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
local FRAME_H = isSmall and math.clamp(vp.Y - 100, 380, 540) or 540

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
Subtitle.Size = UDim2.new(0, 170, 1, 0)
Subtitle.Position = UDim2.new(0, 106, 0, 0)
Subtitle.BackgroundTransparency = 1
Subtitle.Font = Enum.Font.Gotham
Subtitle.Text = "•  Aim Assist + ESP"
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

-- ==================== UI WIDGETS ====================
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
local order = 0
local function nextOrder() order = order + 1; return order end

-- CORE
makeSectionTitle(nextOrder(), "Core")
makeToggle(nextOrder(), "Aimbot Master", Config.Enabled, function(v)
    Config.Enabled = v
    saveConfig()
    notify(v and "✅ Aimbot ON" or "⛔ Aimbot OFF", v and "Aim assist aktif." or "Aim assist dinonaktifkan.", 2)
end)
makeToggle(nextOrder(), "Sticky Lock", Config.StickyLock, function(v) Config.StickyLock = v; saveConfig() end)
makeToggle(nextOrder(), "Wallcheck (Raycast)", Config.Wallcheck, function(v) Config.Wallcheck = v; saveConfig() end)
makeToggle(nextOrder(), "Team Check", Config.TeamCheck, function(v) Config.TeamCheck = v; saveConfig() end)
makeToggle(nextOrder(), "Auto-Switch on Kill", Config.AutoSwitch, function(v) Config.AutoSwitch = v; saveConfig() end)

makeDivider(nextOrder())

-- AIM BEHAVIOR
makeSectionTitle(nextOrder(), "Aim Behavior")
makeSlider(nextOrder(), "Smoothness", 0, 1, Config.Smoothness, true, function(v) Config.Smoothness = v; saveConfig() end)
makeSlider(nextOrder(), "Prediction", 0, 1, Config.Prediction, true, function(v) Config.Prediction = v; saveConfig() end)

makeDropdown(nextOrder(), "Aim Mode", { "Hold", "Toggle", "Always" },
    ({ Hold = 1, Toggle = 2, Always = 3 })[Config.AimMode] or 1,
    function(v) Config.AimMode = v; saveConfig() end
)

makeDropdown(nextOrder(), "Target Part", { "Head", "UpperTorso", "Torso", "Nearest" },
    ({ Head = 1, UpperTorso = 2, Torso = 3, Nearest = 4 })[Config.TargetPart] or 1,
    function(v) Config.TargetPart = v; saveConfig() end
)

makeDivider(nextOrder())

-- VISUALS
makeSectionTitle(nextOrder(), "Visuals")
makeSlider(nextOrder(), "FOV Radius", 40, 400, Config.FovRadius, false, function(v)
    Config.FovRadius = v
    FovCircle.Size = UDim2.fromOffset(v * 2, v * 2)
    saveConfig()
end)
makeToggle(nextOrder(), "Rainbow FOV", Config.RainbowFov, function(v) Config.RainbowFov = v; saveConfig() end)

makeDivider(nextOrder())

-- ESP
makeSectionTitle(nextOrder(), "ESP (Wallhack)")
makeToggle(nextOrder(), "ESP Master", Config.EspEnabled, function(v)
    Config.EspEnabled = v
    saveConfig()
    notify(v and "👁️ ESP ON" or "🚫 ESP OFF", v and "Wallhack visual aktif." or "Wallhack visual off.", 2)
end)
makeToggle(nextOrder(), "Box ESP", Config.EspBox, function(v) Config.EspBox = v; saveConfig() end)
makeToggle(nextOrder(), "Name ESP", Config.EspName, function(v) Config.EspName = v; saveConfig() end)
makeToggle(nextOrder(), "Health Bar", Config.EspHealth, function(v) Config.EspHealth = v; saveConfig() end)
makeToggle(nextOrder(), "Distance ESP", Config.EspDistance, function(v) Config.EspDistance = v; saveConfig() end)
makeToggle(nextOrder(), "Tracer Lines", Config.EspTracer, function(v) Config.EspTracer = v; saveConfig() end)
makeToggle(nextOrder(), "Skeleton ESP", Config.EspSkeleton, function(v) Config.EspSkeleton = v; saveConfig() end)
makeToggle(nextOrder(), "Head Dot", Config.EspHeadDot, function(v) Config.EspHeadDot = v; saveConfig() end)
makeToggle(nextOrder(), "ESP Team Check", Config.EspTeamCheck, function(v) Config.EspTeamCheck = v; saveConfig() end)
makeToggle(nextOrder(), "Show Teammates", Config.EspShowTeam, function(v) Config.EspShowTeam = v; saveConfig() end)

makeSlider(nextOrder(), "ESP Max Distance", 100, 5000, Config.EspMaxDistance, false, function(v)
    Config.EspMaxDistance = v
    saveConfig()
end)

makeDropdown(nextOrder(), "Tracer From", { "Bottom", "Center" },
    Config.EspTracerFrom == "Center" and 2 or 1,
    function(v) Config.EspTracerFrom = v; saveConfig() end
)

makeDivider(nextOrder())

-- ACTIONS
makeSectionTitle(nextOrder(), "Actions")
makeActionButton(nextOrder(), "🔄  Switch Target Now", Theme.Accent, function()
    if _G.__LiyHubSwitchTarget then _G.__LiyHubSwitchTarget() end
end)
makeActionButton(nextOrder(), "💾  Save Config", Theme.SurfaceSecondary, function()
    saveConfig()
    notify("💾 Config Saved", "Pengaturan berhasil disimpan.", 3)
end)
makeActionButton(nextOrder(), "♻️  Reset Config", Theme.Warning, function()
    pcall(function()
        if delfile and isfile(CONFIG_FILE) then delfile(CONFIG_FILE) end
    end)
    notify("♻️ Config Reset", "Restart script untuk memuat default.", 4)
end)

-- Status footer
local statusRow = makeRow(nextOrder(), 22)
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
local aimHeld = false
local aimToggled = false
local headVelocities = {}

local function isAiming()
    if Config.AimMode == "Always" then return true end
    if Config.AimMode == "Toggle" then return aimToggled end
    return aimHeld
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
    local travelTime = dist / 1000
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

    if Config.SilentAim then return end

    local alpha = 1 - math.pow(Config.Smoothness, 0.5)
    alpha = math.clamp(alpha, 0.05, 1)
    Camera.CFrame = Camera.CFrame:Lerp(goalCF, alpha)
end

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

LocalPlayer.CharacterAdded:Connect(function()
    currentTarget = nil
    stickyLocked = false
    headVelocities = {}
    if Config.Enabled then
        notify("♻️ Respawn", "Aimbot auto-resume setelah respawn.", 3)
    end
end)

-- ==================== MAIN LOOP ====================
RunService.RenderStepped:Connect(function()
    -- Aimbot
    if not Config.Enabled then
        currentTarget = nil
        stickyLocked = false
        StatusLbl.Text = "Status: Aimbot Disabled"
        StatusLbl.TextColor3 = Theme.TextSecondary
    elseif not isAiming() then
        StatusLbl.Text = "Status: Standby (hold aim key)"
        StatusLbl.TextColor3 = Theme.Warning
        currentTarget = nil
        stickyLocked = false
    else
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
    end

    -- ESP
    renderESP()
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

local function updateFov()
    FovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
    FovCircle.Size = UDim2.fromOffset(Config.FovRadius * 2, Config.FovRadius * 2)
end
updateFov()
if Camera then
    Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateFov)
end

-- ==================== PERSISTENCE ====================
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
            ]], "https://pastebin.com/raw/PLACEHOLDER")
            queueFn(reExec)
        end
    end)

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
        for plr in pairs(espCache) do cleanupESP(plr) end
        if espFolder then espFolder:Destroy() end
    end)
end

if getgenv then
    getgenv()._LIYHUB_AIMBOT_CLEANUP = cleanup
end

-- ==================== INIT ====================
task.spawn(function()
    local loader = createLoadingOverlay("Initializing Aim Assist + ESP")
    if loader then loader:Update(15) end

    task.wait(0.15)
    if loader then loader:Update(35) end

    task.wait(0.2)
    if loader then loader:Update(60) end

    if not Camera then
        for _ = 1, 20 do
            task.wait(0.1)
            if Workspace.CurrentCamera then Camera = Workspace.CurrentCamera; break end
        end
    end
    if loader then loader:Update(85) end

    pcall(setupPersistence)
    if loader then loader:Update(100) end

    task.wait(0.3)
    if loader then loader:Destroy() end

    ScreenGui.Parent = guiParent

    local execName = getExecutorName()
    local espMode = HAS_DRAWING and "Drawing API" or "BillboardGui (fallback)"
    notify("🎯 LiyHub Aimbot + ESP", string.format("Executor: %s • ESP Mode: %s", execName, espMode), 6)

    print("[LiyHub] Loaded on " .. execName .. " | ESP: " .. espMode)
end)

return true