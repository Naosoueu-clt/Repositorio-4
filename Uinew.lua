local ESPEnabled = false
local ESPConnections = {}

-- Cria ESP para um jogador
local function createESP(player)
    if player == game.Players.LocalPlayer then return end
    if not player.Character or not player.Character:FindFirstChild("Head") then return end

    local char = player.Character

    -- Highlight (caixa vermelha)
    if not char:FindFirstChild("ESPBox") then
        local box = Instance.new("Highlight")
        box.Name = "ESPBox"
        box.FillColor = Color3.fromRGB(255, 0, 0)
        box.OutlineColor = Color3.new(0, 0, 0)
        box.OutlineTransparency = 0
        box.FillTransparency = 0.8
        box.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        box.Adornee = char
        box.Parent = char
    end

    -- Billboard GUI com nome e distância
    if not char.Head:FindFirstChild("ESPHighlight") then
        local highlight = Instance.new("BillboardGui")
        highlight.Name = "ESPHighlight"
        highlight.Size = UDim2.new(0, 100, 0, 40)
        highlight.AlwaysOnTop = true
        highlight.StudsOffset = Vector3.new(0, 3, 0)
        highlight.Adornee = char.Head
        highlight.Parent = char.Head

        -- Nome do jogador
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
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
        distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
        distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        distanceLabel.TextStrokeTransparency = 0
        distanceLabel.TextScaled = true
        distanceLabel.Font = Enum.Font.SourceSansBold
        distanceLabel.Parent = highlight

        -- Atualizar distância em loop
        ESPConnections[player] = task.spawn(function()
            while ESPEnabled and highlight and highlight.Parent do
                local myChar = game.Players.LocalPlayer.Character
                if myChar and myChar:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("HumanoidRootPart") then
                    local dist = (char.HumanoidRootPart.Position - myChar.HumanoidRootPart.Position).Magnitude
                    distanceLabel.Text = string.format("Distância: %.1f", dist)
                end
                task.wait(0.3)
            end
        end)
    end
end

-- Remove ESP do jogador
local function removeESP(player)
    if player.Character then
        local char = player.Character
        local highlight = char:FindFirstChild("ESPBox")
        if highlight then highlight:Destroy() end

        local gui = char:FindFirstChild("Head") and char.Head:FindFirstChild("ESPHighlight")
        if gui then gui:Destroy() end
    end

    if ESPConnections[player] then
        task.cancel(ESPConnections[player])
        ESPConnections[player] = nil
    end
end

-- Ativa/desativa ESP
local function toggleESP()
    ESPEnabled = not ESPEnabled

    for _, player in pairs(game.Players:GetPlayers()) do
        if ESPEnabled then
            createESP(player)
        else
            removeESP(player)
        end
    end
end

-- Atualiza ESP para novos jogadores que entrarem ou respawnarem
game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if ESPEnabled then
            createESP(player)
        end
    end)
end)

-- Atualiza quando um jogador já presente respawnar
for _, player in pairs(game.Players:GetPlayers()) do
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if ESPEnabled then
            createESP(player)
        end
    end)
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
button.Font = Enum.Font.SourceSansBold
button.TextScaled = true
button.Parent = screenGui

-- Botão com debounce
local isToggling = false
button.MouseButton1Click:Connect(function()
    if isToggling then return end
    isToggling = true
    toggleESP()
    task.wait(0.5)
    isToggling = false
end)
