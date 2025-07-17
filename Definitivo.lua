--[[ 
    ESP Script para Roblox (Lua)
    Funcionalidades:
    - Destaca jogadores com borda brilhante (Highlight)
    - Mostra nomes e distância dos jogadores
    - Menu para ativar/desativar ESP
    - Suporte para melhorias: filtro de times, range máximo, suavidade visual

    OBS: Coloque este script em LocalScript (StarterPlayerScripts ou semelhante)
    ATENÇÃO: Para uso em jogos próprios/autorizados. 
--]]

-- CONFIGURAÇÕES
local MAX_DISTANCE = 300    -- Distância máxima para mostrar ESP (em studs)
local SHOW_TEAM = false     -- Mostrar apenas jogadores de outro time?
local ESP_REFRESH = 0.1     -- Intervalo de atualização (segundos)
local ESP_COLOR = Color3.fromRGB(0, 255, 255)
local HIGHLIGHT_FILL = Color3.fromRGB(0, 255, 255)
local HIGHLIGHT_OUTLINE = Color3.fromRGB(255, 255, 0)
local OUTLINE_TRANSPARENCY = 0
local FILL_TRANSPARENCY = 0.7

-- VARIÁVEIS
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local ESP_ENABLED = true

-- TABELA PARA GUARDAR ESP
local ESPObjects = {}

-- FUNÇÃO: Criar highlight
local function createHighlight(target)
    local highlight = Instance.new("Highlight")
    highlight.Adornee = target
    highlight.FillColor = HIGHLIGHT_FILL
    highlight.OutlineColor = HIGHLIGHT_OUTLINE
    highlight.FillTransparency = FILL_TRANSPARENCY
    highlight.OutlineTransparency = OUTLINE_TRANSPARENCY
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = target
    return highlight
end

-- FUNÇÃO: Criar BillboardGui com nome e distância
local function createBillboard(target, name, distance)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPBillboard"
    billboard.Adornee = target
    billboard.Size = UDim2.new(0, 200, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.TextStrokeTransparency = 0.2
    text.TextColor3 = ESP_COLOR
    text.Font = Enum.Font.GothamBold
    text.TextScaled = true
    text.Text = string.format("%s | %.1fm", name, distance/3.571) -- Aproximadamente metros
    text.Parent = billboard

    billboard.Parent = target
    return billboard
end

-- FUNÇÃO: Remover ESP visual
local function removeESP(char)
    if ESPObjects[char] then
        if ESPObjects[char].Highlight then
            pcall(function() ESPObjects[char].Highlight:Destroy() end)
        end
        if ESPObjects[char].Billboard then
            pcall(function() ESPObjects[char].Billboard:Destroy() end)
        end
        ESPObjects[char] = nil
    end
end

-- FUNÇÃO: Atualizar ESP para um jogador
local function updateESP(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then removeESP(char) return end

    -- Filtro por time
    if SHOW_TEAM and player.Team == LocalPlayer.Team then
        removeESP(char)
        return
    end

    local distance = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"))
        and (char.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        or math.huge
    if distance > MAX_DISTANCE then
        removeESP(char)
        return
    end

    -- Criação de ESP visual
    if not ESPObjects[char] then ESPObjects[char] = {} end
    -- Highlight
    if not ESPObjects[char].Highlight or ESPObjects[char].Highlight.Parent ~= char then
        ESPObjects[char].Highlight = createHighlight(char)
    end
    -- Billboard
    if ESPObjects[char].Billboard then
        ESPObjects[char].Billboard:Destroy()
    end
    ESPObjects[char].Billboard = createBillboard(char:FindFirstChild("Head") or char.HumanoidRootPart, player.DisplayName, distance)
end

-- FUNÇÃO: Atualização geral
local function updateAllESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if ESP_ENABLED then
            updateESP(player)
        else
            if player.Character then removeESP(player.Character) end
        end
    end
end

-- LIMPEZA EM DESCONEXÃO
Players.PlayerRemoving:Connect(function(player)
    if player.Character then removeESP(player.Character) end
end)

-- MENU SIMPLES (ScreenGui)
local function setupMenu()
    local gui = Instance.new("ScreenGui")
    gui.Name = "ESPMenu"
    gui.Parent = game:GetService("Players").LocalPlayer.PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 120)
    frame.Position = UDim2.new(0, 10, 0, 120)
    frame.BackgroundTransparency = 0.3
    frame.BackgroundColor3 = Color3.new(0,0,0)
    frame.BorderSizePixel = 2
    frame.Parent = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,30)
    title.Position = UDim2.new(0,0,0,0)
    title.Text = "ESP Menu"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.TextColor3 = Color3.new(1,1,1)
    title.BackgroundTransparency = 1
    title.Parent = frame

    -- Botão ESP ON/OFF
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 32)
    btn.Position = UDim2.new(0,10/200,0,40)
    btn.Text = "ESP: ON"
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 20
    btn.BackgroundColor3 = Color3.fromRGB(20,20,20)
    btn.TextColor3 = Color3.fromRGB(0,255,255)
    btn.Parent = frame

    btn.MouseButton1Click:Connect(function()
        ESP_ENABLED = not ESP_ENABLED
        btn.Text = "ESP: " .. (ESP_ENABLED and "ON" or "OFF")
        btn.TextColor3 = ESP_ENABLED and Color3.fromRGB(0,255,255) or Color3.fromRGB(255,60,60)
        updateAllESP()
    end)

    -- Mostrar times
    local teamBtn = Instance.new("TextButton")
    teamBtn.Size = UDim2.new(1, -20, 0, 28)
    teamBtn.Position = UDim2.new(0,10/200,0,80)
    teamBtn.Text = "Mostrar Todos Times"
    teamBtn.Font = Enum.Font.Gotham
    teamBtn.TextSize = 16
    teamBtn.BackgroundColor3 = Color3.fromRGB(20,20,20)
    teamBtn.TextColor3 = Color3.fromRGB(255,255,255)
    teamBtn.Parent = frame

    teamBtn.MouseButton1Click:Connect(function()
        SHOW_TEAM = not SHOW_TEAM
        teamBtn.Text = SHOW_TEAM and "Somente Outros Times" or "Mostrar Todos Times"
        updateAllESP()
    end)
end

-- LOOP DE ATUALIZAÇÃO
spawn(setupMenu)
RunService.RenderStepped:Connect(function()
    if ESP_ENABLED then
        updateAllESP()
    end
end)

-- ATUALIZAÇÃO PERIÓDICA (para garantir atualização geral)
while true do
    updateAllESP()
    wait(ESP_REFRESH)
end
