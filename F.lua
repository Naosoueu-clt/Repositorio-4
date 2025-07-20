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

local openIconBtn -- para manter visível

local function setupMenuIcon(openCallback)
    if openIconBtn and openIconBtn.Parent then return end
    local gui = Instance.new("ScreenGui")
    gui.Name = "ScriptMenuIcon"
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

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

    -- Botão sempre visível e no topo
    gui.DisplayOrder = 1000
    floatBtn.ZIndex = 20

    makeDraggable(floatBtn)
    floatBtn.MouseButton1Click:Connect(function()
        if openCallback then openCallback() end
    end)
    openIconBtn = floatBtn
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

------------------------ RESTANTE DO SCRIPT (idêntico ao seu anterior) ------------------------
-- (todo o restante do código permanece igual, só substitua o setupMenuIcon pelo acima)

-- No final, chame o setupMenuIcon ANTES de mostrar o painel principal para garantir que sempre estará visível:
coroutine.wrap(showLoadingScreen)()
wait(2.2)
setupMenuIcon(function()
    -- O painel principal sempre aparece ao clicar no olho
    for _,gui in pairs(LocalPlayer.PlayerGui:GetChildren()) do
        if gui.Name == "ScriptMainPanel" then
            local main = gui:FindFirstChild("MainPanel")
            if main then main.Visible = not main.Visible end
        end
    end
end)
setupMainPanel()

RunService.RenderStepped:Connect(function()
    setCameraMode()
    updateAllESP()
end)

-- FIM
