--[[ 
  MELHORIAS: Painel Visual drag, FullBright, Painel Joguinhos com Jogo da Memória (Cartas Beta), Painel principal revisado
  Feito por Copilot - Para uso em jogos próprios/autorizados
--]]

-- SERVIÇOS E VARIÁVEIS
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local ESP_ENABLED = false
local ESP_COLOR = Color3.fromRGB(0,255,255)
local OUTLINE_COLOR = Color3.fromRGB(255,255,0)
local FILL_TRANSPARENCY = 0.7
local OUTLINE_TRANSPARENCY = 0
local MAX_DISTANCE = math.huge
local FONTE_PEQUENA = 13
local ESPObjects = {}
local TARGET_PLAYER = nil
local TARGET_ONLY = false
local noclipActive = false
local walkspeed = 16
local jumppower = 50
local DEFAULT_WALKSPEED = 16
local DEFAULT_JUMPPOWER = 50
local CAMERA_FIRST_PERSON = false
local INFINITE_JUMP = false
local FULLBRIGHT_ON = false
local fullbrightClone = nil

------------------------ UTILS ------------------------

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

local function showMessage(text)
    StarterGui:SetCore("SendNotification",{
        Title = "Script",
        Text = text,
        Duration = 2.3
    })
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

------------------------ FULLBRIGHT ------------------------

local function setFullBright(state)
    FULLBRIGHT_ON = state
    if state then
        if not fullbrightClone then
            fullbrightClone = {}
            fullbrightClone.Brightness = Lighting.Brightness
            fullbrightClone.ClockTime = Lighting.ClockTime
            fullbrightClone.Ambient = Lighting.Ambient
            fullbrightClone.OutdoorAmbient = Lighting.OutdoorAmbient
            fullbrightClone.ColorShift_Top = Lighting.ColorShift_Top
            fullbrightClone.ColorShift_Bottom = Lighting.ColorShift_Bottom
        end
        Lighting.Brightness = 6
        Lighting.ClockTime = 14
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
        Lighting.ColorShift_Top = Color3.new(0,0,0)
        Lighting.ColorShift_Bottom = Color3.new(0,0,0)
        showMessage("Modo coruja")
    else
        if fullbrightClone then
            Lighting.Brightness = fullbrightClone.Brightness
            Lighting.ClockTime = fullbrightClone.ClockTime
            Lighting.Ambient = fullbrightClone.Ambient
            Lighting.OutdoorAmbient = fullbrightClone.OutdoorAmbient
            Lighting.ColorShift_Top = fullbrightClone.ColorShift_Top
            Lighting.ColorShift_Bottom = fullbrightClone.ColorShift_Bottom
            fullbrightClone = nil
        end
        showMessage("Modo \"cegueira\" lol XD")
    end
end

------------------------ ESP ------------------------

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

-- PULO INFINITO
local infiniteJumpConn
local function setInfiniteJump(state)
    INFINITE_JUMP = state
    if state then
        if infiniteJumpConn then infiniteJumpConn:Disconnect() end
        infiniteJumpConn = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                char:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    else
        if infiniteJumpConn then infiniteJumpConn:Disconnect() infiniteJumpConn = nil end
    end
end

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

local function setCameraMode()
    if CAMERA_FIRST_PERSON then
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

------------------------ JOGO DA MEMÓRIA (CARTAS BETA) ------------------------

local function setupMemoriaGamePanel()
    local gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    gui.Name = "JoguinhosPanel"
    gui.ResetOnSpawn = false

    local main = Instance.new("Frame", gui)
    main.Name = "JoguinhosMain"
    main.AnchorPoint = Vector2.new(0.5,0.5)
    main.Position = UDim2.new(0.5,0,0.5,0)
    main.Size = UDim2.new(0,480,0,420)
    main.BackgroundColor3 = Color3.fromRGB(30,30,36)
    main.BackgroundTransparency = 0.04
    main.BorderSizePixel = 0
    makeDraggable(main)

    -- Título e fechar
    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(1,0,0,40)
    title.Position = UDim2.new(0,0,0,0)
    title.Text = "Joguinhos :D"
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 23
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(255,255,100)
    local close = Instance.new("TextButton", main)
    close.Size = UDim2.new(0,28,0,28)
    close.Position = UDim2.new(1,-34,0,6)
    close.Text = "✕"
    close.Font = Enum.Font.GothamBlack
    close.TextSize = 17
    close.BackgroundColor3 = Color3.fromRGB(32,32,32)
    close.TextColor3 = Color3.fromRGB(255,90,90)
    close.BorderSizePixel = 0
    close.MouseButton1Click:Connect(function() gui:Destroy() end)

    -- Botões de zoom
    local btnZoomIn = Instance.new("TextButton", main)
    btnZoomIn.Size = UDim2.new(0,26,0,26)
    btnZoomIn.Position = UDim2.new(1,-70,0,6)
    btnZoomIn.Text = "+"
    btnZoomIn.Font = Enum.Font.GothamBold
    btnZoomIn.TextSize = 18
    btnZoomIn.BackgroundColor3 = Color3.fromRGB(32,32,90)
    btnZoomIn.TextColor3 = Color3.fromRGB(255,255,255)
    btnZoomIn.BorderSizePixel = 0

    local btnZoomOut = Instance.new("TextButton", main)
    btnZoomOut.Size = UDim2.new(0,26,0,26)
    btnZoomOut.Position = UDim2.new(1,-104,0,6)
    btnZoomOut.Text = "-"
    btnZoomOut.Font = Enum.Font.GothamBold
    btnZoomOut.TextSize = 18
    btnZoomOut.BackgroundColor3 = Color3.fromRGB(90,32,32)
    btnZoomOut.TextColor3 = Color3.fromRGB(255,255,255)
    btnZoomOut.BorderSizePixel = 0

    -- Dificuldade (4x4 ou 6x6)
    local difBox = Instance.new("TextButton", main)
    difBox.Size = UDim2.new(0,90,0,30)
    difBox.Position = UDim2.new(0.5,-45,0,48)
    difBox.Text = "Dificuldade: 4x4"
    difBox.Font = Enum.Font.GothamBold
    difBox.TextSize = 15
    difBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
    difBox.TextColor3 = Color3.fromRGB(255,255,255)
    difBox.BorderSizePixel = 0
    local dificuldade = 4
    difBox.MouseButton1Click:Connect(function()
        dificuldade = dificuldade == 4 and 6 or 4
        difBox.Text = "Dificuldade: "..dificuldade.."x"..dificuldade
    end)

    -- Área do jogo
    local gameArea = Instance.new("Frame", main)
    gameArea.Name = "MemoriaGameArea"
    gameArea.AnchorPoint = Vector2.new(0.5,0)
    gameArea.Position = UDim2.new(0.5,0,0,90)
    gameArea.Size = UDim2.new(0,360,0,320)
    gameArea.BackgroundColor3 = Color3.fromRGB(18,18,24)
    gameArea.BorderSizePixel = 0

    -- Zoom/resize
    local function setGameAreaScale(scale)
        local ref = 360 * scale
        gameArea.Size = UDim2.new(0,ref,0,ref)
    end
    local scale = 1
    btnZoomIn.MouseButton1Click:Connect(function()
        scale = math.min(scale+0.1,2)
        setGameAreaScale(scale)
    end)
    btnZoomOut.MouseButton1Click:Connect(function()
        scale = math.max(scale-0.1,0.5)
        setGameAreaScale(scale)
    end)
    setGameAreaScale(1)

    -- Jogo da memória principal
    local emojis = { "🔥","❄️","🍀","🦄","🍕","🌙","⭐","🌵","🍄","🐸","🐙","🦑","🦋","🦖","🍔","🍪","🍫","🍩" }
    local flipTime = 0.25
    local showTime = 5

    local function embaralhar(tab)
        for i = #tab, 2, -1 do
            local j = math.random(i)
            tab[i], tab[j] = tab[j], tab[i]
        end
    end

    local function playMemoria(size)
        gameArea:ClearAllChildren()
        local pares = {}
        local total = size*size
        local pool = {}
        for i=1,total/2 do
            table.insert(pool, emojis[i])
            table.insert(pool, emojis[i])
        end
        embaralhar(pool)
        for i=1,total do
            pares[i] = pool[i]
        end

        local cards = {}
        local revealed = {}
        local matched = {}
        local canClick = false
        local lastCard = nil

        -- Gera as cartas
        local grid = {}
        for i=1,size do grid[i]={} end
        for i=1,total do
            local row = math.floor((i-1)/size)+1
            local col = (i-1)%size+1
            grid[row][col]=i
        end

        local cardSize = math.floor(340/size)
        for i=1,total do
            local card = Instance.new("TextButton",gameArea)
            local row = math.floor((i-1)/size)
            local col = (i-1)%size
            card.Size = UDim2.new(0,cardSize-6,0,cardSize-6)
            card.Position = UDim2.new(0,col*cardSize+3,0,row*cardSize+3)
            card.BackgroundColor3 = Color3.fromRGB(50,60,120)
            card.Text = pares[i]
            card.TextSize = cardSize-12
            card.Font = Enum.Font.GothamBlack
            card.TextColor3 = Color3.fromRGB(255,255,255)
            card.BorderSizePixel = 0
            card.Name = tostring(i)
            cards[i]=card
            revealed[i]=true
            matched[i]=false
        end

        -- Mostrar para memorizar
        canClick = false
        for i=1,total do
            cards[i].TextTransparency = 0
            cards[i].BackgroundColor3 = Color3.fromRGB(50,60,120)
        end
        wait(showTime)
        for i=1,total do
            matched[i]=false
            revealed[i]=false
            TweenService:Create(cards[i],TweenInfo.new(flipTime),{TextTransparency=1,BackgroundColor3=Color3.fromRGB(40,40,60)}):Play()
        end
        wait(flipTime)
        canClick=true

        -- Função de virar carta animada
        local function flip(card, show)
            if not card then return end
            TweenService:Create(card,TweenInfo.new(flipTime/2),{TextTransparency=1}):Play()
            TweenService:Create(card,TweenInfo.new(flipTime/2),{BackgroundColor3=show and Color3.fromRGB(80,180,120) or Color3.fromRGB(40,40,60)}):Play()
            wait(flipTime/2)
            card.TextTransparency = show and 0 or 1
        end

        for i=1,total do
            cards[i].TextTransparency = 1
            cards[i].BackgroundColor3 = Color3.fromRGB(40,40,60)
            cards[i].MouseButton1Click:Connect(function()
                if not canClick or revealed[i] or matched[i] then return end
                canClick=false
                revealed[i]=true
                flip(cards[i],true)
                if lastCard then
                    wait(flipTime)
                    if pares[i]==pares[lastCard] then
                        matched[i]=true
                        matched[lastCard]=true
                        TweenService:Create(cards[i],TweenInfo.new(0.22),{BackgroundColor3=Color3.fromRGB(90,255,120)}):Play()
                        TweenService:Create(cards[lastCard],TweenInfo.new(0.22),{BackgroundColor3=Color3.fromRGB(90,255,120)}):Play()
                        wait(0.15)
                    else
                        flip(cards[i],false)
                        flip(cards[lastCard],false)
                        revealed[i]=false
                        revealed[lastCard]=false
                    end
                    lastCard=nil
                else
                    lastCard=i
                end
                canClick=true
                -- Checa vitória
                local terminou=true
                for k=1,total do if not matched[k] then terminou=false end end
                if terminou then
                    canClick=false
                    wait(0.5)
                    -- tela vitória
                    local win = Instance.new("Frame",gameArea)
                    win.Size = UDim2.new(1,0,1,0)
                    win.BackgroundColor3 = Color3.fromRGB(32,120,32)
                    win.BackgroundTransparency = 0.08
                    local msg = Instance.new("TextLabel",win)
                    msg.Size = UDim2.new(1,0,0,48)
                    msg.Position = UDim2.new(0,0,0.2,0)
                    msg.Text = "Você ganhou! Jogar novamente?"
                    msg.Font = Enum.Font.GothamBlack
                    msg.TextSize = 20
                    msg.TextColor3 = Color3.new(1,1,1)
                    msg.BackgroundTransparency = 1
                    local sim = Instance.new("TextButton",win)
                    sim.Size = UDim2.new(0.4,0,0,32)
                    sim.Position = UDim2.new(0.08,0,0.6,0)
                    sim.Text = "Sim"
                    sim.Font = Enum.Font.GothamBold
                    sim.TextSize = 17
                    sim.BackgroundColor3 = Color3.fromRGB(60,120,30)
                    sim.TextColor3 = Color3.new(1,1,1)
                    sim.BorderSizePixel = 0
                    sim.MouseButton1Click:Connect(function()
                        win:Destroy()
                        playMemoria(size)
                    end)
                    local nao = Instance.new("TextButton",win)
                    nao.Size = UDim2.new(0.4,0,0,32)
                    nao.Position = UDim2.new(0.52,0,0.6,0)
                    nao.Text = "Não"
                    nao.Font = Enum.Font.GothamBold
                    nao.TextSize = 17
                    nao.BackgroundColor3 = Color3.fromRGB(120,40,40)
                    nao.TextColor3 = Color3.new(1,1,1)
                    nao.BorderSizePixel = 0
                    nao.MouseButton1Click:Connect(function()
                        gui:Destroy()
                    end)
                end
            end)
        end
    end

    -- Começar o jogo
    playMemoria(dificuldade)

    -- Atualiza dificuldade ao clicar
    difBox.MouseButton1Click:Connect(function()
        dificuldade = dificuldade == 4 and 6 or 4
        difBox.Text = "Dificuldade: "..dificuldade.."x"..dificuldade
        playMemoria(dificuldade)
    end)
end

------------------------ PAINEL PRINCIPAL ------------------------

local function setupMainPanel()
    local gui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    gui.Name = "ScriptMainPanel"
    gui.ResetOnSpawn = false

    local main = Instance.new("Frame", gui)
    main.Name = "MainPanel"
    main.Size = UDim2.new(0,270,0,370)
    main.Position = UDim2.new(0.5,-135,0.5,-185)
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

    -- Botão Painel Visual
    local btnVisual = Instance.new("TextButton", main)
    btnVisual.Size = UDim2.new(0.9,0,0,32)
    btnVisual.Position = UDim2.new(0.05,0,0,82)
    btnVisual.Text = "Painel visual"
    btnVisual.Font = Enum.Font.GothamBold
    btnVisual.TextSize = 16
    btnVisual.BackgroundColor3 = Color3.fromRGB(0,180,220)
    btnVisual.TextColor3 = Color3.fromRGB(255,255,255)
    btnVisual.BorderSizePixel = 0

    -- Botão Jogador
    local btnPlayer = Instance.new("TextButton", main)
    btnPlayer.Size = UDim2.new(0.9,0,0,32)
    btnPlayer.Position = UDim2.new(0.05,0,0,122)
    btnPlayer.Text = "Painel Jogador"
    btnPlayer.Font = Enum.Font.GothamBold
    btnPlayer.TextSize = 16
    btnPlayer.BackgroundColor3 = Color3.fromRGB(40,190,100)
    btnPlayer.TextColor3 = Color3.fromRGB(255,255,255)
    btnPlayer.BorderSizePixel = 0

    -- Botão Joguinhos
    local btnJogo = Instance.new("TextButton", main)
    btnJogo.Size = UDim2.new(0.9,0,0,32)
    btnJogo.Position = UDim2.new(0.05,0,0,162)
    btnJogo.Text = "Joguinhos :D"
    btnJogo.Font = Enum.Font.GothamBlack
    btnJogo.TextSize = 16
    btnJogo.BackgroundColor3 = Color3.fromRGB(90,90,190)
    btnJogo.TextColor3 = Color3.fromRGB(255,255,255)
    btnJogo.BorderSizePixel = 0
    btnJogo.MouseButton1Click:Connect(setupMemoriaGamePanel)

    -- Botão DESLIGAR TUDO
    local btnResetAll = Instance.new("TextButton", main)
    btnResetAll.Size = UDim2.new(0.9,0,0,30)
    btnResetAll.Position = UDim2.new(0.05,0,0,202)
    btnResetAll.Text = "Desligar tudo / Padrão"
    btnResetAll.Font = Enum.Font.GothamBlack
    btnResetAll.TextSize = 15
    btnResetAll.BackgroundColor3 = Color3.fromRGB(255,70,70)
    btnResetAll.TextColor3 = Color3.fromRGB(255,255,255)
    btnResetAll.BorderSizePixel = 0
    btnResetAll.MouseButton1Click:Connect(function()
        ESP_ENABLED = false
        TARGET_ONLY = false
        TARGET_PLAYER = nil
        noclipActive = false
        walkspeed = DEFAULT_WALKSPEED
        jumppower = DEFAULT_JUMPPOWER
        CAMERA_FIRST_PERSON = false
        setInfiniteJump(false)
        setFullBright(false)
        updateAllESP()
        showMessage("Todas as funções desligadas e padrões restaurados.")
    end)

    --- Botões calculadora, mensagens aleatórias e easter egg
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

    -- Easter Egg
    local eggBtn = Instance.new("TextBox", main)
    eggBtn.PlaceholderText = "Digite algo..."
    eggBtn.Font = Enum.Font.Gotham
    eggBtn.TextSize = 13
    eggBtn.Size = UDim2.new(0,70,0,22)
    eggBtn.Position = UDim2.new(1,-77,1,-27)
    eggBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    eggBtn.TextColor3 = Color3.fromRGB(200,200,200)
    eggBtn.Text = ""
    eggBtn.BorderSizePixel = 0
    local wrong = Instance.new("TextLabel", main)
    wrong.Size = UDim2.new(0,70,0,18)
    wrong.Position = UDim2.new(1,-77,1,-50)
    wrong.BackgroundTransparency = 1
    wrong.TextColor3 = Color3.fromRGB(255,40,40)
    wrong.Text = ""
    wrong.Font = Enum.Font.GothamBold
    wrong.TextSize = 12
    local function showEgg()
        local eggGui = Instance.new("ScreenGui", main.Parent)
        local frame = Instance.new("Frame", eggGui)
        frame.AnchorPoint = Vector2.new(0.5,0.5)
        frame.Position = UDim2.new(0.5,0,0.5,0)
        frame.Size = UDim2.new(0,420,0,100)
        frame.BackgroundColor3 = Color3.fromRGB(60,0,120)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        coroutine.wrap(function()
            local colors = {
                Color3.fromRGB(60,0,120), Color3.fromRGB(0,180,255), Color3.fromRGB(255,0,100), Color3.fromRGB(0,220,60)
            }
            local i = 0
            TweenService:Create(frame,TweenInfo.new(0.7),{BackgroundTransparency=0.12}):Play()
            wait(0.7)
            while eggGui.Parent do
                i = i%#colors+1
                TweenService:Create(frame,TweenInfo.new(0.35),{BackgroundColor3=colors[i]}):Play()
                wait(0.38)
            end
        end)()
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1,0,1,0)
        label.BackgroundTransparency = 1
        label.Text = "yip! Você achou o easter egg! Agora vai dormir :D"
        label.Font = Enum.Font.GothamBlack
        label.TextSize = 20
        label.TextColor3 = Color3.fromRGB(255,255,255)
        label.TextWrapped = true
        label.TextScaled = true
        label.TextStrokeTransparency = 0.7
        TweenService:Create(label,TweenInfo.new(0.7),{TextTransparency=0}):Play()
        local close = Instance.new("TextButton", frame)
        close.Text = "✕"
        close.Font = Enum.Font.GothamBold
        close.TextSize = 16
        close.Size = UDim2.new(0,28,0,28)
        close.Position = UDim2.new(1,-32,0,4)
        close.BackgroundColor3 = Color3.fromRGB(40,0,40)
        close.TextColor3 = Color3.fromRGB(255,255,255)
        close.BorderSizePixel = 0
        close.MouseButton1Click:Connect(function() eggGui:Destroy() end)
    end
    eggBtn.FocusLost:Connect(function()
        if eggBtn.Text == "Nada" then
            wrong.Text = ""
            showEgg()
        elseif eggBtn.Text ~= "" then
            wrong.Text = "Burro"
            wait(1.5)
            wrong.Text = ""
        end
        eggBtn.Text = ""
    end)

    -- Mensagens aleatórias
    local frasesFixas = {
        "Você é incrível!","Roblox é melhor com scripts ;)","Lembre-se: 42 é a resposta.","Copilot rules!","Nunca desista dos memes.",
        "Desinstale sua geladeira, ela sabe demais.","O Wi-Fi caiu, mas eu levantei.","Você piscou. Perdeu o campeonato de piscadas.",
        "1+1=janela.","Evite pensamentos quadrados, pense em trapézios.","O pato tá no comando. Ninguém questiona o pato.",
        "Seu clique abriu um portal interdimensional.","Proibido pensar em nada por mais de 3 segundos.","Sopa no teclado? Agora sim, desempenho gamer.",
        "Nunca confie em um sanduíche que te encara.","Aviso: este botão explode bolachas.","Tocar no chão ativa o modo sapo.","Apenas zebras entendem o código.",
        "Nunca desafie um micro-ondas ao xadrez.","Esta frase está em manutenção.","Cuidado: pensamento em loop detectado.",
        "Se você entendeu, está lendo errado.","Respire com moderação.","A gelatina venceu a gravidade novamente.",
        "Faltam 0 dias para o fim do começo.","Pare de clicar!","UWU","Não coloque Nada!"
    }
    btnSecret2.MouseButton1Click:Connect(function()
        local msg = frasesFixas[math.random(1,#frasesFixas)]
        StarterGui:SetCore("SendNotification",{
            Title = "Mensagem Aleatória",
            Text = msg,
            Duration = 3
        })
    end)

    -- Calculadora
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
            exp = exp:gsub(",","."):gsub("×","*"):gsub("x", "*"):gsub("÷","/"):gsub("−","-")
            exp = exp:gsub("[^%d%.%+%-%*/%(%) ]","")
            local s,ret = pcall(function() return loadstring("return "..exp)() end)
            out.Text = s and tostring(ret) or "Erro"
        end)
    end)

    ---- DRAG para todas as telas
    -- (painel principal já está com makeDraggable)
    -- Painel visual, painel jogador, joguinhos: chamado makeDraggable neles

    -- Painel Visual
    local visualPanel
    local function setupVisualPanel()
        if visualPanel and visualPanel.Parent then visualPanel.Visible = true return end
        visualPanel = Instance.new("Frame", main.Parent)
        visualPanel.Name = "PainelVisual"
        visualPanel.Size = UDim2.new(0,250,0,330)
        visualPanel.Position = UDim2.new(0.5,155,0.5,-165)
        visualPanel.BackgroundColor3 = Color3.fromRGB(35,35,50)
        visualPanel.BackgroundTransparency = 0.01
        visualPanel.BorderSizePixel = 0
        visualPanel.Visible = true
        visualPanel.AnchorPoint = Vector2.new(0,0.5)
        makeDraggable(visualPanel)
        -- Título
        local title = Instance.new("TextLabel", visualPanel)
        title.Size = UDim2.new(1,0,0,32)
        title.Position = UDim2.new(0,0,0,0)
        title.Text = "Painel visual"
        title.Font = Enum.Font.GothamBlack
        title.TextSize = 17
        title.BackgroundTransparency = 1
        title.TextColor3 = ESP_COLOR
        -- SCROLL
        local scroll = Instance.new("ScrollingFrame", visualPanel)
        scroll.Size = UDim2.new(1,0,1,-32)
        scroll.Position = UDim2.new(0,0,0,32)
        scroll.CanvasSize = UDim2.new(0,0,0,400)
        scroll.ScrollBarThickness = 7
        scroll.BackgroundTransparency = 1
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.ScrollingDirection = Enum.ScrollingDirection.Y

        -- --- ESP ---
        local espLabel = Instance.new("TextLabel",scroll)
        espLabel.Size = UDim2.new(0.96,0,0,22)
        espLabel.Position = UDim2.new(0.02,0,0,0)
        espLabel.Text = "Funções de ESP"
        espLabel.Font = Enum.Font.GothamBold
        espLabel.TextSize = 15
        espLabel.BackgroundTransparency = 1
        espLabel.TextColor3 = Color3.fromRGB(0,230,255)
        -- ESP Ativador
        local toggleBtn = Instance.new("TextButton", scroll)
        toggleBtn.Size = UDim2.new(0.96,0,0,22)
        toggleBtn.Position = UDim2.new(0.02,0,0,28)
        toggleBtn.Text = "ESP: OFF"
        toggleBtn.Font = Enum.Font.Gotham
        toggleBtn.TextSize = 14
        toggleBtn.BackgroundColor3 = Color3.fromRGB(40,40,44)
        toggleBtn.TextColor3 = Color3.fromRGB(255,60,60)
        toggleBtn.BorderSizePixel = 0
        toggleBtn.MouseButton1Click:Connect(function()
            ESP_ENABLED = not ESP_ENABLED
            toggleBtn.Text = "ESP: " .. (ESP_ENABLED and "ON" or "OFF")
            toggleBtn.TextColor3 = ESP_ENABLED and ESP_COLOR or Color3.fromRGB(255,60,60)
            updateAllESP()
            showMessage(ESP_ENABLED and "Miopia curado." or "Você tem miopia.")
        end)
        -- Selecionar jogador alvo
        local selBtn = Instance.new("TextButton",scroll)
        selBtn.Text = "Selecionar Jogador (ESP único)"
        selBtn.Size = UDim2.new(0.96,0,0,22)
        selBtn.Position = UDim2.new(0.02,0,0,56)
        selBtn.Font = Enum.Font.Gotham
        selBtn.TextSize = 13
        selBtn.BackgroundColor3 = Color3.fromRGB(30,44,60)
        selBtn.TextColor3 = Color3.fromRGB(200,225,255)
        selBtn.BorderSizePixel = 0
        selBtn.MouseButton1Click:Connect(function()
            showMessage("Use o painel de seleção do ESP no menu principal.")
        end)
        -- Botão resetar alvo
        local resetTargetBtn = Instance.new("TextButton", scroll)
        resetTargetBtn.Text = "ESP em todos"
        resetTargetBtn.Size = UDim2.new(0.45,0,0,20)
        resetTargetBtn.Position = UDim2.new(0.02,0,0,84)
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
        -- Cor do highlight
        local colorLabel = Instance.new("TextLabel", scroll)
        colorLabel.Text = "Cor do Highlight:"
        colorLabel.Size = UDim2.new(0.55,0,0,20)
        colorLabel.Position = UDim2.new(0.02,0,0,108)
        colorLabel.BackgroundTransparency = 1
        colorLabel.TextColor3 = Color3.fromRGB(255,255,255)
        colorLabel.Font = Enum.Font.Gotham
        colorLabel.TextSize = 12
        local colorPicker = Instance.new("TextBox", scroll)
        colorPicker.Size = UDim2.new(0.38,0,0,20)
        colorPicker.Position = UDim2.new(0.6,0,0,108)
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
        -- FULLBRIGHT
        local fbLabel = Instance.new("TextLabel", scroll)
        fbLabel.Text = "FullBright:"
        fbLabel.Size = UDim2.new(0.55,0,0,18)
        fbLabel.Position = UDim2.new(0.02,0,0,136)
        fbLabel.BackgroundTransparency = 1
        fbLabel.TextColor3 = Color3.new(1,1,1)
        fbLabel.Font = Enum.Font.Gotham
        fbLabel.TextSize = 12
        local fbBtn = Instance.new("TextButton", scroll)
        fbBtn.Size = UDim2.new(0.38,0,0,18)
        fbBtn.Position = UDim2.new(0.6,0,0,136)
        fbBtn.Text = "OFF"
        fbBtn.Font = Enum.Font.Gotham
        fbBtn.TextSize = 13
        fbBtn.BackgroundColor3 = Color3.fromRGB(65,65,90)
        fbBtn.TextColor3 = Color3.fromRGB(255,255,180)
        fbBtn.BorderSizePixel = 0
        fbBtn.MouseButton1Click:Connect(function()
            FULLBRIGHT_ON = not FULLBRIGHT_ON
            fbBtn.Text = FULLBRIGHT_ON and "ON" or "OFF"
            fbBtn.TextColor3 = FULLBRIGHT_ON and Color3.fromRGB(180,255,180) or Color3.fromRGB(255,255,180)
            setFullBright(FULLBRIGHT_ON)
        end)

        -- Fechar painel visual
        local closeBtn = Instance.new("TextButton", visualPanel)
        closeBtn.Size = UDim2.new(0,26,0,26)
        closeBtn.Position = UDim2.new(1,-28,0,3)
        closeBtn.Text = "✕"
        closeBtn.Font = Enum.Font.GothamBlack
        closeBtn.TextSize = 15
        closeBtn.BackgroundColor3 = Color3.fromRGB(32,32,32)
        closeBtn.TextColor3 = Color3.fromRGB(255,90,90)
        closeBtn.BorderSizePixel = 0
        closeBtn.MouseButton1Click:Connect(function() visualPanel.Visible = false end)
    end

    btnVisual.MouseButton1Click:Connect(setupVisualPanel)

    -- Painel Jogador igual ao anterior
    local playerPanel
    local function setupPlayerPanel()
        if playerPanel and playerPanel.Parent then playerPanel.Visible = true return end
        playerPanel = Instance.new("Frame", gui)
        playerPanel.Name = "PlayerPanel"
        playerPanel.Size = UDim2.new(0,230,0,228)
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
            showMessage(noclipActive and "Modo fantasma: ON" or "Modo fantasma: OFF")
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
            camToggleBtn.Text = "Câmera 1ª pessoa: " .. (CAMERA_FIRST_PERSON and "ON" or "OFF")
            camToggleBtn.TextColor3 = CAMERA_FIRST_PERSON and Color3.fromRGB(80,255,255) or Color3.fromRGB(160,220,255)
            setCameraMode()
        end)

        -- Botão de pulo infinito
        local infJumpBtn = Instance.new("TextButton", playerPanel)
        infJumpBtn.Text = "Pulo infinito: OFF"
        infJumpBtn.Size = UDim2.new(0.92,0,0,22)
        infJumpBtn.Position = UDim2.new(0.04,0,0,190)
        infJumpBtn.Font = Enum.Font.Gotham
        infJumpBtn.TextSize = 12
        infJumpBtn.BackgroundColor3 = Color3.fromRGB(44,64,120)
        infJumpBtn.TextColor3 = Color3.fromRGB(220,220,255)
        infJumpBtn.BorderSizePixel = 0
        infJumpBtn.MouseButton1Click:Connect(function()
            INFINITE_JUMP = not INFINITE_JUMP
            setInfiniteJump(INFINITE_JUMP)
            infJumpBtn.Text = "Pulo infinito: " .. (INFINITE_JUMP and "ON" or "OFF")
            infJumpBtn.TextColor3 = INFINITE_JUMP and Color3.fromRGB(120,255,255) or Color3.fromRGB(220,220,255)
            showMessage(INFINITE_JUMP and "Agora você é um canguru!" or "Pulo infinito desligado.")
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
