-- ==========================================
-- OPTIMASI DELTA EXECUTOR (Anti-AFK & Bypass)
-- ==========================================
local VirtualUser = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)

-- Tunggu sampai game selesai dimuat sepenuhnya
repeat task.wait() until game:IsLoaded()

local player = game.Players.LocalPlayer
local workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Camera = workspace.CurrentCamera

-- ==========================================
-- CONFIG & STATE (LOCKED)
-- ==========================================
local CONFIG = {
    MiningDelay = 10,
    WoodcuttingDelay = 13,
    SafetyCheckInterval = 0.5
}

local _G_AutoMining = false   
local _G_AutoWood = false     
local isFarming = false
local isRepairing = false
local currentTargetPrompt = nil
local bodyVelocity = nil

local selectedMiningTool = "BeliungBesi"
local selectedWoodTool = "KapakKayu"

-- ==========================================
-- MODERN UI CREATION: BLB HUB PRO (DELTA OPTIMIZED)
-- ==========================================
local playerGui = player:WaitForChild("PlayerGui")
-- Menggunakan gethui() agar GUI aman dari deteksi Anti-Cheat / tidak hilang saat mati
local uiParent = (gethui and gethui()) or game:GetService("CoreGui") or playerGui 

local existingGui = uiParent:FindFirstChild("BLB_AutoFarm_Pro_V28")
if existingGui then existingGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BLB_AutoFarm_Pro_V28"
screenGui.ResetOnSpawn = false
screenGui.Parent = uiParent

-- Main Container
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 270, 0, 430)
mainFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Thickness = 2
uiStroke.Transparency = 0.1
uiStroke.Parent = mainFrame
local strokeGradient = Instance.new("UIGradient")
strokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 204)), 
    ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 0, 255))
})
strokeGradient.Parent = uiStroke

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 42)
header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
header.BackgroundTransparency = 0.9
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header
local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 30)), 
    ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 20, 50))
})
headerGradient.Parent = header

-- Title Label
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

-- Container Konten
local container = Instance.new("Frame")
container.Size = UDim2.new(1, 0, 1, -42)
container.Position = UDim2.new(0, 0, 0, 42)
container.BackgroundTransparency = 1
container.Parent = mainFrame

-- Status Label
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

-- Pembuat Tombol Toggle Modern
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

-- ==========================================
-- FUNGSI SCAN ALAT DI TAS PLAYER
-- ==========================================
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
    
    if #foundTools == 0 then
        table.insert(foundTools, toolType == "Mining" and "BeliungBesi" or "KapakKayu")
    end
    return foundTools
end

-- ==========================================
-- DROPDOWN UI CREATOR
-- ==========================================
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

createDropdown("⛏️ Mining Tool", function() return getPlayerTools("Mining") end, selectedMiningTool, 125, function(val) selectedMiningTool = val end)
createDropdown("🪓 Wood Tool", function() return getPlayerTools("Wood") end, selectedWoodTool, 157, function(val) selectedWoodTool = val end)

-- ==========================================
-- PARAMETER INPUT UI
-- ==========================================
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
        else
            textBox.Text = tostring(defaultVal)
        end
    end)
end

createParamInput("Mining Delay (s)", CONFIG.MiningDelay, 200, function(val) CONFIG.MiningDelay = val end)
createParamInput("Wood Delay (s)", CONFIG.WoodcuttingDelay, 232, function(val) CONFIG.WoodcuttingDelay = val end)

-- ==========================================
-- RESIZE & MINIMIZE BUTTONS
-- ==========================================
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
        mainFrame:TweenSize(UDim2.new(0, 270, 0, 42), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.3, true)
        minimizeBtn.Text = "+"
    else
        mainFrame:TweenSize(UDim2.new(0, 270, 0, 430), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.3, true)
        container.Visible = true
        minimizeBtn.Text = "-"
    end
end)

local sizeState = 1
resizeBtn.MouseButton1Click:Connect(function()
    sizeState = sizeState + 1
    if sizeState > 3 then sizeState = 1 end

    if sizeState == 1 then
        mainFrame.Size = UDim2.new(0, 270, 0, 430)
    elseif sizeState == 2 then
        mainFrame.Size = UDim2.new(0, 220, 0, 340)
    elseif sizeState == 3 then
        mainFrame.Size = UDim2.new(0, 330, 0, 480)
    end
end)

-- ==========================================
-- STABLE DRAGGABLE SYSTEM
-- ==========================================
local dragging, dragInput, dragStart, startPos

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
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
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ==========================================
-- FUNGSI TELEPORT KEMBALI KE KIOS (SAAT OFF)
-- ==========================================
local function teleportToMyKios()
    local character = player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local kiosAktif = workspace:FindFirstChild("KiosAktif")
    if kiosAktif then
        local userKios = kiosAktif:FindFirstChild("Kios_" .. player.Name)
        if userKios then
            local craftPart = userKios:FindFirstChild("Craft") or userKios:FindFirstChildWhichIsA("BasePart")
            if craftPart then
                rootPart.CFrame = craftPart.CFrame * CFrame.new(0, 3, 2)
            end
        end
    end
end

-- ==========================================
-- FLY & NOCLIP SYSTEM (STABIL & AMAN)
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
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = false
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

-- ==========================================
-- PERBAIKAN: METODE HOLD PROMPT DIKEMBALIKAN
-- KE CARA ORIGINAL (TERBUKTI WORK)
-- ==========================================
local function triggerHoldPrompt(prompt)
    if not prompt or not prompt.Parent then return end
    pcall(function()
        prompt.MaxActivationDistance = 40
        prompt.RequiresLineOfSight = false
        local holdTime = prompt.HoldDuration > 0 and prompt.HoldDuration or 1.5
        
        -- Simulasi Hold Original Tanpa fireproximityprompt
        prompt:InputHoldBegin()
        task.wait(holdTime + 0.1)
        prompt:InputHoldEnd()
    end)
end

-- ==========================================
-- AUTO CLAIM KIOS
-- ==========================================
local function checkAndClaimKios()
    local kiosAktif = workspace:FindFirstChild("KiosAktif")
    if kiosAktif then
        for _, kios in ipairs(kiosAktif:GetChildren()) do
            if string.find(kios.Name:lower(), player.Name:lower()) then
                return true 
            end
        end
    end

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
-- PERBAIKAN: AUTO REPAIR SYSTEM (Pasti Teleport)
-- ==========================================
local function checkIfToolBroken()
    local pGui = player:FindFirstChild("PlayerGui")
    if pGui then
        for _, gui in ipairs(pGui:GetDescendants()) do
            if gui:IsA("TextLabel") and gui.Text then
                local txt = string.lower(gui.Text)
                if string.find(txt, "rusak") or string.find(txt, "perbaiki di meja") then
                    if gui.Visible or gui.AbsoluteSize.Y > 0 then
                        return true
                    end
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
    if not rootPart then isRepairing = false return end

    local kiosAktif = workspace:FindFirstChild("KiosAktif")
    if not kiosAktif then isRepairing = false return end

    local userKios = kiosAktif:FindFirstChild("Kios_" .. player.Name)
    if not userKios then
        for _, kios in ipairs(kiosAktif:GetChildren()) do
            if string.find(kios.Name, player.Name) then
                userKios = kios
                break
            end
        end
    end

    if not userKios then isRepairing = false return end

    local craftPart = userKios:FindFirstChild("Craft")
    if not craftPart then isRepairing = false return end

    local tempaPrompt = craftPart:FindFirstChild("TempaPrompt", true)
    if not tempaPrompt then isRepairing = false return end

    rootPart.CFrame = craftPart.CFrame * CFrame.new(0, 0, 3)
    task.wait(0.5)
    enableFly(rootPart)

    triggerHoldPrompt(tempaPrompt)
    task.wait(2.0) 

    pcall(function()
        local pGui = player:FindFirstChild("PlayerGui")
        
        local function directFireButton(guiObject)
            if not guiObject then return end
            -- Delta sangat mendukung penggunaan getconnections dan firesignal
            for _, connection in ipairs(getconnections(guiObject.MouseButton1Click) or {}) do
                connection:Fire()
            end
            for _, connection in ipairs(getconnections(guiObject.Activated) or {}) do
                connection:Fire()
            end
            if firesignal then
                firesignal(guiObject.MouseButton1Click)
                firesignal(guiObject.Activated)
            end
        end

        for _, gui in ipairs(pGui:GetDescendants()) do
            if gui:IsA("TextLabel") or gui:IsA("TextButton") then
                if gui.Text == "Perbaiki" then
                    local targetBtn = gui
                    if not (gui:IsA("TextButton") or gui:IsA("ImageButton")) then
                        if gui.Parent and (gui.Parent:IsA("TextButton") or gui.Parent:IsA("ImageButton")) then
                            targetBtn = gui.Parent
                        end
                    end
                    if targetBtn.AbsoluteSize.Y < 80 then 
                        directFireButton(targetBtn)
                        break
                    end
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
                        if gui.Parent and (gui.Parent:IsA("TextButton") or gui.Parent:IsA("ImageButton")) then
                            targetBtn = gui.Parent
                        end
                    end
                    directFireButton(targetBtn)
                    break
                end
            end
        end
    end)

    task.wait(2.0)
    disableFly()
    isRepairing = false
end

-- ==========================================
-- 1. FUNGSI FARMING KHUSUS MINING
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
            if bodyVelocity then 
                bodyVelocity.Velocity = Vector3.new(0, 0, 0) 
            end
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
        task.wait(customDelay)
    end

    if cameraConnection then cameraConnection:Disconnect() end
    disableFly()
    isFarming = false
    currentTargetPrompt = nil
    task.wait(0.5)
end

-- ==========================================
-- 2. FUNGSI FARMING KHUSUS WOOD
-- ==========================================
local function farmWood(modelTarget, part, prompt, toolName, customDelay, checkToggleFunc)
    local character = player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    isFarming = true
    currentTargetPrompt = prompt

    local targetPos = part.Position
    if prompt and prompt.Parent then
        if prompt.Parent:IsA("Attachment") then
            targetPos = prompt.Parent.WorldPosition
        elseif prompt.Parent:IsA("BasePart") then
            targetPos = prompt.Parent.Position
        end
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
            if bodyVelocity then 
                bodyVelocity.Velocity = Vector3.new(0, 0, 0) 
            end
            
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
        task.wait(customDelay)
    end

    if cameraConnection then cameraConnection:Disconnect() end
    disableFly()
    isFarming = false
    currentTargetPrompt = nil
    task.wait(0.5)
end

-- ==========================================
-- TOGGLE BUTTON CLICKS
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
        isFarming = false
        disableFly()
        teleportToMyKios()
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
        isFarming = false
        disableFly()
        teleportToMyKios()
    end
end)

-- Status Text Update Loop
task.spawn(function()
    while task.wait(0.2) do
        if isRepairing then
        elseif _G_AutoMining or _G_AutoWood then
            if statusLabel.Text ~= "SYSTEM: CLAIMING KIOS" then
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
        if not _G_AutoMining and not _G_AutoWood then continue end

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

        local bahanCraft = workspace:FindFirstChild("BahanCraft")
        if not bahanCraft then continue end

        local activeTargetFound = false

        -- 1. Auto Mining
        if _G_AutoMining then
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

        -- 2. Auto Woodcutting
        if _G_AutoWood then
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
    end
end)

-- Notifikasi Berhasil
StarterGui:SetCore("SendNotification", {
    Title = "BLB HUB PRO V28",
    Text = "Hold Fix & Anti-AFK Ready!",
    Duration = 5
})