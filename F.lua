--[[ ESP System Avançado com Menu de Jogadores --]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESPEnabled = false
local ESPConnections = {}
local ActiveESPPlayer = nil

-- Função para criar o Highlight melhorado
local function createHighlight(char)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPBox"
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.6
    highlight.OutlineTransparency = 0.2
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = char
    highlight.Parent = char
end

-- Cria ESP para um jogador
local function createESP(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char or not char:FindFirstChild("Head") then return end

    if not char:FindFirstChild("ESPBox") then
        createHighlight(char)
    end

    if not char.Head:FindFirstChild("ESPHighlight") then
        local gui = Instance.new("BillboardGui")
        gui.Name = "ESPHighlight"
        gui.Size = UDim2.new(0, 80, 0, 25)
        gui.AlwaysOnTop = true
        gui.StudsOffset = Vector3.new(0, 3, 0)
        gui.Adornee = char.Head
        gui.Parent = char.Head

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        nameLabel.TextStrokeTransparency = 0
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.Parent = gui

        local distLabel = Instance.new("TextLabel")
        distLabel.Name = "DistanceLabel"
        distLabel.Size = UDim2.new(1, 0, 0.5, 0)
        distLabel.Position = UDim2.new(0, 0, 0.5, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        distLabel.TextStrokeTransparency = 0
        distLabel.TextScaled = true
        distLabel.Font = Enum.Font.SourceSansBold
        distLabel.Parent = gui

        ESPConnections[player] = RunService.Heartbeat:Connect(function()
            if not ESPEnabled or not char:FindFirstChild("HumanoidRootPart") then return end
            local myChar = LocalPlayer.Character
            if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                local dist = (char.HumanoidRootPart.Position - myChar.HumanoidRootPart.Position).Magnitude
                distLabel.Text = string.format("Distância: %.1f", dist)
            end
        end)
    end
end

-- Remove ESP
local function removeESP(player)
    if ESPConnections[player] then
        ESPConnections[player]:Disconnect()
        ESPConnections[player] = nil
    end

    if player.Character then
        local char = player.Character
        local h = char:FindFirstChild("ESPBox")
        if h then h:Destroy() end

        local gui = char:FindFirstChild("Head") and char.Head:FindFirstChild("ESPHighlight")
        if gui then gui:Destroy() end
    end
end

-- Toggle ESP geral
local function toggleESP()
    ESPEnabled = not ESPEnabled
    ActiveESPPlayer = nil
    for _, p in pairs(Players:GetPlayers()) do
        if ESPEnabled then
            createESP(p)
        else
            removeESP(p)
        end
    end
end

-- Toggle ESP único
local function toggleSingleESP(targetPlayer)
    ESPEnabled = true
    ActiveESPPlayer = targetPlayer
    for _, p in pairs(Players:GetPlayers()) do
        if p == targetPlayer then
            createESP(p)
        else
            removeESP(p)
        end
    end
end

-- Ver câmera do jogador
local function viewCamera(targetPlayer)
    if targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") then
        Camera.CameraSubject = targetPlayer.Character.Humanoid
    end
end

-- Noclip + teleporte
local function noclipToPlayer(targetPlayer)
    local char = LocalPlayer.Character
    if not char then return end

    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = false
        end
    end

    if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        char:MoveTo(targetPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 3, 0))
    end
end

-- Interface principal
local gui = Instance.new("ScreenGui")
gui.Name = "ESP_UI"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 300)
mainFrame.Position = UDim2.new(0, 100, 0, 100)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "ESP Menu"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextScaled = true
title.Parent = mainFrame

local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(1, 0, 1, -30)
listFrame.Position = UDim2.new(0, 0, 0, 30)
listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
listFrame.ScrollBarThickness = 6
listFrame.BackgroundTransparency = 1
listFrame.Parent = mainFrame

-- Atualiza a lista de jogadores
local function updatePlayerList()
    listFrame:ClearAllChildren()
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = listFrame

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -10, 0, 30)
            btn.Position = UDim2.new(0, 5, 0, 0)
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            btn.TextColor3 = Color3.new(1,1,1)
            btn.Font = Enum.Font.SourceSans
            btn.Text = p.Name
            btn.TextScaled = true
            btn.Parent = listFrame

            btn.MouseButton1Click:Connect(function()
                -- Destroi menus anteriores
                for _, child in ipairs(gui:GetChildren()) do
                    if child:IsA("Frame") and child.Name == "PlayerMenu" then
                        child:Destroy()
                    end
                end

                local menu = Instance.new("Frame")
                menu.Name = "PlayerMenu"
                menu.Size = UDim2.new(0, 180, 0, 90)
                menu.Position = UDim2.new(0.5, -90, 0, btn.AbsolutePosition.Y - 90)
                menu.BackgroundColor3 = Color3.fromRGB(45,45,45)
                menu.Parent = gui

                local camBtn = Instance.new("TextButton")
                camBtn.Size = UDim2.new(1, 0, 0.33, 0)
                camBtn.Text = "Ver Câmera"
                camBtn.Parent = menu

                local noclipBtn = Instance.new("TextButton")
                noclipBtn.Size = UDim2.new(1, 0, 0.33, 0)
                noclipBtn.Position = UDim2.new(0, 0, 0.33, 0)
                noclipBtn.Text = "Noclip + TP"
                noclipBtn.Parent = menu

                local espBtn = Instance.new("TextButton")
                espBtn.Size = UDim2.new(1, 0, 0.33, 0)
                espBtn.Position = UDim2.new(0, 0, 0.66, 0)
                espBtn.Text = "ESP Apenas"
                espBtn.Parent = menu

                camBtn.MouseButton1Click:Connect(function()
                    viewCamera(p)
                end)

                noclipBtn.MouseButton1Click:Connect(function()
                    noclipToPlayer(p)
                end)

                espBtn.MouseButton1Click:Connect(function()
                    toggleSingleESP(p)
                end)

                task.delay(3, function()
                    if menu then menu:Destroy() end
                end)
            end)
        end
    end
end

-- Atualiza lista sempre que entra ou sai jogador
Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)
updatePlayerList()

-- Botão flutuante alternativo com toggle
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 40, 0, 40)
toggleButton.Position = UDim2.new(0, 10, 0, 10)
toggleButton.Text = "👁"
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleButton.TextColor3 = Color3.new(1,1,1)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextScaled = true
toggleButton.Draggable = true
toggleButton.Active = true
toggleButton.Parent = gui

local debounce = false
toggleButton.MouseButton1Click:Connect(function()
    if debounce then return end
    debounce = true
    toggleESP()
    toggleButton.BackgroundColor3 = ESPEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    task.wait(0.3)
    debounce = false
end)

-- Atualiza ESP para novos jogadores/respawns
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if ESPEnabled then
            if not ActiveESPPlayer or ActiveESPPlayer == player then
                createESP(player)
            end
        end
    end)
end)

for _, player in pairs(Players:GetPlayers()) do
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if ESPEnabled then
            if not ActiveESPPlayer or ActiveESPPlayer == player then
                createESP(player)
            end
        end
    end)
end
