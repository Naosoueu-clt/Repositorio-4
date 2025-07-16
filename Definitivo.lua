local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local ESPEnabled = false
local ESPConnections = {}
local SelectedPlayer = nil

local function createESP(player)
	if player == LocalPlayer or not player.Character or not player.Character:FindFirstChild("Head") then return end

	local char = player.Character

	-- Highlight com visual melhorado
	if not char:FindFirstChild("ESPBox") then
		local box = Instance.new("Highlight")
		box.Name = "ESPBox"
		box.FillColor = Color3.fromRGB(255, 0, 0)
		box.OutlineColor = Color3.fromRGB(255, 255, 255)
		box.OutlineTransparency = 0.3
		box.FillTransparency = 0.5
		box.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		box.Adornee = char
		box.Parent = char
	end

	-- Billboard com nome e distância
	if not char.Head:FindFirstChild("ESPHighlight") then
		local gui = Instance.new("BillboardGui")
		gui.Name = "ESPHighlight"
		gui.Size = UDim2.new(0, 80, 0, 25)
		gui.StudsOffset = Vector3.new(0, 3, 0)
		gui.Adornee = char.Head
		gui.AlwaysOnTop = true
		gui.Parent = char.Head

		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(1, 0, 0.5, 0)
		name.BackgroundTransparency = 1
		name.Text = player.Name
		name.TextColor3 = Color3.fromRGB(255, 0, 0)
		name.TextScaled = true
		name.Font = Enum.Font.SourceSansBold
		name.TextStrokeTransparency = 0
		name.TextStrokeColor3 = Color3.new(0, 0, 0)
		name.Parent = gui

		local dist = Instance.new("TextLabel")
		dist.Size = UDim2.new(1, 0, 0.5, 0)
		dist.Position = UDim2.new(0, 0, 0.5, 0)
		dist.BackgroundTransparency = 1
		dist.TextColor3 = Color3.fromRGB(255, 255, 255)
		dist.TextScaled = true
		dist.Font = Enum.Font.SourceSansBold
		dist.TextStrokeTransparency = 0
		dist.TextStrokeColor3 = Color3.new(0, 0, 0)
		dist.Name = "DistanceLabel"
		dist.Parent = gui

		ESPConnections[player] = task.spawn(function()
			while ESPEnabled and gui and gui.Parent do
				local myChar = LocalPlayer.Character
				if myChar and myChar:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("HumanoidRootPart") then
					local distance = (char.HumanoidRootPart.Position - myChar.HumanoidRootPart.Position).Magnitude
					dist.Text = string.format("Distância: %.1f", distance)
				end
				task.wait(0.3)
			end
		end)
	end
end

local function removeESP(player)
	if player.Character then
		local c = player.Character
		local box = c:FindFirstChild("ESPBox")
		if box then box:Destroy() end
		if c:FindFirstChild("Head") and c.Head:FindFirstChild("ESPHighlight") then
			c.Head.ESPHighlight:Destroy()
		end
	end
	if ESPConnections[player] then
		task.cancel(ESPConnections[player])
		ESPConnections[player] = nil
	end
end

local function toggleESP()
	ESPEnabled = not ESPEnabled
	for _, plr in ipairs(Players:GetPlayers()) do
		if ESPEnabled then
			if not SelectedPlayer or plr == SelectedPlayer then
				createESP(plr)
			end
		else
			removeESP(plr)
		end
	end
end

-- Handle joins/respawns
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		if ESPEnabled and (not SelectedPlayer or player == SelectedPlayer) then
			createESP(player)
		end
	end)
end)

for _, p in ipairs(Players:GetPlayers()) do
	p.CharacterAdded:Connect(function()
		task.wait(1)
		if ESPEnabled and (not SelectedPlayer or p == SelectedPlayer) then
			createESP(p)
		end
	end)
end
