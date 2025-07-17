--[[
  Manual Anti-Cheat Script para Roblox (somente uso pessoal)
  Recursos:
    - Varredura por jogadores com velocidade/movimento anormais
    - Destaca nomes/avatares suspeitos (ex: nomes inapropriados)
    - Lista todos os jogadores, mostra nick e displayname
    - Menu flutuante e arrastável com funções
    - Ver câmera de qualquer jogador (spectate)
    - Aviso customizável para suspeitos (opcional)
    - Apenas o usuário autorizado pode abrir o menu
  
  ATENÇÃO: Apenas para uso pessoal, não compartilhe!
]]

-- CONFIGURAÇÕES
local OWNER_USERID = 1234567890 -- Substitua pelo seu UserId!

-- PALAVRAS PROIBIDAS NO NOME/DISPLAYNAME
local BAD_WORDS = {"admin", "hack", "script", "exploit", "cheat", "ban", "nude", "fuck", "sexo", "bunda", "puta"}

-- VELOCIDADE LIMITE
local DEFAULT_WALKSPEED = 16
local SPEED_THRESHOLD = 17

-- SERVIÇOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

if LocalPlayer.UserId ~= OWNER_USERID then return end -- Apenas dono

-- UI - MENU FLUTUANTE
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "ManualAntiCheatMenu"

local MenuFrame = Instance.new("Frame", ScreenGui)
MenuFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
MenuFrame.Position = UDim2.new(0.2,0,0.2,0)
MenuFrame.Size = UDim2.new(0, 350, 0, 320)
MenuFrame.Active = true
MenuFrame.Draggable = true
MenuFrame.BorderSizePixel = 0
MenuFrame.BackgroundTransparency = 0.2

local Title = Instance.new("TextLabel", MenuFrame)
Title.Text = "Manual Anti-Cheat"
Title.Size = UDim2.new(1,0,0,30)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.SourceSansBold
Title.TextScaled = true

local PlayersList = Instance.new("ScrollingFrame", MenuFrame)
PlayersList.Position = UDim2.new(0, 10, 0, 40)
PlayersList.Size = UDim2.new(0, 200, 0, 205)
PlayersList.CanvasSize = UDim2.new(0,0,0,0)
PlayersList.BorderSizePixel = 0
PlayersList.BackgroundTransparency = 0.15
PlayersList.ScrollBarThickness = 8

local ScanButton = Instance.new("TextButton", MenuFrame)
ScanButton.Text = "Varredura"
ScanButton.Position = UDim2.new(0, 220, 0, 50)
ScanButton.Size = UDim2.new(0, 110, 0, 36)
ScanButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
ScanButton.TextColor3 = Color3.new(1,1,1)
ScanButton.Font = Enum.Font.SourceSansBold
ScanButton.TextScaled = true

local SpectateButton = Instance.new("TextButton", MenuFrame)
SpectateButton.Text = "Ver câmera"
SpectateButton.Position = UDim2.new(0, 220, 0, 100)
SpectateButton.Size = UDim2.new(0, 110, 0, 36)
SpectateButton.BackgroundColor3 = Color3.fromRGB(50,50,80)
SpectateButton.TextColor3 = Color3.new(1,1,1)
SpectateButton.Font = Enum.Font.SourceSansBold
SpectateButton.TextScaled = true

local Spectating = false
local SpectateTarget = nil

local StopSpectateButton = Instance.new("TextButton", MenuFrame)
StopSpectateButton.Text = "Parar câmera"
StopSpectateButton.Position = UDim2.new(0, 220, 0, 150)
StopSpectateButton.Size = UDim2.new(0, 110, 0, 36)
StopSpectateButton.BackgroundColor3 = Color3.fromRGB(30,30,30)
StopSpectateButton.TextColor3 = Color3.new(1,1,1)
StopSpectateButton.Font = Enum.Font.SourceSansBold
StopSpectateButton.TextScaled = true

local WarnButton = Instance.new("TextButton", MenuFrame)
WarnButton.Text = "Avisar"
WarnButton.Position = UDim2.new(0, 220, 0, 200)
WarnButton.Size = UDim2.new(0, 110, 0, 36)
WarnButton.BackgroundColor3 = Color3.fromRGB(70,30,30)
WarnButton.TextColor3 = Color3.new(1,1,1)
WarnButton.Font = Enum.Font.SourceSansBold
WarnButton.TextScaled = true

local InfoLabel = Instance.new("TextLabel", MenuFrame)
InfoLabel.Text = "Selecione um jogador na lista"
InfoLabel.Position = UDim2.new(0, 10, 0, 255)
InfoLabel.Size = UDim2.new(0, 320, 0, 50)
InfoLabel.BackgroundTransparency = 1
InfoLabel.TextColor3 = Color3.new(1,1,1)
InfoLabel.Font = Enum.Font.SourceSans
InfoLabel.TextScaled = true
InfoLabel.TextWrapped = true

-- Função de filtro de nomes
local function HasBadWords(str)
    str = string.lower(str)
    for _,bad in ipairs(BAD_WORDS) do
        if string.find(str, bad, 1, true) then
            return true
        end
    end
    return false
end

-- Função: Atualizar a lista de jogadores
local PlayerButtons = {}
local Highlighted = {}
local function UpdatePlayersList()
    for _,b in pairs(PlayerButtons) do b:Destroy() end
    PlayerButtons = {}
    local y = 0
    local suspicious = {}
    for _,player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local speed = humanoid and humanoid.WalkSpeed or DEFAULT_WALKSPEED
        local isSus = false
        local info = "["..player.DisplayName.."] ("..player.Name..")"
        -- Verificação de nome
        if HasBadWords(player.Name) or HasBadWords(player.DisplayName) then
            info = info.." [NOME SUSPEITO]"
            isSus = true
        end
        -- Verificação de velocidade
        if speed > SPEED_THRESHOLD then
            info = info.." [SPEED:"..math.floor(speed).."]"
            isSus = true
        end
        -- Avatar (pode colocar outras regras)
        if char and #char:GetChildren() < 5 then
            info = info.." [AVATAR SUSPEITO]"
            isSus = true
        end
        -- Cria botão
        local btn = Instance.new("TextButton")
        btn.Parent = PlayersList
        btn.Size = UDim2.new(1, -10, 0, 30)
        btn.Position = UDim2.new(0, 5, 0, y)
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Text = info
        btn.BackgroundColor3 = isSus and Color3.fromRGB(120,40,40) or Color3.fromRGB(40,40,40)
        btn.TextColor3 = isSus and Color3.fromRGB(1,0.7,0.7) or Color3.new(1,1,1)
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 18
        btn.AutoButtonColor = false
        btn.MouseButton1Click:Connect(function()
            SpectateTarget = player
            InfoLabel.Text = "Selecionado: "..player.DisplayName.." ("..player.Name..")"
        end)
        y = y + 32
        table.insert(PlayerButtons, btn)
        if isSus then table.insert(suspicious, player) end
        Highlighted[player] = isSus
    end
    PlayersList.CanvasSize = UDim2.new(0,0,0,y+5)
    Title.Text = "Manual Anti-Cheat ["..#Players:GetPlayers().." jogadores]"
end

-- Função: Varredura rápida
local function Scan()
    UpdatePlayersList()
    InfoLabel.Text = "Varredura completa! Jogadores suspeitos destacados em vermelho."
end
ScanButton.MouseButton1Click:Connect(Scan)

-- Função: Spectate (câmera)
local function Spectate()
    if SpectateTarget and SpectateTarget.Character and SpectateTarget.Character:FindFirstChild("HumanoidRootPart") then
        workspace.CurrentCamera.CameraSubject = SpectateTarget.Character:FindFirstChild("Humanoid")
        Spectating = true
        InfoLabel.Text = "Câmera: "..SpectateTarget.DisplayName
    else
        InfoLabel.Text = "Selecione um jogador válido para ver a câmera!"
    end
end
SpectateButton.MouseButton1Click:Connect(Spectate)
StopSpectateButton.MouseButton1Click:Connect(function()
    workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
    Spectating = false
    InfoLabel.Text = "Câmera normal"
end)

-- Função: Avisar o jogador selecionado
local function Warn()
    if SpectateTarget and SpectateTarget:FindFirstChild("PlayerGui") then
        local remote = Instance.new("RemoteEvent")
        remote.Name = "AntiCheatWarn"
        remote.Parent = workspace
        remote.OnServerEvent:Connect(function(plr)
            if plr == SpectateTarget then
                local sg = Instance.new("ScreenGui", plr.PlayerGui)
                sg.Name = "WarnGui"
                local msg = Instance.new("TextLabel", sg)
                msg.Size = UDim2.new(1,0,0.2,0)
                msg.Position = UDim2.new(0,0,0.4,0)
                msg.BackgroundTransparency = 0.3
                msg.BackgroundColor3 = Color3.fromRGB(120,30,30)
                msg.TextColor3 = Color3.new(1,1,1)
                msg.Font = Enum.Font.SourceSansBold
                msg.TextScaled = true
                msg.Text = "ATENÇÃO!\nRemova quaisquer scripts/exploits imediatamente.\nCaso contrário, você poderá ser punido."
                wait(8)
                sg:Destroy()
                remote:Destroy()
            end
        end)
        remote:FireServer(SpectateTarget)
        InfoLabel.Text = "Aviso enviado para "..SpectateTarget.DisplayName
    else
        InfoLabel.Text = "Selecione um jogador para avisar."
    end
end
WarnButton.MouseButton1Click:Connect(Warn)

-- Atualiza a lista se entrar/sair alguém
Players.PlayerAdded:Connect(UpdatePlayersList)
Players.PlayerRemoving:Connect(UpdatePlayersList)
UpdatePlayersList()

-- Atalho para abrir/fechar o menu (tecla: M)
MenuFrame.Visible = true
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.M then
        MenuFrame.Visible = not MenuFrame.Visible
    end
end)

-- Fim do script
