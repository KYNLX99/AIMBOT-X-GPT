--// FPS AIM ASSIST - ROBLOX STUDIO TEST
--// LocalScript
--// StarterPlayer > StarterPlayerScripts

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- SETTINGS
--==================================================

local Settings = {
	Aimbot = false,
	FOV = 180,
	Smoothness = 0.15,
	StickyAim = true,
	WallCheck = true,
	TeamCheck = true,
	TargetPart = "Head",
}

local CurrentTarget = nil

--==================================================
-- GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FPSAimAssist"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--==================================================
-- MAIN FRAME
--==================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(280, 390)
Main.Position = UDim2.new(0, 25, 0.5, -195)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main

--==================================================
-- TITLE BAR
--==================================================

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -90, 1, 0)
Title.Position = UDim2.fromOffset(15, 0)
Title.BackgroundTransparency = 1
Title.Text = "FPS AIM ASSIST"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

--==================================================
-- MINIMIZE BUTTON
--==================================================

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(35, 30)
Minimize.Position = UDim2.new(1, -42, 0, 7)
Minimize.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
Minimize.Text = "-"
Minimize.TextColor3 = Color3.new(1, 1, 1)
Minimize.TextSize = 20
Minimize.Font = Enum.Font.GothamBold
Minimize.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 7)
MinCorner.Parent = Minimize

--==================================================
-- DRAGGABLE GUI
--==================================================

local dragging = false
local dragInput
local dragStart
local startPosition

local function UpdateDrag(input)

	local delta = input.Position - dragStart

	Main.Position = UDim2.new(
		startPosition.X.Scale,
		startPosition.X.Offset + delta.X,

		startPosition.Y.Scale,
		startPosition.Y.Offset + delta.Y
	)

end

TitleBar.InputBegan:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		startPosition = Main.Position

		input.Changed:Connect(function()

			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end

		end)

	end

end)

TitleBar.InputChanged:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then

		dragInput = input

	end

end)

UserInputService.InputChanged:Connect(function(input)

	if input == dragInput and dragging then
		UpdateDrag(input)
	end

end)

--==================================================
-- CONTENT
--==================================================

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -45)
Content.Position = UDim2.fromOffset(0, 45)
Content.BackgroundTransparency = 1
Content.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 10)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Content

--==================================================
-- CREATE TOGGLE
--==================================================

local function CreateToggle(text, defaultValue, callback)

	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, -30, 0, 42)
	Button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
	Button.TextColor3 = Color3.new(1, 1, 1)
	Button.TextSize = 14
	Button.Font = Enum.Font.GothamMedium
	Button.AutoButtonColor = false
	Button.Parent = Content

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = Button

	local enabled = defaultValue

	local function Update()

		if enabled then

			Button.Text = text .. ": ON"
			Button.BackgroundColor3 =
				Color3.fromRGB(45, 130, 80)

		else

			Button.Text = text .. ": OFF"
			Button.BackgroundColor3 =
				Color3.fromRGB(45, 45, 55)

		end

		callback(enabled)

	end

	Button.MouseButton1Click:Connect(function()

		enabled = not enabled

		Update()

	end)

	Update()

	return Button

end

--==================================================
-- TOGGLES
--==================================================

CreateToggle("Aimbot", false, function(value)

	Settings.Aimbot = value

	if not value then
		CurrentTarget = nil
	end

end)

CreateToggle("Sticky Lock", true, function(value)

	Settings.StickyAim = value

end)

CreateToggle("Wallcheck", true, function(value)

	Settings.WallCheck = value

end)

CreateToggle("Team Check", true, function(value)

	Settings.TeamCheck = value

end)

--==================================================
-- FOV LABEL
--==================================================

local FOVLabel = Instance.new("TextLabel")
FOVLabel.Size = UDim2.new(1, -30, 0, 30)
FOVLabel.BackgroundTransparency = 1
FOVLabel.TextColor3 = Color3.new(1, 1, 1)
FOVLabel.TextSize = 14
FOVLabel.Font = Enum.Font.GothamMedium
FOVLabel.Text = "FOV: " .. Settings.FOV
FOVLabel.Parent = Content

--==================================================
-- FOV SLIDER
--==================================================

local FOVSlider = Instance.new("TextButton")
FOVSlider.Size = UDim2.new(1, -30, 0, 25)
FOVSlider.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
FOVSlider.Text = ""
FOVSlider.AutoButtonColor = false
FOVSlider.Parent = Content

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(0, 8)
FOVCorner.Parent = FOVSlider

local FOVFill = Instance.new("Frame")
FOVFill.Size = UDim2.new(0.5, 0, 1, 0)
FOVFill.BackgroundColor3 = Color3.fromRGB(70, 140, 255)
FOVFill.BorderSizePixel = 0
FOVFill.Parent = FOVSlider

local FillCorner = Instance.new("UICorner")
FillCorner.CornerRadius = UDim.new(0, 8)
FillCorner.Parent = FOVFill

local function SetFOVFromX(x)

	local relative = math.clamp(
		(x - FOVSlider.AbsolutePosition.X)
			/ FOVSlider.AbsoluteSize.X,
		0,
		1
	)

	Settings.FOV =
		math.floor(50 + relative * 350)

	FOVLabel.Text =
		"FOV: " .. Settings.FOV

	FOVFill.Size =
		UDim2.new(relative, 0, 1, 0)

end

FOVSlider.MouseButton1Down:Connect(function()

	SetFOVFromX(
		UserInputService:GetMouseLocation().X
	)

end)

--==================================================
-- SMOOTHNESS
--==================================================

local SmoothLabel = Instance.new("TextLabel")
SmoothLabel.Size = UDim2.new(1, -30, 0, 30)
SmoothLabel.BackgroundTransparency = 1
SmoothLabel.TextColor3 = Color3.new(1, 1, 1)
SmoothLabel.TextSize = 14
SmoothLabel.Font = Enum.Font.GothamMedium
SmoothLabel.Text =
	"Smoothness: " .. Settings.Smoothness
SmoothLabel.Parent = Content

local SmoothSlider = Instance.new("TextButton")
SmoothSlider.Size = UDim2.new(1, -30, 0, 25)
SmoothSlider.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
SmoothSlider.Text = ""
SmoothSlider.AutoButtonColor = false
SmoothSlider.Parent = Content

local SmoothCorner = Instance.new("UICorner")
SmoothCorner.CornerRadius = UDim.new(0, 8)
SmoothCorner.Parent = SmoothSlider

local SmoothFill = Instance.new("Frame")
SmoothFill.Size =
	UDim2.new(Settings.Smoothness, 0, 1, 0)
SmoothFill.BackgroundColor3 =
	Color3.fromRGB(70, 140, 255)
SmoothFill.BorderSizePixel = 0
SmoothFill.Parent = SmoothSlider

local SmoothFillCorner = Instance.new("UICorner")
SmoothFillCorner.CornerRadius = UDim.new(0, 8)
SmoothFillCorner.Parent = SmoothFill

local function SetSmoothFromX(x)

	local relative = math.clamp(
		(x - SmoothSlider.AbsolutePosition.X)
			/ SmoothSlider.AbsoluteSize.X,
		0,
		1
	)

	Settings.Smoothness =
		math.max(
			0.03,
			math.floor(relative * 100) / 100
		)

	SmoothLabel.Text =
		"Smoothness: " ..
		string.format("%.2f", Settings.Smoothness)

	SmoothFill.Size =
		UDim2.new(relative, 0, 1, 0)

end

SmoothSlider.MouseButton1Down:Connect(function()

	SetSmoothFromX(
		UserInputService:GetMouseLocation().X
	)

end)

--==================================================
-- SWITCH TARGET
--==================================================

local SwitchButton = Instance.new("TextButton")
SwitchButton.Size = UDim2.new(1, -30, 0, 42)
SwitchButton.BackgroundColor3 =
	Color3.fromRGB(50, 90, 150)
SwitchButton.Text = "SWITCH TARGET"
SwitchButton.TextColor3 = Color3.new(1, 1, 1)
SwitchButton.TextSize = 14
SwitchButton.Font = Enum.Font.GothamBold
SwitchButton.Parent = Content

local SwitchCorner = Instance.new("UICorner")
SwitchCorner.CornerRadius = UDim.new(0, 8)
SwitchCorner.Parent = SwitchButton

SwitchButton.MouseButton1Click:Connect(function()

	CurrentTarget = nil

end)

--==================================================
-- FOV CIRCLE
--==================================================

local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.ZIndex = 0
FOVCircle.Parent = ScreenGui

local FOVCorner2 = Instance.new("UICorner")
FOVCorner2.CornerRadius = UDim.new(1, 0)
FOVCorner2.Parent = FOVCircle

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 2
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Transparency = 0.1
FOVStroke.Parent = FOVCircle

--==================================================
-- CHARACTER CHECK
--==================================================

local function GetCharacter(player)

	if not player then
		return nil
	end

	local character = player.Character

	if not character then
		return nil
	end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	local root =
		character:FindFirstChild("HumanoidRootPart")

	if not humanoid or humanoid.Health <= 0 then
		return nil
	end

	if not root then
		return nil
	end

	return character

end

--==================================================
-- TEAM CHECK
--==================================================

local function IsEnemy(player)

	if player == LocalPlayer then
		return false
	end

	if Settings.TeamCheck then

		if LocalPlayer.Team ~= nil
			and player.Team ~= nil
			and LocalPlayer.Team == player.Team then

			return false

		end

	end

	return true

end

--==================================================
-- WALLCHECK
--==================================================

local function CanSeeTarget(character)

	if not Settings.WallCheck then
		return true
	end

	local targetPart =
		character:FindFirstChild(
			Settings.TargetPart
		)
		or character:FindFirstChild(
			"HumanoidRootPart"
		)

	if not targetPart then
		return false
	end

	local origin =
		Camera.CFrame.Position

	local direction =
		targetPart.Position - origin

	local params =
		RaycastParams.new()

	params.FilterType =
		Enum.RaycastFilterType.Exclude

	params.FilterDescendantsInstances = {
		LocalPlayer.Character
	}

	local result =
		workspace:Raycast(
			origin,
			direction,
			params
		)

	if not result then
		return true
	end

	return result.Instance:IsDescendantOf(
		character
	)

end

--==================================================
-- TARGET VALIDATION
--==================================================

local function IsValidTarget(player)

	if not IsEnemy(player) then
		return false
	end

	local character =
		GetCharacter(player)

	if not character then
		return false
	end

	if not CanSeeTarget(character) then
		return false
	end

	local targetPart =
		character:FindFirstChild(
			Settings.TargetPart
		)

	if not targetPart then

		targetPart =
			character:FindFirstChild(
				"HumanoidRootPart"
			)

	end

	if not targetPart then
		return false
	end

	return true, targetPart

end

--==================================================
-- FIND CLOSEST TARGET
--==================================================

local function FindClosestTarget()

	-- Titik tengah layar = pusat FOV/crosshair

	local viewportSize =
		Camera.ViewportSize

	local screenCenter =
		Vector2.new(
			viewportSize.X / 2,
			viewportSize.Y / 2
		)

	local bestPlayer = nil
	local bestDistance = math.huge

	for _, player in ipairs(
		Players:GetPlayers()
	) do

		local valid, targetPart =
			IsValidTarget(player)

		if valid and targetPart then

			local screenPosition, visible =
				Camera:WorldToViewportPoint(
					targetPart.Position
				)

			if visible
				and screenPosition.Z > 0 then

				local targetPosition =
					Vector2.new(
						screenPosition.X,
						screenPosition.Y
					)

				local distance =
					(
						targetPosition
						- screenCenter
					).Magnitude

				if distance <= Settings.FOV
					and distance < bestDistance then

					bestDistance = distance
					bestPlayer = player

				end

			end

		end

	end

	return bestPlayer

end

--==================================================
-- AIM AT TARGET
--==================================================

local function AimAtTarget(player)

	local valid, targetPart =
		IsValidTarget(player)

	if not valid or not targetPart then
		return false
	end

	local cameraPosition =
		Camera.CFrame.Position

	local targetPosition =
		targetPart.Position

	local targetCFrame =
		CFrame.lookAt(
			cameraPosition,
			targetPosition
		)

	local smooth =
		math.clamp(
			Settings.Smoothness,
			0.03,
			1
		)

	Camera.CFrame =
		Camera.CFrame:Lerp(
			targetCFrame,
			smooth
		)

	return true

end

--==================================================
-- MAIN LOOP
--==================================================

RunService.RenderStepped:Connect(function()

	--================================================
	-- FOV TENGAH LAYAR
	--================================================

	local viewportSize =
		Camera.ViewportSize

	local screenCenter =
		Vector2.new(
			viewportSize.X / 2,
			viewportSize.Y / 2
		)

	FOVCircle.Position =
		UDim2.fromOffset(
			screenCenter.X,
			screenCenter.Y
		)

	FOVCircle.Size =
		UDim2.fromOffset(
			Settings.FOV * 2,
			Settings.FOV * 2
		)

	--================================================
	-- AIMBOT OFF
	--================================================

	if not Settings.Aimbot then

		CurrentTarget = nil

		return

	end

	--================================================
	-- STICKY AIM
	--================================================

	if Settings.StickyAim
		and CurrentTarget then

		local character =
			GetCharacter(CurrentTarget)

		if character then

			local targetPart =
				character:FindFirstChild(
					Settings.TargetPart
				)
				or character:FindFirstChild(
					"HumanoidRootPart"
				)

			if targetPart then

				local screenPosition, visible =
					Camera:WorldToViewportPoint(
						targetPart.Position
					)

				local targetScreen =
					Vector2.new(
						screenPosition.X,
						screenPosition.Y
					)

				local distance =
					(
						targetScreen
						- screenCenter
					).Magnitude

				local allowedDistance =
					Settings.FOV * 1.25

				if not visible
					or screenPosition.Z <= 0
					or distance > allowedDistance
					or not CanSeeTarget(character) then

					CurrentTarget = nil

				end

			else

				CurrentTarget = nil

			end

		else

			CurrentTarget = nil

		end

	end

	--================================================
	-- FIND TARGET
	--================================================

	if not CurrentTarget then

		CurrentTarget =
			FindClosestTarget()

	end

	--================================================
	-- AIM
	--================================================

	if CurrentTarget then

		local success =
			AimAtTarget(CurrentTarget)

		if not success then
			CurrentTarget = nil
		end

	end

end)

--==================================================
-- MINIMIZE
--==================================================

local minimized = false

Minimize.MouseButton1Click:Connect(function()

	minimized = not minimized

	if minimized then

		Content.Visible = false

		Main.Size =
			UDim2.fromOffset(280, 45)

		Minimize.Text = "+"

	else

		Content.Visible = true

		Main.Size =
			UDim2.fromOffset(280, 390)

		Minimize.Text = "-"

	end

end)

--==================================================
-- REOPEN BUTTON
--==================================================

local ReopenButton = Instance.new("TextButton")

ReopenButton.Size =
	UDim2.fromOffset(110, 38)

ReopenButton.Position =
	UDim2.new(0, 20, 0, 20)

ReopenButton.BackgroundColor3 =
	Color3.fromRGB(35, 35, 42)

ReopenButton.Text =
	"OPEN AIM"

ReopenButton.TextColor3 =
	Color3.new(1, 1, 1)

ReopenButton.TextSize = 13
ReopenButton.Font = Enum.Font.GothamBold

ReopenButton.Visible = false
ReopenButton.Parent = ScreenGui

local ReopenCorner =
	Instance.new("UICorner")

ReopenCorner.CornerRadius =
	UDim.new(0, 8)

ReopenCorner.Parent =
	ReopenButton

ReopenButton.MouseButton1Click:Connect(function()

	Main.Visible = true
	ReopenButton.Visible = false

end)

--==================================================
-- INSERT KEY
--==================================================

UserInputService.InputBegan:Connect(function(
	input,
	processed
)

	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Insert then

		Main.Visible =
			not Main.Visible

		ReopenButton.Visible =
			not Main.Visible

	end

end)

print("FPS Aim Assist loaded successfully.")