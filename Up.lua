local ESPEnabled = false
local ESPConnections = {}

-- Cria ESP para um jogador
local function createESP(player)
    if player == game.Players.LocalPlayer then return end
    if not player.Character or not player.Character:FindFirstChild("Head") then return end

    local char = player.Character

    -- Highlight
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

    -- BillboardGui
    if not char.Head:FindFirstChild("ESPHighlight") then
        local highlight = Instance.new("BillboardGui")
        highlight.Name = "ESPHighlight"
        highlight.Size = UDim2.new(0, 80, 0, 25)
        highlight.AlwaysOnTop = true
        highlight.StudsOffset = Vector3.new(0, 3, 0)
        highlight.Adornee = char.Head
        highlight.Parent = char.Head

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

-- Remove ESP
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

-- Alterna ESP
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

-- Atualiza para novos jogadores e respawn
game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if ESPEnabled then
            createESP(player)
        end
    end)
end)

for _, player in pairs(game.Players:GetPlayers()) do
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if ESPEnabled then
            createESP(player)
        end
    end)
end

-- GUI
local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "ESP_UI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Contador de jogadores
local playerCountLabel = Instance.new("TextLabel")
playerCountLabel.Size = UDim2.new(0, 160, 0, 30)
playerCountLabel.Position = UDim2.new(0, 10, 0, 60)
playerCountLabel.BackgroundTransparency = 1
playerCountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
playerCountLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
playerCountLabel.TextStrokeTransparency = 0
playerCountLabel.TextScaled = true
playerCountLabel.Font = Enum.Font.SourceSansBold
playerCountLabel.Text = "Jogadores: 0"
playerCountLabel.Parent = gui

-- Atualiza contador em tempo real
task.spawn(function()
    while true do
        playerCountLabel.Text = "Jogadores: " .. tostring(#game.Players:GetPlayers())
        task.wait(1)
    end
end)

-- Botão flutuante com imagem
local toggleButton = Instance.new("ImageButton")
toggleButton.Size = UDim2.new(0, 50, 0, 50)
toggleButton.Position = UDim2.new(0, 20, 0, 100)
toggleButton.BackgroundTransparency = 1
toggleButton.Image = "rbxassetid://6035047409" -- ícone de "olho"
toggleButton.Parent = gui

-- Debounce
local isToggling = false
toggleButton.MouseButton1Click:Connect(function()
    if isToggling then return end
    isToggling = true
    toggleESP()
    toggleButton.ImageColor3 = ESPEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    task.wait(0.3)
    isToggling = false
end)

-- Arrastar botão
local dragging = false
local dragInput, dragStart, startPos

toggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = toggleButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

toggleButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        toggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                          startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
