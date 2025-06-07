local Material = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kinlei/MaterialLua/master/Module.lua"))()
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local UI = Material.Load({
    Title = "Da hood Experience | Discord: @propertly",
    Style = 1,
    SizeX = 480,
    SizeY = 350,
    Theme = "Dark"
})

function sendNotif(title, text)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 5
        })
    end)
end

local MainPage = UI.New({ Title = "MAIN MTX |" })

local espModes = {
    ["Box ESP"] = false,
    ["Nickname ESP"] = false,
    ["Health"] = false,
    ["Distance"] = false,
    ["Chams"] = false
}
local espObjects = {}

local function clearESP()
    for _, objs in pairs(espObjects) do
        for _, v in pairs(objs) do
            if v and v.Parent then
                v:Destroy()
            end
        end
    end
    espObjects = {}
end

local function clearESPForPlayer(player)
    local objs = espObjects[player.UserId]
    if objs then
        for _, v in pairs(objs) do
            if v and v.Parent then
                v:Destroy()
            end
        end
        espObjects[player.UserId] = nil
    end
end

local function createStackedESP(player)
    if player == LocalPlayer then return end
    local character = player.Character
    if not character then return end
    local head = character:FindFirstChild("Head")
    if not head then return end

    local tag = Instance.new("BillboardGui")
    tag.Name = "StackedESP"
    tag.Adornee = head
    tag.Size = UDim2.new(0, 200, 0, 60)
    tag.StudsOffset = Vector3.new(0, 4, 0)
    tag.AlwaysOnTop = true
    tag.MaxDistance = 99999999999999999999999999999999999999999999999999999999

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.4
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Text = ""
    label.Parent = tag
    tag.Parent = head

    espObjects[player.UserId] = espObjects[player.UserId] or {}
    table.insert(espObjects[player.UserId], tag)

    task.spawn(function()
        while tag.Parent and character and character:FindFirstChild("Humanoid") do
            local dist = 0
            pcall(function()
                dist = (LocalPlayer.Character.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude
            end)

            if dist > 99999999999999999999999999999999999999999999999999999999 then
                tag.Enabled = false
            else
                tag.Enabled = true
            end

            local info = ""
            if espModes["Nickname ESP"] then
                info = info .. player.Name .. "\n"
            end
            if espModes["Health"] then
                info = info .. "HP: " .. math.floor(character.Humanoid.Health) .. "\n"
            end
            if espModes["Distance"] then
                info = info .. string.format("Dist: %.1f m", dist)
            end

            label.Text = info
            task.wait(0.1)
        end
    end)
end

local function createBoxESP(player)
    if player == LocalPlayer then return end
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = hrp
    box.Size = Vector3.new(4, 6, 2)
    box.Color3 = Color3.fromRGB(0, 255, 0)
    box.Transparency = 0.5
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Name = "ESPBox"
    box.Parent = hrp

    espObjects[player.UserId] = espObjects[player.UserId] or {}
    table.insert(espObjects[player.UserId], box)
end

local function clearChamsForPlayer(player)
    local objs = espObjects[player.UserId]
    if objs then
        for i = #objs, 1, -1 do
            local obj = objs[i]
            if obj and obj.Name == "ChamsHighlight" and obj.Parent then
                obj:Destroy()
                table.remove(objs, i)
            end
        end
        if #objs == 0 then
            espObjects[player.UserId] = nil
        end
    end
end

local function createChams(player)
    if player == LocalPlayer then return end
    local character = player.Character
    if not character then return end

    clearChamsForPlayer(player)

    local highlight = Instance.new("Highlight")
    highlight.Name = "ChamsHighlight"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(0, 255, 255)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.3
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    espObjects[player.UserId] = espObjects[player.UserId] or {}
    table.insert(espObjects[player.UserId], highlight)
end

local function setupESPForPlayer(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        clearESPForPlayer(player)
        if espActive then
            if espModes["Box ESP"] then createBoxESP(player) end
            if espModes["Chams"] then createChams(player) end
            if espModes["Nickname ESP"] or espModes["Health"] or espModes["Distance"] then
                createStackedESP(player)
            end
        end
    end)
end

Players.PlayerRemoving:Connect(function(player)
    clearESPForPlayer(player)
end)

local function updateESP()
    clearESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if espModes["Box ESP"] then createBoxESP(plr) end
        if espModes["Chams"] then createChams(plr) end
        if espModes["Nickname ESP"] or espModes["Health"] or espModes["Distance"] then
            createStackedESP(plr)
        end
    end
end

local function setupESPForPlayer(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        clearESPForPlayer(player)
        if espActive then
            if espModes["Box ESP"] then createBoxESP(player) end
            if espModes["Chams"] then createChams(player) end
            if espModes["Nickname ESP"] or espModes["Health"] or espModes["Distance"] then
                createStackedESP(player)
            end
        end
    end)
end

for _, plr in ipairs(Players:GetPlayers()) do
    setupESPForPlayer(plr)
end

Players.PlayerAdded:Connect(function(plr)
    setupESPForPlayer(plr)
end)

MainPage.Label({ Text = "Visuals Mode" })

MainPage.Toggle({
    Text = "ESP Player",
    Callback = function(state)
        espActive = state
        if espActive then
            updateESP()
        else
            clearESP()
        end
    end,
    Enabled = false
})

MainPage.Dropdown({
    Text = "Select ESP Mode",
    Callback = function(selected)
        espModes[selected] = not espModes[selected]
        if espActive then
            updateESP()
        end
    end,
    Options = {"Box ESP", "Nickname ESP", "Health", "Distance", "Chams"}
})

MainPage.Label({
    Text = "animation Mode"
})

local selectedAnimId = "rbxassetid://"
local currentEmoteTrack = nil

local function getAnimator()
    local char = LocalPlayer.Character
    if not char then return nil end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end

    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Name = "CustomAnimator"
        animator.Parent = hum
    end

    return animator
end

MainPage.TextField({
    Text = "Custom Emote ID (without rbxassetid://)",
    Callback = function(input)
        local id = input:gsub("%D", "")
        if id ~= "" then
            selectedAnimId = "rbxassetid://" .. id
            sendNotif("Emote ID Set", "Now using ID: " .. id)
        else
            sendNotif("Invalid ID", "Введите корректный числовой ID.")
        end
    end
})

MainPage.Button({
    Text = "Play Emote",
    Callback = function()
        local animator = getAnimator()
        if not animator then
            sendNotif("Error", "This animation cannot load!")
            return
        end

        if currentEmoteTrack then
            currentEmoteTrack:Stop()
        end

        local anim = Instance.new("Animation")
        anim.AnimationId = selectedAnimId

        local success, track = pcall(function()
            return animator:LoadAnimation(anim)
        end)

        if success and track then
            currentEmoteTrack = track
            track:Play()
            sendNotif("Emote", "succesfuly")
        else
            sendNotif("Error", "This animation cannot load!")
        end
    end
})

MainPage.Button({
    Text = "Stop Emote",
    Callback = function()
        if currentEmoteTrack then
            currentEmoteTrack:Stop()
            currentEmoteTrack = nil
            sendNotif("")
        else
            sendNotif("")
        end
    end
})

local DesyncPage = UI.New({
    Title = "Desync |"
})

local desyncEnabled = false
local desyncMode = ""
local autoDesync = true
local lastHealth

local hrp = game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")
local humanoid = game.Players.LocalPlayer.Character:WaitForChild("Humanoid")
lastHealth = humanoid.Health

local originalCFrame = hrp.CFrame
local desyncThread
local desyncKey = Enum.KeyCode.RightAlt
local bindingMode = false

local function getRandomSkyPosition()
    return Vector3.new(math.random(-1e5, 1e5), math.random(20000, 40000), math.random(-1e5, 1e5))
end

local function getIntermediateSkyPosition()
    return Vector3.new(math.random(-1e5, 1e5), math.random(60000, 80000), math.random(-1e5, 1e5))
end

local function getExtremeSkyPosition()
    local function crazyRand()
        return math.random(-1e3, 1e3) * math.random(1e3, 1e6)
    end
    return Vector3.new(crazyRand(), math.random(50000000, 1000000000), crazyRand())
end

local function randomLarge(min, max)
    local range = max - min
    local part1 = math.random() * range
    return min + part1
end

local function getUltimateUndergroundPosition()
    local x = randomLarge(-1e26, 1e26)
    local y = 4283947984
    local z = randomLarge(-1e26, 1e26)
    return Vector3.new(x, y, z)
end

local function getSilentSkyPosition()
    local x = randomLarge(-1e24, 1e24)
    local y = -1
    local z = randomLarge(-1e24, 1e24)
    return Vector3.new(x, y, z)
end

game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    hrp = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    lastHealth = humanoid.Health
    sendNotif("Character Re-spawned", "Character has respawned. All functions are now restored!")

    humanoid.HealthChanged:Connect(function(newHealth)
        if autoDesync and newHealth < lastHealth and not desyncEnabled then
            sendNotif("Auto Desync", "You took damage! Enabling Pos Desync.")
            enableDesync()
        end
        lastHealth = newHealth
    end)
end)

function enableDesync()
    if desyncEnabled or not hrp then return end

    desyncEnabled = true
    sendNotif("Pos Desync", "Position desync enabled!")
    originalCFrame = hrp.CFrame

    local runService = game:GetService("RunService")
    desyncThread = runService.Heartbeat:Connect(function()
        if not desyncEnabled or not hrp then return end
        local targetCFrame

        if desyncMode == "Version 1" then
            targetCFrame = CFrame.new(getRandomSkyPosition())
        elseif desyncMode == "Version 2" then
            targetCFrame = CFrame.new(getIntermediateSkyPosition())
		elseif desyncMode == "Silent Version" then
            targetCFrame = CFrame.new(getSilentSkyPosition())
        elseif desyncMode == "Extreme Version" then
            targetCFrame = CFrame.new(getExtremeSkyPosition())
        elseif desyncMode == "Ultimate Version" then
            targetCFrame = CFrame.new(getUltimateUndergroundPosition())
        end
        hrp.CFrame = targetCFrame
    end)
end

function disableDesync()
    if not desyncEnabled then return end

    desyncEnabled = false
    if desyncThread then
        desyncThread:Disconnect()
        desyncThread = nil
    end

    if hrp then
        hrp.Anchored = true
        task.wait(0.1)

        hrp.CFrame = originalCFrame
        hrp.Anchored = false
    end

    sendNotif("Pos Desync", "Desync disabled, returning to original position.")
end

DesyncPage.Label({
    Text = "DESYNC & BIND"
})

DesyncPage.Button({
    Text = "Enable Pos Desync",
    Callback = enableDesync
})

DesyncPage.Button({
    Text = "Disable Pos Desync",
    Callback = disableDesync
})

humanoid.HealthChanged:Connect(function(newHealth)
    if autoDesync and newHealth < lastHealth and not desyncEnabled then
        sendNotif("Auto Desync", "You took damage! Enabling Pos Desync.")
        enableDesync()
    end
    lastHealth = newHealth
end)

DesyncPage.Button({
    Text = "Pos Desync Hotkey",
    Callback = function()
        bindingMode = true
        sendNotif("Bind Mode", "Press any key to bind to Pos Desync toggle.")
    end
})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if bindingMode and not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
        desyncKey = input.KeyCode
        bindingMode = false
        sendNotif("Hotkey Set", "New hotkey: " .. desyncKey.Name)
    elseif input.KeyCode == desyncKey and not gameProcessed then
        if desyncEnabled then
            disableDesync()
        else
            enableDesync()
        end
    end
end)

DesyncPage.Label({
    Text = "Mode & Dmg"
})

DesyncPage.Toggle({
    Text = "Auto Desync On Damage",
    Default = true,
    Callback = function(val)
        autoDesync = val
        sendNotif("Auto Desync", "Auto desync on damage: " .. tostring(val))
    end
})

DesyncPage.Dropdown({
    Text = "Desync Mode",
    Callback = function(val)
        desyncMode = val
        sendNotif("Mode Selected", "You selected: " .. val)
    end,
    Options = {"Version 1", "Version 2", "Silent Version", "Extreme Version", "Ultimate Version"}
})

local TeleportPage = UI.New({
    Title = "TELEPORT LOCATION |"
})

TeleportPage.Label({
    Text = "MAIN PLACES"
})

TeleportPage.Button({
    Text = "Teleport to Bank",
    Callback = function()
        local teleportPosition = Vector3.new(-465, 39, -284)
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to the Bank!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})

TeleportPage.Button({
    Text = "Teleport to Roof",
    Callback = function()
        local teleportPosition = Vector3.new(-323, 80, -256)
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to the Roof!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})

TeleportPage.Button({
    Text = "Teleport to UFO",
    Callback = function()
        local teleportPosition = Vector3.new(50, 138, -671)
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to the UFO!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})

TeleportPage.Button({
    Text = "Teleport to Millitary",
    Callback = function()
        local teleportPosition = Vector3.new(37, 50, -826)
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to the Millitary!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})

TeleportPage.Label({
    Text = "Food Store"
})

TeleportPage.Button({
    Text = "Teleport to Food #1",
    Callback = function()
        local teleportPosition = Vector3.new(-336, 23, -298)
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to Food #1!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})

TeleportPage.Button({
    Text = "Teleport to Food #2",
    Callback = function()
        local teleportPosition = Vector3.new(299, 49, -617)
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to Food #2!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})

TeleportPage.Button({
    Text = "Teleport to Food #3",
    Callback = function()
        local teleportPosition = Vector3.new(-279, 22, -807)
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to Food #3!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})

TeleportPage.Button({
    Text = "Teleport to Food #4",
    Callback = function()
        local teleportPosition = Vector3.new(584, 51, -477)
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to Food #4!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})

TeleportPage.Label({
    Text = "Gun Store"
})

TeleportPage.Button({
    Text = "Gunshop #1 Downhill",
    Callback = function()
        local teleportPosition = Vector3.new(-579, 8, -736)
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to Gunshop #1!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})


TeleportPage.Button({
    Text = "Gunshop #2 Uphill",
    Callback = function()
        local teleportPosition = Vector3.new(481, 48, -619)
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to Gunshop #2!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})

TeleportPage.Button({
    Text = "Gunshop #3 Garage",
    Callback = function()
        local teleportPosition = Vector3.new(-1183, 28, -519)
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to Gunshop #3!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})

TeleportPage.Button({
    Text = "Gunshop #4 Aug, Rifle",
    Callback = function()
        local teleportPosition = Vector3.new(-266, 52, -215)
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to Gunshop #4!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})

TeleportPage.Button({
    Text = "Gunshop #5 Rpg, Grenade",
    Callback = function()
        local teleportPosition = Vector3.new(111, -26, -271)
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to Gunshop #5!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})

TeleportPage.Label({
    Text = "Armor Store"
})

TeleportPage.Button({
    Text = "Teleport to Armor #1",
    Callback = function()
        local teleportPosition = Vector3.new(-605, 10, -788)
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to Armor #1!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})

TeleportPage.Button({
    Text = "Teleport to Armor #2",
    Callback = function()
        local teleportPosition = Vector3.new(532, 50, -637)
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to Armor #2!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})

TeleportPage.Button({
    Text = "Teleport to Armor #3",
    Callback = function()
        local teleportPosition = Vector3.new(-933, -28, 565)
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to Armor #3!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})

TeleportPage.Button({
    Text = "Teleport to Armor #4",
    Callback = function()
        local teleportPosition = Vector3.new(409, 48, -50)
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to Armor #4!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})

TeleportPage.Button({
    Text = "Teleport to Armor #5",
    Callback = function()
        local teleportPosition = Vector3.new(-257, 21, -78)
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to Armor #5!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})

TeleportPage.Label({
    Text = "Safe Zones"
})

TeleportPage.Button({
    Text = "Teleport to Safe #1",
    Callback = function()
        local teleportPosition = Vector3.new(-55, -58, 146)
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to Safe #1!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})

TeleportPage.Button({
    Text = "Teleport to Safe #2",
    Callback = function()
        local teleportPosition = Vector3.new(-124, -58, 130 )
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to Safe #2!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})

TeleportPage.Button({
    Text = "Teleport to Safe #3",
    Callback = function()
        local teleportPosition = Vector3.new(-547, 173, -2 )
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to Safe #3!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})

local savedPosition = nil

function getCurrentCoordinates()
    return hrp.Position
end

function teleportToSavedPosition()
    if savedPosition then
        hrp.CFrame = CFrame.new(savedPosition)
        sendNotif("Teleported", "Teleported to saved coordinates: " .. tostring(savedPosition))
    else
        sendNotif("Error", "No coordinates saved to teleport!")
    end
end

function dropMoney(amount)
    pcall(function()
        game:GetService("ReplicatedStorage").MainEvent:FireServer("DropMoney", "" .. amount)
        sendNotif("Money dropped!", "$" .. amount .. " dropped!")
    end)
end

function canDropMoney()
    return tick() - lastDropTime >= 17
end

local Page = UI.New({
    Title = "Drop Money |"
})

Page.Label({
    Text = "DROP MONEY & STOP DROP"
})

Page.Button({
    Text = "Drop All Money",
    Callback = function()
        stopDropping = false
        while money > 100 and not stopDropping do
            dropMoney(money > 15000 and 15000 or money)
            wait(3)
        end
        if stopDropping then
            sendNotif("Stopped!", "Money drop has been stopped.")
        end
    end
})

Page.Button({
    Text = "Stop Drop Money",
    Callback = function()
        stopDropping = true
        sendNotif("Stopped!", "You have stopped the money drop process.")
    end
})

Page.Button({
    Text = "Teleport to Place Drop Money",
    Callback = function()
        local teleportPosition = Vector3.new(-3.17822265625, 11.748022079467773, 189.50340270996094)
        
        if hrp then
            hrp.CFrame = CFrame.new(teleportPosition)
            sendNotif("Teleported", "You have been teleported to the dropper place!")
        else
            sendNotif("Error", "HumanoidRootPart not found!")
        end
    end
})

Page.Label({
    Text = "MONEY DROP OPTIONS"
})

Page.Button({
    Text = "Drop Money Time X5",
    Callback = function()
        if canDropMoney() then
            for i = 1, 5 do
                dropMoney(15000)
                wait(17)
            end
            lastDropTime = tick()
        else
            sendNotif("Cooldown", "Please wait for cooldown to finish!")
        end
    end
})

Page.Button({
    Text = "Drop Money Time X10",
    Callback = function()
        if canDropMoney() then
            for i = 1, 10 do
                dropMoney(15000)
                wait(17)
            end
            lastDropTime = tick()
        else
            sendNotif("Cooldown", "Please wait for cooldown to finish!")
        end
    end
})

Page.Button({
    Text = "Drop Money Time X50",
    Callback = function()
        if canDropMoney() then
            for i = 1, 50 do
                dropMoney(15000)
                wait(17)
            end
            lastDropTime = tick()
        else
            sendNotif("Cooldown", "Please wait for cooldown to finish!")
        end
    end
})

Page.Button({
    Text = "Drop Money Time X100",
    Callback = function()
        if canDropMoney() then
            for i = 1, 100 do
                dropMoney(15000)
                wait(17)
            end
            lastDropTime = tick()
        else
            sendNotif("Cooldown", "Please wait for cooldown to finish!")
        end
    end
})

Page.Button({
    Text = "Drop Money Time X200",
    Callback = function()
        if canDropMoney() then
            for i = 1, 200 do
                dropMoney(15000)
                wait(17)
            end
            lastDropTime = tick()
        else
            sendNotif("Cooldown", "Please wait for cooldown to finish!")
        end
    end
})

Page.Button({
    Text = "Drop Money Time X500",
    Callback = function()
        if canDropMoney() then
            for i = 1, 500 do
                dropMoney(15000)
                wait(17)
            end
            lastDropTime = tick()
        else
            sendNotif("Cooldown", "Please wait for cooldown to finish!")
        end
    end
})

Page.Button({
    Text = "Drop Money Time X1000",
    Callback = function()
        if canDropMoney() then
            for i = 1, 1000 do
                dropMoney(15000)
                wait(17)
            end
            lastDropTime = tick()
        else
            sendNotif("Cooldown", "Please wait for cooldown to finish!")
        end
    end
})

local CoordinatesPage = UI.New({
    Title = "Coordinates"
})

CoordinatesPage.Label({
    Text = "Only for Experts"
})

CoordinatesPage.Button({
    Text = "Get Current Coordinates",
    Callback = function()
        savedPosition = getCurrentCoordinates()
        sendNotif("Coordinates Saved", "Saved coordinates: " .. tostring(savedPosition))
    end
})

CoordinatesPage.Button({
    Text = "Teleport to Saved Coordinates",
    Callback = function()
        teleportToSavedPosition()
    end
})

CoordinatesPage.Slider({
    Text = "Height Adjustment",
    Min = 0,
    Max = 100,
    Def = 0,
    Callback = function(val)
        if savedPosition then
            savedPosition = Vector3.new(savedPosition.X, savedPosition.Y + val, savedPosition.Z)
            sendNotif("Height Adjusted", "New coordinates: " .. tostring(savedPosition))
        end
    end
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local watermarkGui = Instance.new("ScreenGui")
watermarkGui.Name = "WatermarkGui"
watermarkGui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Size = UDim2.new(0, 320, 0, 60)
frame.Position = UDim2.new(0, 15, 0, 15)
frame.AnchorPoint = Vector2.new(0, 0)
frame.Parent = watermarkGui

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(255, 255, 255)
uiStroke.Thickness = 1
uiStroke.Transparency = 0.8
uiStroke.Parent = frame

local function createTextLabel(text, size, posY, parent, posXOffset)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -20, 0, size)
    label.Position = UDim2.new(0, 10 + (posXOffset or 0), 0, posY)
    label.Font = Enum.Font.GothamBold
    label.TextSize = size
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextStrokeTransparency = 0.4
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Text = text
    label.Parent = parent
    return label
end

local titleLabel = createTextLabel("Rescue Experimental", 24, 8, frame)

local bottomFrame = Instance.new("Frame")
bottomFrame.BackgroundTransparency = 1
bottomFrame.Size = UDim2.new(1, -20, 0, 20)
bottomFrame.Position = UDim2.new(0, 10, 0, 34)
bottomFrame.Parent = frame

local versionLabel = Instance.new("TextLabel")
versionLabel.BackgroundTransparency = 1
versionLabel.Size = UDim2.new(0, 100, 1, 0)
versionLabel.Position = UDim2.new(0, 0, 0, 0)
versionLabel.Font = Enum.Font.GothamBold
versionLabel.TextSize = 16
versionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
versionLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
versionLabel.TextStrokeTransparency = 0.4
versionLabel.TextXAlignment = Enum.TextXAlignment.Left
versionLabel.TextYAlignment = Enum.TextYAlignment.Top
versionLabel.Text = "Version 2.2.5 | Update is soon"
versionLabel.Parent = bottomFrame

watermarkGui.Parent = PlayerGui