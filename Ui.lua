local ESPEnabled = false

local function toggleESP()
	for _, player in pairs(game.Players:GetPlayers()) do
		if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
			if ESPEnabled then
				local existing = player.Character:FindFirstChild("ESPBox")
				local gui = player.Character.Head:FindFirstChild("ESPHighlight")
				if existing then existing:Destroy() end
				if gui then gui:Destroy() end
			else
				if not player.Character.Head:FindFirstChild("ESPHighlight") then
					-- Highlight 3D
					local box = Instance.new("Highlight")
					box.Name = "ESPBox"
					box.FillColor = Color3.fromRGB(255, 0, 0)
					box.OutlineColor = Color3.new(0, 0, 0)
					box.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					box.Adornee = player.Character
					box.Parent = player.Character

					-- BillboardGui com nome e distância
					local highlight = Instance.new("BillboardGui")
					highlight.Name = "ESPHighlight"
					highlight.Size = UDim2.new(0, 100, 0, 60)
					highlight.AlwaysOnTop = true
					highlight.StudsOffset = Vector3.new(0, 3, 0)
					highlight.Adornee = player.Character.Head
					highlight.Parent = player.Character.Head

					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(1, 0, 0.5, 0)
					label.Position = UDim2.new(0, 0, 0, 0)
					label.BackgroundTransparency = 1
					label.TextColor3 = Color3.fromRGB(255, 0, 0)
					label.TextStrokeTransparency = 0
					label.TextStrokeColor3 = Color3.new(0, 0, 0)
					label.TextScaled = true
					label.Font = Enum.Font.SourceSansBold
					label.Text = player.Name
					label.Parent = highlight

					local distanceLabel = Instance.new("TextLabel")
					distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
					distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
					distanceLabel.BackgroundTransparency = 1
					distanceLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
					distanceLabel.TextStrokeTransparency = 0
					distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
					distanceLabel.TextScaled = true
					distanceLabel.Font = Enum.Font.SourceSansBold
					distanceLabel.Name = "DistanceLabel"
					distanceLabel.Parent = highlight

					task.spawn(function()
						while highlight and highlight.Parent do
							local char = game.Players.LocalPlayer.Character
							if char and char:FindFirstChild("HumanoidRootPart") then
								local dist = (player.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude
								distanceLabel.Text = string.format("Distância: %.1f", dist)
							end
							task.wait(0.3)
						end
					end)
				end
			end
		end
	end
	ESPEnabled = not ESPEnabled
end

-- Criação de GUI com botão
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ESP_UI"
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Text = "Toggle ESP"
button.Size = UDim2.new(0, 150, 0, 40)
button.Position = UDim2.new(0, 20, 0, 100)
button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
button.TextColor3 = Color3.new(1, 1, 1)
button.Parent = screenGui

button.MouseButton1Click:Connect(toggleESP)
