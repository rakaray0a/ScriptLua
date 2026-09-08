-- ==========================================
-- OPTIMASI DELTA EXECUTOR (Anti-AFK & Bypass)
-- ==========================================
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Tunggu sampai game selesai dimuat sepenuhnya
repeat task.wait() until game:IsLoaded()

local workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Camera = workspace.CurrentCamera
local HttpService = game:GetService("HttpService")

-- ==========================================
-- CONFIG, STATE & SAVE SYSTEM (LOCKED)
-- ==========================================
local CONFIG_FILE_NAME = "BLB_AutoFarm_Config_Pras.json"

local CONFIG = {
    MiningDelay = 4.5,
    WoodcuttingDelay = 5,
    CollectSpeed = 135,
    CookSlots = 3, 
    RestockInterval = 10, 
    SafetyCheckInterval = 0.5
}

local _G_AutoMining = false   
local _G_AutoWood = false     
local _G_AutoCollect = false  
local _G_AutoCook = false     
local _G_AutoRestock = false  
local _G_AntiAfk = true       
local isFarming = false
local isRepairing = false
local currentTargetPrompt = nil
local bodyVelocity = nil
local lastCookCheck = 0       
local lastRestockTime = 0     

local selectedMiningTool = "BeliungArwah"
local selectedWoodTool = "KapakArwah"

local selectedCollectItems = {
    ["Spawn_Dupa"] = true, 
    ["Spawn_Gagak"] = false,
    ["Spawn_JamurKuburan"] = false,
    ["Spawn_Kemenyan"] = false,
    ["Spawn_KepitingSungai"] = false,
    ["Spawn_Melati"] = false
}

-- Mapping nama asli ke nama tampilan UI (Hanya rename tampilan)
local collectDisplayNames = {
    ["Spawn_Dupa"] = "Dupa",
    ["Spawn_Gagak"] = "Gagak",
    ["Spawn_JamurKuburan"] = "Jamur Kuburan",
    ["Spawn_Kemenyan"] = "Kemenyan",
    ["Spawn_KepitingSungai"] = "Kepiting Sungai",
    ["Spawn_Melati"] = "Melati"
}

local collectItemsList = {
    "Spawn_Dupa", 
    "Spawn_Gagak", 
    "Spawn_JamurKuburan", 
    "Spawn_Kemenyan", 
    "Spawn_KepitingSungai", 
    "Spawn_Melati"
}

-- Fungsi Save Config ke File Executor
local function saveConfig()
    pcall(function()
        if writefile then
            local data = {
                MiningDelay = CONFIG.MiningDelay,
                WoodcuttingDelay = CONFIG.WoodcuttingDelay,
                CollectSpeed = CONFIG.CollectSpeed,
                CookSlots = CONFIG.CookSlots,
                RestockInterval = CONFIG.RestockInterval,
                selectedMiningTool = selectedMiningTool,
                selectedWoodTool = selectedWoodTool,
                selectedCollectItems = selectedCollectItems,
                _G_AntiAfk = _G_AntiAfk
            }
            writefile(CONFIG_FILE_NAME, HttpService:JSONEncode(data))
        end
    end)
end

-- Fungsi Load Config dari File Executor
local function loadConfig()
    pcall(function()
        if readfile and isfile and isfile(CONFIG_FILE_NAME) then
            local content = readfile(CONFIG_FILE_NAME)
            local data = HttpService:JSONDecode(content)
            if data then
                if data.MiningDelay then CONFIG.MiningDelay = data.MiningDelay end
                if data.WoodcuttingDelay then CONFIG.WoodcuttingDelay = data.WoodcuttingDelay end
                if data.CollectSpeed then CONFIG.CollectSpeed = data.CollectSpeed end
                if data.CookSlots then CONFIG.CookSlots = data.CookSlots end
                if data.RestockInterval then CONFIG.RestockInterval = data.RestockInterval end
                if data.selectedMiningTool then selectedMiningTool = data.selectedMiningTool end
                if data.selectedWoodTool then selectedWoodTool = data.selectedWoodTool end
                if data._G_AntiAfk ~= nil then _G_AntiAfk = data._G_AntiAfk end
                if data.selectedCollectItems then
                    for k, v in pairs(data.selectedCollectItems) do
                        if selectedCollectItems[k] ~= nil then
                            selectedCollectItems[k] = v
                        end
                    end
                end
            end
        end
    end)
end

loadConfig()

player.Idled:Connect(function()
    if _G_AntiAfk then
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

-- ==========================================
-- MODERN ULTRA UI CREATION: BLB HUB PRO (MENYATU)
-- ==========================================
local playerGui = player:WaitForChild("PlayerGui")
local uiParent = (gethui and gethui()) or game:GetService("CoreGui") or playerGui 

local existingGui = uiParent:FindFirstChild("BLB_AutoFarm_Pro_V28")
if existingGui then existingGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BLB_AutoFarm_Pro_V28"
screenGui.ResetOnSpawn = false
screenGui.Parent = uiParent

-- Main Container (Diperlebar agar panel info menyatu di sebelah kanan di dalam satu kotak)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 510, 0, 680)
mainFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
mainFrame.BackgroundTransparency = 0.04
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 14)
uiCorner.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Thickness = 2
uiStroke.Transparency = 0.15
uiStroke.Parent = mainFrame
local strokeGradient = Instance.new("UIGradient")
strokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 204)), 
    ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 0, 255))
})
strokeGradient.Parent = uiStroke

-- Header Menu Utama
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
header.BackgroundTransparency = 0.9
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 14)
headerCorner.Parent = header
local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 30)), 
    ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 20, 50))
})
headerGradient.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -90, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.Text = "BLB HUB PRO"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 16
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header
local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)), 
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 255))
})
titleGradient.Parent = titleLabel

-- Container Konten Kiri (Fitur & Tombol)
local container = Instance.new("Frame")
container.Size = UDim2.new(0, 260, 1, -42)
container.Position = UDim2.new(0, 0, 0, 42)
container.BackgroundTransparency = 1
container.Parent = mainFrame

-- ==========================================
-- [NEW] PANEL INFORMASI KANAN (MENYATU DALAM UI)
-- ==========================================
local infoFrame = Instance.new("Frame")
infoFrame.Size = UDim2.new(0, 220, 0, 320)
infoFrame.Position = UDim2.new(0, 275, 0, 10)
infoFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
infoFrame.BackgroundTransparency = 0.3
infoFrame.BorderSizePixel = 0
infoFrame.Parent = container

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 10)
infoCorner.Parent = infoFrame

local infoStroke = Instance.new("UIStroke")
infoStroke.Thickness = 1.5
infoStroke.Transparency = 0.3
infoStroke.Parent = infoFrame
local infoGradient = Instance.new("UIGradient")
infoGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 204)), 
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 128))
})
infoGradient.Parent = infoStroke

local infoHeader = Instance.new("Frame")
infoHeader.Size = UDim2.new(1, 0, 0, 35)
infoHeader.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
infoHeader.BackgroundTransparency = 0.92
infoHeader.BorderSizePixel = 0
infoHeader.Parent = infoFrame

local infoHeaderCorner = Instance.new("UICorner")
infoHeaderCorner.CornerRadius = UDim.new(0, 10)
infoHeaderCorner.Parent = infoHeader

local infoTitle = Instance.new("TextLabel")
infoTitle.Size = UDim2.new(1, 0, 1, 0)
infoTitle.BackgroundTransparency = 1
infoTitle.Font = Enum.Font.GothamBlack
infoTitle.Text = "⚡ DELAY REFERENCE"
infoTitle.TextColor3 = Color3.fromRGB(0, 255, 204)
infoTitle.TextSize = 12
infoTitle.Parent = infoHeader

local infoTextContent = Instance.new("TextLabel")
infoTextContent.Size = UDim2.new(1, -20, 1, -40)
infoTextContent.Position = UDim2.new(0, 10, 0, 40)
infoTextContent.BackgroundTransparency = 1
infoTextContent.Font = Enum.Font.Code
infoTextContent.TextXAlignment = Enum.TextXAlignment.Left
infoTextContent.TextYAlignment = Enum.TextYAlignment.Top
infoTextContent.TextColor3 = Color3.fromRGB(220, 220, 240)
infoTextContent.TextSize = 11
infoTextContent.RichText = true
infoTextContent.Text = [[<b><font color="#00ffcc">Auto Mining</font></b>
• Beliung Kayu : delay 13
• Beliung Besi : delay 6
• Beliung Arwah: delay 4.5

<b><font color="#aa00ff">Auto Wood</font></b>
• Kapak Kayu  : delay 13
• Kapak Besi  : delay 6
• Kapak Arwah : delay 4.5]]
infoTextContent.Parent = infoFrame

-- ==========================================
-- STATUS LABEL & KONTROL KIRI
-- ==========================================
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -30, 0, 22)
statusLabel.Position = UDim2.new(0, 15, 0, 10)
statusLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statusLabel.BackgroundTransparency = 0.5
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Text = "SYSTEM: IDLE"
statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
statusLabel.TextSize = 11
statusLabel.Parent = container
local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = statusLabel
local statusStroke = Instance.new("UIStroke")
statusStroke.Color = Color3.fromRGB(60, 60, 80)
statusStroke.Parent = statusLabel

local function createModernToggle(name, yPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -30, 0, 32)
    btn.Position = UDim2.new(0, 15, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamBlack
    btn.Text = name .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.TextSize = 12
    btn.Parent = container

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(50, 50, 70)
    stroke.Thickness = 1.5
    stroke.Parent = btn
    
    return btn, stroke
end

local toggleMineBtn, mineStroke = createModernToggle("AUTO MINING", 42)
local toggleWoodBtn, woodStroke = createModernToggle("AUTO WOOD", 82)
local toggleCollectBtn, collectStroke = createModernToggle("AUTO COLLECT", 122) 
local toggleCookBtn, cookStroke = createModernToggle("AUTO COOK", 162) 
local toggleRestockBtn, restockStroke = createModernToggle("AUTO RESTOCK", 202) 
local toggleAfkBtn, afkStroke = createModernToggle("ANTI-AFK", 242)

if _G_AntiAfk then
    toggleAfkBtn.Text = "ANTI-AFK: ON"
    toggleAfkBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
    toggleAfkBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    afkStroke.Color = Color3.fromRGB(50, 205, 50)
    afkStroke.Thickness = 2
end

local function getPlayerTools(toolType)
    local foundTools = {}
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    
    local containers = {backpack, character}
    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") then
                    local nameLower = item.Name:lower()
                    if toolType == "Mining" and (string.find(nameLower, "beliung") or string.find(nameLower, "pickaxe")) then
                        if not table.find(foundTools, item.Name) then table.insert(foundTools, item.Name) end
                    elseif toolType == "Wood" and (string.find(nameLower, "kapak") or string.find(nameLower, "axe")) then
                        if not table.find(foundTools, item.Name) then table.insert(foundTools, item.Name) end
                    end
                end
            end
        end
    end
    if #foundTools == 0 then table.insert(foundTools, toolType == "Mining" and "BeliungBesi" or "KapakKayu") end
    return foundTools
end

local function createDropdown(name, getListFunc, initialVal, yPos, onSelectCallback)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.45, 0, 0, 24)
    label.Position = UDim2.new(0, 15, 0, yPos)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = name
    label.TextColor3 = Color3.fromRGB(200, 200, 220)
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(0.55, -30, 0, 24)
    dropBtn.Position = UDim2.new(0.45, 15, 0, yPos)
    dropBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    dropBtn.BorderSizePixel = 0
    dropBtn.Font = Enum.Font.GothamBold
    dropBtn.Text = initialVal
    dropBtn.TextColor3 = Color3.fromRGB(0, 255, 204)
    dropBtn.TextSize = 10
    dropBtn.Parent = container

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = dropBtn
    
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(60, 60, 90)
    btnStroke.Parent = dropBtn

    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Size = UDim2.new(0.55, -30, 0, 0)
    listFrame.Position = UDim2.new(0.45, 15, 0, yPos + 28)
    listFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    listFrame.BorderSizePixel = 0
    listFrame.Visible = false
    listFrame.ZIndex = 5
    listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    listFrame.ScrollBarThickness = 2
    listFrame.Parent = container

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = listFrame

    local isOpen = false

    dropBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            for _, child in ipairs(listFrame:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end

            local items = getListFunc()
            for _, itemText in ipairs(items) do
                local itemBtn = Instance.new("TextButton")
                itemBtn.Size = UDim2.new(1, 0, 0, 24)
                itemBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
                itemBtn.BorderSizePixel = 0
                itemBtn.Font = Enum.Font.GothamMedium
                itemBtn.Text = itemText
                itemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                itemBtn.TextSize = 10
                itemBtn.ZIndex = 6
                itemBtn.Parent = listFrame

                itemBtn.MouseButton1Click:Connect(function()
                    dropBtn.Text = itemText
                    onSelectCallback(itemText)
                    saveConfig() 
                    isOpen = false
                    listFrame.Visible = false
                    listFrame:TweenSize(UDim2.new(0.55, -30, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
                end)
            end

            listFrame.CanvasSize = UDim2.new(0, 0, 0, #items * 24)
            local targetHeight = math.clamp(#items * 24, 24, 96)
            listFrame.Visible = true
            listFrame:TweenSize(UDim2.new(0.55, -30, 0, targetHeight), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
        else
            listFrame:TweenSize(UDim2.new(0.55, -30, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
            task.wait(0.15)
            listFrame.Visible = false
        end
    end)
end

local function createMultiSelectDropdown(name, itemsList, selectionDict, displayNameMap, yPos)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.45, 0, 0, 24)
    label.Position = UDim2.new(0, 15, 0, yPos)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = name
    label.TextColor3 = Color3.fromRGB(200, 200, 220)
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(0.55, -30, 0, 24)
    dropBtn.Position = UDim2.new(0.45, 15, 0, yPos)
    dropBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    dropBtn.BorderSizePixel = 0
    dropBtn.Font = Enum.Font.GothamBold
    dropBtn.TextColor3 = Color3.fromRGB(0, 255, 204)
    dropBtn.TextSize = 10
    dropBtn.TextTruncate = Enum.TextTruncate.AtEnd
    dropBtn.Parent = container

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = dropBtn
    
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(60, 60, 90)
    btnStroke.Parent = dropBtn

    local listFrame = Instance.new("ScrollingFrame")
    listFrame.Size = UDim2.new(0.55, -30, 0, 0)
    listFrame.Position = UDim2.new(0.45, 15, 0, yPos + 28)
    listFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    listFrame.BorderSizePixel = 0
    listFrame.Visible = false
    listFrame.ZIndex = 5
    listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    listFrame.ScrollBarThickness = 2
    listFrame.Parent = container

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = listFrame

    local function updateBtnText()
        local count = 0
        local lastName = ""
        for k, v in pairs(selectionDict) do 
            if v then 
                count = count + 1 
                lastName = displayNameMap[k] or k
            end 
        end
        
        if count == 0 then dropBtn.Text = "None"
        elseif count == 1 then dropBtn.Text = lastName
        else dropBtn.Text = count .. " Selected" end
    end
    updateBtnText()

    local isOpen = false

    dropBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            for _, child in ipairs(listFrame:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end

            for _, internalName in ipairs(itemsList) do
                local displayName = displayNameMap[internalName] or internalName
                local itemBtn = Instance.new("TextButton")
                itemBtn.Size = UDim2.new(1, 0, 0, 24)
                itemBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
                itemBtn.BorderSizePixel = 0
                itemBtn.Font = Enum.Font.GothamMedium
                itemBtn.TextSize = 10
                itemBtn.ZIndex = 6
                itemBtn.Parent = listFrame
                
                local function updateItemVisual()
                    if selectionDict[internalName] then
                        itemBtn.TextColor3 = Color3.fromRGB(0, 255, 204)
                        itemBtn.Text = "[✓] " .. displayName
                    else
                        itemBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
                        itemBtn.Text = "[  ] " .. displayName
                    end
                end
                updateItemVisual()

                itemBtn.MouseButton1Click:Connect(function()
                    selectionDict[internalName] = not selectionDict[internalName]
                    updateItemVisual()
                    updateBtnText()
                    saveConfig() 
                end)
            end

            listFrame.CanvasSize = UDim2.new(0, 0, 0, #itemsList * 24)
            local targetHeight = math.clamp(#itemsList * 24, 24, 96)
            listFrame.Visible = true
            listFrame:TweenSize(UDim2.new(0.55, -30, 0, targetHeight), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
        else
            listFrame:TweenSize(UDim2.new(0.55, -30, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.15, true)
            task.wait(0.15)
            listFrame.Visible = false
        end
    end)
end

createDropdown("⛏️ Mining Tool", function() return getPlayerTools("Mining") end, selectedMiningTool, 285, function(val) selectedMiningTool = val end)
createDropdown("🪓 Wood Tool", function() return getPlayerTools("Wood") end, selectedWoodTool, 317, function(val) selectedWoodTool = val end)
createMultiSelectDropdown("🌿 Collect Items", collectItemsList, selectedCollectItems, collectDisplayNames, 349) 

local function createParamInput(name, defaultVal, yPos, callback)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.55, 0, 0, 24)
    label.Position = UDim2.new(0, 15, 0, yPos)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = name
    label.TextColor3 = Color3.fromRGB(150, 150, 170)
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0.45, -30, 0, 24)
    textBox.Position = UDim2.new(0.55, 15, 0, yPos)
    textBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    textBox.BorderSizePixel = 0
    textBox.Font = Enum.Font.GothamBlack
    textBox.Text = tostring(defaultVal)
    textBox.TextColor3 = Color3.fromRGB(170, 0, 255)
    textBox.TextSize = 11
    textBox.Parent = container

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = textBox
    
    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = Color3.fromRGB(50, 50, 70)
    boxStroke.Parent = textBox

    textBox.FocusLost:Connect(function()
        local num = tonumber(textBox.Text)
        if num then
            callback(num)
            saveConfig() 
        else
            textBox.Text = tostring(defaultVal)
        end
    end)
end

createParamInput("Mining Delay (s)", CONFIG.MiningDelay, 381, function(val) CONFIG.MiningDelay = val end)
createParamInput("Wood Delay (s)", CONFIG.WoodcuttingDelay, 413, function(val) CONFIG.WoodcuttingDelay = val end)
createParamInput("Collect Speed", CONFIG.CollectSpeed, 445, function(val) CONFIG.CollectSpeed = val end)
createParamInput("Cook Slots", CONFIG.CookSlots, 477, function(val) CONFIG.CookSlots = val end) 
createParamInput("Restock Interval", CONFIG.RestockInterval, 509, function(val) CONFIG.RestockInterval = val end)

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -75, 0, 6)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
minimizeBtn.BackgroundTransparency = 0.3
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Font = Enum.Font.GothamBlack
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.TextSize = 16
minimizeBtn.Parent = header
local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 8)
minCorner.Parent = minimizeBtn

local resizeBtn = Instance.new("TextButton")
resizeBtn.Size = UDim2.new(0, 30, 0, 30)
resizeBtn.Position = UDim2.new(1, -40, 0, 6)
resizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
resizeBtn.BackgroundTransparency = 0.3
resizeBtn.BorderSizePixel = 0
resizeBtn.Font = Enum.Font.GothamBlack
resizeBtn.Text = "⛶"
resizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resizeBtn.TextSize = 14
resizeBtn.Parent = header
local resCorner = Instance.new("UICorner")
resCorner.CornerRadius = UDim.new(0, 8)
resCorner.Parent = resizeBtn

local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        container.Visible = false
        mainFrame:TweenSize(UDim2.new(0, 510, 0, 42), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.3, true)
        minimizeBtn.Text = "+"
    else
        mainFrame:TweenSize(UDim2.new(0, 510, 0, 680), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.3, true)
        container.Visible = true
        minimizeBtn.Text = "-"
    end
end)

local sizeState = 1
resizeBtn.MouseButton1Click:Connect(function()
    sizeState = sizeState + 1
    if sizeState > 3 then sizeState = 1 end
    if sizeState == 1 then mainFrame.Size = UDim2.new(0, 510, 0, 680)
    elseif sizeState == 2 then mainFrame.Size = UDim2.new(0, 440, 0, 550)
    elseif sizeState == 3 then mainFrame.Size = UDim2.new(0, 600, 0, 760) end
end)

local dragging, dragInput, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ==========================================
-- FLY & NOCLIP SYSTEM (ANTI-SEAT CRASH)
-- ==========================================
local function enableFly(rootPart)
    if bodyVelocity then bodyVelocity:Destroy() end
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Parent = rootPart
end

local function disableFly()
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    local character = player.Character
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end
end

RunService.Stepped:Connect(function()
    local character = player.Character
    if character and (isFarming or isRepairing) then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Sit = false 
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = false
            elseif part:IsA("Seat") or part:IsA("VehicleSeat") then
                part.CanCollide = false
                part.Disabled = true
                part:Sit(nil) 
            end
        end
    end
end)

local function equipTool(toolName)
    local character = player.Character
    if not character then return false end
    local equipped = character:FindFirstChild(toolName)
    if equipped and equipped:IsA("Tool") then return true end

    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        local tool = backpack:FindFirstChild(toolName)
        if tool and tool:IsA("Tool") then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid:EquipTool(tool)
                task.wait(0.2)
                return true
            end
        end
    end
    return false
end

local function triggerHoldPrompt(prompt)
    if not prompt or not prompt.Parent then return end
    pcall(function()
        prompt.MaxActivationDistance = 40
        prompt.RequiresLineOfSight = false
        local holdTime = prompt.HoldDuration > 0 and prompt.HoldDuration or 1.5
        prompt:InputHoldBegin()
        task.wait(holdTime + 0.1)
        prompt:InputHoldEnd()
    end)
end

local function smartWait(delayTime, checkFunc)
    local t = 0
    while t < delayTime do
        if not checkFunc() then return false end 
        task.wait(0.1)
        t = t + 0.1
    end
    return true
end

-- ==========================================
-- FUNGSI PENCARIAN KIOS & CFrame
-- ==========================================
local function getUserKios()
    local kiosAktif = workspace:FindFirstChild("KiosAktif")
    if kiosAktif then
        for _, kios in ipairs(kiosAktif:GetChildren()) do
            if string.find(string.lower(kios.Name), string.lower(player.Name)) then
                return kios
            end
        end
    end
    return nil
end

local function getTargetCFrame(userKios)
    local craftObj = userKios:FindFirstChild("Craft")
    if craftObj then
        if craftObj:IsA("Model") then return craftObj:GetPivot()
        elseif craftObj:IsA("BasePart") then return craftObj.CFrame
        end
    end
    
    local tempaPrompt = userKios:FindFirstChild("TempaPrompt", true)
    if tempaPrompt and tempaPrompt.Parent then
        local parent = tempaPrompt.Parent
        if parent:IsA("Model") then return parent:GetPivot()
        elseif parent:IsA("BasePart") then return parent.CFrame
        elseif parent:IsA("Attachment") then return parent.WorldCFrame 
        end
    end

    local fallback = userKios:FindFirstChildWhichIsA("BasePart", true)
    if fallback then return fallback.CFrame end

    return nil
end

-- ==========================================
-- DYNAMIC AUTO RESTOCK + CAMERA LOCK
-- ==========================================
local function executeAutoRestock()
    if isRepairing or isFarming then return end

    local userKios = getUserKios()
    if not userKios then return end

    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChild("Humanoid")
    if not rootPart or not humanoid then return end

    isFarming = true
    statusLabel.Text = "Status: [ RESTOCKING ]"
    statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)

    humanoid:UnequipTools()
    disableFly()
    task.wait(0.1)
    enableFly(rootPart)

    local originalCameraType = Camera.CameraType
    Camera.CameraType = Enum.CameraType.Scriptable

    local targetFoldersNames = {"MejaMakan", "Rak"}
    
    for _, folderName in ipairs(targetFoldersNames) do
        local parentFolder = userKios:FindFirstChild(folderName)
        if parentFolder then
            for _, itemModel in ipairs(parentFolder:GetChildren()) do
                if itemModel:IsA("Model") or itemModel:IsA("Folder") or itemModel:IsA("BasePart") then
                    local prompt = itemModel:FindFirstChild("RakPrompt", true)
                    if prompt and prompt.Enabled then
                        local targetPart = prompt.Parent
                        local targetPos = nil
                        
                        if targetPart and targetPart:IsA("BasePart") then
                            targetPos = targetPart.Position
                        elseif itemModel:IsA("Model") then
                            targetPos = itemModel:GetPivot().Position
                        end

                        if targetPos then
                            local standPos = targetPos + Vector3.new(0, 1.5, 2)
                            
                            rootPart.CFrame = CFrame.new(standPos)
                            Camera.CFrame = CFrame.lookAt(rootPart.Position + Vector3.new(0, 2, 0), targetPos)
                            
                            task.wait(0.3)
                            if bodyVelocity then bodyVelocity.Velocity = Vector3.new(0, 0, 0) end

                            triggerHoldPrompt(prompt)
                            task.wait(0.5)
                        end
                    end
                end
            end
        end
    end

    Camera.CameraType = Enum.CameraType.Custom

    disableFly()
    isFarming = false
    lastRestockTime = tick() + CONFIG.RestockInterval
end

-- ==========================================
-- AUTO COOK SYSTEM
-- ==========================================
local function executeAutoCook()
    if isRepairing or isFarming then return end

    local userKios = getUserKios()
    if not userKios then return end

    local alatMasak = userKios:FindFirstChild("AlatMasak")
    local kompor = alatMasak and alatMasak:FindFirstChild("Kompor")
    local komporPrompt = kompor and kompor:FindFirstChild("KomporPrompt", true)

    if not komporPrompt or not komporPrompt.Parent then return end

    isFarming = true
    statusLabel.Text = "Status: [ COOKING ]"
    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)

    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChild("Humanoid")
    if not rootPart or not humanoid then isFarming = false return end

    humanoid:UnequipTools()
    disableFly()
    task.wait(0.1)

    local komporCFrame = kompor:IsA("Model") and kompor:GetPivot() or kompor.CFrame
    local safePosition = komporCFrame.Position + Vector3.new(0, 4, 3)
    
    for i = 1, 3 do
        rootPart.Velocity = Vector3.new(0, 0, 0)
        rootPart.CFrame = CFrame.new(safePosition)
        task.wait(0.1)
    end
    enableFly(rootPart)

    triggerHoldPrompt(komporPrompt)
    task.wait(2.5) 

    pcall(function()
        local pGui = player:FindFirstChild("PlayerGui")
        
        local function aggressiveClick(guiObj)
            if not guiObj then return end
            local events = {"MouseButton1Click", "MouseButton1Down", "MouseButton1Up", "Activated", "TouchTap"}
            for _, ev in ipairs(events) do
                for _, conn in ipairs(getconnections(guiObj[ev]) or {}) do pcall(function() conn:Fire() end) end
                if firesignal then firesignal(guiObj[ev]) end
            end
        end

        local function isVisible(obj)
            return obj and obj:IsA("GuiObject") and obj.AbsoluteSize.Y > 0 and obj.Visible
        end

        local memasakGui = pGui:FindFirstChild("MemasakGui")
        local cookBtns = {}

        if memasakGui then
            for _, obj in ipairs(memasakGui:GetDescendants()) do
                if obj.Name == "MasakBtn" and (obj:IsA("TextButton") or obj:IsA("ImageButton")) then
                    if isVisible(obj) then table.insert(cookBtns, obj) end
                end
            end
        end

        if #cookBtns == 0 then
            for _, gui in ipairs(pGui:GetDescendants()) do
                if gui.Name == "MasakBtn" and (gui:IsA("TextButton") or gui:IsA("ImageButton")) then
                    if isVisible(gui) then table.insert(cookBtns, gui) end
                end
            end
        end

        if #cookBtns > 0 then
            for slot = 1, CONFIG.CookSlots do
                for _, btn in ipairs(cookBtns) do
                    aggressiveClick(btn)
                    task.wait(0.15) 
                end
                task.wait(0.4) 
            end
        end

        task.wait(1.0)

        local closeBtn = nil
        if memasakGui then
            closeBtn = memasakGui:FindFirstChild("TutupBtn", true) or memasakGui:FindFirstChild("CloseBtn", true)
        end

        if closeBtn and isVisible(closeBtn) then
            aggressiveClick(closeBtn)
        else
            for _, gui in ipairs(pGui:GetDescendants()) do
                if (gui.Name == "TutupBtn" or gui.Name == "CloseBtn" or gui.Name == "X") and (gui:IsA("TextButton") or gui:IsA("ImageButton")) then
                    if isVisible(gui) then aggressiveClick(gui) break end
                end
            end
        end
    end)

    lastCookCheck = tick() + 60 
    task.wait(1)
    disableFly()
    isFarming = false
end

-- ==========================================
-- AUTO CLAIM KIOS
-- ==========================================
local function checkAndClaimKios()
    if getUserKios() then return true end
    statusLabel.Text = "SYSTEM: CLAIMING KIOS"
    statusLabel.TextColor3 = Color3.fromRGB(170, 0, 255)

    local kiosPlot = workspace:FindFirstChild("KiosPlot")
    if not kiosPlot then return true end

    for _, plot in ipairs(kiosPlot:GetChildren()) do
        if string.find(plot.Name, "Plot") then
            local claimPrompt = plot:FindFirstChildWhichIsA("ProximityPrompt", true)
            if claimPrompt and claimPrompt.Enabled then
                local character = player.Character
                if not character then return false end
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if not rootPart then return false end
                local targetPart = claimPrompt.Parent

                if targetPart and targetPart:IsA("BasePart") then
                    isRepairing = true 
                    enableFly(rootPart)

                    rootPart.CFrame = targetPart.CFrame * CFrame.new(0, 0, 3)
                    task.wait(0.3)
                    if bodyVelocity then bodyVelocity.Velocity = Vector3.new(0, 0, 0) end

                    triggerHoldPrompt(claimPrompt)
                    task.wait(2.0) 

                    disableFly()
                    isRepairing = false
                    return true 
                end
            end
        end
    end

    statusLabel.Text = "SYSTEM: KIOS FULL"
    statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    task.wait(2)
    return false 
end

-- ==========================================
-- FUNGSI TELEPORT KEMBALI KE KIOS (SAAT OFF)
-- ==========================================
local function StopAndTeleport()
    task.spawn(function()
        local timeout = 0
        while isFarming and timeout < 20 do 
            task.wait(0.1) 
            timeout = timeout + 1 
        end
        isFarming = false
        
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local rootPart = character.HumanoidRootPart
            local humanoid = character:FindFirstChild("Humanoid")
            
            if humanoid then humanoid:UnequipTools() end
            
            local userKios = getUserKios()
            if userKios then
                local targetCFrame = getTargetCFrame(userKios)
                if targetCFrame then
                    local safePosition = targetCFrame.Position + Vector3.new(0, 5, 0)
                    for i = 1, 3 do
                        rootPart.Velocity = Vector3.new(0, 0, 0)
                        rootPart.CFrame = CFrame.new(safePosition)
                        task.wait(0.1)
                    end
                    for _, part in ipairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = true end
                    end
                end
            end
        end
        disableFly()
    end)
end

-- ==========================================
-- AUTO REPAIR SYSTEM
-- ==========================================
local function checkIfToolBroken()
    local pGui = player:FindFirstChild("PlayerGui")
    if pGui then
        for _, gui in ipairs(pGui:GetDescendants()) do
            if gui:IsA("TextLabel") and gui.Text then
                local txt = string.lower(gui.Text)
                if string.find(txt, "rusak") or string.find(txt, "perbaiki di meja") then
                    if gui.Visible or gui.AbsoluteSize.Y > 0 then return true end
                end
            end
        end
    end
    return false
end

local function executeAutoRepair()
    if isRepairing then return end
    isRepairing = true
    statusLabel.Text = "Status: [ REPAIRING ]"
    statusLabel.TextColor3 = Color3.fromRGB(255, 170, 0)

    local character = player.Character
    if not character then isRepairing = false return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not rootPart or not humanoid then isRepairing = false return end

    local userKios = getUserKios()
    if not userKios then isRepairing = false return end

    local targetCFrame = getTargetCFrame(userKios)
    if not targetCFrame then isRepairing = false return end

    humanoid:UnequipTools()
    disableFly()
    task.wait(0.1)
    
    local safePosition = targetCFrame.Position + Vector3.new(0, 4, 3)
    for i = 1, 3 do
        rootPart.Velocity = Vector3.new(0, 0, 0)
        rootPart.CFrame = CFrame.new(safePosition)
        task.wait(0.1)
    end
    
    enableFly(rootPart)

    local tempaPrompt = userKios:FindFirstChild("TempaPrompt", true)
    triggerHoldPrompt(tempaPrompt)
    task.wait(2.0) 

    pcall(function()
        local pGui = player:FindFirstChild("PlayerGui")
        local function directFireButton(guiObject)
            if not guiObject then return end
            for _, connection in ipairs(getconnections(guiObject.MouseButton1Click) or {}) do connection:Fire() end
            for _, connection in ipairs(getconnections(guiObject.Activated) or {}) do connection:Fire() end
            if firesignal then firesignal(guiObject.MouseButton1Click) firesignal(guiObject.Activated) end
        end

        for _, gui in ipairs(pGui:GetDescendants()) do
            if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                if gui.Text == "Perbaiki" then
                    local targetBtn = gui
                    if not (gui:IsA("TextButton") or gui:IsA("ImageButton")) then
                        if gui.Parent and (gui.Parent:IsA("TextButton") or gui.Parent:IsA("ImageButton")) then targetBtn = gui.Parent end
                    end
                    if targetBtn.AbsoluteSize.Y < 80 then directFireButton(targetBtn) break end
                end
            end
        end
        task.wait(1.0) 

        local toolSelected = false
        for _, gui in ipairs(pGui:GetDescendants()) do
            if gui:IsA("TextLabel") then
                local txt = gui.Text or ""
                if string.sub(txt, 1, 2) == "0/" then
                    local parentObj = gui.Parent
                    for i = 1, 4 do
                        if parentObj then
                            if parentObj:IsA("TextButton") or parentObj:IsA("ImageButton") or parentObj:IsA("Frame") then
                                directFireButton(parentObj)
                                toolSelected = true
                                break
                            end
                            parentObj = parentObj.Parent
                        end
                    end
                    if toolSelected then break end
                end
            end
        end
        task.wait(0.8)

        for _, gui in ipairs(pGui:GetDescendants()) do
            if gui:IsA("TextButton") or gui:IsA("TextLabel") then
                local txt = gui.Text or ""
                if string.find(txt, "1500") then
                    local targetBtn = gui
                    if not (gui:IsA("TextButton") or gui:IsA("ImageButton")) then
                        if gui.Parent and (gui.Parent:IsA("TextButton") or gui.Parent:IsA("ImageButton")) then targetBtn = gui.Parent end
                    end
                    directFireButton(targetBtn)
                    break
                end
            end
        end
    end)

    task.wait(2.0)
    isRepairing = false
end

-- ==========================================
-- FUNGSI FARMING (MINING, WOOD, & COLLECT)
-- ==========================================
local function farmMining(modelTarget, part, prompt, toolName, customDelay, checkToggleFunc)
    local character = player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    isFarming = true
    currentTargetPrompt = prompt

    local cframeObj, sizeObj = modelTarget:GetBoundingBox()
    rootPart.CFrame = cframeObj * CFrame.new(0, -(sizeObj.Y / 2) - 1.5, 0)

    task.wait(0.2)
    enableFly(rootPart)

    if not equipTool(toolName) then
        disableFly()
        isFarming = false
        return
    end
    task.wait(0.3)

    local targetPromptToLock = prompt
    local cameraConnection
    cameraConnection = RunService.RenderStepped:Connect(function()
        if targetPromptToLock and targetPromptToLock.Parent and rootPart and checkToggleFunc() then
            if bodyVelocity then bodyVelocity.Velocity = Vector3.new(0, 0, 0) end
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
        else
            if cameraConnection then cameraConnection:Disconnect() end
        end
    end)

    while checkToggleFunc() and not checkIfToolBroken() and modelTarget and modelTarget.Parent and part and part.Parent and prompt and prompt.Parent and prompt.Enabled do
        equipTool(toolName)
        triggerHoldPrompt(prompt)
        pcall(function()
            local tool = character:FindFirstChild(toolName)
            if tool then tool:Activate() end
        end)
        if not smartWait(customDelay, checkToggleFunc) then break end
    end

    if cameraConnection then cameraConnection:Disconnect() end
    disableFly()
    isFarming = false
    currentTargetPrompt = nil
end

local function farmWood(modelTarget, part, prompt, toolName, customDelay, checkToggleFunc)
    local character = player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    isFarming = true
    currentTargetPrompt = prompt

    local targetPos = part.Position
    if prompt and prompt.Parent then
        if prompt.Parent:IsA("Attachment") then targetPos = prompt.Parent.WorldPosition
        elseif prompt.Parent:IsA("BasePart") then targetPos = prompt.Parent.Position end
    end
    
    local standPos = targetPos + Vector3.new(0, -1.5, 3)
    local lookAtPos = Vector3.new(targetPos.X, standPos.Y, targetPos.Z)
    rootPart.CFrame = CFrame.lookAt(standPos, lookAtPos)

    task.wait(0.2)
    enableFly(rootPart)

    if not equipTool(toolName) then
        disableFly()
        isFarming = false
        return
    end
    task.wait(0.3)

    local targetPromptToLock = prompt
    local cameraConnection
    cameraConnection = RunService.RenderStepped:Connect(function()
        if targetPromptToLock and targetPromptToLock.Parent and rootPart and checkToggleFunc() then
            if bodyVelocity then bodyVelocity.Velocity = Vector3.new(0, 0, 0) end
            local camPos = rootPart.Position + Vector3.new(0, 2, 0)
            Camera.CFrame = CFrame.lookAt(camPos, targetPos)
        else
            if cameraConnection then cameraConnection:Disconnect() end
        end
    end)

    while checkToggleFunc() and not checkIfToolBroken() and modelTarget and modelTarget.Parent and part and part.Parent and prompt and prompt.Parent and prompt.Enabled do
        equipTool(toolName)
        triggerHoldPrompt(prompt)
        pcall(function()
            local tool = character:FindFirstChild(toolName)
            if tool then tool:Activate() end
        end)
        if not smartWait(customDelay, checkToggleFunc) then break end
    end

    if cameraConnection then cameraConnection:Disconnect() end
    disableFly()
    isFarming = false
    currentTargetPrompt = nil
end

local function farmCollect(modelTarget, part, prompt, checkToggleFunc)
    local character = player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not rootPart or not humanoid then return end

    isFarming = true
    currentTargetPrompt = prompt
    humanoid:UnequipTools()

    local targetPos = part.Position
    if prompt and prompt.Parent then
        if prompt.Parent:IsA("Attachment") then targetPos = prompt.Parent.WorldPosition
        elseif prompt.Parent:IsA("BasePart") then targetPos = prompt.Parent.Position end
    end
    
    local standPos = targetPos + Vector3.new(0, 1.5, 3) 
    local lookAtPos = Vector3.new(targetPos.X, targetPos.Y, targetPos.Z)

    enableFly(rootPart)

    local distance = (rootPart.Position - standPos).Magnitude
    local flySpeed = CONFIG.CollectSpeed
    local flyDuration = distance / flySpeed

    local tweenInfo = TweenInfo.new(flyDuration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = CFrame.lookAt(standPos, lookAtPos)})
    tween:Play()

    local arrived = false
    local tweenConnection = tween.Completed:Connect(function() arrived = true end)

    while not arrived and checkToggleFunc() do
        task.wait(0.1)
    end

    if tweenConnection then tweenConnection:Disconnect() end

    if not checkToggleFunc() then
        tween:Cancel()
        disableFly()
        isFarming = false
        return
    end

    local targetPromptToLock = prompt
    local cameraConnection
    cameraConnection = RunService.RenderStepped:Connect(function()
        if targetPromptToLock and targetPromptToLock.Parent and rootPart and checkToggleFunc() then
            if bodyVelocity then bodyVelocity.Velocity = Vector3.new(0, 0, 0) end
            local camPos = rootPart.Position + Vector3.new(0, 2, 0)
            Camera.CFrame = CFrame.lookAt(camPos, targetPos)
        else
            if cameraConnection then cameraConnection:Disconnect() end
        end
    end)

    while checkToggleFunc() and modelTarget and modelTarget.Parent and part and part.Parent and prompt and prompt.Parent and prompt.Enabled do
        humanoid.Sit = false
        triggerHoldPrompt(prompt)
        task.wait(0.5) 
    end

    if cameraConnection then cameraConnection:Disconnect() end
    disableFly()
    isFarming = false
    currentTargetPrompt = nil
end

-- ==========================================
-- TOGGLE BUTTONS
-- ==========================================
toggleMineBtn.MouseButton1Click:Connect(function()
    _G_AutoMining = not _G_AutoMining
    if _G_AutoMining then
        toggleMineBtn.Text = "AUTO MINING: ON"
        toggleMineBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 204)
        toggleMineBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        mineStroke.Color = Color3.fromRGB(0, 255, 204)
        mineStroke.Thickness = 2
    else
        toggleMineBtn.Text = "AUTO MINING: OFF"
        toggleMineBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        mineStroke.TextColor3 = Color3.fromRGB(200, 200, 200)
        mineStroke.Color = Color3.fromRGB(50, 50, 70)
        mineStroke.Thickness = 1.5
        if not _G_AutoWood and not _G_AutoCollect and not _G_AutoCook and not _G_AutoRestock then StopAndTeleport() end
    end
end)

toggleWoodBtn.MouseButton1Click:Connect(function()
    _G_AutoWood = not _G_AutoWood
    if _G_AutoWood then
        toggleWoodBtn.Text = "AUTO WOOD: ON"
        toggleWoodBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 255)
        toggleWoodBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        woodStroke.Color = Color3.fromRGB(170, 0, 255)
        woodStroke.Thickness = 2
    else
        toggleWoodBtn.Text = "AUTO WOOD: OFF"
        toggleWoodBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        woodStroke.TextColor3 = Color3.fromRGB(200, 200, 200)
        woodStroke.Color = Color3.fromRGB(50, 50, 70)
        woodStroke.Thickness = 1.5
        if not _G_AutoMining and not _G_AutoCollect and not _G_AutoCook and not _G_AutoRestock then StopAndTeleport() end
    end
end)

toggleCollectBtn.MouseButton1Click:Connect(function()
    _G_AutoCollect = not _G_AutoCollect
    if _G_AutoCollect then
        toggleCollectBtn.Text = "AUTO COLLECT: ON"
        toggleCollectBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 0)
        toggleCollectBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        collectStroke.Color = Color3.fromRGB(255, 150, 0)
        collectStroke.Thickness = 2
    else
        toggleCollectBtn.Text = "AUTO COLLECT: OFF"
        toggleCollectBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        collectStroke.TextColor3 = Color3.fromRGB(200, 200, 200)
        collectStroke.Color = Color3.fromRGB(50, 50, 70)
        collectStroke.Thickness = 1.5
        if not _G_AutoMining and not _G_AutoWood and not _G_AutoCook and not _G_AutoRestock then StopAndTeleport() end
    end
end)

toggleCookBtn.MouseButton1Click:Connect(function()
    _G_AutoCook = not _G_AutoCook
    if _G_AutoCook then
        toggleCookBtn.Text = "AUTO COOK: ON"
        toggleCookBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        toggleCookBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        cookStroke.Color = Color3.fromRGB(255, 50, 50)
        cookStroke.Thickness = 2
        lastCookCheck = 0 
    else
        toggleCookBtn.Text = "AUTO COOK: OFF"
        toggleCookBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        cookStroke.TextColor3 = Color3.fromRGB(200, 200, 200)
        cookStroke.Color = Color3.fromRGB(50, 50, 70)
        cookStroke.Thickness = 1.5
        if not _G_AutoMining and not _G_AutoWood and not _G_AutoCollect then StopAndTeleport() end
    end
end)

toggleRestockBtn.MouseButton1Click:Connect(function()
    _G_AutoRestock = not _G_AutoRestock
    if _G_AutoRestock then
        toggleRestockBtn.Text = "AUTO RESTOCK: ON"
        toggleRestockBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        toggleRestockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        restockStroke.Color = Color3.fromRGB(0, 150, 255)
        restockStroke.Thickness = 2
        lastRestockTime = 0
    else
        toggleRestockBtn.Text = "AUTO RESTOCK: OFF"
        toggleRestockBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        restockStroke.TextColor3 = Color3.fromRGB(200, 200, 200)
        restockStroke.Color = Color3.fromRGB(50, 50, 70)
        restockStroke.Thickness = 1.5
        if not _G_AutoMining and not _G_AutoWood and not _G_AutoCollect and not _G_AutoCook then StopAndTeleport() end
    end
end)

toggleAfkBtn.MouseButton1Click:Connect(function()
    _G_AntiAfk = not _G_AntiAfk
    if _G_AntiAfk then
        toggleAfkBtn.Text = "ANTI-AFK: ON"
        toggleAfkBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
        toggleAfkBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        afkStroke.Color = Color3.fromRGB(50, 205, 50)
        afkStroke.Thickness = 2
    else
        toggleAfkBtn.Text = "ANTI-AFK: OFF"
        toggleAfkBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        afkStroke.TextColor3 = Color3.fromRGB(200, 200, 200)
        afkStroke.Color = Color3.fromRGB(50, 50, 70)
        afkStroke.Thickness = 1.5
    end
    saveConfig() 
end)

-- Status Text Update Loop
task.spawn(function()
    while task.wait(0.2) do
        if isRepairing then
        elseif _G_AutoMining or _G_AutoWood or _G_AutoCollect or _G_AutoCook or _G_AutoRestock then
            if statusLabel.Text ~= "SYSTEM: CLAIMING KIOS" and statusLabel.Text ~= "Status: [ COOKING ]" and statusLabel.Text ~= "Status: [ RESTOCKING ]" then
                statusLabel.Text = "SYSTEM: ACTIVE"
                statusLabel.TextColor3 = Color3.fromRGB(0, 255, 204)
            end
        else
            statusLabel.Text = "SYSTEM: IDLE"
            statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end
end)

-- ==========================================
-- MAIN LOOP
-- ==========================================
task.spawn(function()
    while task.wait(CONFIG.SafetyCheckInterval) do
        if not _G_AutoMining and not _G_AutoWood and not _G_AutoCollect and not _G_AutoCook and not _G_AutoRestock then continue end

        local hasKios = checkAndClaimKios()
        if not hasKios then
            task.wait(3)
            continue
        end

        if checkIfToolBroken() then
            executeAutoRepair()
            continue
        end

        if isFarming or isRepairing then continue end

        if _G_AutoRestock and tick() >= lastRestockTime then
            executeAutoRestock()
            continue
        end

        if _G_AutoCook and tick() >= lastCookCheck then
            executeAutoCook()
            continue
        end

        local activeTargetFound = false
        local bahanCraft = workspace:FindFirstChild("BahanCraft")
        
        if _G_AutoMining and bahanCraft then
            for _, child in ipairs(bahanCraft:GetChildren()) do
                if not _G_AutoMining then break end
                if child.Name == "BatuBesar" then
                    local targetPart = child:FindFirstChildWhichIsA("BasePart", true)
                    if targetPart then
                        local prompt = targetPart:FindFirstChildWhichIsA("ProximityPrompt", true) or child:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled then
                            activeTargetFound = true
                            farmMining(child, targetPart, prompt, selectedMiningTool, CONFIG.MiningDelay, function() return _G_AutoMining end)
                            break 
                        end
                    end
                end
            end
        end

        if activeTargetFound then continue end

        if _G_AutoWood and bahanCraft then
            for _, child in ipairs(bahanCraft:GetChildren()) do
                if not _G_AutoWood then break end
                if child.Name == "PohonBesar" then
                    local targetPart = child:FindFirstChildWhichIsA("BasePart", true)
                    if targetPart then
                        local prompt = targetPart:FindFirstChildWhichIsA("ProximityPrompt", true) or child:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.Enabled then
                            activeTargetFound = true
                            farmWood(child, targetPart, prompt, selectedWoodTool, CONFIG.WoodcuttingDelay, function() return _G_AutoWood end)
                            break
                        end
                    end
                end
            end
        end
        
        if activeTargetFound then continue end

        if _G_AutoCollect then
            local spawnBahan = workspace:FindFirstChild("SpawnBahan")
            if spawnBahan then
                for _, child in ipairs(spawnBahan:GetChildren()) do
                    if not _G_AutoCollect then break end
                    
                    if selectedCollectItems[child.Name] == true then
                        local targetPart = child:FindFirstChildWhichIsA("BasePart", true)
                        if targetPart then
                            local prompt = targetPart:FindFirstChildWhichIsA("ProximityPrompt", true) or child:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt and prompt.Enabled then
                                activeTargetFound = true
                                farmCollect(child, targetPart, prompt, function() return _G_AutoCollect end)
                                break
                            end
                        end
                    end
                end
            end
        end

    end
end)

-- Notifikasi Berhasil
StarterGui:SetCore("SendNotification", {
    Title = "BLB HUB PRO V28",
    Text = "UI Unified & All Features Locked!",
    Duration = 5
})