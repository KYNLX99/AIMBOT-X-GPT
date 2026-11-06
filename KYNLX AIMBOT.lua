--// ADVANCED AIMBOT + ESP
--// LocalScript
--// StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = {
	Aimbot = true,
	FOV = 150,
	Smoothness = 0.35, -- Tighter lock for "nempel" effect
	StickyAim = true,
	WallCheck = true,
	TeamCheck = true,
	TargetPart = "Head", -- Strict head targeting
	ESPBox = true,
	ESPLine = true,
}

local CurrentTarget = nil
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local ESP_Instances = {}

--==================================================
-- ESP MANAGEMENT
--==================================================
local function CreateESP(player)
	if ESP_Instances[player] then return end
	
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ESP_Box"
	billboard.Size = UDim2.new(2.2, 0, 3.5, 0)
	billboard.StudsOffset = Vector3.new(0, 1, 0)
	billboard.AlwaysOnTop = true
	billboard.ResetOnSpawn = false
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.Parent = billboard
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 60, 60)
	stroke.Thickness = 2
	stroke.Parent = frame
	
	ESP_Instances[player] = { Billboard = billboard, Stroke = stroke }
end

local function RemoveESP(player)
	if ESP_Instances[player] then
		ESP_Instances[player].Billboard:Destroy()
		ESP_Instances[player] = nil
	end
end

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)
for _, player in ipairs(Players:GetPlayers()) do
	CreateESP(player)
end

--==================================================
-- GUI SETUP
--==================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AdvancedAimESP"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(280, 420)
Main.Position = UDim2.new(0, 25, 0.5, -210)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -90, 1, 0)
Title.Position = UDim2.fromOffset(15, 0)
Title.BackgroundTransparency = 1
Title.Text = "HEAD-LOCK + ESP"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(35, 30)
Minimize.Position = UDim2.new(1, -42, 0, 7)
Minimize.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
Minimize.Text = "-"
Minimize.TextColor3 = Color3.new(1, 1, 1)
Minimize.TextSize = 20
Minimize.Font = Enum.Font.GothamBold
Instance.new("UICorner", Minimize).CornerRadius = UDim.new(0, 6)
Minimize.Parent = TitleBar

-- Drag Logic
local dragging, dragInput, dragStart, startPosition = false, nil, nil, nil
local function UpdateDrag(input)
	local delta = input.Position - dragStart
	Main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
end

TitleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPosition = Main.Position
		input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
	end
end)
TitleBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then UpdateDrag(input) end
end)

-- Content
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -45)
Content.Position = UDim2.fromOffset(0, 45)
Content.BackgroundTransparency = 1
Content.Parent = Main
local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 8)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Content

local function CreateToggle(text, defaultValue, callback)
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, -30, 0, 38)
	Button.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	Button.TextColor3 = Color3.new(1, 1, 1)
	Button.TextSize = 13
	Button.Font = Enum.Font.GothamMedium
	Button.AutoButtonColor = false
	Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 6)
	Button.Parent = Content

	local enabled = defaultValue
	local function Update()
		Button.Text = text .. ": " .. (enabled and "ON" or "OFF")
		Button.BackgroundColor3 = enabled and Color3.fromRGB(40, 120, 70) or Color3.fromRGB(40, 40, 50)
		callback(enabled)
	end
	Button.MouseButton1Click:Connect(function() enabled = not enabled; Update() end)
	Update()
	return Button
end

CreateToggle("Aimbot", true, function(v) Settings.Aimbot = v; if not v then CurrentTarget = nil end end)
CreateToggle("Sticky Lock", true, function(v) Settings.StickyAim = v end)
CreateToggle("Wallcheck", true, function(v) Settings.WallCheck = v end)
CreateToggle("Team Check", true, function(v) Settings.TeamCheck = v end)
CreateToggle("ESP Box", true, function(v) Settings.ESPBox = v end)
CreateToggle("ESP Line", true, function(v) Settings.ESPLine = v end)

-- FOV Slider
local FOVLabel = Instance.new("TextLabel")
FOVLabel.Size = UDim2.new(1, -30, 0, 28)
FOVLabel.BackgroundTransparency = 1
FOVLabel.TextColor3 = Color3.new(1, 1, 1)
FOVLabel.TextSize = 13
FOVLabel.Font = Enum.Font.GothamMedium
FOVLabel.Text = "FOV: " .. Settings.FOV
FOVLabel.Parent = Content

local FOVSlider = Instance.new("TextButton")
FOVSlider.Size = UDim2.new(1, -30, 0, 22)
FOVSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
FOVSlider.Text = ""
FOVSlider.AutoButtonColor = false
Instance.new("UICorner", FOVSlider).CornerRadius = UDim.new(0, 6)
FOVSlider.Parent = Content

local FOVFill = Instance.new("Frame")
FOVFill.Size = UDim2.new((Settings.FOV - 50) / 350, 0, 1, 0)
FOVFill.BackgroundColor3 = Color3.fromRGB(70, 140, 255)
FOVFill.BorderSizePixel = 0
Instance.new("UICorner", FOVFill).CornerRadius = UDim.new(0, 6)
FOVFill.Parent = FOVSlider

local function SetupSlider(slider, fill, label, prefix, minVal, maxVal, isFloat)
	local sliderDragging = false
	local function update(input)
		local relative = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
		local val = minVal + relative * (maxVal - minVal)
		if isFloat then
			val = math.max(0.05, math.floor(val * 100) / 100)
			Settings[prefix] = val
			label.Text = prefix .. ": " .. string.format("%.2f", val)
		else
			val = math.floor(val)
			Settings[prefix] = val
			label.Text = prefix .. ": " .. val
		end
		fill.Size = UDim2.new(relative, 0, 1, 0)
	end
	slider.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then sliderDragging = true; update(input) end end)
	slider.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement and sliderDragging then update(input) end end)
	UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then sliderDragging = false end end)
end

SetupSlider(FOVSlider, FOVFill, FOVLabel, "FOV", 50, 400, false)

-- Smoothness Slider
local SmoothLabel = Instance.new("TextLabel")
SmoothLabel.Size = UDim2.new(1, -30, 0, 28)
SmoothLabel.BackgroundTransparency = 1
SmoothLabel.TextColor3 = Color3.new(1, 1, 1)
SmoothLabel.TextSize = 13
SmoothLabel.Font = Enum.Font.GothamMedium
SmoothLabel.Text = "Smoothness: " .. string.format("%.2f", Settings.Smoothness)
SmoothLabel.Parent = Content

local SmoothSlider = Instance.new("TextButton")
SmoothSlider.Size = UDim2.new(1, -30, 0, 22)
SmoothSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
SmoothSlider.Text = ""
SmoothSlider.AutoButtonColor = false
Instance.new("UICorner", SmoothSlider).CornerRadius = UDim.new(0, 6)
SmoothSlider.Parent = Content

local SmoothFill = Instance.new("Frame")
SmoothFill.Size = UDim2.new((Settings.Smoothness - 0.05) / 0.95, 0, 1, 0)
SmoothFill.BackgroundColor3 = Color3.fromRGB(70, 140, 255)
SmoothFill.BorderSizePixel = 0
Instance.new("UICorner", SmoothFill).CornerRadius = UDim.new(0, 6)
SmoothFill.Parent = SmoothSlider

SetupSlider(SmoothSlider, SmoothFill, SmoothLabel, "Smoothness", 0.05, 1.0, true)

-- Switch Target Button
local SwitchButton = Instance.new("TextButton")
SwitchButton.Size = UDim2.new(1, -30, 0, 38)
SwitchButton.BackgroundColor3 = Color3.fromRGB(50, 90, 150)
SwitchButton.Text = "FORCE SWITCH TARGET"
SwitchButton.TextColor3 = Color3.new(1, 1, 1)
SwitchButton.TextSize = 13
SwitchButton.Font = Enum.Font.GothamBold
Instance.new("UICorner", SwitchButton).CornerRadius = UDim.new(0, 6)
SwitchButton.Parent = Content
SwitchButton.MouseButton1Click:Connect(function() CurrentTarget = nil end)

-- FOV Circle Visual
local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.ZIndex = 1
Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1, 0)
local circleStroke = Instance.new("UIStroke", FOVCircle)
circleStroke.Thickness = 2
circleStroke.Color = Color3.fromRGB(255, 255, 255)
circleStroke.Transparency = 0.15
FOVCircle.Parent = ScreenGui

-- ESP Line Visual
local LineFrame = Instance.new("Frame")
LineFrame.Name = "ESP_Line"
LineFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
LineFrame.BorderSizePixel = 0
LineFrame.AnchorPoint = Vector2.new(0.5, 0)
LineFrame.Visible = false
LineFrame.Parent = ScreenGui

--==================================================
-- CORE LOGIC
--==================================================
local function GetCharacter(player)
	if not player then return nil end
	local char = player.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or hum.Health <= 0 or not root then return nil end
	return char
end

local function IsEnemy(player)
	if player == LocalPlayer then return false end
	if Settings.TeamCheck and LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then return false end
	return true
end

local function CanSeeTarget(character)
	if not Settings.WallCheck then return true end
	local targetPart = character:FindFirstChild(Settings.TargetPart) or character:FindFirstChild("HumanoidRootPart")
	if not targetPart then return false end

	raycastParams.FilterDescendantsInstances = LocalPlayer.Character and {LocalPlayer.Character} or {}
	local origin = Camera.CFrame.Position
	local direction = targetPart.Position - origin
	local result = workspace:Raycast(origin, direction, raycastParams)
	
	if not result then return true end
	return result.Instance:IsDescendantOf(character)
end

local function IsValidTarget(player)
	if not IsEnemy(player) then return false, nil end
	local character = GetCharacter(player)
	if not character then return false, nil end
	if not CanSeeTarget(character) then return false, nil end
	
	local targetPart = character:FindFirstChild(Settings.TargetPart) or character:FindFirstChild("HumanoidRootPart")
	if not targetPart then return false, nil end
	return true, targetPart
end

local function FindClosestTarget()
	local viewportSize = Camera.ViewportSize
	local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
	local bestPlayer, bestDistance = nil, math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		local valid, targetPart = IsValidTarget(player)
		if valid and targetPart then
			local screenPosition, visible = Camera:WorldToViewportPoint(targetPart.Position)
			if visible and screenPosition.Z > 0 then
				local targetVec = Vector2.new(screenPosition.X, screenPosition.Y)
				local distance = (targetVec - screenCenter).Magnitude
				if distance <= Settings.FOV and distance < bestDistance then
					bestDistance = distance
					bestPlayer = player
				end
			end
		end
	end
	return bestPlayer
end

local function AimAtTarget(player)
	local valid, targetPart = IsValidTarget(player)
	if not valid or not targetPart then return false end

	local cameraPosition = Camera.CFrame.Position
	local targetCFrame = CFrame.lookAt(cameraPosition, targetPart.Position)
	local smooth = math.clamp(Settings.Smoothness, 0.05, 1.0)
	
	-- Tight lerp for "nempel" (sticky head-lock) feel
	Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, smooth)
	return true
end

--==================================================
-- RENDER LOOP
--==================================================
RunService.RenderStepped:Connect(function()
	local viewportSize = Camera.ViewportSize
	local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)

	-- Update FOV Circle
	FOVCircle.Position = UDim2.fromOffset(screenCenter.X, screenCenter.Y)
	FOVCircle.Size = UDim2.fromOffset(Settings.FOV * 2, Settings.FOV * 2)

	-- Update ESP Box
	for player, esp in pairs(ESP_Instances) do
		local char = GetCharacter(player)
		if char and Settings.ESPBox then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp and esp.Billboard.Parent ~= hrp then
				esp.Billboard.Parent = hrp
			end
			-- Visual feedback: Yellow when locked, Red otherwise
			if CurrentTarget == player then
				esp.Stroke.Color = Color3.fromRGB(255, 220, 50)
				esp.Stroke.Thickness = 3
			else
				esp.Stroke.Color = Color3.fromRGB(255, 60, 60)
				esp.Stroke.Thickness = 2
			end
		elseif esp.Billboard.Parent ~= nil then
			esp.Billboard.Parent = nil
		end
	end

	-- Update ESP Line
	if Settings.ESPLine and CurrentTarget then
		local char = GetCharacter(CurrentTarget)
		if char then
			local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
			if head then
				local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
				if onScreen and pos.Z > 0 then
					local targetVec = Vector2.new(pos.X, pos.Y)
					local dist = (targetVec - screenCenter).Magnitude
					local angle = math.deg(math.atan2(targetVec.Y - screenCenter.Y, targetVec.X - screenCenter.X))
					
					LineFrame.Position = UDim2.fromOffset(screenCenter.X, screenCenter.Y)
					LineFrame.Size = UDim2.fromOffset(2, dist)
					LineFrame.Rotation = angle
					LineFrame.Visible = true
				else
					LineFrame.Visible = false
				end
			else
				LineFrame.Visible = false
			end
		else
			LineFrame.Visible = false
		end
	else
		LineFrame.Visible = false
	end

	-- Aimbot Logic
	if not Settings.Aimbot then
		CurrentTarget = nil
		return
	end

	if Settings.StickyAim and CurrentTarget then
		local char = GetCharacter(CurrentTarget)
		if char then
			local targetPart = char:FindFirstChild(Settings.TargetPart) or char:FindFirstChild("HumanoidRootPart")
			if targetPart then
				local screenPosition, visible = Camera:WorldToViewportPoint(targetPart.Position)
				local targetVec = Vector2.new(screenPosition.X, screenPosition.Y)
				local distance = (targetVec - screenCenter).Magnitude
				local allowedDistance = Settings.FOV * 1.3

				if not visible or screenPosition.Z <= 0 or distance > allowedDistance or not CanSeeTarget(char) then
					CurrentTarget = nil
				end
			else
				CurrentTarget = nil
			end
		else
			CurrentTarget = nil
		end
	end

	if not CurrentTarget then
		CurrentTarget = FindClosestTarget()
	end

	if CurrentTarget then
		if not AimAtTarget(CurrentTarget) then
			CurrentTarget = nil
		end
	end
end)

--==================================================
-- UI MINIMIZE / REOPEN
--==================================================
local minimized = false
Minimize.MouseButton1Click:Connect(function()
	minimized = not minimized
	Content.Visible = not minimized
	Main.Size = minimized and UDim2.fromOffset(280, 45) or UDim2.fromOffset(280, 420)
	Minimize.Text = minimized and "+" or "-"
end)

local ReopenButton = Instance.new("TextButton")
ReopenButton.Size = UDim2.fromOffset(110, 38)
ReopenButton.Position = UDim2.new(0, 20, 0, 20)
ReopenButton.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
ReopenButton.Text = "OPEN MENU"
ReopenButton.TextColor3 = Color3.new(1, 1, 1)
ReopenButton.TextSize = 13
ReopenButton.Font = Enum.Font.GothamBold
ReopenButton.Visible = false
Instance.new("UICorner", ReopenButton).CornerRadius = UDim.new(0, 6)
ReopenButton.Parent = ScreenGui

ReopenButton.MouseButton1Click:Connect(function()
	Main.Visible = true
	ReopenButton.Visible = false
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Insert then
		Main.Visible = not Main.Visible
		ReopenButton.Visible = not Main.Visible
	end
end)

print("Head-lock Aimbot + ESP stashed.")
