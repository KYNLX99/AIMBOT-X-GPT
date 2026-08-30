--[=[
    Aimbot Script for Roblox FPS
    Fitur:
    - Toggle On/Off
    - FOV Detection (lingkaran)
    - Smoothness slider
    - Lock (Sticky Aim)
    - Wallcheck (raycast)
    - Switch Target (otomatis & manual)
    - Close/Reopen UI
]=]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ===== UI Setup =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimbotGUI"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 300)
mainFrame.Position = UDim2.new(0.5, -110, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 25)
titleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -30, 1, 0)
titleLabel.Position = UDim2.new(0, 5, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Aimbot v1.0"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = titleBar

-- Close/Reopen Button (Minimize)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -25, 0, 2.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar

local isUIVisible = true
closeBtn.MouseButton1Click:Connect(function()
    isUIVisible = not isUIVisible
    mainFrame.Visible = isUIVisible
end)

-- Toggle Aimbot On/Off
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 180, 0, 30)
toggleBtn.Position = UDim2.new(0.5, -90, 0, 40)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
toggleBtn.Text = "Aimbot: ON"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 14
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = mainFrame

local aimbotEnabled = true
toggleBtn.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    toggleBtn.Text = aimbotEnabled and "Aimbot: ON" or "Aimbot: OFF"
    toggleBtn.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 0, 0)
end)

-- FOV Circle (tampilan di layar)
local fovCircle = Instance.new("Frame")
fovCircle.Size = UDim2.new(0, 150, 0, 150)
fovCircle.Position = UDim2.new(0.5, -75, 0.5, -75)
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel = 2
fovCircle.BorderColor3 = Color3.fromRGB(0, 255, 0)
fovCircle.Visible = true
fovCircle.ZIndex = 10
fovCircle.Parent = screenGui
-- Membuat bulat
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = fovCircle

-- Slider Smoothness
local smoothSlider = Instance.new("Frame")
smoothSlider.Size = UDim2.new(0, 180, 0, 25)
smoothSlider.Position = UDim2.new(0.5, -90, 0, 85)
smoothSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
smoothSlider.BorderSizePixel = 0
smoothSlider.Parent = mainFrame

local smoothLabel = Instance.new("TextLabel")
smoothLabel.Size = UDim2.new(0, 60, 1, 0)
smoothLabel.Position = UDim2.new(0, 5, 0, 0)
smoothLabel.BackgroundTransparency = 1
smoothLabel.Text = "Smooth:"
smoothLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
smoothLabel.TextSize = 12
smoothLabel.TextXAlignment = Enum.TextXAlignment.Left
smoothLabel.Font = Enum.Font.SourceSans
smoothLabel.Parent = smoothSlider

local smoothValue = Instance.new("TextLabel")
smoothValue.Size = UDim2.new(0, 30, 1, 0)
smoothValue.Position = UDim2.new(1, -35, 0, 0)
smoothValue.BackgroundTransparency = 1
smoothValue.Text = "0.5"
smoothValue.TextColor3 = Color3.fromRGB(255, 255, 255)
smoothValue.TextSize = 12
smoothValue.Font = Enum.Font.SourceSans
smoothValue.Parent = smoothSlider

-- Slider track (menggunakan TextButton sebagai handle)
local sliderTrack = Instance.new("TextButton")
sliderTrack.Size = UDim2.new(0, 70, 0, 6)
sliderTrack.Position = UDim2.new(0, 65, 0.5, -3)
sliderTrack.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
sliderTrack.BorderSizePixel = 0
sliderTrack.AutoButtonColor = false
sliderTrack.Parent = smoothSlider

local sliderHandle = Instance.new("TextButton")
sliderHandle.Size = UDim2.new(0, 12, 0, 12)
sliderHandle.Position = UDim2.new(0, 0, 0.5, -6)
sliderHandle.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
sliderHandle.BorderSizePixel = 0
sliderHandle.AutoButtonColor = false
sliderHandle.Parent = sliderTrack

local smoothness = 0.5 -- default

local function updateSlider(inputX)
    local trackSize = sliderTrack.AbsoluteSize.X
    local handlePos = math.clamp(inputX - sliderTrack.AbsolutePosition.X, 0, trackSize)
    sliderHandle.Position = UDim2.new(0, handlePos, 0.5, -6)
    smoothness = handlePos / trackSize
    smoothValue.Text = string.format("%.2f", smoothness)
end

sliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        updateSlider(input.Position.X)
    end
end)
sliderTrack.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        updateSlider(input.Position.X)
    end
end)

-- Wallcheck Toggle
local wallcheckBtn = Instance.new("TextButton")
wallcheckBtn.Size = UDim2.new(0, 180, 0, 25)
wallcheckBtn.Position = UDim2.new(0.5, -90, 0, 125)
wallcheckBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
wallcheckBtn.Text = "Wallcheck: ON"
wallcheckBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
wallcheckBtn.TextSize = 13
wallcheckBtn.Font = Enum.Font.SourceSansBold
wallcheckBtn.BorderSizePixel = 0
wallcheckBtn.Parent = mainFrame

local wallcheckEnabled = true
wallcheckBtn.MouseButton1Click:Connect(function()
    wallcheckEnabled = not wallcheckEnabled
    wallcheckBtn.Text = wallcheckEnabled and "Wallcheck: ON" or "Wallcheck: OFF"
    wallcheckBtn.BackgroundColor3 = wallcheckEnabled and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 0, 0)
end)

-- Switch Target Button (manual)
local switchBtn = Instance.new("TextButton")
switchBtn.Size = UDim2.new(0, 80, 0, 25)
switchBtn.Position = UDim2.new(0.5, -90, 0, 165)
switchBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 200)
switchBtn.Text = "Switch"
switchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
switchBtn.TextSize = 13
switchBtn.Font = Enum.Font.SourceSansBold
switchBtn.BorderSizePixel = 0
switchBtn.Parent = mainFrame

-- ===== Aimbot Variables =====
local currentTarget = nil
local stickyLock = false  -- true jika sedang menempel
local fovRadius = 75 -- setengah dari ukuran FOV circle (dalam pixel)

-- Fungsi untuk mendapatkan musuh terdekat dalam FOV
local function getNearestTarget()
    local players = Players:GetPlayers()
    local bestTarget = nil
    local bestDistance = math.huge
    local cameraPos = Camera.CFrame.Position
    local cameraLook = Camera.CFrame.LookVector

    for _, p in ipairs(players) do
        if p ~= player and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local head = p.Character:FindFirstChild("Head")
            if head then
                local headPos = head.Position
                -- Cek apakah headPos berada dalam FOV (proyeksi ke layar)
                local screenPos, onScreen = Camera:WorldToViewportPoint(headPos)
                if onScreen then
                    local viewportSize = Camera.ViewportSize
                    local centerX = viewportSize.X / 2
                    local centerY = viewportSize.Y / 2
                    local dx = screenPos.X - centerX
                    local dy = screenPos.Y - centerY
                    local dist = math.sqrt(dx*dx + dy*dy)
                    if dist <= fovRadius then
                        -- Hitung jarak Euclidean 3D
                        local dist3D = (headPos - cameraPos).Magnitude
                        if dist3D < bestDistance then
                            -- Wallcheck (jika aktif)
                            if wallcheckEnabled then
                                local rayParams = RaycastParams.new()
                                rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                                rayParams.FilterDescendantsInstances = {player.Character, p.Character}
                                local rayResult = Workspace:Raycast(cameraPos, (headPos - cameraPos).Unit * dist3D, rayParams)
                                if rayResult then
                                    -- ada halangan
                                    continue
                                end
                            end
                            bestTarget = p
                            bestDistance = dist3D
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

-- Fungsi untuk menggerakkan kamera secara smooth menuju target
local function aimAtTarget(target, deltaTime)
    if not target or not target.Character then return end
    local head = target.Character:FindFirstChild("Head")
    if not head then return end

    local targetPos = head.Position
    local cameraPos = Camera.CFrame.Position
    local lookAt = CFrame.lookAt(cameraPos, targetPos)
    local currentCF = Camera.CFrame

    -- Interpolasi (smoothness)
    local lerpFactor = 1 - math.pow(smoothness, 2)  -- smoothness 0 -> 1, 1 -> 0
    if lerpFactor < 0.01 then lerpFactor = 0.01 end
    local newCF = currentCF:Lerp(lookAt, lerpFactor * 0.5) -- dikali 0.5 agar lebih halus
    Camera.CFrame = newCF
end

-- Fungsi untuk mengecek apakah target masih valid (hidup, dalam FOV, tidak terhalang)
local function isTargetValid(target)
    if not target or not target.Character then return false end
    local head = target.Character:FindFirstChild("Head")
    if not head then return false end
    local humanoid = target.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end

    local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
    if not onScreen then return false end
    local viewportSize = Camera.ViewportSize
    local centerX = viewportSize.X / 2
    local centerY = viewportSize.Y / 2
    local dx = screenPos.X - centerX
    local dy = screenPos.Y - centerY
    if math.sqrt(dx*dx + dy*dy) > fovRadius then return false end

    -- Wallcheck
    if wallcheckEnabled then
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        rayParams.FilterDescendantsInstances = {player.Character, target.Character}
        local rayResult = Workspace:Raycast(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).Unit * 500, rayParams)
        if rayResult then
            return false
        end
    end
    return true
end

-- ===== Main Loop =====
local lastTime = tick()
RunService.RenderStepped:Connect(function(deltaTime)
    if not aimbotEnabled then
        currentTarget = nil
        stickyLock = false
        return
    end

    -- Jika stickyLock aktif, pastikan target masih valid
    if stickyLock and currentTarget then
        if not isTargetValid(currentTarget) then
            stickyLock = false
            currentTarget = nil
        end
    end

    -- Jika tidak ada target atau stickyLock mati, cari target baru
    if not currentTarget or not stickyLock then
        local newTarget = getNearestTarget()
        if newTarget then
            currentTarget = newTarget
            stickyLock = true
        else
            currentTarget = nil
            stickyLock = false
        end
    end

    -- Lakukan aiming
    if currentTarget and stickyLock then
        aimAtTarget(currentTarget, deltaTime)
    end
end)

-- Tombol switch manual: paksa pindah target
switchBtn.MouseButton1Click:Connect(function()
    if not aimbotEnabled then return end
    local newTarget = getNearestTarget()
    if newTarget and newTarget ~= currentTarget then
        currentTarget = newTarget
        stickyLock = true
    end
end)

-- Update FOV Circle position setiap kali layar berubah
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    local size = Camera.ViewportSize
    fovCircle.Size = UDim2.new(0, fovRadius*2, 0, fovRadius*2)
    fovCircle.Position = UDim2.new(0.5, -fovRadius, 0.5, -fovRadius)
end)
-- Inisialisasi ukuran FOV
task.wait(0.1)
local size = Camera.ViewportSize
fovCircle.Size = UDim2.new(0, fovRadius*2, 0, fovRadius*2)
fovCircle.Position = UDim2.new(0.5, -fovRadius, 0.5, -fovRadius)

-- Sembunyikan kursor saat berada di atas UI agar tidak mengganggu
mainFrame.MouseEnter:Connect(function()
    mouse.Icon = ""
end)
mainFrame.MouseLeave:Connect(function()
    mouse.Icon = "rbxasset://SystemCursors/Arrow"
end)