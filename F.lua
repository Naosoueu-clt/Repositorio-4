--[[ 
  ESP Avançado para Roblox (Lua) - Repaginado e Revisado
  Feito por Copilot - Para uso em jogos próprios/autorizados
  Atualização: Câmera ESP robusta, calculadora aprimorada, frases dinâmicas com nomes de jogadores.
--]]

-- SERVIÇOS E VARIÁVEIS INICIAIS
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

-- ESP VARS
local ESP_ENABLED = false -- ESP agora inicia desligado
local ESP_COLOR = Color3.fromRGB(0,255,255)
local OUTLINE_COLOR = Color3.fromRGB(255,255,0)
local FILL_TRANSPARENCY = 0.7
local OUTLINE_TRANSPARENCY = 0
local MAX_DISTANCE = math.huge
local FONTE_PEQUENA = 13
local ESPObjects = {}
local TARGET_PLAYER = nil
local TARGET_ONLY = false

-- JOGADOR VARS
local noclipActive = false
local walkspeed = 16
local jumppower = 50
local CAMERA_FIRST_PERSON = false
local CAMERA_LOCKED = false
local DEFAULT_WALKSPEED = 16
local DEFAULT_JUMPPOWER = 50

-- UTILS
local function makeDraggable(frame, dragBar)
    local dragging, dragStart, startPos = false, Vector2.new(0, 0), UDim2.new()
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

local function showLoadingScreen()
    local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    gui.Name = "ESPLoading"
    local frame = Instance.new("Frame", gui)
    frame.AnchorPoint = Vector2.new(0.5,0.5)
    frame.Position = UDim2.new(0.5,0,0.5,0)
    frame.Size = UDim2.new(0,220,0,55)
    frame.BackgroundColor3 = Color3.fromRGB(30,30,35)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(0,255,255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 21
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

-- ESP FUNÇÕES
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
    -- Se ESP está desligado, não mostra
    if not ESP_ENABLED then removeESP(char) return end
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
        updateESP(player)
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

-- Noclip
RunService.Stepped:Connect(function()
    if noclipActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        for _,part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- WalkSpeed e JumpPower (aplicação automática)
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

-- Funções de câmera do próprio jogador
local function setCameraMode()
    if CAMERA_LOCKED and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 10, 0)
    elseif CAMERA_FIRST_PERSON then
        Camera.CameraType = Enum.CameraType.Custom
        Camera.FieldOfView = 70
        LocalPlayer.CameraMinZoomDistance = 0.5
        LocalPlayer.CameraMaxZoomDistance = 0.5
        Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    else
        Camera.CameraType = Enum.CameraType.Custom
        Camera.FieldOfView = 70
        LocalPlayer.CameraMinZoomDistance = 8
        LocalPlayer.CameraMaxZoomDistance = 30
        Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    end
end

-- ÍCONE PARA ABRIR O MENU PRINCIPAL
local function setupMenuIcon(openCallback)
    local gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    gui.Name = "ScriptMenuIcon"
    gui.ResetOnSpawn = false

    local floatBtn = Instance.new("TextButton")
    floatBtn.Name = "FloatButton"
    floatBtn.Size = UDim2.new(0,40,0,40)
    floatBtn.Position = UDim2.new(0,8,0.4,0)
    floatBtn.BackgroundTransparency = 1
    floatBtn.Text = "👁"
    floatBtn.Font = Enum.Font.GothamBlack
    floatBtn.TextSize = 28
    floatBtn.TextColor3 = Color3.new(1,1,1)
    floatBtn.BorderSizePixel = 0
    floatBtn.AutoButtonColor = true
    floatBtn.Parent = gui

    makeDraggable(floatBtn)
    floatBtn.MouseButton1Click:Connect(function()
        if openCallback then openCallback() end
    end)

    return floatBtn
end

-- CÂMERA ESP: seguir alvo robusto
local following = false
local function followTargetCamera()
    RunService:BindToRenderStep("FollowTargetCam", Enum.RenderPriority.Camera.Value + 1, function()
        if following and ESP_ENABLED and TARGET_PLAYER and TARGET_PLAYER.Character and TARGET_PLAYER.Character:FindFirstChild("HumanoidRootPart") then
            Camera.CameraSubject = TARGET_PLAYER.Character.HumanoidRootPart
        else
            Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            RunService:UnbindFromRenderStep("FollowTargetCam")
        end
    end)
end

-- FRASES DINÂMICAS COM NOMES DE JOGADORES
local frasesBase = {
    "O pato está no comando.",
    "Proibido pensar em nada por mais de 3 segundos.",
    "Nunca desafie um micro-ondas ao xadrez.",
    "Seu clique abriu um portal interdimensional.",
    "Faltam 0 dias para o fim do começo.",
    "Sopa no teclado? Agora sim, desempenho gamer.",
    "{player} está sendo observado pelo pato.",
    "{player} saiu voando com um sanduíche.",
    "Cuidado, {player}! O Wi-Fi caiu.",
    "{player1} e {player2} estão disputando quem pisca mais rápido.",
    "{player} ativou o modo sapo.",
    "{player} perdeu no campeonato de piscadas.",
    "Nunca confie em um sanduíche que te encara.",
    "O Wi-Fi caiu, mas {player} levantou.",
    "{player1} e {player2} abriram um portal interdimensional.",
    "Apenas zebras entendem o código de {player}."
}
local function pickPlayer()
    local plist = Players:GetPlayers()
    if #plist == 0 then return "Alguém" end
    return plist[math.random(1,#plist)].DisplayName
end
local function pick2Players()
    local plist = Players:GetPlayers()
    if #plist < 2 then return pickPlayer(), pickPlayer() end
    local p1 = plist[math.random(1,#plist)]
    local p2 = plist[math.random(1,#plist)]
    while p2 == p1 and #plist > 1 do p2 = plist[math.random(1,#plist)] end
    return p1.DisplayName, p2.DisplayName
end
local function gerarFrase()
    local f = frasesBase[math.random(1,#frasesBase)]
    local p1, p2 = pickPlayer(), pickPlayer()
    if f:find("{player1}") then
        p1,p2 = pick2Players()
        f = f:gsub("{player1}", p1):gsub("{player2}", p2)
    elseif f:find("{player}") then
        f = f:gsub("{player}", p1)
    end
    return f
end

-- PAINEL PRINCIPAL REWORK
local function setupMainPanel()
    local gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    gui.Name = "ScriptMainPanel"
    gui.ResetOnSpawn = false

    local main = Instance.new("Frame", gui)
    main.Name = "MainPanel"
    main.Size = UDim2.new(0,270,0,260)
    main.Position = UDim2.new(0.5,-135,0.5,-130)
    main.AnchorPoint = Vector2.new(0.5,0.5)
    main.BackgroundColor3 = Color3.fromRGB(30,30,36)
    main.BackgroundTransparency = 0.04
    main.BorderSizePixel = 0
    main.Visible = false

    makeDraggable(main)

    -- TÍTULO
    local title = Instance.new("TextLabel", main)
    title.Name = "MainTitle"
    title.Size = UDim2.new(1,0,0,30)
    title.Position = UDim2.new(0,0,0,0)
    title.Text = "!!Definitivo!!"
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 19
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255,255,100)

    -- Mensagem de boas vindas
    local hello = Instance.new("TextLabel", main)
    hello.Size = UDim2.new(1,-20,0,42)
    hello.Position = UDim2.new(0,10,0,34)
    hello.BackgroundTransparency = 1
    hello.TextWrapped = true
    hello.Text = "Olá, querido usuário, obrigado por usar meu script!\nUse com responsabilidade... ou não >:3"
    hello.Font = Enum.Font.Gotham
    hello.TextSize = 14
    hello.TextColor3 = Color3.fromRGB(150,230,255)

    -- BOTÕES PAINEL PRINCIPAL
    local btnESP = Instance.new("TextButton", main)
    btnESP.Size = UDim2.new(0.9,0,0,32)
    btnESP.Position = UDim2.new(0.05,0,0,82)
    btnESP.Text = "Painel ESP"
    btnESP.Font = Enum.Font.GothamBold
    btnESP.TextSize = 16
    btnESP.BackgroundColor3 = Color3.fromRGB(0,180,220)
    btnESP.TextColor3 = Color3.fromRGB(255,255,255)
    btnESP.BorderSizePixel = 0

    local btnPlayer = Instance.new("TextButton", main)
    btnPlayer.Size = UDim2.new(0.9,0,0,32)
    btnPlayer.Position = UDim2.new(0.05,0,0,122)
    btnPlayer.Text = "Painel Jogador"
    btnPlayer.Font = Enum.Font.GothamBold
    btnPlayer.TextSize = 16
    btnPlayer.BackgroundColor3 = Color3.fromRGB(40,190,100)
    btnPlayer.TextColor3 = Color3.fromRGB(255,255,255)
    btnPlayer.BorderSizePixel = 0

    -- Botão secreto
    local btnSecret = Instance.new("TextButton", main)
    btnSecret.Size = UDim2.new(0.27,0,0,22)
    btnSecret.Position = UDim2.new(0.03,0,1,-27)
    btnSecret.Text = "1+1=2"
    btnSecret.Font = Enum.Font.GothamBlack
    btnSecret.TextSize = 13
    btnSecret.BackgroundColor3 = Color3.fromRGB(35,35,60)
    btnSecret.TextColor3 = Color3.fromRGB(245,245,200)
    btnSecret.BorderSizePixel = 0

    local btnSecret2 = Instance.new("TextButton", main)
    btnSecret2.Size = UDim2.new(0.27,0,0,22)
    btnSecret2.Position = UDim2.new(0.36,0,1,-27)
    btnSecret2.Text = "Mensagem"
    btnSecret2.Font = Enum.Font.GothamBlack
    btnSecret2.TextSize = 13
    btnSecret2.BackgroundColor3 = Color3.fromRGB(45,45,70)
    btnSecret2.TextColor3 = Color3.fromRGB(200,255,255)
    btnSecret2.BorderSizePixel = 0

    -- Botão fechar
    local closeBtn = Instance.new("TextButton", main)
    closeBtn.Size = UDim2.new(0,28,0,28)
    closeBtn.Position = UDim2.new(1,-30,0,2)
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.GothamBlack
    closeBtn.TextSize = 17
    closeBtn.BackgroundColor3 = Color3.fromRGB(32,32,32)
    closeBtn.TextColor3 = Color3.fromRGB(255,90,90)
    closeBtn.BorderSizePixel = 0

    closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

    -- FRASES DINÂMICAS
    btnSecret2.MouseButton1Click:Connect(function()
        local msg = gerarFrase()
        StarterGui:SetCore("SendNotification",{
            Title = "Mensagem Aleatória",
            Text = msg,
            Duration = 3
        })
    end)

    -- CALCULADORA MELHORADA
    btnSecret.MouseButton1Click:Connect(function()
        local calcGui = Instance.new("ScreenGui", gui)
        calcGui.Name = "CalcGui"
        local frame = Instance.new("Frame", calcGui)
        frame.Size = UDim2.new(0,180,0,180)
        frame.Position = UDim2.new(0.5,-90,0.5,-90)
        frame.BackgroundColor3 = Color3.fromRGB(40,40,44)
        frame.AnchorPoint = Vector2.new(0.5,0.5)
        frame.BorderSizePixel = 0
        local tb = Instance.new("TextBox", frame)
        tb.Size = UDim2.new(1,-10,0,30)
        tb.Position = UDim2.new(0,5,0,5)
        tb.Text = ""
        tb.Font = Enum.Font.Gotham
        tb.TextSize = 16
        tb.BackgroundColor3 = Color3.fromRGB(60,60,70)
        tb.TextColor3 = Color3.fromRGB(255,255,255)
        tb.PlaceholderText = "Digite: 5+2×3-1÷2"
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(1,-10,0,30)
        btn.Position = UDim2.new(0,5,0,45)
        btn.Text = "Calcular"
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 15
        btn.BackgroundColor3 = Color3.fromRGB(0,160,220)
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.BorderSizePixel = 0
        local out = Instance.new("TextLabel", frame)
        out.Size = UDim2.new(1,-10,0,30)
        out.Position = UDim2.new(0,5,0,85)
        out.Text = ""
        out.Font = Enum.Font.Gotham
        out.TextSize = 15
        out.BackgroundTransparency = 1
        out.TextColor3 = Color3.fromRGB(255,255,220)
        local closeCalc = Instance.new("TextButton", frame)
        closeCalc.Size = UDim2.new(0,22,0,22)
        closeCalc.Position = UDim2.new(1,-25,0,4)
        closeCalc.Text = "✕"
        closeCalc.Font = Enum.Font.GothamBlack
        closeCalc.TextSize = 14
        closeCalc.BackgroundColor3 = Color3.fromRGB(60,60,60)
        closeCalc.TextColor3 = Color3.fromRGB(255,90,90)
        closeCalc.BorderSizePixel = 0
        closeCalc.MouseButton1Click:Connect(function() calcGui:Destroy() end)
        btn.MouseButton1Click:Connect(function()
            local exp = tb.Text
            exp = exp:gsub(",",".") -- aceita vírgula decimal
            exp = exp:gsub("×","*"):gsub("x", "*"):gsub("÷","/"):gsub("−","-")
            exp = exp:gsub("[^%d%.%+%-%*/%(%) ]","") -- só aceita números, operadores, ponto, parênteses
            local s,ret = pcall(function() return loadstring("return "..exp)() end)
            out.Text = s and tostring(ret) or "Erro"
        end)
    end)

    -- Painéis ESP e Jogador
    local espPanel, playerPanel = nil, nil

    -- PAINEL ESP
    local function setupESPPanel()
        if espPanel and espPanel.Parent then espPanel.Visible = true return end
        espPanel = Instance.new("Frame", gui)
        espPanel.Name = "ESPPanel"
        espPanel.Size = UDim2.new(0,250,0,320)
        espPanel.Position = UDim2.new(0.5,-125,0.5,-160)
        espPanel.BackgroundColor3 = Color3.fromRGB(35,35,50)
        espPanel.BackgroundTransparency = 0.01
        espPanel.BorderSizePixel = 0
        espPanel.Visible = true
        espPanel.AnchorPoint = Vector2.new(0.5,0.5)
        makeDraggable(espPanel)

        -- Título
        local title = Instance.new("TextLabel", espPanel)
        title.Size = UDim2.new(1,0,0,32)
        title.Position = UDim2.new(0,0,0,0)
        title.Text = "Painel ESP"
        title.Font = Enum.Font.GothamBlack
        title.TextSize = 17
        title.BackgroundTransparency = 1
        title.TextColor3 = ESP_COLOR

        -- Ativar/desativar ESP
        local toggleBtn = Instance.new("TextButton", espPanel)
        toggleBtn.Size = UDim2.new(0.9,0,0,28)
        toggleBtn.Position = UDim2.new(0.05,0,0,38)
        toggleBtn.Text = "ESP: OFF"
        toggleBtn.Font = Enum.Font.Gotham
        toggleBtn.TextSize = 15
        toggleBtn.BackgroundColor3 = Color3.fromRGB(40,40,44)
        toggleBtn.TextColor3 = Color3.fromRGB(255,60,60)
        toggleBtn.BorderSizePixel = 0
        toggleBtn.MouseButton1Click:Connect(function()
            ESP_ENABLED = not ESP_ENABLED
            toggleBtn.Text = "ESP: " .. (ESP_ENABLED and "ON" or "OFF")
            toggleBtn.TextColor3 = ESP_ENABLED and ESP_COLOR or Color3.fromRGB(255,60,60)
            if not ESP_ENABLED then
                following = false -- desliga seguir alvo se desligar ESP
                RunService:UnbindFromRenderStep("FollowTargetCam")
            end
            updateAllESP()
        end)

        -- Jogadores no servidor
        local playerCount = Instance.new("TextLabel", espPanel)
        playerCount.Size = UDim2.new(0.9,0,0,20)
        playerCount.Position = UDim2.new(0.05,0,0,70)
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

        -- Tempo de servidor
        local serverTime = Instance.new("TextLabel", espPanel)
        serverTime.Size = UDim2.new(0.9,0,0,20)
        serverTime.Position = UDim2.new(0.05,0,0,92)
        serverTime.Text = "Tempo do servidor: 0:00"
        serverTime.Font = Enum.Font.Gotham
        serverTime.TextSize = 13
        serverTime.BackgroundTransparency = 1
        serverTime.TextColor3 = Color3.fromRGB(255,255,255)
        serverTime.TextXAlignment = Enum.TextXAlignment.Left
        local sessionStart = tick()
        RunService.RenderStepped:Connect(function()
            local t = math.floor(tick()-sessionStart)
            serverTime.Text = string.format("Tempo do servidor: %d:%02d", math.floor(t/60), t%60)
        end)

        -- Mudar cor do highlight
        local colorLabel = Instance.new("TextLabel", espPanel)
        colorLabel.Size = UDim2.new(0.5,0,0,20)
        colorLabel.Position = UDim2.new(0.05,0,0,120)
        colorLabel.Text = "Mudar cor:"
        colorLabel.BackgroundTransparency = 1
        colorLabel.TextColor3 = Color3.fromRGB(255,255,255)
        colorLabel.Font = Enum.Font.Gotham
        colorLabel.TextSize = 12
        local colorPicker = Instance.new("TextBox", espPanel)
        colorPicker.Size = UDim2.new(0.38,0,0,20)
        colorPicker.Position = UDim2.new(0.58,0,0,120)
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
                title.TextColor3 = ESP_COLOR
                toggleBtn.TextColor3 = ESP_ENABLED and ESP_COLOR or Color3.fromRGB(255,60,60)
                updateAllESP()
            end
        end)

        -- Painel de jogadores para ESP alvo
        local playerPanelBtn = Instance.new("TextButton", espPanel)
        playerPanelBtn.Text = "Selecionar Jogador"
        playerPanelBtn.Size = UDim2.new(0.93,0,0,22)
        playerPanelBtn.Position = UDim2.new(0.035,0,0,150)
        playerPanelBtn.Font = Enum.Font.Gotham
        playerPanelBtn.TextSize = 13
        playerPanelBtn.BackgroundColor3 = Color3.fromRGB(30,44,60)
        playerPanelBtn.TextColor3 = Color3.fromRGB(200,225,255)
        playerPanelBtn.BorderSizePixel = 0

        -- Botão: resetar alvo
        local resetTargetBtn = Instance.new("TextButton", espPanel)
        resetTargetBtn.Text = "ESP em todos"
        resetTargetBtn.Size = UDim2.new(0.45,0,0,20)
        resetTargetBtn.Position = UDim2.new(0.035,0,0,180)
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
        local cameraBtn = Instance.new("TextButton", espPanel)
        cameraBtn.Text = "Seguir câmera"
        cameraBtn.Size = UDim2.new(0.45,0,0,20)
        cameraBtn.Position = UDim2.new(0.52,0,0,180)
        cameraBtn.Font = Enum.Font.Gotham
        cameraBtn.TextSize = 12
        cameraBtn.BackgroundColor3 = Color3.fromRGB(30,44,60)
        cameraBtn.TextColor3 = Color3.fromRGB(200,225,255)
        cameraBtn.BorderSizePixel = 0
        cameraBtn.MouseButton1Click:Connect(function()
            if TARGET_PLAYER and TARGET_PLAYER.Character and TARGET_PLAYER.Character:FindFirstChild("HumanoidRootPart") then
                following = not following
                cameraBtn.TextColor3 = following and Color3.fromRGB(60,255,255) or Color3.fromRGB(200,225,255)
                if following then
                    followTargetCamera()
                else
                    Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    RunService:UnbindFromRenderStep("FollowTargetCam")
                end
            end
        end)

        -- Painel de seleção de jogadores
        local playerPanel = Instance.new("Frame", gui)
        playerPanel.Name = "PlayerPanelESP"
        playerPanel.Visible = false
        playerPanel.Size = UDim2.new(0,170,0,180)
        playerPanel.Position = UDim2.new(0.5,90,0.5,-50)
        playerPanel.BackgroundColor3 = Color3.fromRGB(40,40,40)
        playerPanel.BackgroundTransparency = 0.05
        playerPanel.BorderSizePixel = 0
        playerPanel.AnchorPoint = Vector2.new(0,0)
        playerPanel.ZIndex = 5
        makeDraggable(playerPanel)

        local playerPanelTitle = Instance.new("TextLabel", playerPanel)
        playerPanelTitle.Size = UDim2.new(1,0,0,24)
        playerPanelTitle.Text = "Jogadores"
        playerPanelTitle.BackgroundTransparency = 1
        playerPanelTitle.Font = Enum.Font.GothamBold
        playerPanelTitle.TextSize = 14
        playerPanelTitle.TextColor3 = ESP_COLOR

        local closePlayerPanelBtn = Instance.new("TextButton", playerPanel)
        closePlayerPanelBtn.Text = "✕"
        closePlayerPanelBtn.Font = Enum.Font.GothamBlack
        closePlayerPanelBtn.TextSize = 13
        closePlayerPanelBtn.Size = UDim2.new(0,22,0,22)
        closePlayerPanelBtn.Position = UDim2.new(1,-24,0,2)
        closePlayerPanelBtn.BackgroundColor3 = Color3.fromRGB(32,32,32)
        closePlayerPanelBtn.TextColor3 = Color3.fromRGB(255,90,90)
        closePlayerPanelBtn.BorderSizePixel = 0
        closePlayerPanelBtn.MouseButton1Click:Connect(function() playerPanel.Visible = false end)

        local playerList = Instance.new("ScrollingFrame", playerPanel)
        playerList.Size = UDim2.new(1, -10, 1, -30)
        playerList.Position = UDim2.new(0,5,0,26)
        playerList.BackgroundTransparency = 0.08
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
                item.Size = UDim2.new(1,0,0,20)
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
                y = y + 20
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
        -- Fechar ESP painel
        local closeBtn = Instance.new("TextButton", espPanel)
        closeBtn.Size = UDim2.new(0,26,0,26)
        closeBtn.Position = UDim2.new(1,-28,0,3)
        closeBtn.Text = "✕"
        closeBtn.Font = Enum.Font.GothamBlack
        closeBtn.TextSize = 15
        closeBtn.BackgroundColor3 = Color3.fromRGB(32,32,32)
        closeBtn.TextColor3 = Color3.fromRGB(255,90,90)
        closeBtn.BorderSizePixel = 0
        closeBtn.MouseButton1Click:Connect(function() espPanel.Visible = false end)
    end

    -- PAINEL JOGADOR
    local function setupPlayerPanel()
        if playerPanel and playerPanel.Parent then playerPanel.Visible = true return end
        playerPanel = Instance.new("Frame", gui)
        playerPanel.Name = "PlayerPanel"
        playerPanel.Size = UDim2.new(0,230,0,210)
        playerPanel.Position = UDim2.new(0.5,140,0.5,-105)
        playerPanel.BackgroundColor3 = Color3.fromRGB(36,44,36)
        playerPanel.BackgroundTransparency = 0.02
        playerPanel.BorderSizePixel = 0
        playerPanel.Visible = true
        playerPanel.AnchorPoint = Vector2.new(0.5,0.5)
        makeDraggable(playerPanel)
        local title = Instance.new("TextLabel", playerPanel)
        title.Size = UDim2.new(1,0,0,32)
        title.Position = UDim2.new(0,0,0,0)
        title.Text = "Painel Jogador"
        title.Font = Enum.Font.GothamBlack
        title.TextSize = 16
        title.BackgroundTransparency = 1
        title.TextColor3 = Color3.fromRGB(110,255,110)

        -- Noclip
        local noclipBtn = Instance.new("TextButton", playerPanel)
        noclipBtn.Text = "Noclip: OFF"
        noclipBtn.Size = UDim2.new(0.92,0,0,24)
        noclipBtn.Position = UDim2.new(0.04,0,0,40)
        noclipBtn.Font = Enum.Font.Gotham
        noclipBtn.TextSize = 13
        noclipBtn.BackgroundColor3 = Color3.fromRGB(50,70,50)
        noclipBtn.TextColor3 = Color3.fromRGB(255,255,255)
        noclipBtn.BorderSizePixel = 0
        noclipBtn.MouseButton1Click:Connect(function()
            noclipActive = not noclipActive
            noclipBtn.Text = "Noclip: " .. (noclipActive and "ON" or "OFF")
            noclipBtn.TextColor3 = noclipActive and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,255,255)
        end)

        -- WalkSpeed
        local wsLabel = Instance.new("TextLabel", playerPanel)
        wsLabel.Text = "Velocidade:"
        wsLabel.Size = UDim2.new(0.5,0,0,20)
        wsLabel.Position = UDim2.new(0.04,0,0,72)
        wsLabel.BackgroundTransparency = 1
        wsLabel.TextColor3 = Color3.fromRGB(255,255,255)
        wsLabel.Font = Enum.Font.Gotham
        wsLabel.TextSize = 12
        local wsBox = Instance.new("TextBox", playerPanel)
        wsBox.Size = UDim2.new(0.35,0,0,20)
        wsBox.Position = UDim2.new(0.56,0,0,72)
        wsBox.Text = tostring(walkspeed)
        wsBox.Font = Enum.Font.Gotham
        wsBox.TextSize = 12
        wsBox.BackgroundColor3 = Color3.fromRGB(50,70,50)
        wsBox.TextColor3 = Color3.fromRGB(255,255,255)
        wsBox.BorderSizePixel = 0
        wsBox.ClearTextOnFocus = false
        wsBox.FocusLost:Connect(function()
            local val = tonumber(wsBox.Text)
            if val and val >= 1 and val <= 100 then
                walkspeed = val
            else
                wsBox.Text = tostring(walkspeed)
            end
        end)

        -- JumpPower
        local jpLabel = Instance.new("TextLabel", playerPanel)
        jpLabel.Text = "Pulo:"
        jpLabel.Size = UDim2.new(0.5,0,0,20)
        jpLabel.Position = UDim2.new(0.04,0,0,104)
        jpLabel.BackgroundTransparency = 1
        jpLabel.TextColor3 = Color3.fromRGB(255,255,255)
        jpLabel.Font = Enum.Font.Gotham
        jpLabel.TextSize = 12
        local jpBox = Instance.new("TextBox", playerPanel)
        jpBox.Size = UDim2.new(0.35,0,0,20)
        jpBox.Position = UDim2.new(0.56,0,0,104)
        jpBox.Text = tostring(jumppower)
        jpBox.Font = Enum.Font.Gotham
        jpBox.TextSize = 12
        jpBox.BackgroundColor3 = Color3.fromRGB(50,70,50)
        jpBox.TextColor3 = Color3.fromRGB(255,255,255)
        jpBox.BorderSizePixel = 0
        jpBox.ClearTextOnFocus = false
        jpBox.FocusLost:Connect(function()
            local val = tonumber(jpBox.Text)
            if val and val >= 1 and val <= 100 then
                jumppower = val
            else
                jpBox.Text = tostring(jumppower)
            end
        end)

        -- Botão padrão
        local btnPadrao = Instance.new("TextButton", playerPanel)
        btnPadrao.Text = "Colocar padrão"
        btnPadrao.Size = UDim2.new(0.92,0,0,22)
        btnPadrao.Position = UDim2.new(0.04,0,0,134)
        btnPadrao.Font = Enum.Font.Gotham
        btnPadrao.TextSize = 12
        btnPadrao.BackgroundColor3 = Color3.fromRGB(32,64,32)
        btnPadrao.TextColor3 = Color3.fromRGB(255,220,160)
        btnPadrao.BorderSizePixel = 0
        btnPadrao.MouseButton1Click:Connect(function()
            walkspeed = DEFAULT_WALKSPEED
            jumppower = DEFAULT_JUMPPOWER
            wsBox.Text = tostring(walkspeed)
            jpBox.Text = tostring(jumppower)
        end)

        -- Botão de câmera 1°/3° pessoa
        local camToggleBtn = Instance.new("TextButton", playerPanel)
        camToggleBtn.Text = "Câmera 1ª pessoa: OFF"
        camToggleBtn.Size = UDim2.new(0.92,0,0,22)
        camToggleBtn.Position = UDim2.new(0.04,0,0,162)
        camToggleBtn.Font = Enum.Font.Gotham
        camToggleBtn.TextSize = 12
        camToggleBtn.BackgroundColor3 = Color3.fromRGB(32,32,64)
        camToggleBtn.TextColor3 = Color3.fromRGB(160,220,255)
        camToggleBtn.BorderSizePixel = 0
        camToggleBtn.MouseButton1Click:Connect(function()
            CAMERA_FIRST_PERSON = not CAMERA_FIRST_PERSON
            CAMERA_LOCKED = false
            camToggleBtn.Text = "Câmera 1ª pessoa: " .. (CAMERA_FIRST_PERSON and "ON" or "OFF")
            camToggleBtn.TextColor3 = CAMERA_FIRST_PERSON and Color3.fromRGB(80,255,255) or Color3.fromRGB(160,220,255)
            setCameraMode()
        end)

        -- Botão de câmera fixa
        local camLockBtn = Instance.new("TextButton", playerPanel)
        camLockBtn.Text = "Câmera fixa: OFF"
        camLockBtn.Size = UDim2.new(0.92,0,0,22)
        camLockBtn.Position = UDim2.new(0.04,0,0,188)
        camLockBtn.Font = Enum.Font.Gotham
        camLockBtn.TextSize = 12
        camLockBtn.BackgroundColor3 = Color3.fromRGB(64,32,32)
        camLockBtn.TextColor3 = Color3.fromRGB(255,200,200)
        camLockBtn.BorderSizePixel = 0
        camLockBtn.MouseButton1Click:Connect(function()
            CAMERA_LOCKED = not CAMERA_LOCKED
            CAMERA_FIRST_PERSON = false
            camLockBtn.Text = "Câmera fixa: " .. (CAMERA_LOCKED and "ON" or "OFF")
            camLockBtn.TextColor3 = CAMERA_LOCKED and Color3.fromRGB(255,160,160) or Color3.fromRGB(255,200,200)
            setCameraMode()
        end)

        -- Fechar painel jogador
        local closeBtn = Instance.new("TextButton", playerPanel)
        closeBtn.Size = UDim2.new(0,26,0,26)
        closeBtn.Position = UDim2.new(1,-28,0,3)
        closeBtn.Text = "✕"
        closeBtn.Font = Enum.Font.GothamBlack
        closeBtn.TextSize = 14
        closeBtn.BackgroundColor3 = Color3.fromRGB(32,32,32)
        closeBtn.TextColor3 = Color3.fromRGB(255,90,90)
        closeBtn.BorderSizePixel = 0
        closeBtn.MouseButton1Click:Connect(function() playerPanel.Visible = false end)
    end

    btnESP.MouseButton1Click:Connect(setupESPPanel)
    btnPlayer.MouseButton1Click:Connect(setupPlayerPanel)

    -- Ícone de olho para abrir o menu principal
    local iconBtn = setupMenuIcon(function()
        main.Visible = not main.Visible
    end)
end

coroutine.wrap(showLoadingScreen)()
wait(2.2)
setupMainPanel()

RunService.RenderStepped:Connect(function()
    setCameraMode()
    updateAllESP()
end)
