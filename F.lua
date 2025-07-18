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
local UserInputService = game:GetService("UserInputService")

-- VARIÁVEIS DO ESP
local ESP_ENABLED = true
local ESP_COLOR = Color3.fromRGB(0,255,255)
local OUTLINE_COLOR = Color3.fromRGB(255,255,0)
local FILL_TRANSPARENCY = 0.7
local OUTLINE_TRANSPARENCY = 0
local MAX_DISTANCE = math.huge
local FONTE_PEQUENA = 13
local ESPObjects = {}
local TARGET_PLAYER = nil
local TARGET_ONLY = false

-- VARIÁVEIS DE FUNÇÕES EXTRAS
local noclipActive = false
local walkspeed = 16
local jumppower = 50

-- TELA DE CARREGAMENTO
local function showLoadingScreen()
    local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    gui.Name = "ESPLoading"
    local frame = Instance.new("Frame", gui)
    frame.AnchorPoint = Vector2.new(0.5,0.5)
    frame.Position = UDim2.new(0.5,0,0.5,0)
    frame.Size = UDim2.new(0,200,0,50)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,35)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(0,255,255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 20
    label.Text = "Script carregando"
    label.TextStrokeTransparency = 0.8
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
    billboard.Size = UDim2.new(0, 150, 0, 18)
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

local function removeESP(char)
    if ESPObjects[char] then
        pcall(function() ESPObjects[char].Highlight:Destroy() end)
        pcall(function() ESPObjects[char].Billboard:Destroy() end)
        ESPObjects[char] = nil
    end
end

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

-- Drag universal
local function makeDraggable(frame, dragBar)
    local dragging = false
    local dragStart = Vector2.new(0, 0)
    local startPos = UDim2.new()

    local target = dragBar or frame

    target.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if conn then conn:Disconnect() end
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Noclip
local function toggleNoclip(state)
    noclipActive = state
end
RunService.Stepped:Connect(function()
    if noclipActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        for _,part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- Speed e JumpPower (aplicação automática)
local function applyStats()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        hum.WalkSpeed = walkspeed
        hum.JumpPower = jumppower
    end
end
LocalPlayer.CharacterAdded:Connect(function()
    wait(0.1)
    applyStats()
end)
RunService.RenderStepped:Connect(function()
    applyStats()
end)

-- MENU POLIDO COM BOTÃO FLUTUANTE
local function setupMenu()
    local gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    gui.Name = "ESPMenu"
    gui.ResetOnSpawn = false

    -- Ícone de olho unicode
    local eyeIcon = "👁"

    -- Botão flutuante
    local floatBtn = Instance.new("TextButton")
    floatBtn.Name = "FloatButton"
    floatBtn.Size = UDim2.new(0,40,0,40)
    floatBtn.Position = UDim2.new(0,8,0.35,0)
    floatBtn.BackgroundColor3 = ESP_COLOR
    floatBtn.Text = eyeIcon
    floatBtn.Font = Enum.Font.GothamBlack
    floatBtn.TextSize = 26
    floatBtn.TextColor3 = Color3.new(1,1,1)
    floatBtn.BorderSizePixel = 0
    floatBtn.AutoButtonColor = true
    floatBtn.Parent = gui

    makeDraggable(floatBtn)

    -- MENU PRINCIPAL (painel reduzido para tela de celular)
    local menu = Instance.new("Frame", gui)
    menu.Name = "MenuFrame"
    menu.Size = UDim2.new(0,210,0,220)
    menu.Position = UDim2.new(0,55,0.35,0)
    menu.BackgroundColor3 = Color3.fromRGB(24,24,28)
    menu.BorderSizePixel = 0
    menu.Visible = false
    menu.AnchorPoint = Vector2.new(0,0.5)
    menu.BackgroundTransparency = 0.05

    -- Drag apenas pela barra do título
    local dragBar = Instance.new("Frame", menu)
    dragBar.Size = UDim2.new(1,0,0,34)
    dragBar.BackgroundTransparency = 1
    dragBar.Name = "DragBar"
    makeDraggable(menu, dragBar)

    -- Fechar menu
    local closeBtn = Instance.new("TextButton", menu)
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.GothamBlack
    closeBtn.TextSize = 17
    closeBtn.Size = UDim2.new(0,28,0,28)
    closeBtn.Position = UDim2.new(1,-30,0,3)
    closeBtn.BackgroundColor3 = Color3.fromRGB(32,32,32)
    closeBtn.TextColor3 = Color3.fromRGB(255,90,90)
    closeBtn.BorderSizePixel = 0

    closeBtn.MouseButton1Click:Connect(function() menu.Visible = false end)
    floatBtn.MouseButton1Click:Connect(function() menu.Visible = not menu.Visible end)

    -- Título
    local title = Instance.new("TextLabel", menu)
    title.Size = UDim2.new(0.8,0,0,34)
    title.Position = UDim2.new(0,5,0,0)
    title.Text = "ESP Menu"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = ESP_COLOR
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Name = "MenuTitle"
    title.Parent = dragBar

    -- Ativar/desativar ESP
    local toggleBtn = Instance.new("TextButton", menu)
    toggleBtn.Size = UDim2.new(0.93,0,0,30)
    toggleBtn.Position = UDim2.new(0.035,0,0,40)
    toggleBtn.Text = "ESP: ON"
    toggleBtn.Font = Enum.Font.Gotham
    toggleBtn.TextSize = 15
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
    playerCount.Size = UDim2.new(0.93,0,0,20)
    playerCount.Position = UDim2.new(0.035,0,0,75)
    playerCount.Text = "Jogadores: " .. tostring(#Players:GetPlayers())
    playerCount.Font = Enum.Font.Gotham
    playerCount.TextSize = 13
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
    corLabel.Size = UDim2.new(0.55,0,0,20)
    corLabel.Position = UDim2.new(0.035,0,0,104)
    corLabel.BackgroundTransparency = 1
    corLabel.TextColor3 = Color3.fromRGB(255,255,255)
    corLabel.Font = Enum.Font.Gotham
    corLabel.TextSize = 12

    local colorPicker = Instance.new("TextBox", menu)
    colorPicker.Size = UDim2.new(0.35,0,0,20)
    colorPicker.Position = UDim2.new(0.62,0,0,104)
    colorPicker.Text = "0,255,255"
    colorPicker.Font = Enum.Font.Gotham
    colorPicker.TextSize = 12
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
    distLabel.Text = "Distância Máx:"
    distLabel.Size = UDim2.new(0.55,0,0,20)
    distLabel.Position = UDim2.new(0.035,0,0,130)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.fromRGB(255,255,255)
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = 12

    local distBox = Instance.new("TextBox", menu)
    distBox.Size = UDim2.new(0.35,0,0,20)
    distBox.Position = UDim2.new(0.62,0,0,130)
    distBox.Text = tostring(MAX_DISTANCE == math.huge and "inf" or MAX_DISTANCE)
    distBox.Font = Enum.Font.Gotham
    distBox.TextSize = 12
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

    -- Botão para abrir painel de jogadores
    local playerPanelBtn = Instance.new("TextButton", menu)
    playerPanelBtn.Text = "Selecionar Jogador"
    playerPanelBtn.Size = UDim2.new(0.93,0,0,24)
    playerPanelBtn.Position = UDim2.new(0.035,0,0,160)
    playerPanelBtn.Font = Enum.Font.Gotham
    playerPanelBtn.TextSize = 13
    playerPanelBtn.BackgroundColor3 = Color3.fromRGB(30,44,60)
    playerPanelBtn.TextColor3 = Color3.fromRGB(200,225,255)
    playerPanelBtn.BorderSizePixel = 0

    -- Botão: MAIS (abre painel de funções extras)
    local moreBtn = Instance.new("TextButton", menu)
    moreBtn.Text = "Mais"
    moreBtn.Size = UDim2.new(0.93,0,0,22)
    moreBtn.Position = UDim2.new(0.035,0,1,-26)
    moreBtn.Font = Enum.Font.Gotham
    moreBtn.TextSize = 13
    moreBtn.BackgroundColor3 = Color3.fromRGB(34,34,54)
    moreBtn.TextColor3 = Color3.fromRGB(215,215,255)
    moreBtn.BorderSizePixel = 0

    -- Botão: resetar alvo
    local resetTargetBtn = Instance.new("TextButton", menu)
    resetTargetBtn.Text = "ESP em todos"
    resetTargetBtn.Size = UDim2.new(0.45,0,0,22)
    resetTargetBtn.Position = UDim2.new(0.035,0,1,-54)
    resetTargetBtn.Font = Enum.Font.Gotham
    resetTargetBtn.TextSize = 12
    resetTargetBtn.BackgroundColor3 = Color3.fromRGB(33,44,33)
    resetTargetBtn.TextColor3 = Color3.fromRGB(180,255,180)
    resetTargetBtn.BorderSizePixel = 0
    resetTargetBtn.MouseButton1Click:Connect(function()
        TARGET_ONLY = false
        TARGET_PLAYER = nil
        updateAllESP()
    end)

    -- Botão: seguir câmera do alvo
    local cameraBtn = Instance.new("TextButton", menu)
    cameraBtn.Text = "Seguir câmera"
    cameraBtn.Size = UDim2.new(0.45,0,0,22)
    cameraBtn.Position = UDim2.new(0.52,0,1,-54)
    cameraBtn.Font = Enum.Font.Gotham
    cameraBtn.TextSize = 12
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

    -- PAINEL DE JOGADORES (separado)
    local playerPanel = Instance.new("Frame", gui)
    playerPanel.Name = "PlayerPanel"
    playerPanel.Visible = false
    playerPanel.Size = UDim2.new(0,180,0,200)
    playerPanel.Position = UDim2.new(0,menu.Position.X.Offset+220,0,menu.Position.Y.Offset-50)
    playerPanel.BackgroundColor3 = Color3.fromRGB(28,28,38)
    playerPanel.BackgroundTransparency = 0.09
    playerPanel.BorderSizePixel = 0
    playerPanel.AnchorPoint = Vector2.new(0,0)
    playerPanel.ZIndex = 5

    -- Drag do painel de jogadores por barra superior
    local playerPanelDragBar = Instance.new("Frame", playerPanel)
    playerPanelDragBar.Size = UDim2.new(1,0,0,28)
    playerPanelDragBar.Position = UDim2.new(0,0,0,0)
    playerPanelDragBar.BackgroundTransparency = 1
    playerPanelDragBar.Name = "PlayerPanelDragBar"
    makeDraggable(playerPanel, playerPanelDragBar)

    local playerPanelTitle = Instance.new("TextLabel", playerPanelDragBar)
    playerPanelTitle.Size = UDim2.new(1,-28,1,0)
    playerPanelTitle.Position = UDim2.new(0,4,0,0)
    playerPanelTitle.Text = "Jogadores"
    playerPanelTitle.BackgroundTransparency = 1
    playerPanelTitle.Font = Enum.Font.GothamBold
    playerPanelTitle.TextSize = 15
    playerPanelTitle.TextXAlignment = Enum.TextXAlignment.Left
    playerPanelTitle.TextColor3 = ESP_COLOR

    local closePlayerPanelBtn = Instance.new("TextButton", playerPanelDragBar)
    closePlayerPanelBtn.Text = "✕"
    closePlayerPanelBtn.Font = Enum.Font.GothamBlack
    closePlayerPanelBtn.TextSize = 15
    closePlayerPanelBtn.Size = UDim2.new(0,24,1,0)
    closePlayerPanelBtn.Position = UDim2.new(1,-26,0,2)
    closePlayerPanelBtn.BackgroundColor3 = Color3.fromRGB(32,32,32)
    closePlayerPanelBtn.TextColor3 = Color3.fromRGB(255,90,90)
    closePlayerPanelBtn.BorderSizePixel = 0

    closePlayerPanelBtn.MouseButton1Click:Connect(function() playerPanel.Visible = false end)

    local playerList = Instance.new("ScrollingFrame", playerPanel)
    playerList.Size = UDim2.new(1, -10, 1, -36)
    playerList.Position = UDim2.new(0,5,0,32)
    playerList.BackgroundTransparency = 0.1
    playerList.BackgroundColor3 = Color3.fromRGB(30,30,36)
    playerList.BorderSizePixel = 0
    playerList.ScrollBarThickness = 6
    playerList.CanvasSize = UDim2.new(0,0,0,0)
    playerList.ZIndex = 6

    local function refreshPlayerList()
        playerList:ClearAllChildren()
        local y = 0
        local playersArr = Players:GetPlayers()
        for i,player in ipairs(playersArr) do
            local item = Instance.new("TextButton", playerList)
            item.Size = UDim2.new(1,0,0,22)
            item.Position = UDim2.new(0,0,0,y)
            item.BackgroundColor3 = (player == TARGET_PLAYER) and Color3.fromRGB(44,200,80) or Color3.fromRGB(38,38,40)
            item.Font = Enum.Font.Gotham
            item.TextSize = 12
            item.TextColor3 = Color3.fromRGB(200,255,255)
            item.Text = string.format("%s  [%s]", player.DisplayName, player.Name)
            item.TextXAlignment = Enum.TextXAlignment.Left
            item.BorderSizePixel = 0
            item.Name = player.Name
            item.ZIndex = 7
            item.MouseButton1Click:Connect(function()
                TARGET_PLAYER = player
                TARGET_ONLY = true
                refreshPlayerList()
                playerPanel.Visible = false
                updateAllESP()
            end)
            y = y + 22
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

    playerPanelBtn.MouseButton1Click:Connect(function()
        playerPanel.Visible = not playerPanel.Visible
        if playerPanel.Visible then
            refreshPlayerList()
        end
    end)

    -- PAINEL DE FUNÇÕES EXTRAS
    local morePanel = Instance.new("Frame", gui)
    morePanel.Name = "MorePanel"
    morePanel.Visible = false
    morePanel.Size = UDim2.new(0,180,0,170)
    morePanel.Position = UDim2.new(0,menu.Position.X.Offset+220,0,menu.Position.Y.Offset+20)
    morePanel.BackgroundColor3 = Color3.fromRGB(28,28,38)
    morePanel.BackgroundTransparency = 0.09
    morePanel.BorderSizePixel = 0
    morePanel.AnchorPoint = Vector2.new(0,0)
    morePanel.ZIndex = 6

    local moreDragBar = Instance.new("Frame", morePanel)
    moreDragBar.Size = UDim2.new(1,0,0,28)
    moreDragBar.Position = UDim2.new(0,0,0,0)
    moreDragBar.BackgroundTransparency = 1
    moreDragBar.Name = "MorePanelDragBar"
    makeDraggable(morePanel, moreDragBar)

    local moreTitle = Instance.new("TextLabel", moreDragBar)
    moreTitle.Size = UDim2.new(1,-28,1,0)
    moreTitle.Position = UDim2.new(0,4,0,0)
    moreTitle.Text = "Funções Extras"
    moreTitle.BackgroundTransparency = 1
    moreTitle.Font = Enum.Font.GothamBold
    moreTitle.TextSize = 15
    moreTitle.TextXAlignment = Enum.TextXAlignment.Left
    moreTitle.TextColor3 = ESP_COLOR

    local closeMorePanelBtn = Instance.new("TextButton", moreDragBar)
    closeMorePanelBtn.Text = "✕"
    closeMorePanelBtn.Font = Enum.Font.GothamBlack
    closeMorePanelBtn.TextSize = 15
    closeMorePanelBtn.Size = UDim2.new(0,24,1,0)
    closeMorePanelBtn.Position = UDim2.new(1,-26,0,2)
    closeMorePanelBtn.BackgroundColor3 = Color3.fromRGB(32,32,32)
    closeMorePanelBtn.TextColor3 = Color3.fromRGB(255,90,90)
    closeMorePanelBtn.BorderSizePixel = 0
    closeMorePanelBtn.MouseButton1Click:Connect(function() morePanel.Visible = false end)

    -- Noclip toggle
    local noclipBtn = Instance.new("TextButton", morePanel)
    noclipBtn.Text = "Noclip: OFF"
    noclipBtn.Size = UDim2.new(0.9,0,0,28)
    noclipBtn.Position = UDim2.new(0.05,0,0,36)
    noclipBtn.Font = Enum.Font.Gotham
    noclipBtn.TextSize = 13
    noclipBtn.BackgroundColor3 = Color3.fromRGB(40,40,44)
    noclipBtn.TextColor3 = Color3.fromRGB(200,255,255)
    noclipBtn.BorderSizePixel = 0

    noclipBtn.MouseButton1Click:Connect(function()
        noclipActive = not noclipActive
        noclipBtn.Text = "Noclip: " .. (noclipActive and "ON" or "OFF")
        noclipBtn.TextColor3 = noclipActive and Color3.fromRGB(100,255,100) or Color3.fromRGB(200,255,255)
    end)

    -- WalkSpeed (slider vertical fake)
    local wsLabel = Instance.new("TextLabel", morePanel)
    wsLabel.Text = "Velocidade"
    wsLabel.Size = UDim2.new(0.5,0,0,18)
    wsLabel.Position = UDim2.new(0.05,0,0,74)
    wsLabel.BackgroundTransparency = 1
    wsLabel.TextColor3 = Color3.fromRGB(255,255,255)
    wsLabel.Font = Enum.Font.Gotham
    wsLabel.TextSize = 12
    wsLabel.TextXAlignment = Enum.TextXAlignment.Left

    local wsBox = Instance.new("TextBox", morePanel)
    wsBox.Size = UDim2.new(0.35,0,0,18)
    wsBox.Position = UDim2.new(0.57,0,0,74)
    wsBox.Text = tostring(walkspeed)
    wsBox.Font = Enum.Font.Gotham
    wsBox.TextSize = 12
    wsBox.BackgroundColor3 = Color3.fromRGB(20,20,20)
    wsBox.TextColor3 = Color3.fromRGB(255,255,255)
    wsBox.BorderSizePixel = 0
    wsBox.ClearTextOnFocus = false

    wsBox.FocusLost:Connect(function()
        local val = tonumber(wsBox.Text)
        if val and val >= 1 and val <= 200 then
            walkspeed = val
        else
            wsBox.Text = tostring(walkspeed)
        end
    end)

    -- JumpPower (slider vertical fake)
    local jpLabel = Instance.new("TextLabel", morePanel)
    jpLabel.Text = "Pulo"
    jpLabel.Size = UDim2.new(0.5,0,0,18)
    jpLabel.Position = UDim2.new(0.05,0,0,104)
    jpLabel.BackgroundTransparency = 1
    jpLabel.TextColor3 = Color3.fromRGB(255,255,255)
    jpLabel.Font = Enum.Font.Gotham
    jpLabel.TextSize = 12
    jpLabel.TextXAlignment = Enum.TextXAlignment.Left

    local jpBox = Instance.new("TextBox", morePanel)
    jpBox.Size = UDim2.new(0.35,0,0,18)
    jpBox.Position = UDim2.new(0.57,0,0,104)
    jpBox.Text = tostring(jumppower)
    jpBox.Font = Enum.Font.Gotham
    jpBox.TextSize = 12
    jpBox.BackgroundColor3 = Color3.fromRGB(20,20,20)
    jpBox.TextColor3 = Color3.fromRGB(255,255,255)
    jpBox.BorderSizePixel = 0
    jpBox.ClearTextOnFocus = false

    jpBox.FocusLost:Connect(function()
        local val = tonumber(jpBox.Text)
        if val and val >= 1 and val <= 500 then
            jumppower = val
        else
            jpBox.Text = tostring(jumppower)
        end
    end)

    -- Botão para abrir painel de funções extras
    moreBtn.MouseButton1Click:Connect(function()
        morePanel.Visible = not morePanel.Visible
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
