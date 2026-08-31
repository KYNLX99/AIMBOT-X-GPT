--========================================================--
--        FPS AIM ASSIST - ROBLOX STUDIO TEST             --
--========================================================--
-- LocalScript
-- StarterPlayer > StarterPlayerScripts
--
-- FITUR:
-- • Aim Assist ON/OFF
-- • FOV Circle di tengah layar
-- • Aim ke HEAD
-- • Sticky Lock
-- • Wall Check
-- • Auto Switch setelah target mati
-- • Switch Target manual
-- • Smoothness Slider
-- • GUI Drag Mouse + Touch
-- • Minimize / Reopen
--========================================================--

--========================================================--
-- SERVICES
--========================================================--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

--========================================================--
-- SETTINGS
--========================================================--

local AimEnabled = false
local StickyLock = true
local WallCheck = true

local FOVRadius = 150

-- 0.03 = sangat halus
-- 1.00 = sangat cepat
local Smoothness = 0.80

local CurrentTarget = nil

--========================================================--
-- GUI
--========================================================--

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PrivateAimAssist"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

--========================================================--
-- FOV CIRCLE
--========================================================--

local FOV = Instance.new("Frame")
FOV.Name = "FOV"
FOV.AnchorPoint = Vector2.new(0.5, 0.5)
FOV.Position = UDim2.fromScale(0.5, 0.5)
FOV.Size = UDim2.fromOffset(
	FOVRadius * 2,
	FOVRadius * 2
)

FOV.BackgroundTransparency = 1
FOV.BorderSizePixel = 0
FOV.Visible = false
FOV.Parent = ScreenGui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOV

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 2
FOVStroke.Transparency = 0.1
FOVStroke.Parent = FOV

--========================================================--
-- MAIN WINDOW
--========================================================--

local Main = Instance.new("Frame")

Main.Name = "Main"
Main.Size = UDim2.fromOffset(290, 315)
Main.Position = UDim2.fromOffset(30, 150)

Main.BackgroundColor3 =
	Color3.fromRGB(25, 25, 30)

Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

--========================================================--
-- HEADER / DRAG AREA
--========================================================--

local Header = Instance.new("TextButton")

Header.Name = "DragHeader"
Header.Size = UDim2.new(1, 0, 0, 45)

Header.BackgroundColor3 =
	Color3.fromRGB(35, 35, 43)

Header.BorderSizePixel = 0

Header.Text = "FPS AIM ASSIST"
Header.TextColor3 =
	Color3.fromRGB(255, 255, 255)

Header.TextSize = 15
Header.Font = Enum.Font.GothamBold

Header.TextXAlignment =
	Enum.TextXAlignment.Left

Header.AutoButtonColor = false
Header.Active = true
Header.Parent = Main

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 10)
HeaderCorner.Parent = Header

local HeaderPadding = Instance.new("UIPadding")
HeaderPadding.PaddingLeft = UDim.new(0, 13)
HeaderPadding.Parent = Header

--========================================================--
-- MINIMIZE BUTTON
--========================================================--

local Minimize = Instance.new("TextButton")

Minimize.Size = UDim2.fromOffset(35, 35)
Minimize.Position = UDim2.new(1, -75, 0, 5)

Minimize.BackgroundTransparency = 1

Minimize.Text = "—"
Minimize.TextColor3 =
	Color3.fromRGB(255, 255, 255)

Minimize.TextSize = 20
Minimize.Font = Enum.Font.GothamBold

Minimize.Parent = Header

--========================================================--
-- CLOSE BUTTON
--========================================================--

local Close = Instance.new("TextButton")

Close.Size = UDim2.fromOffset(35, 35)
Close.Position = UDim2.new(1, -38, 0, 5)

Close.BackgroundTransparency = 1

Close.Text = "×"
Close.TextColor3 =
	Color3.fromRGB(255, 100, 100)

Close.TextSize = 22
Close.Font = Enum.Font.GothamBold

Close.Parent = Header

--========================================================--
-- BUTTON CREATOR
--========================================================--

local function CreateButton(text, y)

	local Button = Instance.new("TextButton")

	Button.Size =
		UDim2.new(1, -30, 0, 40)

	Button.Position =
		UDim2.fromOffset(15, y)

	Button.BackgroundColor3 =
		Color3.fromRGB(45, 45, 55)

	Button.BorderSizePixel = 0

	Button.Text = text

	Button.TextColor3 =
		Color3.fromRGB(255, 255, 255)

	Button.TextSize = 13
	Button.Font = Enum.Font.GothamSemibold

	Button.Parent = Main

	local Corner = Instance.new("UICorner")

	Corner.CornerRadius =
		UDim.new(0, 7)

	Corner.Parent = Button

	return Button
end

--========================================================--
-- BUTTONS
--========================================================--

local AimButton =
	CreateButton(
		"AIM ASSIST : OFF",
		60
	)

local StickyButton =
	CreateButton(
		"STICKY LOCK : ON",
		108
	)

local WallButton =
	CreateButton(
		"WALL CHECK : ON",
		156
	)

local SwitchButton =
	CreateButton(
		"SWITCH TARGET",
		204
	)


--========================================================--
-- SMOOTHNESS LABEL
--========================================================--

local SmoothLabel =
	Instance.new("TextLabel")

SmoothLabel.Size =
	UDim2.fromOffset(105, 30)

SmoothLabel.Position =
	UDim2.fromOffset(15, 260)

SmoothLabel.BackgroundTransparency = 1

SmoothLabel.Text =
	"Smooth: 80%"

SmoothLabel.TextColor3 =
	Color3.fromRGB(255, 255, 255)

SmoothLabel.TextSize = 13
SmoothLabel.Font = Enum.Font.Gotham

SmoothLabel.TextXAlignment =
	Enum.TextXAlignment.Left

SmoothLabel.Parent = Main

--========================================================--
-- SMOOTHNESS SLIDER
--========================================================--

local Slider =
	Instance.new("Frame")

Slider.Size =
	UDim2.fromOffset(145, 8)

Slider.Position =
	UDim2.fromOffset(125, 271)

Slider.BackgroundColor3 =
	Color3.fromRGB(65, 65, 75)

Slider.BorderSizePixel = 0
Slider.Active = true
Slider.Parent = Main

local SliderCorner =
	Instance.new("UICorner")

SliderCorner.CornerRadius =
	UDim.new(1, 0)

SliderCorner.Parent = Slider

local Fill =
	Instance.new("Frame")

Fill.Size =
	UDim2.new(0.80, 0, 1, 0)

Fill.BackgroundColor3 =
	Color3.fromRGB(90, 170, 255)

Fill.BorderSizePixel = 0
Fill.Parent = Slider

local FillCorner =
	Instance.new("UICorner")

FillCorner.CornerRadius =
	UDim.new(1, 0)

FillCorner.Parent = Fill

--========================================================--
-- REOPEN BUTTON
--========================================================--

local Reopen =
	Instance.new("TextButton")

Reopen.Size =
	UDim2.fromOffset(110, 38)

Reopen.Position =
	UDim2.fromOffset(20, 20)

Reopen.BackgroundColor3 =
	Color3.fromRGB(35, 35, 43)

Reopen.BorderSizePixel = 0

Reopen.Text = "OPEN MENU"

Reopen.TextColor3 =
	Color3.fromRGB(255, 255, 255)

Reopen.TextSize = 13
Reopen.Font = Enum.Font.GothamBold

Reopen.Visible = false
Reopen.Parent = ScreenGui

local ReopenCorner =
	Instance.new("UICorner")

ReopenCorner.CornerRadius =
	UDim.new(0, 8)

ReopenCorner.Parent = Reopen

--========================================================--
-- TEAM / ENEMY CHECK
--========================================================--

local function IsEnemy(player)
	if player == LocalPlayer then
		return false
	end

	if LocalPlayer.Team ~= nil and player.Team ~= nil then
		return player.Team ~= LocalPlayer.Team
	end

	return true
end

--========================================================--
-- TARGET VALIDATION
--========================================================--

local function IsValidTarget(player)
	if not player or player == LocalPlayer then
		return false
	end

	if not IsEnemy(player) then
		return false
	end

	local character = player.Character
	if not character or not character.Parent then
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild("Head")
	local root = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	if not head or not root then
		return false
	end

	return true
end

--========================================================--
-- WALL CHECK
--========================================================--

local function CanSeeTarget(player)
	if not WallCheck then
		return true
	end

	if not IsValidTarget(player) then
		return false
	end

	local Camera = workspace.CurrentCamera
	if not Camera then
		return false
	end

	local Character = player.Character
	local Head = Character and Character:FindFirstChild("Head")
	if not Head then
		return false
	end

	local Origin = Camera.CFrame.Position
	local Direction = Head.Position - Origin

	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = {
		LocalPlayer.Character
	}
	Params.IgnoreWater = true

	local Result = workspace:Raycast(Origin, Direction, Params)

	if not Result then
		return true
	end

	return Result.Instance:IsDescendantOf(Character)
end

--========================================================--
-- GET CLOSEST TARGET
--========================================================--

local function GetClosestTarget()
	local Camera = workspace.CurrentCamera
	if not Camera then
		return nil
	end

	local viewport = Camera.ViewportSize
	local center = viewport * 0.5
	local radius = FOVRadius
	local radiusSq = radius * radius

	local closestPlayer = nil
	local closestScreenDistSq = radiusSq

	for _, player in ipairs(Players:GetPlayers()) do
		if IsValidTarget(player) then
			local character = player.Character
			local head = character and character:FindFirstChild("Head")

			if head then
				local screenPos, onScreen =
					Camera:WorldToViewportPoint(head.Position)

				if onScreen and screenPos.Z > 0 then
					local dx = screenPos.X - center.X
					local dy = screenPos.Y - center.Y
					local distSq = dx * dx + dy * dy

					if distSq <= closestScreenDistSq then
						if CanSeeTarget(player) then
							closestScreenDistSq = distSq
							closestPlayer = player
						end
					end
				end
			end
		end
	end

	return closestPlayer
end

--========================================================--
-- SWITCH TARGET
--========================================================--

local function SwitchTarget()
	local Camera = workspace.CurrentCamera
	if not Camera then
		return
	end

	local Viewport = Camera.ViewportSize
	local Center = Vector2.new(Viewport.X * 0.5, Viewport.Y * 0.5)

	local Targets = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if IsValidTarget(player) then
			local Head = player.Character and player.Character:FindFirstChild("Head")

			if Head then
				local Position, Visible =
					Camera:WorldToViewportPoint(Head.Position)

				if Visible and Position.Z > 0 then
					local Point = Vector2.new(Position.X, Position.Y)
					local Distance = (Point - Center).Magnitude

					if Distance <= FOVRadius and CanSeeTarget(player) then
						table.insert(Targets, {
							Player = player,
							Distance = Distance
						})
					end
				end
			end
		end
	end

	if #Targets == 0 then
		CurrentTarget = nil
		return
	end

	table.sort(Targets, function(x, y)
		return x.Distance < y.Distance
	end)

	if not CurrentTarget then
		CurrentTarget = Targets[1].Player
		return
	end

	for index, data in ipairs(Targets) do
		if data.Player == CurrentTarget then
			local nextIndex = index + 1
			if nextIndex > #Targets then
				nextIndex = 1
			end

			CurrentTarget = Targets[nextIndex].Player
			return
		end
	end

	CurrentTarget = Targets[1].Player
end

--========================================================--
-- AIM TO HEAD
--========================================================--

local function AimAtHead(player, dt)
	if not IsValidTarget(player) then
		return false
	end

	local camera = workspace.CurrentCamera
	local character = player.Character
	local head = character and character:FindFirstChild("Head")

	if not camera or not head then
		return false
	end

	if not CanSeeTarget(player) then
		return false
	end

	local desired = CFrame.lookAt(camera.CFrame.Position, head.Position)

	-- Responsif: nilai Smoothness tinggi bergerak hampir instan.
	local strength = math.clamp(Smoothness, 0.03, 1)
	local alpha

	if strength >= 0.85 then
		alpha = 0.98
	else
		alpha = 1 - math.exp(
			-30 * strength * math.max(dt or (1 / 60), 1 / 240)
		)
	end

	camera.CFrame = camera.CFrame:Lerp(desired, alpha)

	-- Saat sudah sangat dekat ke kepala, hilangkan sisa error kecil.
	if camera.CFrame.LookVector:Dot(desired.LookVector) > 0.99995 then
		camera.CFrame = desired
	end

	return true
end

--========================================================--
-- AIM BUTTON
--========================================================--

AimButton.MouseButton1Click:Connect(
	function()

		AimEnabled =
			not AimEnabled

		if AimEnabled then

			AimButton.Text =
				"AIM ASSIST : ON"

			FOV.Visible = true

			CurrentTarget =
				GetClosestTarget()

		else

			AimButton.Text =
				"AIM ASSIST : OFF"

			FOV.Visible = false

			CurrentTarget = nil

		end
	end
)

--========================================================--
-- STICKY BUTTON
--========================================================--

StickyButton.MouseButton1Click:Connect(
	function()

		StickyLock =
			not StickyLock

		if StickyLock then

			StickyButton.Text =
				"STICKY LOCK : ON"

		else

			StickyButton.Text =
				"STICKY LOCK : OFF"

		end
	end
)

--========================================================--
-- WALL BUTTON
--========================================================--

WallButton.MouseButton1Click:Connect(
	function()

		WallCheck =
			not WallCheck

		if WallCheck then

			WallButton.Text =
				"WALL CHECK : ON"

		else

			WallButton.Text =
				"WALL CHECK : OFF"

		end
	end
)

--========================================================--
-- SWITCH BUTTON
--========================================================--

SwitchButton.MouseButton1Click:Connect(
	function()

		SwitchTarget()

	end
)

--========================================================--
-- ESP BUTTON
--========================================================--

ESPButton.MouseButton1Click:Connect(
	function()

		ESPEnabled = not ESPEnabled

		if ESPEnabled then
			ESPButton.Text = "ENEMY ESP : ON"
			RefreshESP()
		else
			ESPButton.Text = "ENEMY ESP : OFF"
			RefreshESP()
		end
	end
)

--========================================================--
-- SLIDER
--========================================================--

local SliderDragging = false

local function UpdateSlider(x)

	local StartX =
		Slider.AbsolutePosition.X

	local Width =
		Slider.AbsoluteSize.X

	local Percentage =
		math.clamp(
			(x - StartX) / Width,
			0,
			1
		)

	Fill.Size =
		UDim2.new(
			Percentage,
			0,
			1,
			0
		)

	Smoothness =
		0.03 +
		Percentage * 0.97

	SmoothLabel.Text =
		"Smooth: " ..
		math.floor(
			Percentage * 100
		) ..
		"%"
end

Slider.InputBegan:Connect(
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			SliderDragging = true

			UpdateSlider(
				input.Position.X
			)
		end
	end
)

UserInputService.InputChanged:Connect(
	function(input)

		if not SliderDragging then
			return
		end

		if input.UserInputType ==
			Enum.UserInputType.MouseMovement
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			UpdateSlider(
				input.Position.X
			)
		end
	end
)

UserInputService.InputEnded:Connect(
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			SliderDragging = false
		end
	end
)

--========================================================--
-- GUI DRAG - MOUSE + TOUCH
--========================================================--

local Dragging = false
local DragStart = nil
local StartPosition = nil
local DragInput = nil

local function UpdateDrag(input)

	if not DragStart
		or not StartPosition then

		return
	end

	local Delta =
		input.Position -
		DragStart

	Main.Position =
		UDim2.new(
			StartPosition.X.Scale,
			StartPosition.X.Offset +
				Delta.X,

			StartPosition.Y.Scale,
			StartPosition.Y.Offset +
				Delta.Y
		)
end

Header.InputBegan:Connect(
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			Dragging = true

			DragStart =
				input.Position

			StartPosition =
				Main.Position

			DragInput = input
		end
	end
)

Header.InputChanged:Connect(
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseMovement
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			DragInput = input
		end
	end
)

UserInputService.InputChanged:Connect(
	function(input)

		if not Dragging then
			return
		end

		if input == DragInput then
			UpdateDrag(input)
		end
	end
)

UserInputService.InputEnded:Connect(
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			Dragging = false
			DragInput = nil
		end
	end
)

--========================================================--
-- MINIMIZE
--========================================================--

Minimize.MouseButton1Click:Connect(
	function()

		Main.Visible = false
		Reopen.Visible = true

	end
)

--========================================================--
-- CLOSE
--========================================================--

Close.MouseButton1Click:Connect(
	function()

		Main.Visible = false
		Reopen.Visible = true

	end
)

--========================================================--
-- REOPEN
--========================================================--

Reopen.MouseButton1Click:Connect(
	function()

		Main.Visible = true
		Reopen.Visible = false

	end
)

--========================================================--
-- MAIN AIM LOOP
--========================================================--

RunService:BindToRenderStep(
	"PrivateAimAssist",
	Enum.RenderPriority.Camera.Value + 1000,
	function(dt)
		if not AimEnabled then
			return
		end

		-- Target mati/hilang -> reacquire segera.
		if CurrentTarget and not IsValidTarget(CurrentTarget) then
			CurrentTarget = nil
		end

		if StickyLock and CurrentTarget and IsValidTarget(CurrentTarget) then
			-- Sticky tetap mengunci target sampai invalid.
			if CanSeeTarget(CurrentTarget) then
				AimAtHead(CurrentTarget, dt)
			end
		else
			-- Non-sticky: cari target terbaik setiap frame.
			CurrentTarget = GetClosestTarget()
			if CurrentTarget then
				AimAtHead(CurrentTarget, dt)
			end
		end

		-- Bila sticky belum punya target, acquire sekarang juga.
		if StickyLock and not CurrentTarget then
			CurrentTarget = GetClosestTarget()
			if CurrentTarget then
				AimAtHead(CurrentTarget, dt)
			end
		end
	end
)


--========================================================--
-- INITIALIZE
--========================================================--

FOV.Visible = false

print(
	"[FPS Aim Assist] Loaded successfully."
)