--[[ 
  ESP Avançado para Roblox (Lua)
  Feito por Copilot - Para uso em jogos próprios/autorizados
--]]

-- CONFIGURAÇÕES INICIAIS
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

-- VARIÁVEIS DO ESP
local ESP_ENABLED = true
local ESP_COLOR = Color3.fromRGB(0,255,255)
local OUTLINE_COLOR = Color3.fromRGB(255,255,0)
local FILL_TRANSPARENCY = 0.7
local OUTLINE_TRANSPARENCY = 0
local MAX_DISTANCE = math.huge -- Agora sem limite por padrão (pode ser ajustado no menu)
local FONTE_PEQUENA = 13
local ESPObjects = {}
local TARGET_PLAYER = nil
local TARGET_ONLY = false

-- TELA DE CARREGAMENTO
local function showLoadingScreen()
    local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    gui.Name = "ESPLoading"
    local frame = Instance.new("Frame", gui)
    frame.AnchorPoint = Vector2.new(0.5,0.5)
    frame.Position = UDim2.new(0.5,0,0.5,0)
    frame.Size = UDim2.new(0,240,0,60)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,35)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(0,255,255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 22
    label.Text = "Script carregando"
    label.TextStrokeTransparency = 0.8
    -- Animação de "..."
    coroutine.wrap(function()
        while gui.Parent do
            for i=1,3 do
                label.Text = "Script carregando" .. string.rep(".", i)
                wait(0.3)
            end
        end
    end)()
    wait(2)
    label.Text = "Script carregado!"
    label.TextColor3 = Color3.fromRGB(60,255,80)
    -- Fade out
    TweenService:Create(frame, TweenInfo.new(1), {BackgroundTransparency=1}):Play()
    TweenService:Create(label, TweenInfo.new(1), {TextTransparency=1}):Play()
    wait(1.1)
    gui:Destroy()
end

-- CRIAÇÃO DE HIGHLIGHT
local function createHighlight(char)
    local highlight = Instance.new("Highlight")
    highlight.Adornee = char
    highlight.FillColor = ESP_COLOR
    highlight.OutlineColor = OUTLINE_COLOR
    highlight.FillTransparency = FILL_TRANSPARENCY
    highlight.OutlineTransparency = OUTLINE_TRANSPARENCY
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char
    return highlight
end

local function createBillboard(target, name, distance)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPBillboard"
    billboard.Adornee = target
    billboard.Size = UDim2.new(0, 170, 0, 20)
    billboard.StudsOffset = Vector3.new(0, 3.3, 0)
    billboard.AlwaysOnTop = true

    local text = Instance.new("TextLabel", billboard)
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextStrokeTransparency = 0.4
    text.TextColor3 = ESP_COLOR
    text.Font = Enum.Font.Gotham
    text.TextScaled = false
    text.TextSize = FONTE_PEQUENA
    text.Text = string.format("%s | %.1fm", name, distance/3.571)
    text.TextXAlignment = Enum.TextXAlignment.Center
    text.TextYAlignment = Enum.TextYAlignment.Center

    return billboard
end

-- REMOVE ESP
local function removeESP(char)
    if ESPObjects[char] then
        pcall(function() ESPObjects[char].Highlight:Destroy() end)
        pcall(function() ESPObjects[char].Billboard:Destroy() end)
        ESPObjects[char] = nil
    end
end

-- ATUALIZA ESP PARA UM JOGADOR
local function updateESP(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then removeESP(char) return end

    if TARGET_ONLY and player ~= TARGET_PLAYER then removeESP(char) return end

    local distance = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
        and (char.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        or math.huge
    if distance > MAX_DISTANCE then removeESP(char) return end

    if not ESPObjects[char] then ESPObjects[char] = {} end

    if not ESPObjects[char].Highlight or ESPObjects[char].Highlight.Parent ~= char then
        ESPObjects[char].Highlight = createHighlight(char)
    else
        ESPObjects[char].Highlight.FillColor = ESP_COLOR
    end

    if ESPObjects[char].Billboard then ESPObjects[char].Billboard:Destroy() end
    ESPObjects[char].Billboard = createBillboard(char:FindFirstChild("Head") or char.HumanoidRootPart, player.DisplayName, distance)
    ESPObjects[char].Billboard.Parent = char
end

local function updateAllESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if ESP_ENABLED then
            updateESP(player)
        else
            if player.Character then removeESP(player.Character) end
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    if player.Character then removeESP(player.Character) end
end)
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(0.1)
        updateESP(player)
    end)
end)

-- MENU POLIDO COM BOTÃO FLUTUANTE
local function setupMenu()
    local gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    gui.Name = "ESPMenu"
    gui.ResetOnSpawn = false

    -- Botão flutuante
    local floatBtn = Instance.new("TextButton")
    floatBtn.Name = "FloatButton"
    floatBtn.Size = UDim2.new(0,42,0,42)
    floatBtn.Position = UDim2.new(0,11,0.37,0)
    floatBtn.BackgroundColor3 = ESP_COLOR
    floatBtn.Text = "☰"
    floatBtn.Font = Enum.Font.GothamBlack
    floatBtn.TextSize = 25
    floatBtn.TextColor3 = Color3.new(1,1,1)
    floatBtn.BorderSizePixel = 0
    floatBtn.AutoButtonColor = true
    floatBtn.Parent = gui

    -- Drag do botão flutuante
    local dragging, dragInput, dragStart, startPos
    floatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = floatBtn.Position
        end
    end)
    floatBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            floatBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    floatBtn.MouseButton1Up:Connect(function() dragging = false end)

    -- MENU PRINCIPAL
    local menu = Instance.new("Frame", gui)
    menu.Name = "MenuFrame"
    menu.Size = UDim2.new(0,340,0,410)
    menu.Position = UDim2.new(0,60,0.35,0)
    menu.BackgroundColor3 = Color3.fromRGB(24,24,28)
    menu.BorderSizePixel = 0
    menu.Visible = false
    menu.AnchorPoint = Vector2.new(0,0.5)
    menu.BackgroundTransparency = 0.05

    -- Drag do painel principal (menu)
    local draggingPanel, dragInputPanel, dragStartPanel, startPosPanel
    menu.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingPanel = true
            dragStartPanel = input.Position
            startPosPanel = menu.Position
        end
    end)
    menu.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInputPanel = input
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInputPanel and draggingPanel then
            local delta = input.Position - dragStartPanel
            menu.Position = UDim2.new(startPosPanel.X.Scale, startPosPanel.X.Offset + delta.X, startPosPanel.Y.Scale, startPosPanel.Y.Offset + delta.Y)
        end
    end)
    menu.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingPanel = false
        end
    end)

    -- Fechar menu
    local closeBtn = Instance.new("TextButton", menu)
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.GothamBlack
    closeBtn.TextSize = 19
    closeBtn.Size = UDim2.new(0,30,0,30)
    closeBtn.Position = UDim2.new(1,-34,0,4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(32,32,32)
    closeBtn.TextColor3 = Color3.fromRGB(255,90,90)
    closeBtn.BorderSizePixel = 0

    closeBtn.MouseButton1Click:Connect(function() menu.Visible = false end)
    floatBtn.MouseButton1Click:Connect(function() menu.Visible = not menu.Visible end)

    -- Título
    local title = Instance.new("TextLabel", menu)
    title.Size = UDim2.new(1,0,0,38)
    title.Position = UDim2.new(0,0,0,0)
    title.Text = "ESP Menu"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 21
    title.TextColor3 = ESP_COLOR
    title.BackgroundTransparency = 1

    -- Ativar/desativar ESP
    local toggleBtn = Instance.new("TextButton", menu)
    toggleBtn.Size = UDim2.new(0.5,-10,0,34)
    toggleBtn.Position = UDim2.new(0,10,0,50)
    toggleBtn.Text = "ESP: ON"
    toggleBtn.Font = Enum.Font.Gotham
    toggleBtn.TextSize = 17
    toggleBtn.BackgroundColor3 = Color3.fromRGB(40,40,44)
    toggleBtn.TextColor3 = ESP_COLOR
    toggleBtn.BorderSizePixel = 0

    toggleBtn.MouseButton1Click:Connect(function()
        ESP_ENABLED = not ESP_ENABLED
        toggleBtn.Text = "ESP: " .. (ESP_ENABLED and "ON" or "OFF")
        toggleBtn.TextColor3 = ESP_ENABLED and ESP_COLOR or Color3.fromRGB(255,60,60)
        updateAllESP()
    end)

    -- Contador de jogadores
    local playerCount = Instance.new("TextLabel", menu)
    playerCount.Size = UDim2.new(0.5,-10,0,34)
    playerCount.Position = UDim2.new(0.5,10,0,50)
    playerCount.Text = "Jogadores: " .. tostring(#Players:GetPlayers())
    playerCount.Font = Enum.Font.Gotham
    playerCount.TextSize = 15
    playerCount.BackgroundTransparency = 1
    playerCount.TextColor3 = Color3.fromRGB(255,255,255)
    playerCount.TextXAlignment = Enum.TextXAlignment.Left

    Players.PlayerAdded:Connect(function()
        playerCount.Text = "Jogadores: " .. tostring(#Players:GetPlayers())
    end)
    Players.PlayerRemoving:Connect(function()
        playerCount.Text = "Jogadores: " .. tostring(#Players:GetPlayers())
    end)

    -- Alterar cor do highlight
    local corLabel = Instance.new("TextLabel", menu)
    corLabel.Text = "Cor do Highlight:"
    corLabel.Size = UDim2.new(0.5,-10,0,24)
    corLabel.Position = UDim2.new(0,10,0,95)
    corLabel.BackgroundTransparency = 1
    corLabel.TextColor3 = Color3.fromRGB(255,255,255)
    corLabel.Font = Enum.Font.Gotham
    corLabel.TextSize = 14

    local colorPicker = Instance.new("TextBox", menu)
    colorPicker.Size = UDim2.new(0.25,0,0,24)
    colorPicker.Position = UDim2.new(0.45,10,0,95)
    colorPicker.Text = "0,255,255"
    colorPicker.Font = Enum.Font.Gotham
    colorPicker.TextSize = 14
    colorPicker.BackgroundColor3 = Color3.fromRGB(20,20,20)
    colorPicker.TextColor3 = ESP_COLOR
    colorPicker.BorderSizePixel = 0
    colorPicker.ClearTextOnFocus = false

    colorPicker.FocusLost:Connect(function()
        local r,g,b = colorPicker.Text:match("(%d+),%s*(%d+),%s*(%d+)")
        if r and g and b then
            ESP_COLOR = Color3.fromRGB(tonumber(r),tonumber(g),tonumber(b))
            floatBtn.BackgroundColor3 = ESP_COLOR
            title.TextColor3 = ESP_COLOR
            toggleBtn.TextColor3 = ESP_ENABLED and ESP_COLOR or Color3.fromRGB(255,60,60)
            updateAllESP()
        end
    end)

    -- Campo de ajuste de distância máxima
    local distLabel = Instance.new("TextLabel", menu)
    distLabel.Text = "Distância Máxima (Studs):"
    distLabel.Size = UDim2.new(0.5,-10,0,24)
    distLabel.Position = UDim2.new(0,10,0,120)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.fromRGB(255,255,255)
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = 14

    local distBox = Instance.new("TextBox", menu)
    distBox.Size = UDim2.new(0.25,0,0,24)
    distBox.Position = UDim2.new(0.45,10,0,120)
    distBox.Text = tostring(MAX_DISTANCE == math.huge and "inf" or MAX_DISTANCE)
    distBox.Font = Enum.Font.Gotham
    distBox.TextSize = 14
    distBox.BackgroundColor3 = Color3.fromRGB(20,20,20)
    distBox.TextColor3 = Color3.fromRGB(255,255,255)
    distBox.BorderSizePixel = 0
    distBox.ClearTextOnFocus = false

    distBox.FocusLost:Connect(function()
        if distBox.Text:lower() == "inf" then
            MAX_DISTANCE = math.huge
        else
            local val = tonumber(distBox.Text)
            if val and val > 0 then
                MAX_DISTANCE = val
            end
        end
        updateAllESP()
    end)

    -- Lista de jogadores
    local listLabel = Instance.new("TextLabel", menu)
    listLabel.Text = "Jogadores:"
    listLabel.Size = UDim2.new(1, -20, 0, 22)
    listLabel.Position = UDim2.new(0,10,0,155)
    listLabel.BackgroundTransparency = 1
    listLabel.TextColor3 = Color3.fromRGB(255,255,255)
    listLabel.Font = Enum.Font.Gotham
    listLabel.TextSize = 15
    listLabel.TextXAlignment = Enum.TextXAlignment.Left

    local playerList = Instance.new("ScrollingFrame", menu)
    playerList.Size = UDim2.new(1, -20, 0, 140)
    playerList.Position = UDim2.new(0,10,0,177)
    playerList.BackgroundTransparency = 0.1
    playerList.BackgroundColor3 = Color3.fromRGB(30,30,36)
    playerList.BorderSizePixel = 0
    playerList.ScrollBarThickness = 6
    playerList.CanvasSize = UDim2.new(0,0,0,0)

    local function refreshPlayerList()
        playerList:ClearAllChildren()
        local y = 0
        local playersArr = Players:GetPlayers()
        for i,player in ipairs(playersArr) do
            local item = Instance.new("TextButton", playerList)
            item.Size = UDim2.new(1,0,0,27)
            item.Position = UDim2.new(0,0,0,y)
            item.BackgroundColor3 = (player == TARGET_PLAYER) and Color3.fromRGB(44,200,80) or Color3.fromRGB(38,38,40)
            item.Font = Enum.Font.Gotham
            item.TextSize = 14
            item.TextColor3 = Color3.fromRGB(200,255,255)
            item.Text = string.format("%s  [%s]", player.DisplayName, player.Name)
            item.TextXAlignment = Enum.TextXAlignment.Left
            item.BorderSizePixel = 0
            item.Name = player.Name

            item.MouseButton1Click:Connect(function()
                TARGET_PLAYER = player
                TARGET_ONLY = true
                refreshPlayerList()
            end)
            y = y + 27
        end
        playerList.CanvasSize = UDim2.new(0,0,0,y)
    end
    refreshPlayerList()
    Players.PlayerAdded:Connect(refreshPlayerList)
    Players.PlayerRemoving:Connect(function()
        if TARGET_PLAYER and not Players:FindFirstChild(TARGET_PLAYER.Name) then
            TARGET_PLAYER = nil
            TARGET_ONLY = false
        end
        refreshPlayerList()
    end)

    -- Botão: resetar alvo
    local resetTargetBtn = Instance.new("TextButton", menu)
    resetTargetBtn.Text = "ESP em todos"
    resetTargetBtn.Size = UDim2.new(0.5,-10,0,28)
    resetTargetBtn.Position = UDim2.new(0,10,1,-38)
    resetTargetBtn.Font = Enum.Font.Gotham
    resetTargetBtn.TextSize = 14
    resetTargetBtn.BackgroundColor3 = Color3.fromRGB(33,44,33)
    resetTargetBtn.TextColor3 = Color3.fromRGB(180,255,180)
    resetTargetBtn.BorderSizePixel = 0
    resetTargetBtn.MouseButton1Click:Connect(function()
        TARGET_ONLY = false
        TARGET_PLAYER = nil
        refreshPlayerList()
        updateAllESP()
    end)

    -- Botão: seguir câmera do alvo
    local cameraBtn = Instance.new("TextButton", menu)
    cameraBtn.Text = "Seguir câmera do alvo"
    cameraBtn.Size = UDim2.new(0.5,-10,0,28)
    cameraBtn.Position = UDim2.new(0.5,10,1,-38)
    cameraBtn.Font = Enum.Font.Gotham
    cameraBtn.TextSize = 14
    cameraBtn.BackgroundColor3 = Color3.fromRGB(30,44,60)
    cameraBtn.TextColor3 = Color3.fromRGB(200,225,255)
    cameraBtn.BorderSizePixel = 0
    local following = false
    cameraBtn.MouseButton1Click:Connect(function()
        if TARGET_PLAYER and TARGET_PLAYER.Character and TARGET_PLAYER.Character:FindFirstChild("HumanoidRootPart") then
            following = not following
            cameraBtn.TextColor3 = following and Color3.fromRGB(60,255,255) or Color3.fromRGB(200,225,255)
        end
    end)
    RunService.RenderStepped:Connect(function()
        if following and TARGET_PLAYER and TARGET_PLAYER.Character and TARGET_PLAYER.Character:FindFirstChild("HumanoidRootPart") then
            Camera.CameraSubject = TARGET_PLAYER.Character.HumanoidRootPart
        else
            Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") or Camera.CameraSubject
        end
    end)
end

coroutine.wrap(showLoadingScreen)()
wait(2.7)
setupMenu()
RunService.RenderStepped:Connect(function()
    if ESP_ENABLED then
        updateAllESP()
    else
        for _,player in ipairs(Players:GetPlayers()) do
            if player.Character then removeESP(player.Character) end
        end
    end
end)
