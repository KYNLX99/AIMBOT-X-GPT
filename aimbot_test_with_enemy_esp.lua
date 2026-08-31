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
local Smoothness = 0.25

local CurrentTarget = nil

--========================================================--
-- ESP SETTINGS
--========================================================--

local ESPEnabled = false
local ESPObjects = {}

--========================================================--
-- ENEMY CHECK FOR ESP
--========================================================--

local function IsESPEnemy(player)
	if player == LocalPlayer then
		return false
	end

	-- Jika game memakai Team, hanya Team berbeda yang dianggap enemy.
	if LocalPlayer.Team ~= nil and player.Team ~= nil then
		return player.Team ~= LocalPlayer.Team
	end

	-- Game tanpa Team: semua player lain dianggap enemy.
	return true
end

--========================================================--
-- REMOVE ESP
--========================================================--

local function RemoveESP(player)
	local data = ESPObjects[player]
	if not data then
		return
	end

	if data.CharacterAddedConnection then
		data.CharacterAddedConnection:Disconnect()
	end

	if data.CharacterRemovingConnection then
		data.CharacterRemovingConnection:Disconnect()
	end

	if data.Highlight and data.Highlight.Parent then
		data.Highlight:Destroy()
	end

	if data.Billboard and data.Billboard.Parent then
		data.Billboard:Destroy()
	end

	ESPObjects[player] = nil
end

--========================================================--
-- CREATE / UPDATE ENEMY ESP
--========================================================--

local function CreateESP(player)
	if player == LocalPlayer or not ESPEnabled or not IsESPEnemy(player) then
		RemoveESP(player)
		return
	end

	local character = player.Character
	if not character then
		RemoveESP(player)
		return
	end

	local head = character:FindFirstChild("Head")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not head or not humanoid or humanoid.Health <= 0 then
		RemoveESP(player)
		return
	end

	-- Jangan membuat object berulang-ulang.
	local old = ESPObjects[player]
	if old and old.Character == character
		and old.Highlight and old.Highlight.Parent
		and old.Billboard and old.Billboard.Parent then
		return
	end

	RemoveESP(player)

	local highlight = Instance.new("Highlight")
	highlight.Name = "EnemyESP"
	highlight.Adornee = character
	highlight.FillTransparency = 0.75
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "EnemyESPInfo"
	billboard.Adornee = head
	billboard.Size = UDim2.fromOffset(180, 45)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 1000
	billboard.Parent = workspace

	local label = Instance.new("TextLabel")
	label.Name = "Info"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = player.DisplayName
	label.TextSize = 13
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.4
	label.Parent = billboard

	ESPObjects[player] = {
		Character = character,
		Highlight = highlight,
		Billboard = billboard,
		Label = label,
	}

	-- Satu updater ringan per player.
	task.spawn(function()
		while ESPEnabled do
			local data = ESPObjects[player]

			if not data
				or data.Character ~= character
				or not character.Parent
				or not humanoid.Parent
				or humanoid.Health <= 0
				or not head.Parent
				or not IsESPEnemy(player) then
				break
			end

			local myCharacter = LocalPlayer.Character
			local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
			local targetRoot = character:FindFirstChild("HumanoidRootPart")

			if myRoot and targetRoot and data.Label then
				local distance = (myRoot.Position - targetRoot.Position).Magnitude
				data.Label.Text = player.DisplayName .. "\n" .. math.floor(distance) .. " studs"
			elseif data.Label then
				data.Label.Text = player.DisplayName
			end

			task.wait(0.1)
		end

		if ESPObjects[player]
			and ESPObjects[player].Character == character then
			RemoveESP(player)
		end
	end)
end

--========================================================--
-- REFRESH ESP
--========================================================--

local function RefreshESP()
	-- Bersihkan object yang sudah tidak valid / bukan enemy.
	for player in pairs(ESPObjects) do
		if not ESPEnabled or not IsESPEnemy(player) then
			RemoveESP(player)
		end
	end

	if not ESPEnabled then
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and IsESPEnemy(player) then
			CreateESP(player)
		end
	end
end

--========================================================--
-- ESP PLAYER EVENTS
--========================================================--

local function HookESPPlayer(player)
	if player == LocalPlayer then
		return
	end

	-- Character baru / respawn.
	player.CharacterAdded:Connect(function(character)
		-- Tunggu Head/Humanoid tersedia, tanpa bergantung pada delay tetap.
		local humanoid = character:WaitForChild("Humanoid", 5)
		local head = character:WaitForChild("Head", 5)

		if humanoid and head and ESPEnabled then
			task.defer(function()
				CreateESP(player)
			end)
		end
	end)

	player.CharacterRemoving:Connect(function()
		RemoveESP(player)
	end)

	-- Perubahan Team milik player lain.
	player:GetPropertyChangedSignal("Team"):Connect(function()
		if ESPEnabled then
			RefreshESP()
		end
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	HookESPPlayer(player)
end

Players.PlayerAdded:Connect(function(player)
	HookESPPlayer(player)

	if ESPEnabled then
		task.defer(function()
			if player.Parent then
				CreateESP(player)
			end
		end)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	RemoveESP(player)
end)

LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
	RefreshESP()
end)

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
Main.Size = UDim2.fromOffset(290, 365)
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

local ESPButton =
	CreateButton(
		"ENEMY ESP : OFF",
		252
	)

--========================================================--
-- SMOOTHNESS LABEL
--========================================================--

local SmoothLabel =
	Instance.new("TextLabel")

SmoothLabel.Size =
	UDim2.fromOffset(105, 30)

SmoothLabel.Position =
	UDim2.fromOffset(15, 310)

SmoothLabel.BackgroundTransparency = 1

SmoothLabel.Text =
	"Smooth: 25%"

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
	UDim2.fromOffset(125, 321)

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
	UDim2.new(0.25, 0, 1, 0)

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

	-- Jika game menggunakan Team,
	-- hanya team berbeda yang menjadi target.
	if LocalPlayer.Team ~= nil
		and player.Team ~= nil then

		return player.Team ~=
			LocalPlayer.Team
	end

	return true
end

--========================================================--
-- TARGET VALIDATION
--========================================================--

local function IsValidTarget(player)

	if not player then
		return false
	end

	if not IsEnemy(player) then
		return false
	end

	local character =
		player.Character

	if not character then
		return false
	end

	local humanoid =
		character:FindFirstChildOfClass(
			"Humanoid"
		)

	local head =
		character:FindFirstChild(
			"Head"
		)

	if not humanoid or not head then
		return false
	end

	if humanoid.Health <= 0 then
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

	local Camera =
		workspace.CurrentCamera

	if not Camera then
		return false
	end

	local Character =
		player.Character

	local Head =
		Character:FindFirstChild(
			"Head"
		)

	if not Head then
		return false
	end

	local Origin =
		Camera.CFrame.Position

	local Direction =
		Head.Position - Origin

	local Params =
		RaycastParams.new()

	Params.FilterType =
		Enum.RaycastFilterType.Exclude

	Params.FilterDescendantsInstances = {
		LocalPlayer.Character
	}

	Params.IgnoreWater = true

	local Result =
		workspace:Raycast(
			Origin,
			Direction,
			Params
		)

	if Result == nil then
		return true
	end

	return Result.Instance:IsDescendantOf(
		Character
	)
end

--========================================================--
-- GET CLOSEST TARGET
--========================================================--

local function GetClosestTarget()

	local Camera =
		workspace.CurrentCamera

	if not Camera then
		return nil
	end

	local Viewport =
		Camera.ViewportSize

	local Center =
		Vector2.new(
			Viewport.X / 2,
			Viewport.Y / 2
		)

	local Closest = nil
	local ClosestDistance = FOVRadius + 3

	for _, player in
		ipairs(Players:GetPlayers()) do

		if IsValidTarget(player) then

			local Head =
				player.Character:FindFirstChild(
					"Head"
				)

			local ScreenPosition,
				OnScreen =
				Camera:WorldToViewportPoint(
					Head.Position
				)

			if OnScreen
				and ScreenPosition.Z > 0 then

				local Point =
					Vector2.new(
						ScreenPosition.X,
						ScreenPosition.Y
					)

				local Distance =
					(Point - Center).Magnitude

				if Distance <=
					ClosestDistance then

					if CanSeeTarget(player) then

						ClosestDistance =
							Distance

						Closest = player

					end
				end
			end
		end
	end

	return Closest
end

--========================================================--
-- SWITCH TARGET
--========================================================--

local function SwitchTarget()

	local Camera =
		workspace.CurrentCamera

	if not Camera then
		return
	end

	local Viewport =
		Camera.ViewportSize

	local Center =
		Vector2.new(
			Viewport.X / 2,
			Viewport.Y / 2
		)

	local Targets = {}

	for _, player in
		ipairs(Players:GetPlayers()) do

		if IsValidTarget(player) then

			local Head =
				player.Character:FindFirstChild(
					"Head"
				)

			local Position, Visible =
				Camera:WorldToViewportPoint(
					Head.Position
				)

			if Visible
				and Position.Z > 0 then

				local Point =
					Vector2.new(
						Position.X,
						Position.Y
					)

				local Distance =
					(Point - Center).Magnitude

				if Distance <= FOVRadius + 3
					and CanSeeTarget(player) then

					table.insert(
						Targets,
						{
							Player = player,
							Distance = Distance
						}
					)
				end
			end
		end
	end

	if #Targets == 0 then

		CurrentTarget = nil
		return
	end

	table.sort(
		Targets,
		function(a, b)
			return a.Distance <
				b.Distance
		end
	)

	if not CurrentTarget then

		CurrentTarget =
			Targets[1].Player

		return
	end

	for Index, Data in
		ipairs(Targets) do

		if Data.Player ==
			CurrentTarget then

			local NextIndex =
				Index + 1

			if NextIndex > #Targets then
				NextIndex = 1
			end

			CurrentTarget =
				Targets[NextIndex].Player

			return
		end
	end

	CurrentTarget =
		Targets[1].Player
end

--========================================================--
-- AIM TO HEAD
--========================================================--

local function AimAtHead(player, dt)
	if not IsValidTarget(player) then
		return false
	end

	local Camera = workspace.CurrentCamera
	if not Camera then
		return false
	end

	local Character = player.Character
	local Head = Character and Character:FindFirstChild("Head")
	if not Head or not CanSeeTarget(player) then
		return false
	end

	local DesiredCFrame = CFrame.lookAt(
		Camera.CFrame.Position,
		Head.Position
	)

	-- Smoothing konsisten di berbagai FPS.
	local alpha = 1 - math.pow(
		1 - math.clamp(Smoothness, 0.03, 1),
		math.max(dt or (1 / 60), 1 / 240) * 60
	)

	Camera.CFrame = Camera.CFrame:Lerp(DesiredCFrame, alpha)

	if Smoothness >= 0.98 then
		Camera.CFrame = DesiredCFrame
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
	Enum.RenderPriority.Camera.Value + 100,
	function(dt)
		if not AimEnabled then
			return
		end

		-- Buang target yang benar-benar sudah mati/hilang.
		if CurrentTarget and not IsValidTarget(CurrentTarget) then
			CurrentTarget = nil
		end

		if StickyLock then
			-- Sticky: jangan ganti target hanya karena target bergerak.
			if not CurrentTarget then
				CurrentTarget = GetClosestTarget()
			end
		else
			-- Non-sticky: pilih target terbaik setiap frame.
			CurrentTarget = GetClosestTarget()
		end

		if CurrentTarget and CanSeeTarget(CurrentTarget) then
			AimAtHead(CurrentTarget, dt)
		elseif CurrentTarget and not StickyLock then
			CurrentTarget = nil
		end

		-- Auto retarget jika target hilang tepat saat proses aim.
		if not CurrentTarget then
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