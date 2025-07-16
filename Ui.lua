local ESPEnabled = false

local function toggleESP()
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            if ESPEnabled then
                -- Remove ESP
                local existingBox = player.Character:FindFirstChild("ESPBox")
                local existingGui = player.Character.Head:FindFirstChild("ESPHighlight")
                if existingBox then existingBox:Destroy() end
                if existingGui then existingGui:Destroy() end
            else
                -- Adiciona ESP
                if not player.Character:FindFirstChild("ESPBox") then
                    -- Caixa vermelha ao redor
                    local box = Instance.new("Highlight")
                    box.Name = "ESPBox"
                    box.FillColor = Color3.fromRGB(255, 0, 0)
                    box.OutlineColor = Color3.new(0, 0, 0)
                    box.OutlineTransparency = 0
                    box.FillTransparency = 0.8
                    box.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    box.Adornee = player.Character
                    box.Parent = player.Character
                end

                -- Nome + Distância
                if not player.Character.Head:FindFirstChild("ESPHighlight") then
                    local highlight = Instance.new("BillboardGui")
                    highlight.Name = "ESPHighlight"
                    highlight.Size = UDim2.new(0, 100, 0, 60)
                    highlight.AlwaysOnTop = true
                    highlight.StudsOffset = Vector3.new(0, 3, 0)
                    highlight.Adornee = player.Character.Head
                    highlight.Parent = player.Character.Head

                    -- Nome
                    local nameLabel = Instance.new("TextLabel")
                    nameLabel.Size = UDim2.new(0, 100, 0, 20)
                    nameLabel.Position = UDim2.new(0, 0, 0, 0)
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.Text = player.Name
                    nameLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
                    nameLabel.TextStrokeTransparency = 0
                    nameLabel.TextScaled = true
                    nameLabel.Font = Enum.Font.SourceSansBold
                    nameLabel.Parent = highlight

                    -- Distância
                    local distanceLabel = Instance.new("TextLabel")
                    distanceLabel.Name = "DistanceLabel"
                    distanceLabel.Size = UDim2.new(0, 100, 0, 20)
                    distanceLabel.Position = UDim2.new(0, 0, 0, 20)
                    distanceLabel.BackgroundTransparency = 1
                    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
                    distanceLabel.TextStrokeTransparency = 0
                    distanceLabel.TextScaled = true
                    distanceLabel.Font = Enum.Font.SourceSansBold
                    distanceLabel.Parent = highlight

                    -- Atualizar distância
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

-- Cria botão na tela
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
