local repo =
    'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager =
    loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local Workspace = game:GetService('Workspace')
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService('UserInputService')
local StarterGui = game:GetService('StarterGui')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Camera = Workspace.CurrentCamera

local function sendNotif(title, text)
    library:Notify({
        Title = title,
        Description = text,
        Duration = 3,
        Callback = function() end,
    })
end

local Window = Library:CreateWindow({
    Title = 'Rescue Experimental V2.7.2 | https://discord.gg/WjDx83xQbA',
    Center = true,
    AutoShow = true,
})

local UIS = game:GetService('UserInputService')

local function toggleMenu()
    if Window:IsVisible() then
        Window:Hide()
        UserInputService.MouseIconEnabled = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    else
        Window:Show()
        UserInputService.MouseIconEnabled = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end
    if input.KeyCode == Enum.KeyCode.RightShift then
        toggleMenu()
    end
end)

UserInputService.MouseIconEnabled = true
UserInputService.MouseBehavior = Enum.MouseBehavior.Default

local AimbotTab = Window:AddTab('Aimbot')
local PlayerTab = Window:AddTab('Player')
local VisualsTab = Window:AddTab('Visuals')
local TeleportTab = Window:AddTab('Miscellaneous')

TabBox = AimbotTab:AddLeftTabbox()

Tab1 = TabBox:AddTab('Camera Aimbot')
Tab2 = TabBox:AddTab('Sticky Aim')

aimbotActive = false
aimPartName = 'HumanoidRootPart'
aimBind = Enum.KeyCode.X
waitingForAimBind = false
targetPlayer = nil
aiming = false

wallCheckEnabled = false
koCheckEnabled = false
wallCheckType = 'Once'
aimMethod = 'Camera'
forceFieldCheck = false

AIM_RADIUS = 200
invisibleBulletEnabled = false
rainbowFOV = false
fovFilled = false
hue = 0

targetStrafeEnabled = false
targetStrafeBind = Enum.KeyCode.F1
waitingForTargetStrafeBind = false
targetStrafeSpeed = 10
targetStrafeHeight = 1
targetStrafeDistance = 10
allowTargetStrafeBindToggle = false

autoPredEnabled = false
autoPredMath = 200

circle = Drawing.new('Circle')
circle.Color = Color3.fromRGB(255, 255, 255)
circle.Thickness = 2
circle.NumSides = 80
circle.Radius = AIM_RADIUS
circle.Filled = false
circle.Transparency = 1
circle.Visible = false

fovColor = Color3.fromRGB(255, 255, 255)
circle.Color = fovColor

resolverType = 'Recalculate'
autoLockEnabled = false
predictionX = 0
predictionY = 0
velocityResolverEnabled = false
resolverInterval = 0.1
lastResolveTime = 0

antiGroundShots = false
teamCheckEnabled = false
showTracer = false
showDot = false

rainbowDotTracerEnabled = false
highlightEnabled = false
rainbowHighlightEnabled = false

tracerLine = Drawing.new('Line')
tracerLine.Visible = false
tracerLine.Color = Color3.fromRGB(255, 255, 255)
tracerLine.Thickness = 2
tracerLine.ZIndex = 2

tracerOutline = Drawing.new('Line')
tracerOutline.Visible = false
tracerOutline.Color = Color3.fromRGB(0, 0, 0)
tracerOutline.Thickness = 4
tracerOutline.ZIndex = 1

dotCircle = Drawing.new('Circle')
dotCircle.Visible = false
dotCircle.Color = Color3.fromRGB(255, 255, 255)
dotCircle.Radius = 4
dotCircle.Filled = true
dotCircle.ZIndex = 2

dotOutline = Drawing.new('Circle')
dotOutline.Visible = false
dotOutline.Color = Color3.fromRGB(0, 0, 0)
dotOutline.Radius = 6
dotOutline.Filled = true
dotOutline.ZIndex = 1

highlights = {}

function sendNotif(title, text)
    StarterGui:SetCore(
        'SendNotification',
        { Title = title, Text = text, Duration = 3 }
    )
end

function isVisible(targetPart)
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = { LocalPlayer.Character }
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local raycastResult = Workspace:Raycast(origin, direction, raycastParams)
    if raycastResult then
        return raycastResult.Instance:IsDescendantOf(targetPart.Parent)
    else
        return true
    end
end

function isKO(player)
    if not player.Character then
        return true
    end
    local humanoid = player.Character:FindFirstChildOfClass('Humanoid')
    if humanoid and humanoid.Health > 2 then
        return false
    end
    return true
end

function hasForceField(player)
    if not player.Character then
        return false
    end
    return player.Character:FindFirstChildOfClass('ForceField') ~= nil
end

function findTargetInRadius(partName)
    local mousePos = UserInputService:GetMouseLocation()
    local closestPlayer = nil
    local closestDist = math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if
            player ~= LocalPlayer
            and player.Character
            and player.Character:FindFirstChild(partName)
        then
            if
                teamCheckEnabled
                and LocalPlayer.Team
                and player.Team == LocalPlayer.Team
            then
                continue
            end
            if antiGroundShots then
                local hum = player.Character:FindFirstChildOfClass('Humanoid')
                if hum and hum.FloorMaterial ~= Enum.Material.Air then
                    continue
                end
            end
            local part = player.Character[partName]
            local screenPos, onScreen =
                Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local pos2d = Vector2.new(screenPos.X, screenPos.Y)
                local dist = (pos2d - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
                if dist <= AIM_RADIUS and dist < closestDist then
                    if wallCheckEnabled and wallCheckType == 'Once' then
                        if isVisible(part) then
                            closestDist = dist
                            closestPlayer = player
                        end
                    else
                        closestDist = dist
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer
end

function velocityResolver(player)
    if not player.Character then
        return nil
    end
    local hrp = player.Character:FindFirstChild('HumanoidRootPart')
    if not hrp then
        return nil
    end
    local currentTime = tick()
    if currentTime - lastResolveTime < resolverInterval then
        return hrp.Position
    end
    lastResolveTime = currentTime
    local velocity = hrp.Velocity
    local predictedPos = hrp.Position
    if velocity.Magnitude > 1 then
        local offset = velocity.Unit * 1.5
        predictedPos = predictedPos + offset
    end
    return predictedPos
end

function predictPosition(player, partName)
    if
        not player.Character or not player.Character:FindFirstChild(partName)
    then
        return nil
    end
    local part = player.Character[partName]
    local hrp = player.Character:FindFirstChild('HumanoidRootPart')
    if not hrp then
        return part.Position
    end
    if velocityResolverEnabled then
        local velResolvedPos = velocityResolver(player)
        if velResolvedPos then
            return velResolvedPos
        end
    end
    if autoPredEnabled then
        local vel = hrp.Velocity
        return part.Position + (vel / autoPredMath)
    end
    if resolverType == 'Recalculate' then
        return Vector3.new(
            part.Position.X + predictionX,
            part.Position.Y + predictionY,
            part.Position.Z + predictionX
        )
    elseif resolverType == 'Move Direction' then
        local velocity = hrp.Velocity or Vector3.new()
        return part.Position + velocity * 0.1
    else
        return part.Position
    end
end

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        circle.Position = Vector2.new(input.Position.X, input.Position.Y + 50)
    end
end)

fixedInvisibleBulletPos = nil

RunService.RenderStepped:Connect(function()
    if rainbowFOV then
        hue = (hue + 1) % 360
        circle.Color = Color3.fromHSV(hue / 360, 1, 1)
    else
        circle.Color = fovColor
    end

    if aimbotActive and autoLockEnabled then
        if
            not targetPlayer
            or not (
                targetPlayer.Character
                and targetPlayer.Character:FindFirstChild(aimPartName)
            )
        then
            targetPlayer = findTargetInRadius(aimPartName)
            aiming = targetPlayer ~= nil
        end
    end

    if
        aimbotActive
        and aiming
        and targetPlayer
        and targetPlayer.Character
        and targetPlayer.Character:FindFirstChild(aimPartName)
    then
        if koCheckEnabled and isKO(targetPlayer) then
            aiming = false
            targetPlayer = nil
            fixedInvisibleBulletPos = nil
            return
        elseif forceFieldCheck and hasForceField(targetPlayer) then
            aiming = false
            targetPlayer = nil
            fixedInvisibleBulletPos = nil
            return
        end

        local targetPart = targetPlayer.Character[aimPartName]
        if
            wallCheckEnabled
            and wallCheckType == 'Repeat'
            and not isVisible(targetPart)
        then
            aiming = false
            targetPlayer = nil
            fixedInvisibleBulletPos = nil
            return
        end

        local camPos = Camera.CFrame.Position
        local targetPos = predictPosition(targetPlayer, aimPartName)
        local direction = (targetPos - camPos).Unit

        if aimMethod == 'Camera' then
            Camera.CFrame = CFrame.new(camPos, camPos + direction)
        elseif aimMethod == 'Mouse' then
            local screenPos = Camera:WorldToViewportPoint(targetPos)
            mousemoverel(
                screenPos.X - UserInputService:GetMouseLocation().X,
                screenPos.Y - UserInputService:GetMouseLocation().Y
            )
        end

        if invisibleBulletEnabled then
            local targetChar = targetPlayer.Character
            local rightHand = targetChar:FindFirstChild('RightHand')
                or targetChar:FindFirstChild('Right Arm')
            local localChar = LocalPlayer.Character
            if
                rightHand
                and localChar
                and localChar:FindFirstChild('HumanoidRootPart')
            then
                if not fixedInvisibleBulletPos then
                    fixedInvisibleBulletPos = localChar.HumanoidRootPart.Position
                        + Vector3.new(0, 0, 10)
                end
                rightHand.CFrame = CFrame.new(fixedInvisibleBulletPos)
            end
        else
            fixedInvisibleBulletPos = nil
        end
    else
        fixedInvisibleBulletPos = nil
    end

    if targetPlayer and targetPlayer.Character then
        if highlightEnabled or rainbowHighlightEnabled then
            if not highlights[targetPlayer] then
                local h = Instance.new('Highlight')
                h.Parent = targetPlayer.Character
                h.FillTransparency = 0.5
                h.OutlineTransparency = 0
                h.OutlineColor = Color3.fromRGB(0, 0, 0)
                h.FillColor = Color3.fromRGB(255, 255, 255)
                highlights[targetPlayer] = h
            end
            if rainbowHighlightEnabled then
                hue = (hue + 1) % 360
                highlights[targetPlayer].FillColor =
                    Color3.fromHSV(hue / 360, 1, 1)
                highlights[targetPlayer].OutlineColor = Color3.fromRGB(0, 0, 0)
            else
                highlights[targetPlayer].FillColor =
                    Color3.fromRGB(255, 255, 255)
                highlights[targetPlayer].OutlineColor = Color3.fromRGB(0, 0, 0)
            end
        end
    end

    for player, h in pairs(highlights) do
        if
            (player ~= targetPlayer or not aimbotActive or not aiming)
            and h
            and h.Parent
        then
            h:Destroy()
            highlights[player] = nil
        end
    end

    if
        aiming
        and targetPlayer
        and targetPlayer.Character
        and targetPlayer.Character:FindFirstChild(aimPartName)
    then
        local part = targetPlayer.Character[aimPartName]
        local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
        if rainbowDotTracerEnabled then
            hue = (hue + 1) % 360
            tracerLine.Color = Color3.fromHSV(hue / 360, 1, 1)
            tracerOutline.Color = Color3.fromHSV(hue / 360, 1, 1)
            dotCircle.Color = Color3.fromHSV(hue / 360, 1, 1)
        else
            tracerLine.Color = Color3.fromRGB(255, 255, 255)
            tracerOutline.Color = Color3.fromRGB(0, 0, 0)
            dotCircle.Color = Color3.fromRGB(255, 255, 255)
        end
        if showTracer and onScreen then
            local mousePos = UserInputService:GetMouseLocation()
            tracerOutline.From = Vector2.new(mousePos.X, mousePos.Y)
            tracerOutline.To = Vector2.new(screenPos.X, screenPos.Y)
            tracerLine.From = Vector2.new(mousePos.X, mousePos.Y)
            tracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
            tracerOutline.Visible = true
            tracerLine.Visible = true
        else
            tracerOutline.Visible = false
            tracerLine.Visible = false
        end
        if showDot and onScreen then
            dotOutline.Position = Vector2.new(screenPos.X, screenPos.Y)
            dotCircle.Position = Vector2.new(screenPos.X, screenPos.Y)
            dotOutline.Visible = true
            dotCircle.Visible = true
        else
            dotOutline.Visible = false
            dotCircle.Visible = false
        end
    else
        tracerOutline.Visible = false
        tracerLine.Visible = false
        dotOutline.Visible = false
        dotCircle.Visible = false
    end
end)

RunService.RenderStepped:Connect(function()
    if targetStrafeEnabled and aiming and targetPlayer then
        local targetPart = targetPlayer.Character[aimPartName]
        local hrp = LocalPlayer.Character
            and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
        local humanoid = LocalPlayer.Character
            and LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
        if hrp and humanoid then
            humanoid.PlatformStand = true
            local angle = tick() * targetStrafeSpeed
            local offset = Vector3.new(
                math.sin(angle) * targetStrafeDistance,
                targetStrafeHeight,
                math.cos(angle) * targetStrafeDistance
            )
            local basePos = Vector3.new(
                targetPart.Position.X,
                targetPart.Position.Y + targetStrafeHeight,
                targetPart.Position.Z
            )
            local strafePosition = basePos + offset
            local direction = (targetPart.Position - hrp.Position).Unit
            direction = Vector3.new(direction.X, 0, direction.Z)
            local desiredCFrame =
                CFrame.new(strafePosition, strafePosition + direction)
            hrp.CFrame = hrp.CFrame:Lerp(desiredCFrame, 0.2)
            hrp.Velocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
        end
    else
        local humanoid = LocalPlayer.Character
            and LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
        if humanoid then
            humanoid.PlatformStand = false
        end
    end
end)

Tab1:AddToggle('EnableAimbot', {
    Text = 'Enable',
    Default = false,
})
    :AddKeyPicker('AimBind', {
        Default = '',
        Mode = 'Toggle',
        Text = 'Camera Aimbot',
        NoUI = false,
        SyncToggleState = false,
        Callback = function(state)
            if UserInputService:GetFocusedTextBox() then
                return
            end

            aiming = state
            if not state then
                targetPlayer = nil
            else
                targetPlayer = findTargetInRadius(aimPartName)
            end
        end,
    })
    :OnChanged(function(state)
        if UserInputService:GetFocusedTextBox() then
            return
        end

        aimbotActive = state
        circle.Visible = state

        if not state then
            aiming = false
            targetPlayer = nil
        end

        if aimbotNotifyEnabled then
            Library:Notify(
                'Aimbot - ' .. (state and 'Enabled' or 'Disabled'),
                3
            )
        end
    end)

Tab1:AddToggle('AutoLock', {
    Text = 'Auto Lock',
    Default = false,
}):OnChanged(function(state)
    autoLockEnabled = state
end)

Tab1:AddInput('PredictionX', {
    Default = '0',
    Numeric = true,
    Finished = true,
    Text = 'Prediction X',
    Placeholder = 'Enter position X',
}):OnChanged(function(value)
    predictionX = tonumber(value) or 0
end)

Tab1:AddInput('PredictionY', {
    Default = '0',
    Numeric = true,
    Finished = true,
    Text = 'Prediction Y',
    Placeholder = 'Enter position Y',
}):OnChanged(function(value)
    predictionY = tonumber(value) or 0
end)

Tab1:AddToggle('VelocityResolver', {
    Text = 'Velocity Resolver',
    Default = false,
}):OnChanged(function(state)
    velocityResolverEnabled = state
end)

Tab1:AddSlider('ResolverInterval', {
    Text = 'Resolver Interval',
    Default = 0.1,
    Min = 0,
    Max = 0.5,
    Rounding = 2,
    Compact = false,
}):OnChanged(function(value)
    resolverInterval = value
end)

Tab1:AddDropdown('ResolverType', {
    Values = { 'Recalculate', 'Move Direction' },
    Default = resolverType,
    Multi = false,
    Text = 'Resolver Type',
}):OnChanged(function(value)
    resolverType = value
end)

Tab1:AddDropdown('AimPart', {
    Values = { 'Head', 'HumanoidRootPart', 'UpperTorso', 'LowerTorso' },
    Default = aimPartName,
    Multi = false,
    Text = 'Hit Part',
}):OnChanged(function(value)
    aimPartName = value
end)

Tab1:AddToggle('AutoPred', {
    Text = 'Auto Pred',
    Default = false,
}):OnChanged(function(state)
    autoPredEnabled = state
end)

Tab1:AddSlider('AutoPredMath', {
    Text = 'Auto Pred Math',
    Default = 200,
    Min = 200,
    Max = 300,
    Rounding = 0,
    Compact = false,
}):OnChanged(function(value)
    autoPredMath = value
end)

local ManualTargetInput = Tab1:AddInput('ManualTargetInput', {
    Text = 'Manual Target Aimbot',
    Default = '',
    Numeric = false,
    Finished = true,
    Placeholder = 'Enter player name',
})

local manualTargetName = ''

ManualTargetInput:OnChanged(function(value)
    manualTargetName = value:lower()
    if aimbotActive and manualTargetName ~= '' then
        local foundPlayer = nil
        for _, player in pairs(Players:GetPlayers()) do
            local nameLower = player.Name:lower()
            local displayNameLower = player.DisplayName:lower()
            if
                nameLower:find(manualTargetName)
                or displayNameLower:find(manualTargetName)
            then
                foundPlayer = player
                break
            end
        end
        if foundPlayer then
            targetPlayer = foundPlayer
            aiming = true
            Library:Notify(
                'Manual target set: '
                    .. foundPlayer.Name
                    .. ' ('
                    .. foundPlayer.DisplayName
                    .. ')',
                3
            )
        else
            targetPlayer = nil
            aiming = false
            Library:Notify('Manual target not found', 3)
        end
    elseif not aimbotActive then
        targetPlayer = nil
        aiming = false
    end
end)

Tab1:AddToggle('WallCheck', {
    Text = 'Wall Check',
    Default = false,
}):OnChanged(function(state)
    wallCheckEnabled = state
end)

Tab1:AddDropdown('WallCheckType', {
    Values = { 'Once', 'Repeat' },
    Default = wallCheckType,
    Multi = false,
    Text = 'Wall Check Type',
}):OnChanged(function(value)
    wallCheckType = value
end)

Tab1:AddToggle('KOCheck', {
    Text = 'K.O Check',
    Default = false,
}):OnChanged(function(state)
    koCheckEnabled = state
end)

Tab1:AddToggle('TeamCheck', {
    Text = 'Team Check',
    Default = false,
}):OnChanged(function(state)
    teamCheckEnabled = state
end)

Tab1:AddToggle('ForceFieldCheck', {
    Text = 'ForceField Check',
    Default = false,
}):OnChanged(function(state)
    forceFieldCheck = state
end)

Tab1:AddToggle('AntiGroundShots', {
    Text = 'Anti Ground Shots',
    Default = false,
}):OnChanged(function(state)
    antiGroundShots = state
end)

Tab1
    :AddToggle('InvisibleBullet', {
        Text = 'Invisible Bullet',
        Default = false,
        Tooltip = '[Not supported REAL da hood] teleporting and anchor player character',
    })
    :OnChanged(function(state)
        invisibleBulletEnabled = state
    end)

TweenService = game:GetService('TweenService')
playerGui = LocalPlayer:WaitForChild('PlayerGui')

local statsTargetEnabled = false
local currentTarget = nil

local screenGui = Instance.new('ScreenGui')
screenGui.Name = 'StatsTargetGui'
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false

local statsFrame = Instance.new('Frame')
statsFrame.Size = UDim2.new(0, 320, 0, 100)
statsFrame.Position = UDim2.new(0.5, 0, 1, -150)
statsFrame.AnchorPoint = Vector2.new(0.5, 1)
statsFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
statsFrame.BorderSizePixel = 0
statsFrame.Visible = false
statsFrame.BackgroundTransparency = 0.1
statsFrame.Parent = screenGui

local uiCorner = Instance.new('UICorner')
uiCorner.CornerRadius = UDim.new(0, 6)
uiCorner.Parent = statsFrame

local avatarImage = Instance.new('ImageLabel')
avatarImage.Size = UDim2.new(0, 80, 0, 80)
avatarImage.Position = UDim2.new(0, 10, 0.5, -40)
avatarImage.BackgroundTransparency = 1
avatarImage.ScaleType = Enum.ScaleType.Fit
avatarImage.BorderSizePixel = 0
avatarImage.Parent = statsFrame

local avatarUICorner = Instance.new('UICorner')
avatarUICorner.CornerRadius = UDim.new(1, 0)
avatarUICorner.Parent = avatarImage

local infoFrame = Instance.new('Frame')
infoFrame.Position = UDim2.new(0, 100, 0, 10)
infoFrame.Size = UDim2.new(1, -110, 1, -20)
infoFrame.BackgroundTransparency = 1
infoFrame.Parent = statsFrame

local displayNameLabel = Instance.new('TextLabel')
displayNameLabel.Size = UDim2.new(1, 0, 0, 20)
displayNameLabel.BackgroundTransparency = 1
displayNameLabel.Font = Enum.Font.GothamBold
displayNameLabel.TextSize = 19
displayNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
displayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
displayNameLabel.Text = 'DisplayName'
displayNameLabel.Parent = infoFrame

local usernameLabel = Instance.new('TextLabel')
usernameLabel.Size = UDim2.new(1, 0, 0, 16)
usernameLabel.Position = UDim2.new(0, 0, 0, 20)
usernameLabel.BackgroundTransparency = 1
usernameLabel.Font = Enum.Font.GothamSemibold
usernameLabel.TextSize = 19
usernameLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
usernameLabel.Text = '@username'
usernameLabel.Parent = infoFrame

local progressBG = Instance.new('Frame')
progressBG.Position = UDim2.new(0, 100, 1, -20)
progressBG.Size = UDim2.new(0, 200, 0, 8)
progressBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
progressBG.BorderSizePixel = 0
progressBG.Parent = statsFrame

local progressFill = Instance.new('Frame')
progressFill.Size = UDim2.new(1, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBG

local lastTargetInfo = {
    displayName = '',
    username = '',
    health = -1,
    userId = -1,
}

local function showStatsFrame()
    if statsFrame.Visible then
        return
    end
    statsFrame.Visible = true
    TweenService
        :Create(
            statsFrame,
            TweenInfo.new(0.25),
            { BackgroundTransparency = 0.1 }
        )
        :Play()
end

local function hideStatsFrame()
    if not statsFrame.Visible then
        return
    end
    local tweenOut = TweenService:Create(
        statsFrame,
        TweenInfo.new(0.25),
        { BackgroundTransparency = 1 }
    )
    tweenOut:Play()
    tweenOut.Completed:Wait()
    statsFrame.Visible = false
end

local function updateStatsTarget(player)
    if not statsTargetEnabled or not player or not player.Character then
        hideStatsFrame()
        currentTarget = nil
        return
    end

    local humanoid = player.Character:FindFirstChildOfClass('Humanoid')
    if not humanoid then
        hideStatsFrame()
        return
    end

    local displayName = player.DisplayName or 'Unknown'
    local username = player.Name or 'Unknown'
    local health = math.floor(humanoid.Health)
    local userId = player.UserId or 0

    if
        currentTarget ~= player
        or lastTargetInfo.displayName ~= displayName
        or lastTargetInfo.username ~= username
        or lastTargetInfo.health ~= health
        or lastTargetInfo.userId ~= userId
    then
        currentTarget = player
        displayNameLabel.Text = displayName
        usernameLabel.Text = '[' .. username .. ']'
        avatarImage.Image = 'https://www.roblox.com/headshot-thumbnail/image?userId='
            .. userId
            .. '&width=150&height=150&format=png'

        local percent = math.clamp(health / humanoid.MaxHealth, 0, 1)
        progressFill.Size = UDim2.new(percent, 0, 1, 0)

        showStatsFrame()

        lastTargetInfo.displayName = displayName
        lastTargetInfo.username = username
        lastTargetInfo.health = health
        lastTargetInfo.userId = userId
    end
end

RunService.RenderStepped:Connect(function()
    if statsTargetEnabled and targetPlayer and targetPlayer.Character then
        updateStatsTarget(targetPlayer)
    else
        hideStatsFrame()
    end
end)

Tab1:AddToggle('CheckTracer', {
    Text = 'Tracer Target',
    Default = false,
}):OnChanged(function(state)
    showTracer = state
end)

Tab1:AddToggle('CheckDot', {
    Text = 'Dot Target',
    Default = false,
}):OnChanged(function(state)
    showDot = state
end)

Tab1:AddToggle('RainbowDotTracer', {
    Text = 'Rainbow Dot & Tracer',
    Default = false,
    Callback = function(state)
        rainbowDotTracerEnabled = state
    end,
})
Tab1:AddToggle('Highlight', {
    Text = 'Highlight',
    Default = false,
    Callback = function(state)
        highlightEnabled = state
        if state then
            rainbowHighlightEnabled = false
        end
    end,
})
Tab1:AddToggle('RainbowHighlight', {
    Text = 'Rainbow Highlight',
    Default = false,
    Callback = function(state)
        rainbowHighlightEnabled = state
        if state then
            highlightEnabled = false
        end
    end,
})

Tab1:AddToggle('StatsTarget', {
    Text = 'Stats Target v2',
    Default = false,
}):OnChanged(function(state)
    statsTargetEnabled = state
    if not state then
        hideStatsFrame()
    end
end)

Tab1:AddDropdown('AimMethod', {
    Values = { 'Camera', 'Mouse' },
    Default = aimMethod,
    Multi = false,
    Text = 'Aim Method',
}):OnChanged(function(value)
    aimMethod = value
end)

Tab1:AddToggle('ShowFOV', {
    Text = 'Show FOV Circle',
    Default = true,
    Callback = function(state)
        circle.Visible = state and aimbotActive
    end,
}):AddColorPicker('FOVCircleColor', {
    Default = fovColor,
    Title = 'FOV Circle Color',
    Callback = function(color)
        fovColor = color
        if not rainbowFOV then
            circle.Color = color
        end
    end,
})

Tab1:AddToggle('RainbowFOV', {
    Text = 'Rainbow FOV',
    Default = false,
}):OnChanged(function(state)
    rainbowFOV = state
end)

Tab1:AddSlider('FOVSize', {
    Text = 'FOV Size',
    Default = AIM_RADIUS,
    Min = 50,
    Max = 500,
    Rounding = 0,
}):OnChanged(function(value)
    AIM_RADIUS = value
    circle.Radius = value
end)

Tab1:AddSlider('FOVTransparency', {
    Text = 'FOV Transparency',
    Default = 0.7,
    Min = 0,
    Max = 1,
    Rounding = 2,
}):OnChanged(function(value)
    circle.Transparency = value
end)

--// Services
local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')

--// Global Settings
getgenv().Silent = getgenv().Silent or {}
local S = getgenv().Silent
S.Enabled = S.Enabled or false
S.ToggleSetting = S.ToggleSetting or false
S.FOVRadius = S.FOVRadius or 100
S.FOVTransparency = S.FOVTransparency or 0.7
S.TargetPart = S.TargetPart or 'HumanoidRootPart'
S.RainbowFOV = S.RainbowFOV or false
S.FOVColor = S.FOVColor or Color3.fromRGB(255, 255, 255)
S.AutoPred = S.AutoPred or true
S.AutoPredMath = S.AutoPredMath or 200
S.WallCheck = S.WallCheck or false
S.KOCheck = S.KOCheck or false
S.TeamCheck = S.TeamCheck or false
S.ForceFieldCheck = S.ForceFieldCheck or false
S.AntiGroundShots = S.AntiGroundShots or false
S.TracerTarget = S.TracerTarget or false
S.TracerDot = S.TracerDot or false
S.RainbowTracerDot = S.RainbowTracerDot or false
S.ShowFOVCircle = S.ShowFOVCircle or true

--// Drawing
getgenv().Drawings = getgenv().Drawings or {}
local FOVCircle = getgenv().Drawings.FOVCircle or Drawing.new('Circle')
local TracerLineOutline = getgenv().Drawings.TracerLineOutline
    or Drawing.new('Line')
local TracerLine = getgenv().Drawings.TracerLine or Drawing.new('Line')
local TracerDotOutline = getgenv().Drawings.TracerDotOutline
    or Drawing.new('Circle')
local TracerDotObj = getgenv().Drawings.TracerDotObj or Drawing.new('Circle')

--// Initialize Drawing Objects
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Thickness = 2
FOVCircle.NumSides = 100
FOVCircle.Filled = false
FOVCircle.Visible = false

TracerLineOutline.Thickness = 4
TracerLineOutline.Color = Color3.fromRGB(0, 0, 0)
TracerLineOutline.Visible = false

TracerLine.Thickness = 2
TracerLine.Color = Color3.fromRGB(255, 255, 255)
TracerLine.Visible = false

TracerDotOutline.Radius = 6
TracerDotOutline.Filled = false
TracerDotOutline.Color = Color3.fromRGB(0, 0, 0)
TracerDotOutline.Thickness = 2
TracerDotOutline.Visible = false

TracerDotObj.Radius = 4
TracerDotObj.Filled = true
TracerDotObj.Color = Color3.fromRGB(255, 255, 255)
TracerDotObj.Visible = false

getgenv().Drawings.FOVCircle = FOVCircle
getgenv().Drawings.TracerLineOutline = TracerLineOutline
getgenv().Drawings.TracerLine = TracerLine
getgenv().Drawings.TracerDotOutline = TracerDotOutline
getgenv().Drawings.TracerDotObj = TracerDotObj

--// Utilities
local playerPositions = {}

local function getRainbowColor()
    return Color3.fromHSV(tick() % 5 / 5, 1, 1)
end

local function WallCheck(targetPart)
    if not S.WallCheck then
        return true
    end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = { LocalPlayer.Character }
    local result = workspace:Raycast(origin, direction, rayParams)
    return result == nil
        or (
            result.Instance and result.Instance:IsDescendantOf(
                targetPart.Parent
            )
        )
end

local function IsKnockedOut(player)
    local body = player.Character
        and player.Character:FindFirstChild('BodyEffects')
    local ko = body
        and (
            body:FindFirstChild('K.O')
            or body:FindFirstChild('KO')
            or body:FindFirstChild('K_O')
        )
    return ko and ko.Value
end

local function IsValidTarget(player)
    if not player.Character then
        return false
    end
    local part = player.Character:FindFirstChild(S.TargetPart)
    if not part then
        return false
    end
    if S.KOCheck and IsKnockedOut(player) then
        return false
    end
    if S.TeamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return false
    end
    if
        S.ForceFieldCheck
        and player.Character:FindFirstChildOfClass('ForceField')
    then
        return false
    end
    if S.WallCheck and not WallCheck(part) then
        return false
    end
    return true
end

local function GetClosestTarget()
    local closest, minDist = nil, S.FOVRadius
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsValidTarget(player) then
            local part = player.Character:FindFirstChild(S.TargetPart)
            if part then
                local screenPos, onScreen =
                    Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (
                        Vector2.new(screenPos.X, screenPos.Y)
                        - UserInputService:GetMouseLocation()
                    ).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

local function PredictPosition(player)
    if not player.Character then
        return nil
    end
    local part = player.Character:FindFirstChild(S.TargetPart)
    if not part then
        return nil
    end

    playerPositions[player] = playerPositions[player] or {}
    table.insert(playerPositions[player], part.Position)
    if #playerPositions[player] > 3 then
        table.remove(playerPositions[player], 1)
    end

    local vel = Vector3.new()
    if #playerPositions[player] > 1 then
        vel = (
            playerPositions[player][#playerPositions[player]]
            - playerPositions[player][1]
        ) / (0.1 * (#playerPositions[player] - 1))
    end

    local travelTime = (Camera.CFrame.Position - part.Position).Magnitude
        / (S.AutoPredMath or 200)
    return part.Position + vel * travelTime * 0.5
end

--// Render Loop
RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    FOVCircle.Position = mousePos
    FOVCircle.Radius = S.FOVRadius
    FOVCircle.Transparency = S.FOVTransparency
    FOVCircle.Visible = S.Enabled and S.ShowFOVCircle
    if FOVCircle.Visible then
        FOVCircle.Color = S.RainbowFOV and getRainbowColor() or S.FOVColor
    end

    local target = GetClosestTarget()
    if target and S.Enabled then
        local predictedPos = PredictPosition(target)
        local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
        local color = S.RainbowTracerDot and getRainbowColor() or S.FOVColor

        if S.TracerTarget and onScreen then
            TracerLineOutline.From = Vector2.new(
                Camera.ViewportSize.X / 2,
                Camera.ViewportSize.Y / 2
            )
            TracerLineOutline.To = Vector2.new(screenPos.X, screenPos.Y)
            TracerLineOutline.Visible = true

            TracerLine.From = Vector2.new(
                Camera.ViewportSize.X / 2,
                Camera.ViewportSize.Y / 2
            )
            TracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
            TracerLine.Color = color
            TracerLine.Visible = true
        else
            TracerLine.Visible = false
            TracerLineOutline.Visible = false
        end

        if S.TracerDot and onScreen then
            TracerDotOutline.Position = Vector2.new(screenPos.X, screenPos.Y)
            TracerDotOutline.Visible = true
            TracerDotObj.Position = Vector2.new(screenPos.X, screenPos.Y)
            TracerDotObj.Color = color
            TracerDotObj.Visible = true
        else
            TracerDotObj.Visible = false
            TracerDotOutline.Visible = false
        end
    else
        TracerLine.Visible = false
        TracerLineOutline.Visible = false
        TracerDotObj.Visible = false
        TracerDotOutline.Visible = false
    end
end)

if getrawmetatable and setreadonly and newcclosure then
    local mt = getrawmetatable(game)
    local oldIndex = mt.__index
    setreadonly(mt, false)
    mt.__index = newcclosure(function(self, key)
        if
            typeof(self) == 'Instance'
            and self:IsA('Mouse')
            and key == 'Hit'
            and S.Enabled
        then
            local target = GetClosestTarget()
            if target then
                local pos = PredictPosition(target)
                if pos then
                    return CFrame.new(pos)
                end
            end
        end
        return oldIndex(self, key)
    end)
    setreadonly(mt, true)
end

Tab2:AddToggle('silentAimToggle', {
    Text = 'Enable',
    Default = S.ToggleSetting,
    Callback = function(state)
        S.ToggleSetting = state
        S.Enabled = state
    end,
})
    :AddKeyPicker('SilentAimBind', {
        Default = '',
        Mode = 'Toggle',
        Text = 'Sticky Aim',
        NoUI = false,
        Callback = function(state)
            if not S.ToggleSetting then
                return
            end
            S.Enabled = state
        end,
    })
    :OnChanged(function(state)
        if not S.ToggleSetting then
            S.Enabled = false
            return
        end
        S.Enabled = state
    end)

Tab2:AddInput('predictionXInput', {
    Text = 'Prediction X',
    Default = tostring(S.PredictionX or 0),
    Numeric = true,
    PlaceholderText = 'Enter X prediction',
    Callback = function(value)
        S.PredictionX = tonumber(value) or 0
    end,
})

Tab2:AddInput('predictionYInput', {
    Text = 'Prediction Y',
    Default = tostring(S.PredictionY or 0),
    Numeric = true,
    PlaceholderText = 'Enter Y prediction',
    Callback = function(value)
        S.PredictionY = tonumber(value) or 0
    end,
})

Tab2:AddToggle('velocityResolverToggle', {
    Text = 'Velocity Resolver',
    Default = S.VelocityResolver or false,
    Callback = function(state)
        S.VelocityResolver = state
    end,
})

Tab2:AddSlider('resolverIntervalSlider', {
    Text = 'Resolver Interval',
    Default = S.ResolverInterval or 0.1,
    Min = 0.01,
    Max = 0.5,
    Rounding = 2,
    Callback = function(value)
        S.ResolverInterval = value
    end,
})

Tab2:AddDropdown('resolverTypeDropdown', {
    Text = 'Resolver Type',
    Values = { 'Recalculate', 'Move Direction' },
    Default = S.ResolverType or 'Recalculate',
    Callback = function(value)
        S.ResolverType = value
    end,
})

Tab2:AddDropdown('targetPartDropdown', {
    Values = { 'HumanoidRootPart', 'Head', 'UpperTorso', 'LowerTorso' },
    Default = 1,
    Text = 'Target Part',
    Callback = function(value)
        S.TargetPart = value
    end,
})

Tab2:AddToggle('autoPredToggle', {
    Text = 'Auto Pred',
    Default = S.AutoPred or false,
    Callback = function(state)
        S.AutoPred = state
    end,
})

Tab2:AddSlider('autoPredMathSlider', {
    Text = 'Auto Pred Math',
    Default = S.AutoPredMath or 200,
    Min = 200,
    Max = 300,
    Rounding = 0,
    Callback = function(value)
        S.AutoPredMath = value
    end,
})

Tab2:AddToggle('wallCheckToggle', {
    Text = 'Wall Check',
    Default = S.WallCheck or false,
    Callback = function(state)
        S.WallCheck = state
    end,
})

Tab2:AddDropdown('wallCheckModeDropdown', {
    Text = 'Wall Check Mode',
    Values = { 'Once', 'Repeat' },
    Default = (S.WallCheckMode == 'Repeat') and 2 or 1,
    Callback = function(value)
        S.WallCheckMode = value
    end,
})

Tab2:AddToggle('KOCheckToggle', {
    Text = 'K.O Check',
    Default = S.KOCheck or false,
    Callback = function(state)
        S.KOCheck = state
    end,
})

Tab2:AddToggle('teamCheckToggle', {
    Text = 'Team Check',
    Default = S.TeamCheck or false,
    Callback = function(state)
        S.TeamCheck = state
    end,
})

Tab2:AddToggle('forceFieldCheckToggle', {
    Text = 'Force Field Check',
    Default = S.ForceFieldCheck or false,
    Callback = function(state)
        S.ForceFieldCheck = state
    end,
})

Tab2:AddToggle('antiGroundShotsToggle', {
    Text = 'Anti Ground Shots',
    Default = S.AntiGroundShots or false,
    Callback = function(state)
        S.AntiGroundShots = state
    end,
})

Tab2:AddToggle('tracerTargetToggle', {
    Text = 'Tracer Target',
    Default = S.TracerTarget or false,
    Callback = function(state)
        S.TracerTarget = state
    end,
})

Tab2:AddToggle('tracerDotToggle', {
    Text = 'Tracer Dot',
    Default = S.TracerDot or false,
    Callback = function(state)
        S.TracerDot = state
    end,
})

Tab2:AddToggle('rainbowTracerDotToggle', {
    Text = 'Rainbow Dot & Tracer',
    Default = S.RainbowTracerDot or false,
    Callback = function(state)
        S.RainbowTracerDot = state
    end,
})

Tab2:AddDropdown('fovPositionDropdown', {
    Text = 'Method',
    Values = { 'Hook', 'MetaHook', 'FireEvent', 'MainEvent' },
    Default = 1,
    Callback = function(value) end,
})

Tab2:AddToggle('showFOVCircleToggle', {
    Text = 'Show FOV Circle',
    Default = S.ShowFOVCircle,
    Callback = function(state)
        S.ShowFOVCircle = state
        FOVCircleInstance.Visible = state and S.Enabled
    end,
}):AddColorPicker('fovCircleColorPicker', {
    Default = S.FOVColor,
    Title = 'FOV Circle Color',
    Callback = function(color)
        S.FOVColor = color
        if not S.RainbowFOV then
            FOVCircleInstance.Color = color
        end
    end,
})

Tab2:AddToggle('rainbowFOVToggle', {
    Text = 'Rainbow FOV',
    Default = S.RainbowFOV,
    Callback = function(state)
        S.RainbowFOV = state
    end,
})

Tab2:AddSlider('silentFOVSlider', {
    Text = 'FOV Size',
    Default = S.FOVRadius,
    Min = 50,
    Max = 500,
    Rounding = 0,
    Callback = function(value)
        S.FOVRadius = value
    end,
})
Tab2:AddSlider('fovTransparencySlider', {
    Text = 'FOV Transparency',
    Default = S.FOVTransparency,
    Min = 0,
    Max = 1,
    Rounding = 2,
    Callback = function(value)
        S.FOVTransparency = value
    end,
})

TargetStrafeGroup = AimbotTab:AddLeftGroupbox('Target Strafe')

strafeMode = 'Static'
strafeModeOption = 'Custom'

TargetStrafeGroup:AddToggle('EnableTargetStrafe', {
    Text = 'Enable',
    Default = false,
})
    :AddKeyPicker('StrafeBind', {
        Default = '',
        Mode = 'Toggle',
        Text = 'Target Strafe',
        NoUI = false,
        SyncToggleState = false,
        Callback = function(state)
            if UserInputService:GetFocusedTextBox() then
                return false
            end
            if allowTargetStrafeBindToggle then
                targetStrafeEnabled = state
            else
                targetStrafeEnabled = false
            end
        end,
    })
    :OnChanged(function(state)
        allowTargetStrafeBindToggle = state
        targetStrafeEnabled = state
    end)

TargetStrafeGroup:AddDropdown('StrafeModeDropdown', {
    Values = { 'Static', 'Smooth' },
    Default = strafeMode,
    Multi = false,
    Text = 'Strafe Mode',
}):OnChanged(function(value)
    strafeMode = value
end)

TargetStrafeGroup:AddInput('ManualTargetInput', {
    Text = 'Manual Target Strafe',
    Default = '',
    Placeholder = 'Enter player name',
    Numeric = false,
    Finished = true,
    Callback = function(text)
        if text == '' then
            manualTargetName = nil
            currentTarget = nil
            manualTargetPlayer = nil
            return
        end
        manualTargetName = text
        local lowerText = text:lower()
        local exactMatch, partialMatch = nil, nil
        for _, plr in ipairs(Players:GetPlayers()) do
            local plrName = plr.Name:lower()
            local plrDisplay = plr.DisplayName:lower()
            if
                plr.Character
                and plr.Character:FindFirstChild('HumanoidRootPart')
            then
                if plrDisplay == lowerText or plrName == lowerText then
                    exactMatch = plr
                    break
                elseif
                    plrDisplay:find(lowerText, 1, true)
                    or plrName:find(lowerText, 1, true)
                then
                    partialMatch = plr
                end
            end
        end
        currentTarget = exactMatch or partialMatch
        manualTargetPlayer = currentTarget
    end,
})

sliderStrafeSpeed = targetStrafeSpeed
sliderStrafeDistance = targetStrafeDistance
sliderStrafeHeight = targetStrafeHeight

function instantStrafe(hrp, targetPos, direction)
    if strafeMode == 'Smooth' then
        local currentCFrame = hrp.CFrame
        local targetCFrame = CFrame.new(targetPos, targetPos + direction)
        local lerpAlpha = 0.15
        hrp.CFrame = currentCFrame:Lerp(targetCFrame, lerpAlpha)
        hrp.Velocity = hrp.Velocity * 0.9
        hrp.RotVelocity = hrp.RotVelocity * 0.9
    else
        hrp.CFrame = CFrame.new(targetPos, targetPos + direction)
    end
end

function performStrafe(target)
    if
        not target
        or not target.Character
        or not target.Character:FindFirstChild(aimPartName)
    then
        return
    end
    local targetPart = target.Character[aimPartName]
    local hrp = LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    local humanoid = LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
    if not hrp or not humanoid then
        return
    end
    humanoid.PlatformStand = true
    local angle = tick() * targetStrafeSpeed
    local offset = Vector3.new(
        math.sin(angle) * targetStrafeDistance,
        targetStrafeHeight,
        math.cos(angle) * targetStrafeDistance
    )
    local basePos = targetPart.Position
    local strafePosition = basePos + offset
    local direction = (basePos - hrp.Position).Unit
    direction = Vector3.new(direction.X, 0, direction.Z)
    instantStrafe(hrp, strafePosition, direction)
end

RunService.RenderStepped:Connect(function()
    if targetStrafeEnabled then
        if aiming and targetPlayer then
            performStrafe(targetPlayer)
        end
        if manualTargetPlayer then
            performStrafe(manualTargetPlayer)
        end
    end
end)

TargetStrafeGroup:AddDropdown('StrafeModeOptionDropdown', {
    Values = { 'Custom', 'Random', 'Crazy' },
    Default = strafeModeOption,
    Multi = false,
    Text = 'Strafe Mode Option',
}):OnChanged(function(value)
    strafeModeOption = value
end)

TargetStrafeGroup:AddSlider('StrafeSpeed', {
    Text = 'Speed',
    Default = targetStrafeSpeed,
    Min = 1,
    Max = 50,
    Rounding = 1,
}):OnChanged(function(value)
    sliderStrafeSpeed = value
    if strafeModeOption == 'Custom' then
        targetStrafeSpeed = value
    end
end)

TargetStrafeGroup:AddSlider('StrafeDistance', {
    Text = 'Distance',
    Default = targetStrafeDistance,
    Min = 1,
    Max = 50,
    Rounding = 1,
}):OnChanged(function(value)
    sliderStrafeDistance = value
    if strafeModeOption == 'Custom' then
        targetStrafeDistance = value
    end
end)

TargetStrafeGroup:AddSlider('StrafeHeight', {
    Text = 'Height',
    Default = targetStrafeHeight,
    Min = -5,
    Max = 50,
    Rounding = 1,
}):OnChanged(function(value)
    sliderStrafeHeight = value
    if strafeModeOption == 'Custom' then
        targetStrafeHeight = value
    end
end)

task.spawn(function()
    while true do
        task.wait(0.01)
        if strafeModeOption == 'Crazy' then
            targetStrafeSpeed = math.random(100, 500)
            targetStrafeDistance = math.random(1, 50)
            targetStrafeHeight = math.random(1, 30)
        elseif strafeModeOption == 'Random' then
            targetStrafeSpeed = math.random(1, 20)
            targetStrafeDistance = math.random(1, 20)
            targetStrafeHeight = sliderStrafeHeight
        elseif strafeModeOption == 'Custom' then
            targetStrafeSpeed = sliderStrafeSpeed
            targetStrafeDistance = sliderStrafeDistance
            targetStrafeHeight = sliderStrafeHeight
        end
    end
end)

SUPPORTED_GAME = 2788229376
isSupportedGame = (game.PlaceId == SUPPORTED_GAME)
if not isSupportedGame then
    warn('Loaded RESCUE plugin ANTIGAGX')
end

Players = game:GetService('Players')
RunService = game:GetService('RunService')
ReplicatedStorage = game:GetService('ReplicatedStorage')
UserInputService = game:GetService('UserInputService')

player = Players.LocalPlayer
character = player.Character or player.CharacterAdded:Wait()
mainEvent = isSupportedGame and ReplicatedStorage:FindFirstChild('MainEvent')

allowedTools = {
    ['[AUG]'] = true,
    ['[Rifle]'] = true,
    ['[LMG]'] = true,
    ['[Flintlock]'] = true,
}

RageGroup = AimbotTab:AddRightGroupbox('Rage Kill')

isActive = false
manualTargetActive = false
targetPlayer = nil
targetHRP = nil
equippedTools = {}
whitelist = {}
whitelistConnections = {}
lastReloadTimes = {}
ReloadCooldown = 0.7
OrbitCooldown = 0.8
rageBindActive = false

RageGroup:AddToggle('RageKillToggle', {
    Text = 'Enable',
    Default = false,
})
    :AddKeyPicker('RageKillKey', {
        Default = '',
        Mode = 'Toggle',
        Text = 'Rage Kill',
        NoUI = false,
        SyncToggleState = false,
        Callback = function(state)
            if UserInputService:GetFocusedTextBox() then
                return
            end
            if isActive then
                rageBindActive = state
                if isActive and rageBindActive then
                    equipAndTrackTools()
                end
            else
                rageBindActive = false
            end
        end,
    })
    :OnChanged(function(state)
        isActive = state
        if isActive then
            equipAndTrackTools()
        else
            rageBindActive = false
        end
    end)

RageGroup:AddSlider('OrbitFrametime', {
    Text = 'Strafe Frametime',
    Default = 0.8,
    Min = 0.3,
    Max = 1.2,
    Rounding = 1,
    Callback = function(value)
        OrbitCooldown = value
    end,
})

RageGroup:AddInput('OrbitTarget', {
    Default = '',
    Placeholder = 'Enter player name',
    Numeric = false,
    Finished = true,
    Text = 'Manual Target Rage',
    Callback = function(targetName)
        if not isActive then
            return
        end
        targetPlayer = nil
        targetName = targetName:lower()
        for _, p in ipairs(Players:GetPlayers()) do
            if
                p.Name:lower():find(targetName)
                or p.DisplayName:lower():find(targetName)
            then
                targetPlayer = p
                break
            end
        end
        if not targetPlayer or not targetPlayer.Character then
            return
        end
        targetHRP = targetPlayer.Character:FindFirstChild('HumanoidRootPart')
        local myHRP = character:FindFirstChild('HumanoidRootPart')
        if not targetHRP or not myHRP then
            return
        end
        manualTargetActive = true
        equipAndTrackTools()

        local originalPosition = myHRP.CFrame
        local duration = OrbitCooldown
        local startTime = tick()
        local radius = 5
        local rng = Random.new()
        local connection
        connection = RunService.Heartbeat:Connect(function()
            local elapsed = tick() - startTime
            if elapsed >= duration then
                myHRP.CFrame = originalPosition
                connection:Disconnect()
                manualTargetActive = false
                return
            end
            local speed = rng:NextNumber(100, 5000)
            local angle = elapsed * speed
            local offset = Vector3.new(
                math.cos(angle) * radius,
                0,
                math.sin(angle) * radius
            )
            myHRP.CFrame = CFrame.new(targetHRP.Position + offset)
        end)
    end,
})

AutoWeapons = {}
local selectedWeaponsLabel = RageGroup:AddLabel('Selected: None')
local dropdown = RageGroup:AddDropdown('AutoWeaponSelect', {
    Values = { '[AUG]', '[Rifle]', '[LMG]', '[Flintlock]' },
    Default = '',
    Multi = false,
    Text = 'Weapons',
    Callback = function(selected)
        if AutoWeapons[selected] then
            AutoWeapons[selected] = nil
        else
            AutoWeapons[selected] = true
        end
        local list = {}
        for w, _ in pairs(AutoWeapons) do
            table.insert(list, w)
        end
        if #list == 0 then
            selectedWeaponsLabel:SetText('Selected: None')
        else
            selectedWeaponsLabel:SetText(
                'Selected: ' .. table.concat(list, ', ')
            )
        end
    end,
})

function shouldEquip(toolName)
    return AutoWeapons[toolName] == true
end

function equipAndTrackTools()
    table.clear(equippedTools)
    local backpack = player:FindFirstChild('Backpack')
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if
                tool:IsA('Tool')
                and allowedTools[tool.Name]
                and shouldEquip(tool.Name)
            then
                tool.Parent = character
            end
        end
    end
    for _, tool in ipairs(character:GetChildren()) do
        if
            tool:IsA('Tool')
            and allowedTools[tool.Name]
            and shouldEquip(tool.Name)
            and tool:FindFirstChild('Handle')
        then
            table.insert(equippedTools, tool)
        end
    end
end

local selectedPlayer = nil
local function applyWhitelistVisuals(targetPlayer)
    local function applyToChar(char)
        if not char or char:FindFirstChild('WhitelistedCham') then
            return
        end
        local hrp = char:FindFirstChild('HumanoidRootPart')
        local head = char:FindFirstChild('Head') or char:WaitForChild('Head', 2)
        if not head then
            return
        end

        local highlight = Instance.new('Highlight')
        highlight.Name = 'WhitelistedCham'
        highlight.Adornee = char
        highlight.FillColor = Color3.fromRGB(128, 0, 128)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
        highlight.OutlineTransparency = 0
        highlight.Parent = char

        local billboard = Instance.new('BillboardGui')
        billboard.Name = 'WhitelistedTag'
        billboard.Size = UDim2.new(0, 120, 0, 16)
        billboard.Adornee = head
        billboard.AlwaysOnTop = true

        local textLabel = Instance.new('TextLabel')
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = 'Rage WhiteList'
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.TextScaled = true
        textLabel.TextStrokeTransparency = 0
        textLabel.TextColor3 = Color3.fromRGB(255, 0, 255)
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

        local gradient = Instance.new('UIGradient')
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(128, 0, 255)),
        })
        gradient.Parent = textLabel
        textLabel.Parent = billboard
        billboard.Parent = char
    end

    if targetPlayer.Character then
        applyToChar(targetPlayer.Character)
    end

    if whitelistConnections[targetPlayer] then
        whitelistConnections[targetPlayer]:Disconnect()
    end
    whitelistConnections[targetPlayer] = targetPlayer.CharacterAdded:Connect(
        function(newChar)
            task.wait(0.5)
            applyToChar(newChar)
        end
    )
end

local function removeWhitelistVisuals(targetPlayer)
    if whitelistConnections[targetPlayer] then
        whitelistConnections[targetPlayer]:Disconnect()
        whitelistConnections[targetPlayer] = nil
    end
    local char = targetPlayer.Character
    if not char then
        return
    end
    local highlight = char:FindFirstChild('WhitelistedCham')
    if highlight then
        highlight:Destroy()
    end
    local billboard = char:FindFirstChild('WhitelistedTag')
    if billboard then
        billboard:Destroy()
    end
end

local function findPlayer(query)
    query = string.lower(query)
    local partialMatches = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        local name = string.lower(plr.Name)
        local display = string.lower(plr.DisplayName)
        if name == query or display == query then
            return plr
        elseif string.find(name, query) or string.find(display, query) then
            table.insert(partialMatches, plr)
        end
    end
    if #partialMatches == 1 then
        return partialMatches[1]
    elseif #partialMatches > 1 then
        table.sort(partialMatches, function(a, b)
            return #a.Name < #b.Name
        end)
        return partialMatches[1]
    end
    return nil
end

local function getPlayerNames(query)
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if
            not query
            or string.find(string.lower(p.Name), string.lower(query))
            or string.find(string.lower(p.DisplayName), string.lower(query))
        then
            table.insert(names, p.Name)
        end
    end
    return names
end

local playerDropdown = RageGroup:AddDropdown('PlayerDropdown', {
    Text = 'Select Player',
    Values = getPlayerNames(),
    Default = getPlayerNames()[1] or 'None',
    Multi = false,
    Callback = function(val)
        selectedPlayer = val
    end,
})

local playerInput = RageGroup:AddInput('PlayerInput', {
    Text = 'Search Player',
    Default = '',
    Placeholder = 'Enter player name...',
    Numeric = false,
    Finished = true,
    Callback = function(text)
        local matches = getPlayerNames(text)
        if #matches == 0 then
            matches = { 'None' }
        end
        if playerDropdown.SetValues then
            playerDropdown:SetValues(matches)
        end
        local lowerText = text:lower()
        local foundExact = false
        for _, name in ipairs(matches) do
            if name:lower() == lowerText then
                if playerDropdown.SetValue then
                    playerDropdown:SetValue(name)
                    selectedPlayer = name
                end
                foundExact = true
                break
            end
        end
        if not foundExact and playerDropdown.SetValue then
            playerDropdown:SetValue(matches[1])
            selectedPlayer = matches[1] ~= 'None' and matches[1] or nil
        end
    end,
})

RageGroup:AddButton('Whitelist', function()
    if not selectedPlayer then
        return
    end
    local target = findPlayer(selectedPlayer)
    if target then
        whitelist[target] = true
        applyWhitelistVisuals(target)
    end
end)

RageGroup:AddButton('Clear Whitelist', function()
    for plr, _ in pairs(whitelist) do
        removeWhitelistVisuals(plr)
    end
    whitelist = {}
end)

Players.PlayerAdded:Connect(function()
    local currentInput = playerInput:GetValue()
    playerInput.Callback(currentInput)
end)
Players.PlayerRemoving:Connect(function()
    local currentInput = playerInput:GetValue()
    playerInput.Callback(currentInput)
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    newChar.ChildAdded:Connect(function(child)
        if
            child:IsA('Tool')
            and allowedTools[child.Name]
            and shouldEquip(child.Name)
            and child:FindFirstChild('Handle')
        then
            table.insert(equippedTools, child)
        end
    end)
    newChar.ChildRemoved:Connect(function(child)
        if child:IsA('Tool') then
            for i, tool in ipairs(equippedTools) do
                if tool == child then
                    table.remove(equippedTools, i)
                    break
                end
            end
        end
    end)
    for p, _ in pairs(whitelist) do
        applyWhitelistVisuals(p)
    end
end)

local function isKO(character)
    if not character then
        return true
    end
    local effects = character:FindFirstChild('BodyEffects')
    if not effects then
        return true
    end
    local ko = effects:FindFirstChild('K.O')
    if not ko then
        return true
    end
    return ko.Value
end

RunService.Heartbeat:Connect(function()
    if not isActive or not (rageBindActive or manualTargetActive) then
        return
    end
    equipAndTrackTools()
    local localRoot = character:FindFirstChild('HumanoidRootPart')
    if not localRoot then
        return
    end
    local closestTarget, closestDistance = nil, math.huge

    if manualTargetActive and targetPlayer and targetPlayer.Character then
        if not isKO(targetPlayer.Character) then
            closestTarget = targetPlayer.Character:FindFirstChild('Head')
            closestDistance = (
                targetPlayer.Character.HumanoidRootPart.Position
                - localRoot.Position
            ).Magnitude
        end
    else
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if
                otherPlayer ~= player
                and otherPlayer.Character
                and not whitelist[otherPlayer]
            then
                local head = otherPlayer.Character:FindFirstChild('Head')
                local root =
                    otherPlayer.Character:FindFirstChild('HumanoidRootPart')
                if
                    head
                    and root
                    and not isKO(otherPlayer.Character)
                    and not otherPlayer.Character:FindFirstChild(
                        'GRABBING_CONSTRAINT'
                    )
                    and not otherPlayer.Character:FindFirstChildOfClass(
                        'ForceField'
                    )
                    and otherPlayer.Character:FindFirstChild(
                        'FULLY_LOADED_CHAR'
                    )
                then
                    local dist = (root.Position - localRoot.Position).Magnitude
                    if dist < closestDistance then
                        closestDistance = dist
                        closestTarget = head
                    end
                end
            end
        end
    end

    if not closestTarget then
        return
    end

    for _, tool in ipairs(equippedTools) do
        if tool.Parent == character and tool:FindFirstChild('Handle') then
            if
                not manualTargetActive
                and tool:FindFirstChild('Ammo')
                and tool.Ammo.Value <= 0
            then
                local lastTime = lastReloadTimes[tool] or 0
                if tick() - lastTime > ReloadCooldown then
                    pcall(function()
                        mainEvent:FireServer('Reload', tool)
                    end)
                    lastReloadTimes[tool] = tick()
                end
            end
            pcall(function()
                mainEvent:FireServer(
                    'ShootGun',
                    tool.Handle,
                    tool.Handle.CFrame.Position,
                    closestTarget.Position,
                    closestTarget,
                    Vector3.new()
                )
            end)
        end
    end
end)

AutoKillGroup = AimbotTab:AddRightGroupbox('Auto Kill')

selectedTarget = nil
autoKillEnabled = false
targetNameInput = ''
strafeModeOption = 'Custom'
randomStrafeEnabled = false

strafeDirection = 1
baseStrafeSpeed = 20
currentStrafeSpeed = baseStrafeSpeed
jitterUpdateInterval = 0.15
lastJitterUpdate = 0
orbitAngle = 0

orbitRadius = 7
orbitHeight = 1

selectedWeapon = '[LMG]'
equipMethods = {
    ['[LMG]'] = true,
    ['[Rifle]'] = false,
    ['[AUG]'] = false,
}

originalHRPPos = nil
originalCameraSubject = nil

function findTarget(name)
    name = name:lower()
    for _, player in ipairs(game:GetService('Players'):GetPlayers()) do
        if
            player ~= game:GetService('Players').LocalPlayer
            and player.Character
            and player.Character:FindFirstChild('HumanoidRootPart')
        then
            local uname = player.Name:lower()
            local dname = player.DisplayName:lower()
            if uname:find(name) or dname:find(name) then
                return player
            end
        end
    end
    return nil
end

function equipWeapon()
    local backpack = game:GetService('Players').LocalPlayer
        :WaitForChild('Backpack')
    local character = game:GetService('Players').LocalPlayer.Character
        or game:GetService('Players').LocalPlayer.CharacterAdded:Wait()

    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA('Tool') and not equipMethods[tool.Name] then
            tool.Parent = backpack
        end
    end

    for method, enabled in pairs(equipMethods) do
        if enabled then
            local weapon = backpack:FindFirstChild(method)
            if weapon and weapon:IsA('Tool') then
                weapon.Parent = character
            end
        end
    end
end

function shootAtTarget(tool, enemy)
    if enemy and enemy.Character and tool and tool:FindFirstChild('Handle') then
        local head = enemy.Character:FindFirstChild('Head')
        local humanoid = enemy.Character:FindFirstChildOfClass('Humanoid')
        local forceField = enemy.Character:FindFirstChild('ForceField')
        if forceField then
            return
        end
        if head and humanoid and humanoid.Health > 5 then
            local MainEvent = game:GetService('ReplicatedStorage')
                :FindFirstChild('MainEvent')
            if MainEvent then
                MainEvent:FireServer(
                    'ShootGun',
                    tool.Handle,
                    tool.Handle.CFrame.Position,
                    enemy.Character.HumanoidRootPart.Position,
                    head,
                    Vector3.new(0, 0, -1)
                )
            end
        end
    end
end

function doStompAttack()
    for i = 1, 5 do
        for _, plr in ipairs(game:GetService('Players'):GetPlayers()) do
            if
                plr ~= game:GetService('Players').LocalPlayer
                and plr.Character
                and plr.Character:FindFirstChild('HumanoidRootPart')
            then
                if
                    (plr.Character.HumanoidRootPart.Position - game:GetService(
                        'Players'
                    ).LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                    < 13
                then
                    local mainEvent = game:GetService('ReplicatedStorage')
                        :FindFirstChild('MainEvent') or game
                        :GetService('ReplicatedStorage')
                        :FindFirstChild('MainRemote') or game
                        :GetService('ReplicatedStorage')
                        :FindFirstChild('MAINEVENT') or (game:GetService(
                        'ReplicatedStorage'
                    ).assets and game:GetService(
                        'ReplicatedStorage'
                    ).assets.dh and game
                        :GetService('ReplicatedStorage').assets.dh
                        :FindFirstChild('MainEvent'))
                    if mainEvent then
                        mainEvent:FireServer('Stomp')
                    end
                end
            end
        end
        task.wait(0.5)
    end
end

AutoKillGroup:AddToggle('AutoKillToggle', {
    Text = 'Enable',
    Default = false,
    Callback = function(state)
        autoKillEnabled = state
        local char = game:GetService('Players').LocalPlayer.Character
        local hrp = char and char:FindFirstChild('HumanoidRootPart')
        if state then
            if hrp then
                originalHRPPos = hrp.CFrame
            end
            originalCameraSubject = workspace.CurrentCamera.CameraSubject
            if targetNameInput ~= '' then
                selectedTarget = findTarget(targetNameInput)
                if selectedTarget then
                    equipWeapon()
                end
            end
        else
            if hrp and originalHRPPos then
                hrp.CFrame = originalHRPPos
            end
            if originalCameraSubject then
                workspace.CurrentCamera.CameraSubject = originalCameraSubject
            end
            selectedTarget = nil
        end
    end,
})

AutoKillGroup:AddInput('TargetNameInput', {
    Default = '',
    Text = 'Target Name',
    Placeholder = 'Enter player name',
    Finished = true,
    Callback = function(value)
        targetNameInput = (value or ''):lower()
        selectedTarget = nil
        if targetNameInput ~= '' then
            selectedTarget = findTarget(targetNameInput)
            if selectedTarget then
                equipWeapon()
            end
        end
    end,
})

AutoKillGroup:AddDropdown('WeaponSelect', {
    Values = { '[LMG]', '[Rifle]', '[AUG]' },
    Default = selectedWeapon,
    Multi = false,
    Text = 'Select Weapon',
    Callback = function(value)
        selectedWeapon = value
        for k, _ in pairs(equipMethods) do
            equipMethods[k] = (k == selectedWeapon)
        end
        equipWeapon()
    end,
})

AutoKillGroup:AddDropdown('StrafeModeOptionDropdown', {
    Values = { 'Custom', 'Random' },
    Default = strafeModeOption,
    Multi = false,
    Text = 'Strafe Mode Option',
}):OnChanged(function(value)
    strafeModeOption = value
end)

AutoKillGroup:AddSlider('StrafeSpeedSlider', {
    Text = 'Orbit Speed',
    Default = baseStrafeSpeed,
    Min = 10,
    Max = 600,
    Rounding = 0,
    Callback = function(value)
        baseStrafeSpeed = value
    end,
})

AutoKillGroup:AddSlider('OrbitRadiusSlider', {
    Text = 'Orbit Distance',
    Default = orbitRadius,
    Min = 1,
    Max = 30,
    Rounding = 0,
    Callback = function(value)
        orbitRadius = value
    end,
})

AutoKillGroup:AddSlider('OrbitHeightSlider', {
    Text = 'Orbit Height',
    Default = orbitHeight,
    Min = -10,
    Max = 20,
    Rounding = 0,
    Callback = function(value)
        orbitHeight = value
    end,
})

game:GetService('RunService').RenderStepped:Connect(function(delta)
    if not autoKillEnabled or not selectedTarget then
        return
    end
    local char = game:GetService('Players').LocalPlayer.Character
    local targetChar = selectedTarget.Character
    if not char or not targetChar then
        return
    end
    local hrp = char:FindFirstChild('HumanoidRootPart')
    local targetHrp = targetChar:FindFirstChild('HumanoidRootPart')
    local targetHum = targetChar:FindFirstChildOfClass('Humanoid')
    if not hrp or not targetHrp or not targetHum then
        return
    end
    local tool = char:FindFirstChildOfClass('Tool')

    if tool and tool:FindFirstChild('Ammo') and tool.Ammo.Value <= 0 then
        local mainEvent = game:GetService('ReplicatedStorage')
            :FindFirstChild('MainEvent')
        if mainEvent then
            mainEvent:FireServer('Reload', tool)
            task.wait(1)
        end
        return
    end

    if targetHum.Health <= 3 then
        local currentTorso = targetChar:FindFirstChild('Torso')
            or targetChar:FindFirstChild('UpperTorso')
            or targetChar:FindFirstChild('HumanoidRootPart')
        if currentTorso then
            hrp.CFrame =
                CFrame.new(currentTorso.Position + Vector3.new(0, 3.5, 0))
            doStompAttack()
            game:GetService('VirtualInputManager')
                :SendKeyEvent(true, Enum.KeyCode.R, false, game)
            task.wait(0.1)
            game:GetService('VirtualInputManager')
                :SendKeyEvent(false, Enum.KeyCode.R, false, game)
            task.wait(2.5)
        end
    else
        if
            strafeModeOption == 'Random'
            and tick() - lastJitterUpdate > jitterUpdateInterval
        then
            currentStrafeSpeed = math.random(200, 500)
            lastJitterUpdate = tick()
        else
            currentStrafeSpeed = baseStrafeSpeed
        end

        orbitAngle = orbitAngle + currentStrafeSpeed * delta
        local offsetX = math.cos(orbitAngle) * orbitRadius
        local offsetZ = math.sin(orbitAngle) * orbitRadius
        local orbitPos = Vector3.new(
            targetHrp.Position.X + offsetX,
            targetHrp.Position.Y + orbitHeight,
            targetHrp.Position.Z + offsetZ
        )

        hrp.CFrame = CFrame.new(orbitPos)

        if tool then
            shootAtTarget(tool, selectedTarget)
        end
    end
end)

local UtilitiesGroup = PlayerTab:AddLeftGroupbox('Utilities')

local Lighting = game:GetService('Lighting')

UtilitiesGroup:AddButton('Force Reset', function()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild('Head') then
        character.Head:Destroy()
    end
end)

local antiStompEnabled = false
local method = 'Character'

local function Headless(character)
    if character then
        local head = character:FindFirstChild('Head')
        if head then
            head:Destroy()
        end
    end
end

RunService.Heartbeat:Connect(function()
    if antiStompEnabled then
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChild('Humanoid')
        if humanoid and humanoid.Health > 0 then
            if humanoid.Health < 15 then
                if method == 'Character' then
                    humanoid.Health = 0
                elseif method == 'Headless' then
                    if humanoid.Health < 6 then
                        Headless(character)
                    end
                end
            end
        end
    end
end)

UtilitiesGroup:AddToggle('AntiStomp', {
    Text = 'Anti Stomp',
    Callback = function(state)
        antiStompEnabled = state
    end,
    Enabled = false,
})

UtilitiesGroup:AddDropdown('AntiStompMethod', {
    Text = 'Anti Stomp Method',
    Default = method,
    Values = { 'Character', 'Headless' },
    Callback = function(value)
        method = value
    end,
})

local AutoStompEnabled = false
local AutoStompDelay = 0.05
local LastStompTime = 0

local function fireStomp()
    if ReplicatedStorage:FindFirstChild('MainEvent') then
        ReplicatedStorage.MainEvent:FireServer('Stomp')
    elseif ReplicatedStorage:FindFirstChild('MainRemote') then
        ReplicatedStorage.MainRemote:FireServer('Stomp')
    elseif ReplicatedStorage:FindFirstChild('MAINEVENT') then
        ReplicatedStorage.MAINEVENT:FireServer('STOMP')
    elseif
        ReplicatedStorage:FindFirstChild('assets')
        and ReplicatedStorage.assets:FindFirstChild('dh')
        and ReplicatedStorage.assets.dh:FindFirstChild('MainEvent')
    then
        ReplicatedStorage.assets.dh.MainEvent:FireServer('Stomp')
    end
end

UtilitiesGroup:AddToggle('AutoStomp', {
    Text = 'Auto Stomp',
    Default = false,
    Callback = function(value)
        AutoStompEnabled = value
    end,
})
    :AddKeyPicker('AutoStompBind', {
        Default = '',
        Mode = 'Toggle',
        Text = 'Auto Stomp',
        NoUI = false,
        SyncToggleState = false,
        Callback = function(state)
            if UserInputService:GetFocusedTextBox() then
                return
            end
            AutoStompEnabled = state
        end,
    })
    :OnChanged(function(state)
        if UserInputService:GetFocusedTextBox() then
            return
        end
        if not state then
            AutoStompEnabled = false
        end
    end)

UtilitiesGroup:AddSlider('AutoStompDelay', {
    Text = 'Delay Auto Stomp',
    Default = 0.1,
    Min = 0.1,
    Max = 1,
    Rounding = 1,
    Callback = function(value)
        AutoStompDelay = value
    end,
})

RunService.RenderStepped:Connect(function()
    if not AutoStompEnabled then
        return
    end

    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild('HumanoidRootPart') then
        return
    end

    local now = tick()
    if now - LastStompTime < AutoStompDelay then
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        if
            player ~= LocalPlayer
            and player.Character
            and player.Character:FindFirstChild('HumanoidRootPart')
        then
            local dist = (
                character.HumanoidRootPart.Position
                - player.Character.HumanoidRootPart.Position
            ).Magnitude
            if dist < 13 then
                fireStomp()
                LastStompTime = now
                break
            end
        end
    end
end)

local RapidFireEnabled = false
local modifiedTools = {}
local originalDelays = {}

local function rapidfire(tool)
    if not tool or not tool:FindFirstChild('GunScript') then
        return
    end
    if modifiedTools[tool] then
        return
    end

    for _, connection in ipairs(getconnections(tool.Activated)) do
        local funcinfo = debug.getinfo(connection.Function)
        for i = 1, funcinfo.nups do
            local upvalue, name = debug.getupvalue(connection.Function, i)
            if type(upvalue) == 'number' and upvalue > 0 then
                if not originalDelays[tool] then
                    originalDelays[tool] = {}
                end
                originalDelays[tool][i] = upvalue

                debug.setupvalue(connection.Function, i, 0.0000000000001)
                modifiedTools[tool] = true
            end
        end
    end
end

local function restoreDelays()
    for tool, upvalues in pairs(originalDelays) do
        for _, connection in ipairs(getconnections(tool.Activated)) do
            for upIndex, originalValue in pairs(upvalues) do
                debug.setupvalue(connection.Function, upIndex, originalValue)
            end
        end
    end
    originalDelays = {}
    modifiedTools = {}
end

local function onCharacterAdded(character)
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA('Tool') and tool:FindFirstChild('Handle') then
            if RapidFireEnabled then
                rapidfire(tool)
            end
        end
    end

    character.ChildAdded:Connect(function(child)
        if child:IsA('Tool') and child:FindFirstChild('Handle') then
            if RapidFireEnabled then
                rapidfire(child)
            end
        end
    end)
end

if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

UtilitiesGroup:AddToggle('RapidFireToggle', {
    Text = 'Rapid Fire',
    Default = false,
    Callback = function(Value)
        RapidFireEnabled = Value

        if Value then
            modifiedTools = {}
            originalDelays = {}
            if LocalPlayer.Character then
                onCharacterAdded(LocalPlayer.Character)
            end
        else
            restoreDelays()
        end
    end,
})

UtilitiesGroup:AddToggle('Auto Reload', {
    Text = 'Auto Reload',
    Default = false,
    Callback = function(state)
        if state then
            RunService:BindToRenderStep('Auto-Reload', 0, function()
                local character = player.Character
                if character then
                    local tool = character:FindFirstChildWhichIsA('Tool')
                    if tool and tool:FindFirstChild('Ammo') then
                        if tool.Ammo.Value <= 0 then
                            ReplicatedStorage.MainEvent:FireServer(
                                'Reload',
                                tool
                            )
                            wait(1)
                        end
                    end
                end
            end)
        else
            RunService:UnbindFromRenderStep('Auto-Reload')
        end
    end,
})

local MOD_USERNAMES = {
    ['iisunxqq'] = true,
    ['l4t3tr1pz'] = true,
    ['bubba_bug'] = true,
    ['dodgehit1'] = true,
    ['ywsiri'] = true,
    ['n1k_5a'] = true,
    ['clouvdsfr'] = true,
    ['vhxthedev'] = true,
    ['ghostofhertouch'] = true,
    ['callmedevelolper'] = true,
    ['tabloint'] = true,
    ['r1ivall'] = true,
    ['redusofficial'] = true,
    ['qtshifu'] = true,
    ['halu'] = true,
    ['renixbunny'] = true,
    ['ehqd'] = true,
    ['ryuksban'] = true,
    ['swiveied'] = true,
    ['eviiphantoms'] = true,
    ['saienythedev'] = true,
    ['512f6'] = true,
    ['ghostlic'] = true,
    ['drizzyaudemars'] = true,
    ['reallycyan'] = true,
    ['iumu'] = true,
    ['jokethefool'] = true,
    ['benoxa'] = true,
    ['dtbbullet'] = true,
    ['luutyy'] = true,
    ['dtbkxng1'] = true,
    ['4naty44'] = true,
    ['jellieefishh'] = true,
    ['ijuanky'] = true,
    ['baznaudemars'] = true,
    ['vb3ez'] = true,
    ['int3rludes'] = true,
    ['ilovegodyay1234'] = true,
    ['whohelped'] = true,
}

local MOD_SYMBOLS = { '✅', '☑', '👑', '⭐', '🛡', '✨', '🌟' }
local MOD_GROUP_IDS =
    { 35832401, 8068202, 10604500, 8068202, 268150549, 539644662 }

local MOD_IDS = {
    163721789,
    15427717,
    201454243,
    822999,
    63794379,
    17260230,
    28357488,
    93101606,
    8195210,
    89473551,
    16917269,
    85989579,
    1553950697,
    476537893,
    155627580,
    31163456,
    7200829,
    25717070,
    201454243,
    15427717,
    63794379,
    16138978,
    60660789,
    17260230,
    16138978,
    1161411094,
    9125623,
    11319153,
    34758833,
    194109750,
    35616559,
    1257271138,
    28885841,
    23558830,
    25717070,
    4255947062,
    29242182,
    2395613299,
    3314981799,
    3390225662,
    2459178,
    2846299656,
    2967502742,
    7001683347,
    7312775547,
    328566086,
    170526279,
    99356639,
    352087139,
    6074834798,
    2212830051,
    3944434729,
    5136267958,
    84570351,
    542488819,
    1830168970,
    3950637598,
    1962396833,
}

local detectorEnabled = false
local modAction = 'kick'
local playerAddedConnection
local heartbeatConnection
local lastCheck = 0
local notifiedPlayers = {}

local function hasModSymbols(name)
    if not name then
        return false
    end
    for _, symbol in ipairs(MOD_SYMBOLS) do
        if name:find(symbol, 1, true) then
            return true
        end
    end
    return false
end

local function isInModGroup(player)
    for _, groupId in ipairs(MOD_GROUP_IDS) do
        local success, rank = pcall(function()
            return player:GetRankInGroup(groupId)
        end)
        if success and rank and rank > 0 then
            return true
        end
    end
    return false
end

local function isModId(player)
    for _, id in ipairs(MOD_IDS) do
        if player.UserId == id then
            return true
        end
    end
    return false
end

local function detectMods()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local nameLower = player.Name:lower()
            local displayLower = player.DisplayName:lower()
            local isModUser = MOD_USERNAMES[nameLower]
                or MOD_USERNAMES[displayLower]
            local hasEmoji = hasModSymbols(player.Name)
                or hasModSymbols(player.DisplayName)

            local inGroup, inId = false, false
            local successGroup, resultGroup = pcall(function()
                return isInModGroup(player)
            end)
            if successGroup then
                inGroup = resultGroup
            end
            local successId, resultId = pcall(function()
                return isModId(player)
            end)
            if successId then
                inId = resultId
            end

            if isModUser or hasEmoji or inGroup or inId then
                if modAction == 'kick' then
                    LocalPlayer:Kick(
                        'Moderator/Admin detected @' .. player.Name
                    )
                elseif modAction == 'notify' then
                    if not notifiedPlayers[player.UserId] then
                        notifiedPlayers[player.UserId] = true
                        pcall(function()
                            Library:Notify(
                                'Moderator/Admin detected: ' .. player.Name,
                                5
                            )
                        end)
                    end
                end
            end
        end
    end
end

UtilitiesGroup:AddToggle('ModDetector', {
    Text = 'Mod Detector',
    Default = false,
    Callback = function(state)
        detectorEnabled = state
        if state then
            detectMods()
            playerAddedConnection = Players.PlayerAdded:Connect(detectMods)
            heartbeatConnection = RunService.Heartbeat:Connect(function()
                if detectorEnabled and tick() - lastCheck > 3 then
                    detectMods()
                    lastCheck = tick()
                end
            end)
        else
            if playerAddedConnection then
                playerAddedConnection:Disconnect()
            end
            if heartbeatConnection then
                heartbeatConnection:Disconnect()
            end
            playerAddedConnection, heartbeatConnection = nil, nil
            notifiedPlayers = {}
        end
    end,
})

UtilitiesGroup:AddDropdown('ModActionDropdown', {
    Values = { 'kick', 'notify' },
    Default = 'kick',
    Multi = false,
    Text = 'detect mode',
    Callback = function(value)
        modAction = value
    end,
})

CASH_AURA_ENABLED = false
COOLDOWN = 0.2
CASH_AURA_RANGE = 17

function GetCash()
    local Found = {}
    local Drop = workspace:FindFirstChild('Ignored')
        and workspace.Ignored:FindFirstChild('Drop')

    if Drop then
        for _, v in pairs(Drop:GetChildren()) do
            if v.Name == 'MoneyDrop' then
                local Pos = v:GetAttribute('OriginalPos') or v.Position

                if
                    game.Players.LocalPlayer.Character
                    and game.Players.LocalPlayer.Character:FindFirstChild(
                        'HumanoidRootPart'
                    )
                    and (
                            Pos
                            - game.Players.LocalPlayer.Character.HumanoidRootPart.Position
                        ).Magnitude
                        <= CASH_AURA_RANGE
                then
                    table.insert(Found, v)
                end
            end
        end
    end

    return Found
end

function CashAura()
    while CASH_AURA_ENABLED do
        local Cash = GetCash()

        for _, v in pairs(Cash) do
            local clickDetector = v:FindFirstChildOfClass('ClickDetector')
            if clickDetector then
                fireclickdetector(clickDetector)
            end
        end

        task.wait(COOLDOWN)
    end
end

UtilitiesGroup:AddToggle('Cash_Aura_Toggle', {
    Text = 'Cash Aura',
    Default = false,
    Callback = function(Value)
        CASH_AURA_ENABLED = Value
        if CASH_AURA_ENABLED then
            task.spawn(CashAura)
        end
    end,
})

local effectsToRemove = {
    'SunRaysEffect',
    'ColorCorrectionEffect',
    'BloomEffect',
    'DepthOfFieldEffect',
}

local gameEffectsToRemove = {
    'ParticleEmitter',
    'Trail',
    'Fire',
    'Smoke',
}

local effectConnection
local gameEffectConnections = {}

local function removeEffect(inst)
    if table.find(effectsToRemove, inst.ClassName) then
        pcall(function()
            inst:Destroy()
        end)
    end
end

local function removeGameEffect(inst)
    if table.find(gameEffectsToRemove, inst.ClassName) then
        pcall(function()
            inst:Destroy()
        end)
    end
end

local function scanAndRemoveEffects()
    for _, obj in ipairs(Lighting:GetDescendants()) do
        removeEffect(obj)
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        removeGameEffect(obj)
    end
    for _, obj in ipairs(game:GetService('StarterGui'):GetDescendants()) do
        removeGameEffect(obj)
    end
end

local function setupEffectBlocker()
    if effectConnection then
        effectConnection:Disconnect()
    end
    effectConnection = Lighting.DescendantAdded:Connect(function(obj)
        task.wait(0.1)
        removeEffect(obj)
    end)

    local workspaceConn = workspace.DescendantAdded:Connect(function(obj)
        task.wait(0.1)
        removeGameEffect(obj)
    end)
    table.insert(gameEffectConnections, workspaceConn)

    local starterGuiConn = starterGui.DescendantAdded:Connect(function(obj)
        task.wait(0.1)
        removeGameEffect(obj)
    end)
    table.insert(gameEffectConnections, starterGuiConn)
end

local function disconnectGameEffectConnections()
    for _, conn in ipairs(gameEffectConnections) do
        conn:Disconnect()
    end
    gameEffectConnections = {}
end

UtilitiesGroup:AddToggle('AntiEffects', {
    Text = 'Anti Effects',
    Callback = function(state)
        if state then
            scanAndRemoveEffects()
            setupEffectBlocker()
        else
            if effectConnection then
                effectConnection:Disconnect()
                effectConnection = nil
            end
            disconnectGameEffectConnections()
        end
    end,
    Enabled = false,
})

getgenv().AntiRPGDesyncEnabled, getgenv().GrenadeDetectionEnabled, getgenv().AntiRPGDesyncLoop =
    false, false, nil
local RunService, Workspace, LocalPlayer =
    game:GetService('RunService'), game.Workspace, game.Players.LocalPlayer

local function IsThreatNear(threatName)
    local Threat = Workspace:FindFirstChild('Ignored')
        and Workspace.Ignored:FindFirstChild(threatName)
    local HRP = LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    return Threat and HRP and (Threat.Position - HRP.Position).Magnitude < 16
end

local function StartThreatDetection()
    if getgenv().AntiRPGDesyncLoop then
        return
    end

    getgenv().AntiRPGDesyncLoop = RunService.PostSimulation:Connect(function()
        local HRP, Humanoid =
            LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(
                'HumanoidRootPart'
            ),
            LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(
                'Humanoid'
            )
        if not HRP or not Humanoid then
            return
        end

        local RPGThreat = Workspace.Ignored:FindFirstChild('Model')
            and Workspace.Ignored.Model:FindFirstChild('Launcher')
        local GrenadeThreat = IsThreatNear('Handle')

        if
            getgenv().AntiRPGDesyncEnabled and RPGThreat
            or getgenv().GrenadeDetectionEnabled and GrenadeThreat
        then
            local Offset = Vector3.new(
                math.random(-100, 100),
                math.random(50, 150),
                math.random(-100, 100)
            )
            Humanoid.CameraOffset = -Offset
            local OldCFrame = HRP.CFrame
            HRP.CFrame = CFrame.new(HRP.CFrame.Position + Offset)
            RunService.RenderStepped:Wait()
            HRP.CFrame = OldCFrame
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        if
            getgenv().AntiRPGDesyncEnabled or getgenv().GrenadeDetectionEnabled
        then
            StartThreatDetection()
        end
    end)
end

local function StopThreatDetection()
    if getgenv().AntiRPGDesyncLoop then
        getgenv().AntiRPGDesyncLoop:Disconnect()
        getgenv().AntiRPGDesyncLoop = nil
    end
end

UtilitiesGroup:AddToggle('RPGDetection', {
    Text = 'Anti RPG',
    Default = false,
    Callback = function(state)
        getgenv().AntiRPGDesyncEnabled = state
        if state or getgenv().GrenadeDetectionEnabled then
            StartThreatDetection()
        else
            StopThreatDetection()
        end
    end,
})

UtilitiesGroup:AddToggle('GrenadeDetection', {
    Text = 'Anti Grenade',
    Default = false,
    Callback = function(state)
        getgenv().GrenadeDetectionEnabled = state
        if state or getgenv().AntiRPGDesyncEnabled then
            StartThreatDetection()
        else
            StopThreatDetection()
        end
    end,
})

local antifling = nil
local updateInterval = 0.2

UtilitiesGroup:AddToggle('AntiflingToggle', {
    Text = 'Anti Fling',
    Default = false,
    Callback = function(state)
        if state then
            antifling = game:GetService('RunService').Heartbeat
                :Connect(function()
                    task.spawn(function()
                        for _, player in
                            pairs(game:GetService('Players'):GetPlayers())
                        do
                            if
                                player ~= game.Players.LocalPlayer
                                and player.Character
                            then
                                for _, v in
                                    pairs(player.Character:GetDescendants())
                                do
                                    if
                                        v:IsA('BasePart')
                                        and v.CanCollide ~= false
                                    then
                                        v.CanCollide = false
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(updateInterval)
                end)
        else
            if antifling then
                antifling:Disconnect()
                antifling = nil
            end
        end
    end,
})

local originalHeight = workspace.FallenPartsDestroyHeight

UtilitiesGroup:AddToggle('AntiVoid', {
    Text = 'Anti Void',
    Default = false,
    Callback = function(state)
        if state then
            originalHeight = workspace.FallenPartsDestroyHeight
            workspace.FallenPartsDestroyHeight = -math.huge
        else
            workspace.FallenPartsDestroyHeight = originalHeight
        end
    end,
})

local TextChatService = game:GetService('TextChatService')

local defaultStates = {
    ChatWindowEnabled = TextChatService:FindFirstChild(
        'ChatWindowConfiguration'
    ) and TextChatService.ChatWindowConfiguration.Enabled,
    ChatInputEnabled = TextChatService:FindFirstChild(
        'ChatInputBarConfiguration'
    ) and TextChatService.ChatInputBarConfiguration.Enabled,
    CoreGuiChat = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat),
}

UtilitiesGroup:AddToggle('ChatSpyToggle', {
    Text = 'Chat Spy',
    Default = false,
    Callback = function(state)
        if state then
            if TextChatService:FindFirstChild('ChatWindowConfiguration') then
                TextChatService.ChatWindowConfiguration.Enabled = true
            end
            if TextChatService:FindFirstChild('ChatInputBarConfiguration') then
                TextChatService.ChatInputBarConfiguration.Enabled = true
            end
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
        else
            if TextChatService:FindFirstChild('ChatWindowConfiguration') then
                TextChatService.ChatWindowConfiguration.Enabled =
                    defaultStates.ChatWindowEnabled
            end
            if TextChatService:FindFirstChild('ChatInputBarConfiguration') then
                TextChatService.ChatInputBarConfiguration.Enabled =
                    defaultStates.ChatInputEnabled
            end
            StarterGui:SetCoreGuiEnabled(
                Enum.CoreGuiType.Chat,
                defaultStates.CoreGuiChat
            )
        end
    end,
})

local seats = {}

local function disableSeats(state)
    if #seats == 0 then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA('Seat') or obj:IsA('VehicleSeat') then
                table.insert(seats, obj)
            end
        end
    end

    for _, seat in pairs(seats) do
        seat.Disabled = state
    end
end

UtilitiesGroup:AddToggle('Disable Seats', {
    Text = 'Disable Seats',
    Callback = function(state)
        disableSeats(state)
    end,
    Enabled = false,
})

TextChatService = game:GetService('TextChatService')
channel = TextChatService.TextChannels.RBXGeneral

messages = {
    'bro tried to kill me ? what an loser',
    'Skid!!! skid!!!11111 you are skid',
    'probably skill issue moment',
    'WHERE BRO AIMING AT!?',
    'ong ur so bad',
    'imagine dying to me',
    'whats the point of playing with that aim',
    'talking with dots is special language for you ?',
    'wowzies',
    '1d luh bro',
    'WOW U SUCK',
    'couldnt be me',
    'just broke ur ankles',
    'UR ANKLES? GONE?',
    'destroyed',
    'LOL DESTROYED',
    'LOL',
    'ur aim trash',
    'cant touch this',
    'just admit ur aim sucks',
    'ez clapped',
    'get rekt',
    'try harder next time',
    'noob alert',
    'lag much?',
    'u suck at this game dude!',
    '1v1 me lol',
    'why even try?',
    'dude just admit u suck',
    'what is that guy trying to do ?',
    'im using the best executor than jjsploit!',
    'absolute bot moment',
    'ez brainless kill',
    'did you even practice?',
    'aim assist much?',
    'cant believe this hit',
    'why u even live',
    'easy clap kid',
    'get carried harder',
    'get outplayed',
    'u literally walking target',
    'think before you shoot',
    'ez money',
    'try aiming next time',
    'ur controller must be broken',
    'ez noob farm',
    'too slow bro',
    'you wish u were this good',
    'bot detected',
    'cant even hit stationary',
    'learning curve much?',
    'ez tutorial boss',
    'come back when u git gud',
    'u just got demoed',
    'no skill, all luck',
    'trash tier play',
    'im the nightmare of your dreams',
    'try harder or rage quit',
    'u literally feed me',
    'EZ clap, again',
    'ur brain must be lagging',
    'thinking like a bot',
    'cant clutch this',
    'ez teleport kill',
    'im untouchable',
    'try again, maybe next life',
    'what a free kill',
    'maybe uninstall',
    'ur so predictable',
    'ez pew pew',
    'cant escape the skill',
    'ur RNG is trash',
    'pathetic attempt',
    'u wish u were me',
    'ez demolition',
    'no reaction time bro',
    'u just got embarrassed',
    'my grandma could aim better',
    'ez brainless farm',
    'u feed, i lead',
    'ur ego is carry me',
    'ez ez ez',
    'cant believe this is allowed',
    'u cant even hit me',
    'u wish u had my aim',
    'ur my biggest fan huh?',
    'cant stop watching me',
    'obsessed much?',
    'dreaming about me?',
    'stalking me in game?',
    'all this just for me?',
    'ur attention is mine now',
    'im famous and u know it',
    'cant hide your fanboy vibes',
    'ur obsession is obvious',
    'ur aim is as bad as ur jokes',
    'literally bot behavior',
    'cant even press W correctly',
    'ez aim practice',
    'try using both hands',
    'i feel bad for u',
    'maybe uninstall Roblox',
    'ur keyboard must be broken',
    'lagging in real life?',
    'cant even hit a dummy',
    'u need aim lessons',
    'gg ez',
    'ur brain on cooldown',
    'try moving instead of standing',
    'ez skill gap',
    '1v1 me in slow motion',
    'my cat could kill u',
    'u feed harder than anyone',
    'ur so free',
    'u should play offline',
    'ur mouse has no DPI',
    'im doing this with one hand',
    'ur reaction time is potato',
    'cant hit a stationary part',
    'ez brain dead',
    'try breathing and aiming',
    'u literally die from air',
    'ur aim is paper thin',
    'i dont even try',
    'u keep feeding me',
    'pathetic',
    'ur RNG is cursed',
    'ez noob destruction',
    'cant touch this ez',
    'im carrying ur whole team',
    'u need a tutorial',
    'ur shots are imaginary',
    'why even try',
    'get some practice bro',
    'ur aim is a meme',
    'stop moving pls',
    'cant dodge my bullets',
    'ur game sense is broken',
    'ez ez ez again',
    'ur aim is a disaster',
    'try a different game',
    'u literally gift me kills',
    'EZ gg easy clap',
    'cant even hit air',
    'ur keyboard layout is wrong',
    'total bot',
    'ur aim is tragic',
    'bot feeder detected',
    'im unstoppable',
    'u cant hit this',
    'ez brainless',
    'u literally chasing me',
    'cant even react',
    'u wish u had my skill',
    'easy clap incoming',
    'ur game sense is trash',
    'try again noob',
    'im too fast for u',
    'ur shots are weak',
    'u cant aim straight',
    'stop feeding me',
    'ur team is useless',
    'EZ wipe',
    'ur reaction time zero',
    'cant even hit moving',
    'lol ur predictable',
    'ur aim is hopeless',
    'cant beat me',
    'EZ brainless carry',
    'ur skills are imaginary',
    'ur mouse lagging?',
    'EZ ez ez ez',
    'ur aim is weak',
    'cant even land headshots',
    'u literally feed daily',
    'EZ demolition complete',
    'ur skill rating is 0',
    'try harder noob',
    'EZ wipe again',
    'ur brain cant keep up',
    'cant escape my skill',
    'EZ domination',
    'ur aim is tragic again',
    'EZ victory lap',
    'cant touch me',
    'ur fanboy mode activated',
    'stalking much?',
    'EZ feed farm',
    'ur aim is garbage',
    'EZ EZ EZ final',
    'ur obsession shows',
    'ur aim is pure chaos',
    'cant dodge ez bullets',
    'EZ feed complete',
    'ur fan vibes strong',
    'EZ gg wp',
    'ur reactions nonexistent',
    'EZ brainless massacre',
    'cant follow my speed',
    'ur aim is nonexistent',
    'bro cant even hit air',
    'npc movement detected',
    'u missed a standing target',
    'walking free kill',
    'aim slower than my wifi',
    'still learning wasd?',
    'missed again wow',
    'ur aim expired',
    'walking xp bag',
    'default bot behavior',
    'cant even 1v0',
    'u shooting ghosts',
    'walking L detected',
    'spectators laughing rn',
    'ur kd = 0',
    'bro lost to map',
    'respawn faster kid',
    'ur mouse broken or what',
    'walking donation',
    'aim softer than bread',
    'bro missed afk',
    'u aim like blind cat',
    'ur kills imaginary',
    'press uninstall already',
    'npc with scripts > u',
    'still in training stage',
    'ur ping = ur iq',
    'ur skill bugged',
    'walking reset button',
    'ur accuracy negative',
    'bro cant press shoot',
    'spawn = death for u',
    'ur aim random number',
    'still loading skill pack',
    'ur reaction expired',
    'walking lag spike',
    'bro plays in slow mode',
    'ur aim like broken ui',
    'cant aim straight',
    'u play like obby lava',
    'bro missed point blank',
    'ur kd cry ratio',
    'npc smoother than u',
    'ur aim placebo',
    'bro runs like cutscene',
    'cant clutch 1v0',
    'walking trashcan',
    'bro still beta tester',
    'ur brain timeout',
    'u aim on tutorial bot',
    'still lagging 2025',
    'ur hands slippery',
    'bro feeding nonstop',
    'ur aim pure chaos',
    'press alt f4 for skill',
    'walking zero damage',
    'ur reaction potato',
    'bro spectating himself',
    'cant dodge ez shots',
    'ur aim placebo effect',
    'respawn is ur best skill',
    'bro shooting walls',
    'ur shots imaginary',
    'walking disaster',
    'aim reset required',
    'bro died to gravity',
    'ur aim tutorial level',
    'still on default settings',
    'ur aim invisible',
    'walking free xp',
    'bro misclicked life',
    'ur brain bugged',
    'aim patch not installed',
    'cant win coinflip',
    'u gift kills daily',
    'walking comedy',
    'bro plays like statue',
    'ur kd refund worthy',
    'still no improvement',
    'ur aim disabled',
    'bro needs dlc to aim',
    'ur game sense 0',
    'npc pathfinding better',
    'ur brain afk',
    'walking demo target',
    'cant escape skill issue',
    'ur kd cry fest',
    'still missing bro?',
    'ur aim fossil',
    'bro typing instead of aiming',
    'ur playstyle tutorial',
    'walking practice dummy',
    'u miss more than u breathe',
    'ur rng cursed',
    'spawn = free kill',
    'bro losing to bots',
    'ur aim lagging',
    'walking hitbox for me',
    'cant hit static',
    'ur kd nightmare',
    'still not improved',
    'bro forgot shoot key',
    'ur aim glitching',
    'walking zero skill',
    'ur mouse wireless on 1%',
    'bro drifts like lag',
    'cant react on time',
    'ur shots weak af',
    'still stuck bronze',
    'ur aim downgrade',
    'bro playing with delay',
    'ur stats negative',
    'walking bot clone',
    'cant move right',
    'ur aim is nothing same your life too',
}

isEnabled = false
shuffledMessages = {}
currentIndex = 1

function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

function resetShuffled()
    shuffledMessages = {}
    for i = 1, #messages do
        table.insert(shuffledMessages, messages[i])
    end
    shuffle(shuffledMessages)
    currentIndex = 1
end

function sendMessagesSequentially()
    if #shuffledMessages == 0 then
        resetShuffled()
    end
    while isEnabled do
        if channel then
            channel:SendAsync(shuffledMessages[currentIndex])
        end
        currentIndex = currentIndex + 1
        if currentIndex > #shuffledMessages then
            resetShuffled()
        end
        wait(3)
    end
end

UtilitiesGroup:AddToggle('TestTalk', {
    Text = 'Trash Talk',
    Default = false,
}):OnChanged(function(state)
    isEnabled = state
    if state then
        spawn(sendMessagesSequentially)
    end
end)

rizzMessages = {
    'hey, you caught my eye',
    'you seem really interesting',
    'i like how you move and how you smells',
    'you have a great face',
    'i can’t stop noticing you',
    'wanna chat sometime?',
    'you’re really captivating',
    'i could watch you play all day',
    'you should take off your shoes and socks you know for what',
    'you make everything look easy',
    'i admire how focused you are',
    'you’re really talented',
    'i like your waterproof energy',
    'you brighten my day just by being here',
    'you have an amazing style',
    'i like your confidence',
    'can i smell u ? you smells so good',
    'there’s something about you',
    'i like the way you think',
    'you make the game more fun for dihs',
    'your presence is refreshing',
    'i like how unique you are',
    'you’re someone i want to know better',
    'i admire your determination',
    'you’re unforgettable',
    'i like your mindset',
    'are you wifi? cuz i’m feeling a connection',
    'you’re very intriguing',
    'you stand out in every way',
    'i can’t help but smile when i see you',
    'your vibe is unmatched',
    'you make winning look easy',
    'i like your focus',
    'you’re always confident',
    'i enjoy watching you play',
    'your moves are smooth',
    'i like how composed you are',
    'you’re fun to be around',
    'your energy is contagious',
    'i like your style and grace',
    'you have a natural charm',
    'i feel drawn to you',
    'you’re captivating effortlessly',
    'i like how playful you are',
    'you seem very smart',
    'i admire your strategy',
    'you’re fascinating',
    'i like your confidence and poise',
    'you’re always in control',
    'can i smell ur shoes ?',
    'i enjoy your company',
    'you have a spark i can’t ignore',
    'i like your personality',
    'you make the game more exciting',
    'i admire your skill',
    'you’re so engaging',
    'i like your passion',
    'you have amazing instincts',
    'you’re very inspiring',
    'i enjoy watching your decisions',
    'you’re fun to follow',
    'i like your creativity',
    'you’re very thoughtful',
    'i like how unique your style is',
    'you make challenges fun',
    'you’re impressive',
    'i like your calmness under pressure',
    'you’re very skilled',
    'i enjoy how you lead',
    'you’re very confident',
    'can i smell ur socks ?',
    'i like your reactions',
    'you’re playful in a great way',
    'i like your dedication',
    'you’re very entertaining',
    'i like your cleverness',
    'you’re very charming',
    'i admire your patience',
    'you’re always interesting',
    'i like your sharpness',
    'you’re inspiring to watch',
    'i like your boldness',
    'you’re naturally fun',
    'i admire your consistency',
    'you’re very dynamic',
    'i like how you adapt',
    'you’re very energetic',
    'i enjoy your humor',
    'you’re very engaging',
    'i like your initiative',
    'you’re a natural at this',
    'i like your enthusiasm',
    'you’re very impressive',
    'i enjoy your vibe',
    'you’re very motivating',
    'i like your calm energy',
    'you’re very expressive',
    'i enjoy your presence',
    'you’re fun to interact with',
    'i like your alertness',
    'you’re captivating to watch',
    'i admire your confidence and poise',
    'you’re naturally cool',
    'i like your creativity and style',
    'you’re very charming',
    'i enjoy your energy and humor',
    'you’re fascinating to follow',
    'i like your natural charisma',
    'you’re very inspiring',
    'i enjoy your attention to detail',
    'you’re naturally magnetic',
    'i like how smooth you are',
    'you’re very memorable',
    'i enjoy your sharp instincts',
    'you’re naturally attractive',
    'i like how you wear stockings',
    'i like your elegance and grace',
    'you’re very impressive overall',
    'i admire your playfulness',
    'you’re naturally entertaining',
    'i enjoy your unique energy',
    'you’re very captivating overall',
    'i like your natural charm',
    'are you a magician? cuz whenever you’re around, everyone else disappears',
    'you must be a map, because I keep getting lost in your eyes',
    'are you a campfire? cuz you’re hot and I want s’more',
    'if being cute was a crime, you’d be serving a life sentence',
    'you’ve got something I can’t quite put into words… probably charm overload',
    'do you have a name, or can I call you mine?',
    'are you a keyboard? cuz you’re my type',
    'are you a Wi-Fi signal? cuz I feel a strong connection',
    'if you were a vegetable, you’d be a cute-cumber',
    'you must be tired, cuz you’ve been running through my mind all day',
    'is your aura Wi-Fi enabled? cuz I’m picking up good vibes',
    'are you a charger? cuz without you I’d die',
    'you must be a lottery ticket, cuz I feel lucky around you',
    'are you made of copper and tellurium? cuz you’re Cu-Te',
    'you must be a sunrise, cuz you brighten my morning',
    'are you a puzzle? cuz I can’t stop thinking about how to figure you out',
    'you must be a time traveler, cuz I see you in my future',
    'you’re like a software update, you just made my day better',
    'if you were a meme, you’d be legendary',
    'are you a star? cuz your light’s impossible to ignore',
    'i like your vibe, it’s way above 9000',
    'are you a donut? cuz you’re sweet and round… perfect',
    'you’ve got a smile that could break the internet',
    'you must be made of stardust, cuz you shine',
    'if i followed you home, would you keep me? ;)',
    'your energy is like caffeine… makes me feel alive',
    'you’re like a plot twist, unexpected and amazing',
    'i like how your brain works, it’s chaotic genius',
    'are you a rainbow? cuz you color my world',
    'you’ve got that je ne sais quoi that breaks physics',
    'you must be a rare item, cuz everyone’s looking for you',
    'your aura just hacked my attention',
    'i like how your presence crashes all my distractions',
    'you’ve got charisma that should be illegal',
    'are you a potion? cuz i feel enchanted',
    'you’re like my favorite song on repeat',
    'if i were a cat, i’d purr every time you’re near',
    'you’ve got a gravitational pull i can’t resist',
    'you make ordinary moments feel cinematic',
    'you’re like a glitch in reality… in the best way',
    'i like your style, it’s meta-level impressive',
    'you’re the kind of mystery i’d never want to solve',
    'are you a comic book hero? cuz my heart just went kapow',
    'you’re like a bonus level in life… unexpected and fun',
    'your energy should have its own theme song',
    'i like the way you break all my expectations',
    'you’re like a secret code only my brain can decrypt',
    'you make multitasking look like an art form',
    'your aura should come with a warning sign',
    'i like how you turn everything you touch into gold',
    'you’re like a DLC pack for life… way better than expected',
    'your confidence is basically cheat codes',
    'you’re like a perfect combo move, flawless every time',
}

isEnabled = false
shuffledRizzMessages = {}
currentRizzIndex = 1

function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

function resetShuffledRizz()
    shuffledRizzMessages = {}
    for i = 1, #rizzMessages do
        table.insert(shuffledRizzMessages, rizzMessages[i])
    end
    shuffle(shuffledRizzMessages)
    currentRizzIndex = 1
end

function sendRizzMessages()
    if #shuffledRizzMessages == 0 then
        resetShuffledRizz()
    end
    while isEnabled do
        if channel then
            channel:SendAsync(shuffledRizzMessages[currentRizzIndex])
        end
        currentRizzIndex = currentRizzIndex + 1
        if currentRizzIndex > #shuffledRizzMessages then
            resetShuffledRizz()
        end
        wait(3)
    end
end

UtilitiesGroup:AddToggle('RizzTalk', {
    Text = 'Rizz Talk',
    Default = false,
}):OnChanged(function(state)
    isEnabled = state
    if state then
        spawn(sendRizzMessages)
    end
end)

getgenv().Test = false
getgenv().SoundId = '8323804973'
getgenv().ToolEnabled = false

getgenv().CreateTool = function()
    getgenv().Tool = Instance.new('Tool')
    getgenv().Tool.RequiresHandle = false
    getgenv().Tool.Name = '[Kick]'
    getgenv().Tool.TextureId = 'rbxassetid://483225199'
    getgenv().Animation = Instance.new('Animation')
    getgenv().Animation.AnimationId = 'rbxassetid://138408477594658'
    getgenv().Tool.Activated:Connect(function()
        getgenv().Test = true
        getgenv().Player = game.Players.LocalPlayer
        getgenv().Character = getgenv().Player.Character
            or getgenv().Player.CharacterAdded:Wait()
        getgenv().Humanoid = getgenv().Character:FindFirstChild('Humanoid')
        if getgenv().Humanoid then
            getgenv().AnimationTrack =
                getgenv().Humanoid:LoadAnimation(getgenv().Animation)
            getgenv().AnimationTrack:AdjustSpeed(3.4)
            getgenv().AnimationTrack:Play()
        end
        task.wait(0.6)
        getgenv().Boombox =
            game.Players.LocalPlayer.Backpack:FindFirstChild('[Boombox]')
        if getgenv().Boombox then
            getgenv().Boombox.Parent = game.Players.LocalPlayer.Character
            game:GetService('ReplicatedStorage').MainEvent
                :FireServer('Boombox', tonumber(getgenv().SoundId))
            getgenv().Boombox.RequiresHandle = false
            getgenv().Boombox.Parent = game.Players.LocalPlayer.Backpack
            task.wait(1)
            game:GetService('ReplicatedStorage').MainEvent
                :FireServer('BoomboxStop')
        else
            getgenv().Sound = Instance.new('Sound', workspace)
            getgenv().Sound.SoundId = 'rbxassetid://' .. getgenv().SoundId
            getgenv().Sound:Play()
            task.wait(1)
            getgenv().Sound:Stop()
        end
        wait(1.4)
        getgenv().Test = false
    end)
    getgenv().Tool.Parent = game.Players.LocalPlayer:WaitForChild('Backpack')
end

getgenv().RemoveTool = function()
    getgenv().Player = game.Players.LocalPlayer
    getgenv().Tool = getgenv().Player.Backpack:FindFirstChild('[Kick]')
        or getgenv().Player.Character:FindFirstChild('[Kick]')
    if getgenv().Tool then
        getgenv().Tool:Destroy()
    end
end

game:GetService('RunService').Heartbeat:Connect(function()
    if getgenv().Test then
        getgenv().Character = game.Players.LocalPlayer.Character
        if not getgenv().Character then
            return
        end
        getgenv().HumanoidRootPart =
            getgenv().Character:FindFirstChild('HumanoidRootPart')
        if not getgenv().HumanoidRootPart then
            return
        end
        getgenv().originalVelocity = getgenv().HumanoidRootPart.Velocity
        getgenv().HumanoidRootPart.Velocity = Vector3.new(
            getgenv().HumanoidRootPart.CFrame.LookVector.X * 800,
            800,
            getgenv().HumanoidRootPart.CFrame.LookVector.Z * 800
        )
        game:GetService('RunService').RenderStepped:Wait()
        getgenv().HumanoidRootPart.Velocity = getgenv().originalVelocity
    end
end)

UtilitiesGroup:AddToggle('ToolToggle', {
    Text = 'Knockout Kick',
    Default = false,
    Callback = function(state)
        getgenv().ToolEnabled = state
        if state then
            getgenv().CreateTool()
        else
            getgenv().RemoveTool()
        end
    end,
})

game.Players.LocalPlayer.CharacterAdded:Connect(function()
    if getgenv().ToolEnabled then
        task.wait(1)
        getgenv().CreateTool()
    end
end)

MovementGroup = PlayerTab:AddLeftGroupbox('Movement')

speedV2Enabled = false
speedValue = 16

flightEnabled = false
flightValue = 16

hoverHeight = nil
bindsEnabled = true

flightMode = 'Minecraft'

UserInputService.TextBoxFocused:Connect(function()
    bindsEnabled = false
end)

UserInputService.TextBoxFocusReleased:Connect(function()
    bindsEnabled = true
end)

function resetWalkSpeed()
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass('Humanoid')
        if humanoid then
            humanoid.WalkSpeed = 16
        end
    end
end

function resetFlight()
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass('Humanoid')
        if humanoid then
            humanoid.PlatformStand = false
        end
    end
end

function antiFlingActivate()
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild('HumanoidRootPart')
        local humanoid = char:FindFirstChildOfClass('Humanoid')
        if hrp and humanoid then
            humanoid.PlatformStand = true
            hrp.Velocity = Vector3.new(0, 0, 0)
        end
    end
end

function antiFlingReset()
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass('Humanoid')
        if humanoid then
            humanoid.PlatformStand = false
        end
    end
end

function setSpeedCFrame()
    if not speedV2Enabled or UserInputService:GetFocusedTextBox() then
        return
    end
    if not bindsEnabled then
        return
    end

    local char = LocalPlayer.Character
    if not char then
        return
    end
    local hrp = char:FindFirstChild('HumanoidRootPart')
    if not hrp then
        return
    end

    local moveDir = Vector3.new()
    local camCF = workspace.CurrentCamera.CFrame

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        moveDir = moveDir + camCF.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        moveDir = moveDir - camCF.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        moveDir = moveDir - camCF.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        moveDir = moveDir + camCF.RightVector
    end

    moveDir = Vector3.new(moveDir.X, 0, moveDir.Z)
    if moveDir.Magnitude > 0 then
        moveDir = moveDir.Unit
            * speedValue
            * (RunService.Heartbeat:Wait() or 0.016)
        hrp.CFrame = hrp.CFrame + moveDir
    end
end

function setFlightCFrame()
    if not flightEnabled then
        return
    end
    local char = LocalPlayer.Character
    if not char then
        return
    end
    local hrp = char:FindFirstChild('HumanoidRootPart')
    local humanoid = char:FindFirstChildOfClass('Humanoid')
    if not hrp or not humanoid then
        return
    end

    humanoid.PlatformStand = true
    local delta = RunService.Heartbeat:Wait() or 0.016
    local camCF = workspace.CurrentCamera.CFrame

    if flightMode == 'Minecraft' then
        if not bindsEnabled then
            hoverHeight = hrp.Position.Y
            hrp.CFrame = CFrame.new(hrp.Position.X, hoverHeight, hrp.Position.Z)
            hrp.Velocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
            return
        end

        local moveDir = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDir = moveDir
                + Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDir = moveDir
                - Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDir = moveDir
                - Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDir = moveDir
                + Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
        end

        local verticalDir = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            verticalDir = 1
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            verticalDir = -1
        end

        if hoverHeight == nil or math.abs(hrp.Position.Y - hoverHeight) > 5 then
            hoverHeight = hrp.Position.Y
        end
        if verticalDir ~= 0 then
            hoverHeight = hoverHeight + verticalDir * flightValue * delta
        end
        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit * flightValue * delta
        else
            moveDir = Vector3.zero
        end

        local newPos = hrp.Position + Vector3.new(moveDir.X, 0, moveDir.Z)
        hrp.CFrame = CFrame.new(newPos.X, hoverHeight, newPos.Z)
        hrp.Velocity = Vector3.zero
        hrp.RotVelocity = Vector3.zero
    elseif flightMode == 'Classic' then
        local moveDir = Vector3.new()
        local camLook = camCF.LookVector
        local camRight = camCF.RightVector

        if not bindsEnabled then
            hrp.Velocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
            return
        end

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDir = moveDir + camLook
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDir = moveDir - camLook
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDir = moveDir - camRight
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDir = moveDir + camRight
        end

        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit * flightValue * delta
            hrp.CFrame = hrp.CFrame + moveDir
        end

        hrp.Velocity = Vector3.zero
        hrp.RotVelocity = Vector3.zero
    end
end

RunService.Heartbeat:Connect(function()
    if speedV2Enabled then
        setSpeedCFrame()
    end
    if flightEnabled then
        setFlightCFrame()
    else
        resetFlight()
        hoverHeight = nil
    end
end)

MovementGroup:AddToggle('SpeedCFrameToggle', {
    Text = 'Speed CFrame',
    Default = false,
})
    :AddKeyPicker('SpeedToggleBind', {
        Default = '',
        Mode = 'Toggle',
        Text = 'Speed CFrame',
        NoUI = false,
        SyncToggleState = false,
        Callback = function(state)
            if not bindsEnabled then
                return
            end
            Toggles.SpeedCFrameToggle:SetValue(state)
        end,
    })
    :OnChanged(function(state)
        speedV2Enabled = state
        if not state then
            antiFlingReset()
            resetWalkSpeed()
        end
    end)

MovementGroup:AddSlider('SpeedCFrameSlider', {
    Text = 'Speed Amount',
    Min = 1,
    Max = 1500,
    Default = 16,
    Rounding = 0,
    Callback = function(value)
        speedValue = value
    end,
})

MovementGroup:AddToggle('No Jump Cooldown', {
    Text = 'No Jump Cooldown',
    Default = false,
    Callback = function(state)
        if state then
            local player = game.Players.LocalPlayer
            local function nojumpcooldown(character)
                character:WaitForChild('Humanoid').UseJumpPower = false
            end
            player.CharacterAdded:Connect(nojumpcooldown)
            if player.Character then
                nojumpcooldown(player.Character)
            end
        end
    end,
})

MovementGroup:AddToggle('No Slow Down', {
    Text = 'No Slow Down',
    Default = false,
    Callback = function(state)
        if state then
            RunService:BindToRenderStep('NoSlowDown', 0, function()
                local character = player.Character
                if not character then
                    return
                end

                local bodyEffects = character:FindFirstChild('BodyEffects')
                if not bodyEffects then
                    return
                end

                local movement = bodyEffects:FindFirstChild('Movement')
                if movement then
                    local noWalkSpeed = movement:FindFirstChild('NoWalkSpeed')
                    if noWalkSpeed then
                        noWalkSpeed:Destroy()
                    end

                    local reduceWalk = movement:FindFirstChild('ReduceWalk')
                    if reduceWalk then
                        reduceWalk:Destroy()
                    end

                    local noJumping = movement:FindFirstChild('NoJumping')
                    if noJumping then
                        noJumping:Destroy()
                    end
                end

                if
                    bodyEffects:FindFirstChild('Reload')
                    and bodyEffects.Reload.Value == true
                then
                    bodyEffects.Reload.Value = false
                end
            end)
        else
            RunService:UnbindFromRenderStep('NoSlowDown')
        end
    end,
})

MovementGroup:AddToggle('FlightCFrameToggle', {
    Text = 'Flight CFrame',
    Default = false,
})
    :AddKeyPicker('FlightToggleBind', {
        Default = '',
        Mode = 'Toggle',
        Text = 'Flight CFrame',
        NoUI = false,
        SyncToggleState = false,
        Callback = function(state)
            if not bindsEnabled then
                return
            end
            Toggles.FlightCFrameToggle:SetValue(state)
        end,
    })
    :OnChanged(function(state)
        flightEnabled = state
        if not state then
            antiFlingActivate()
            task.spawn(function()
                task.wait(0.01)
                antiFlingReset()
                task.wait(2)
                antiFlingReset()
            end)
            resetFlight()
        end
    end)

MovementGroup:AddDropdown('FlightModeDropdown', {
    Text = 'Flight Mode',
    Default = 'Minecraft',
    Values = { 'Minecraft', 'Classic' },
    Callback = function(value)
        flightMode = value
        if flightMode == 'Classic' then
            char = LocalPlayer.Character
            if char then
                humanoid = char:FindFirstChildOfClass('Humanoid')
                hrp = char:FindFirstChild('HumanoidRootPart')
                if humanoid and hrp then
                    humanoid.PlatformStand = false
                    hrp.Velocity = Vector3.zero
                    hrp.RotVelocity = Vector3.zero
                    task.wait(0.03)
                end
            end
        elseif flightMode == 'Minecraft' then
            char = LocalPlayer.Character
            if char then
                humanoid = char:FindFirstChildOfClass('Humanoid')
                if humanoid then
                    humanoid.PlatformStand = true
                end
            end
        end
    end,
})

MovementGroup:AddSlider('FlightAmountSlider', {
    Text = 'Flight Amount',
    Min = 1,
    Max = 1500,
    Default = 16,
    Rounding = 0,
    Callback = function(value)
        flightValue = value
    end,
})

TabBox = PlayerTab:AddRightTabbox()

Tab1 = TabBox:AddTab('Pos Desync')
Tab2 = TabBox:AddTab('Fake Pos')

rng = Random.new()
desyncEnabled = false
desyncMode = 'Custom'
randomMode = false
autoDesyncOnDamage = false
originalCFrame = nil
desyncThread = nil

character = nil
hrp = nil
humanoid = nil
lastHealth = nil
customPos = Vector3.new(0, 0, 0)
Clone = nil
underMapSpeed = 999999
underMapThread = nil

flightEnabled = false
flightValue = 100
speedV2Enabled = false
speedValue = 50

Services = {
    RunService = game:GetService('RunService'),
    LocalPlayer = game:GetService('Players').LocalPlayer,
    UserInputService = game:GetService('UserInputService'),
}

function IsChatFocused()
    return Services.UserInputService:GetFocusedTextBox() ~= nil
end

function randomLarge(min, max)
    return min + rng:NextNumber() * (max - min)
end

function getRandomSkyPosition()
    baseX = rng:NextNumber(-995000, 995000)
    baseY = rng:NextNumber(22000, 98000)
    baseZ = rng:NextNumber(-995000, 995000)
    time = tick()
    offsetX = math.sin(time * 3 + baseX) * 5000
    offsetY = math.cos(time * 2 + baseY) * 2000
    offsetZ = math.sin(time * 4 + baseZ) * 5000
    return Vector3.new(baseX + offsetX, baseY + offsetY, baseZ + offsetZ)
end

function getIntermediateSkyPosition()
    baseX = rng:NextNumber(-1e6, 1e6)
    baseY = rng:NextNumber(45000, 85000)
    baseZ = rng:NextNumber(-1e6, 1e6)
    time = tick()
    offsetX = (math.sin(time * 5 + baseX) + rng:NextNumber(-1, 1)) * 3000
    offsetY = (math.cos(time * 3 + baseY) + rng:NextNumber(-0.5, 0.5)) * 1500
    offsetZ = (math.sin(time * 6 + baseZ) + rng:NextNumber(-1, 1)) * 3000
    return Vector3.new(baseX + offsetX, baseY + offsetY, baseZ + offsetZ)
end

function getExtremeSkyPosition()
    function crazyRand()
        return rng:NextNumber(-1e9, 1e9)
    end
    return Vector3.new(crazyRand(), rng:NextNumber(5e7, 1e9), crazyRand())
end

function getUltimateUndergroundPosition()
    return Vector3.new(randomLarge(-1e9, 1e9), 1e8, randomLarge(-1e9, 1e9))
end

function getSilentSkyPosition()
    return Vector3.new(randomLarge(-1e6, 1e6), -25, randomLarge(-1e6, 1e6))
end

function getRandomModePosition()
    function randomSigned(min, max)
        sign = rng:NextInteger(0, 1) == 1 and 1 or -1
        return rng:NextNumber(min, max) * sign
    end
    heightChoice = rng:NextInteger(1, 3)
    if heightChoice == 1 then
        y = rng:NextNumber(1000, 50000)
    elseif heightChoice == 2 then
        y = rng:NextNumber(120000, 1e7)
    else
        y = rng:NextNumber(1e7, 1e9)
    end
    x = randomSigned(1e5, 1e7)
    z = randomSigned(1e5, 1e7)
    return Vector3.new(x, y, z)
end

function enableAntiFling()
    if not hrp or not hrp.Parent then
        return
    end
    for _, part in ipairs(hrp.Parent:GetDescendants()) do
        if part:IsA('BasePart') then
            part.Velocity = Vector3.zero
            part.RotVelocity = Vector3.zero
            part.AssemblyLinearVelocity = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
            part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0)
        end
    end
end

function disableAntiFling()
    if not hrp or not hrp.Parent then
        return
    end
    for _, part in ipairs(hrp.Parent:GetDescendants()) do
        if part:IsA('BasePart') then
            part.CustomPhysicalProperties = PhysicalProperties.new(1, 0.3, 0.5)
        end
    end
end

function enableDesync()
    if desyncEnabled or not hrp then
        return
    end
    desyncEnabled = true
    originalCFrame = hrp.CFrame

    Char = Services.LocalPlayer.Character
    AnimTracks = {}
    currentAnim = nil

    Char.Archivable = true

    function novel(part)
        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero
        part.Velocity = Vector3.zero
    end

    function IsAnimPlaying(humanoid, anim)
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            if track.Animation == anim then
                return true
            end
        end
        return false
    end

    function AnimPlay(humanoid, anim, speed)
        if not IsAnimPlaying(humanoid, anim) then
            if currentAnim then
                currentAnim:Stop()
            end
            currentAnim = humanoid:LoadAnimation(anim)
            currentAnim:Play()
            currentAnim:AdjustSpeed(speed or 1)
        end
    end

    function AnimCheck(humanoid, moveDirection)
        state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Jumping then
            AnimPlay(humanoid, AnimTracks['Jump'])
        elseif state == Enum.HumanoidStateType.Freefall then
            AnimPlay(humanoid, AnimTracks['Fall'])
        elseif moveDirection.Magnitude > 0 then
            AnimPlay(humanoid, AnimTracks['Run'], 1.2)
        else
            AnimPlay(humanoid, AnimTracks['Idle'])
        end
    end

    function LoadAnimations()
        AnimateScript = Char:FindFirstChild('Animate')
        if AnimateScript then
            AnimTracks['Run'] = AnimateScript.run.RunAnim
            AnimTracks['Idle'] = AnimateScript.idle.Animation1
            AnimTracks['Jump'] = AnimateScript.jump.JumpAnim
            AnimTracks['Fall'] = AnimateScript.fall.FallAnim
        end
    end

    LoadAnimations()

    Clone = Char:Clone()
    Clone.Parent = workspace
    workspace.Camera.CameraSubject = Clone.Humanoid

    desyncThread = Services.RunService.Heartbeat:Connect(function()
        if not desyncEnabled or not hrp then
            return
        end

        if randomMode then
            targetCFrame = CFrame.new(getRandomModePosition())
        else
            if desyncMode == 'Custom' then
                targetCFrame = CFrame.new(customPos)
            elseif desyncMode == 'Version 1' then
                targetCFrame = CFrame.new(getRandomSkyPosition())
            elseif desyncMode == 'Version 2' then
                targetCFrame = CFrame.new(getIntermediateSkyPosition())
            elseif desyncMode == 'Silent Version' then
                targetCFrame = CFrame.new(getSilentSkyPosition())
            elseif desyncMode == 'Extreme Version' then
                targetCFrame = CFrame.new(getExtremeSkyPosition())
            elseif desyncMode == 'Ultimate Version' then
                targetCFrame = CFrame.new(getUltimateUndergroundPosition())
            else
                targetCFrame = originalCFrame
            end
        end

        hrp.CFrame = targetCFrame

        for _, part in pairs(Char:GetChildren()) do
            if part:IsA('BasePart') then
                novel(part)
            end
        end

        cloneHRP = Clone:FindFirstChild('HumanoidRootPart')
        delta = Services.RunService.Heartbeat:Wait() or 0.016

        if cloneHRP then
            camCF = workspace.CurrentCamera.CFrame
            moveDir = Vector3.zero
            verticalDir = 0
            flyDir = Vector3.zero

            if not IsChatFocused() then
                if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    moveDir += camCF.LookVector
                    flyDir += camCF.LookVector
                end
                if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    moveDir -= camCF.LookVector
                    flyDir -= camCF.LookVector
                end
                if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    moveDir -= camCF.RightVector
                    flyDir -= camCF.RightVector
                end
                if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    moveDir += camCF.RightVector
                    flyDir += camCF.RightVector
                end
                if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    verticalDir = 1
                end
                if
                    Services.UserInputService:IsKeyDown(
                        Enum.KeyCode.LeftControl
                    )
                then
                    verticalDir = -1
                end
            end

            moveDir = Vector3.new(moveDir.X, 0, moveDir.Z)
            flyDir = Vector3.new(flyDir.X, 0, flyDir.Z)

            humanoidClone = Clone.Humanoid

            if speedV2Enabled then
                isJumping = humanoidClone:GetState()
                    == Enum.HumanoidStateType.Jumping
                if
                    humanoidClone.FloorMaterial == Enum.Material.Air
                    or isJumping
                then
                    cloneHRP.Anchored = false
                    humanoidClone.PlatformStand = false
                    humanoidClone.Jump = false
                    humanoidClone:Move(Char.Humanoid.MoveDirection, false)
                    if moveDir.Magnitude > 0 then
                        speedStep = moveDir.Unit * speedValue * delta
                        cloneHRP.CFrame = cloneHRP.CFrame + speedStep
                    end
                elseif moveDir.Magnitude > 0 then
                    cloneHRP.Anchored = true
                    humanoidClone.PlatformStand = true
                    humanoidClone.Jump = false
                    speedStep = moveDir.Unit * speedValue * delta
                    cloneHRP.CFrame = cloneHRP.CFrame + speedStep
                else
                    cloneHRP.Anchored = true
                    humanoidClone.PlatformStand = true
                    humanoidClone.Jump = false
                end
            else
                cloneHRP.Anchored = false
                humanoidClone.PlatformStand = false
                humanoidClone.Jump = false
                humanoidClone:Move(Char.Humanoid.MoveDirection, false)
            end

            if flightEnabled then
                cloneHRP.Anchored = true
                humanoidClone.PlatformStand = true
                if flyDir.Magnitude > 0 then
                    flyDir = flyDir.Unit * flightValue * delta
                end
                yStep = verticalDir * flightValue * delta
                cloneHRP.CFrame = cloneHRP.CFrame
                    + Vector3.new(flyDir.X, yStep, flyDir.Z)
            end

            if Toggles.UnderMapMode.Value then
                cloneHRP.CFrame =
                    CFrame.new(cloneHRP.Position.X, -25, cloneHRP.Position.Z)
                cloneHRP.Velocity = Vector3.new(
                    (math.random() - 0.5) * 2 * underMapSpeed,
                    0,
                    (math.random() - 0.5) * 2 * underMapSpeed
                )
            end
        end

        Clone.Humanoid.Jump = Char.Humanoid.Jump
        AnimCheck(Clone.Humanoid, Char.Humanoid.MoveDirection)
    end)
end

function disableDesync()
    if not desyncEnabled then
        return
    end
    desyncEnabled = false
    if desyncThread then
        desyncThread:Disconnect()
        desyncThread = nil
    end
    if Clone and Clone:FindFirstChild('HumanoidRootPart') then
        Clone.HumanoidRootPart.Anchored = false
        Clone.Humanoid.PlatformStand = false
    end
    if Clone and Clone:FindFirstChild('HumanoidRootPart') and hrp then
        hrp.CFrame = Clone.HumanoidRootPart.CFrame
        workspace.CurrentCamera.CameraSubject = humanoid
        Clone:Destroy()
        Clone = nil
    end
    if hrp and humanoid then
        hrp.Anchored = true
        enableAntiFling()
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        task.delay(0.01, function()
            if hrp and hrp.Parent then
                hrp.Anchored = false
                disableAntiFling()
                humanoid.PlatformStand = false
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)
    end
end

function setupHealthListener()
    if humanoid then
        humanoid.HealthChanged:Connect(function(newHealth)
            if
                autoDesyncOnDamage
                and newHealth < lastHealth
                and Toggles.EnablePosDesync.Value
            then
                enableDesync()
            end
            lastHealth = newHealth
        end)
    end
end

function onCharacterAdded(char)
    character = char
    hrp = character:WaitForChild('HumanoidRootPart')
    humanoid = character:WaitForChild('Humanoid')
    lastHealth = humanoid.Health
    setupHealthListener()
end

if Services.LocalPlayer.Character then
    onCharacterAdded(Services.LocalPlayer.Character)
end
Services.LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

Tab1:AddToggle('EnablePosDesync', { Text = 'Enable', Default = false })
    :AddKeyPicker('DesyncToggleBind', {
        Default = '',
        Mode = 'Toggle',
        Text = 'Pos Desync',
        NoUI = false,
        SyncToggleState = false,
        Callback = function(state)
            if not IsChatFocused() then
                if Toggles.EnablePosDesync.Value then
                    if state then
                        enableDesync()
                    else
                        disableDesync()
                    end
                end
            end
        end,
    })
    :OnChanged(function(value)
        if value then
            enableDesync()
        else
            disableDesync()
        end
    end)

Tab1:AddToggle('AutoDesyncOnDamage', {
    Text = 'Auto On Damage',
    Default = false,
    Callback = function(value)
        autoDesyncOnDamage = value
        if value then
            local savedHeight = workspace.FallenPartsDestroyHeight
            workspace.FallenPartsDestroyHeight = -math.huge

            task.delay(3, function()
                workspace.FallenPartsDestroyHeight = savedHeight
            end)

            local char = Services.LocalPlayer.Character
            if char then
                local hrp = char:FindFirstChild('HumanoidRootPart')
                if hrp then
                    hrp.CFrame =
                        CFrame.new(hrp.Position.X, -49999, hrp.Position.Z)
                    task.delay(1, function()
                        local head = char:FindFirstChild('Head')
                        if head then
                            head:Destroy()
                        end
                        Services.LocalPlayer:LoadCharacter()
                    end)
                end
            end
        end
    end,
})

Tab1:AddToggle('UnderMapMode', {
    Text = 'Pause Resolver',
    Default = false,
    Tooltip = 'The function is used if you are in the game.\n'
        .. 'When you turn on normal pos desync you get the message "gameplay frozen".\n'
        .. 'This function will allow you to use pos desync in velocity mode\n'
        .. 'but you will see yourself as teleporting\n'
        .. 'including under yourself.\n'
        .. 'Use this function only if you are being killed by an exploiter.\n'
        .. 'If you are not being killed by an exploiter but want to use normal pos desync, use Custom desync mode.\n'
        .. 'Do not use this function in regular Roblox games without anti-cheat,\n'
        .. 'as it may cause issues including "gameplay freeze".\n'
        .. 'This feature is still under development and will be updated in the future.',
    Callback = function(value)
        Toggles.UnderMapMode.Value = value
    end,
})

Tab1:AddToggle('RandomPosMode', {
    Text = 'Random Mode',
    Default = false,
    Callback = function(value)
        randomMode = value
    end,
})

Tab1:AddDropdown('DesyncVersion', {
    Text = 'Desync Version',
    Default = 'Custom',
    Values = {
        'Custom',
        'Version 1',
        'Version 2',
        'Silent Version',
        'Extreme Version',
        'Ultimate Version',
    },
    Callback = function(value)
        desyncMode = value
    end,
})

Tab1:AddInput('CustomXInput', {
    Default = '1000',
    Numeric = true,
    Finished = true,
    Text = 'Custom X',
    Callback = function(value)
        local number = tonumber(value)
        if number then
            customPos = Vector3.new(number, customPos.Y, customPos.Z)
        end
    end,
})

Tab1:AddInput('CustomYInput', {
    Default = '1000',
    Numeric = true,
    Finished = true,
    Text = 'Custom Y',
    Callback = function(value)
        local number = tonumber(value)
        if number then
            customPos = Vector3.new(customPos.X, number, customPos.Z)
        end
    end,
})

Tab1:AddInput('CustomZInput', {
    Default = '1000',
    Numeric = true,
    Finished = true,
    Text = 'Custom Z',
    Callback = function(value)
        local number = tonumber(value)
        if number then
            customPos = Vector3.new(customPos.X, customPos.Y, number)
        end
    end,
})

local a = false
local DesyncEnabled = false
local FakePosEnabled = false
local originalHeight = workspace.FallenPartsDestroyHeight
local positionVersion = 'Custom'
local customPosition = { X = 500, Y = 500, Z = 500 }
local originalPosition = nil
local fakeClone = nil
local mode = 'Voidless'

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local Workspace = game:GetService('Workspace')
local LocalPlayer = Players.LocalPlayer

local function getHRP()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return character:FindFirstChild('HumanoidRootPart')
end

local function removeSeats()
    for _, seat in pairs(Workspace:GetDescendants()) do
        if seat:IsA('Seat') or seat:IsA('VehicleSeat') then
            seat:Destroy()
        end
    end
end

local function applyFakeLag()
    pcall(function()
        setfflag('S2PhysicsSenderRate', '1')
    end)
    pcall(function()
        setfpscap(1)
    end)
    task.wait(0.1)
    pcall(function()
        setfflag('S2PhysicsSenderRate', '200')
    end)
    pcall(function()
        setfpscap(240)
    end)
end

local function getBasePosition()
    if positionVersion == 'Version 1' then
        return 100000
    elseif positionVersion == 'Version 2' then
        return 5000000
    elseif positionVersion == 'Version 3' then
        return 10000000
    elseif positionVersion == 'Custom' then
        return nil
    end
    return 100000
end

local function getFakePos()
    if positionVersion == 'Custom' then
        return CFrame.new(customPosition.X, customPosition.Y, customPosition.Z)
    else
        local base = getBasePosition()
        return CFrame.new(base, base, base)
    end
end

local function createFakeClone(hrp)
    if fakeClone then
        fakeClone:Destroy()
    end

    fakeClone = Instance.new('Model')
    fakeClone.Name = 'FakeClone'
    fakeClone.Parent = Workspace

    local cloneHRP = Instance.new('Part')
    cloneHRP.Name = 'HumanoidRootPart'
    cloneHRP.Size = hrp.Size
    cloneHRP.CFrame = hrp.CFrame
    cloneHRP.Anchored = false
    cloneHRP.CanCollide = false
    cloneHRP.Parent = fakeClone

    local cloneHumanoid = Instance.new('Humanoid')
    cloneHumanoid.Parent = fakeClone
end

local function startFakePos()
    if FakePosEnabled then
        return
    end
    FakePosEnabled = true
    DesyncEnabled = true

    local hrp = getHRP()
    if not hrp then
        return
    end

    if mode == 'Voidless' then
        originalPosition = hrp.CFrame
        hrp.CFrame = getFakePos()

        removeSeats()
        Workspace.FallenPartsDestroyHeight = -math.huge
        applyFakeLag()

        task.delay(3, function()
            if hrp and originalPosition then
                hrp.CFrame = originalPosition
            end
        end)
    elseif mode == 'On the spot' then
        createFakeClone(hrp)
        fakeClone.HumanoidRootPart.CFrame = getFakePos()

        removeSeats()
        Workspace.FallenPartsDestroyHeight = -math.huge
        applyFakeLag()
    end
end

local function stopFakePos()
    FakePosEnabled = false
    DesyncEnabled = false

    pcall(function()
        setfflag('S2PhysicsSenderRate', '200')
    end)
    pcall(function()
        setfpscap(240)
    end)
    Workspace.FallenPartsDestroyHeight = originalHeight

    if fakeClone then
        fakeClone:Destroy()
        fakeClone = nil
    end
end

RunService.Heartbeat:Connect(function()
    if DesyncEnabled and getHRP() then
        a = not a
        pcall(function()
            sethiddenproperty(getHRP(), 'NetworkIsSleeping', a)
        end)
    end
end)

Tab2:AddToggle('EnableFakePos', { Text = 'Enable', Default = false })
    :AddKeyPicker('FakePosBind', {
        Default = '',
        Mode = 'Toggle',
        Text = 'Fake Position',
        NoUI = false,
        SyncToggleState = false,
        Callback = function(state)
            if UserInputService:GetFocusedTextBox() then
                return
            end
            if not Toggles.EnableFakePos then
                return
            end
            if state then
                startFakePos()
            else
                stopFakePos()
            end
        end,
    })
    :OnChanged(function(state)
        if UserInputService:GetFocusedTextBox() then
            return
        end
        if state then
            startFakePos()
        else
            stopFakePos()
        end
    end)

Tab2:AddDropdown('PositionVersion', {
    Text = 'Position Version',
    Default = 'Custom',
    Values = { 'Custom', 'Version 1', 'Version 2', 'Version 3' },
}):OnChanged(function(value)
    positionVersion = value
end)

Tab2:AddDropdown('FakePosMode', {
    Text = 'Mode',
    Default = 'Voidless',
    Values = { 'Voidless', 'On the spot' },
}):OnChanged(function(value)
    mode = value
end)

Tab2:AddInput(
    'CustomX',
    { Text = 'Custom X', Numeric = true, PlaceholderText = 'Enter number' }
):OnChanged(function(value)
    customPosition.X = tonumber(value) or customPosition.X
end)
Tab2:AddInput(
    'CustomY',
    { Text = 'Custom Y', Numeric = true, PlaceholderText = 'Enter number' }
):OnChanged(function(value)
    customPosition.Y = tonumber(value) or customPosition.Y
end)
Tab2:AddInput(
    'CustomZ',
    { Text = 'Custom Z', Numeric = true, PlaceholderText = 'Enter number' }
):OnChanged(function(value)
    customPosition.Z = tonumber(value) or customPosition.Z
end)

Players = game:GetService('Players')
Client = Players.LocalPlayer
ReplicatedStorage = game:GetService('ReplicatedStorage')
RunService = game:GetService('RunService')
UserInputService = game:GetService('UserInputService')

KillAuraGroup = PlayerTab:AddRightGroupbox('Kill Aura')

Table = {
    Aiming = {
        SilentConfig = {
            Kill_Aura = false,
            Kill_Aura_Range = 200,
        },
    },
}

Script = {
    Targeting = { Target = nil },
    Functions = {},
    Connections = {},
    Drawings = {},
    AuraWhiteList = {},
}

hitsounds = {
    Bubble = 'rbxassetid://6534947588',
    Lazer = 'rbxassetid://130791043',
    Pick = 'rbxassetid://1347140027',
    Pop = 'rbxassetid://198598793',
    Rust = 'rbxassetid://1255040462',
    Sans = 'rbxassetid://3188795283',
    Fart = 'rbxassetid://130833677',
    Big = 'rbxassetid://5332005053',
    Vine = 'rbxassetid://5332680810',
    UwU = 'rbxassetid://8679659744',
    Bruh = 'rbxassetid://4578740568',
    Skeet = 'rbxassetid://5633695679',
    Neverlose = 'rbxassetid://6534948092',
    Fatality = 'rbxassetid://6534947869',
    Bonk = 'rbxassetid://5766898159',
    Minecraft = 'rbxassetid://5869422451',
    Gamesense = 'rbxassetid://4817809188',
    RIFK7 = 'rbxassetid://9102080552',
    Bamboo = 'rbxassetid://3769434519',
    Crowbar = 'rbxassetid://546410481',
    Weeb = 'rbxassetid://6442965016',
    Beep = 'rbxassetid://8177256015',
    Bambi = 'rbxassetid://8437203821',
    Stone = 'rbxassetid://3581383408',
    OldFatality = 'rbxassetid://6607142036',
    Click = 'rbxassetid://8053704437',
    Ding = 'rbxassetid://7149516994',
    Snow = 'rbxassetid://6455527632',
    Laser = 'rbxassetid://7837461331',
    Mario = 'rbxassetid://2815207981',
    Steve = 'rbxassetid://4965083997',
    CallOfDuty = 'rbxassetid://5952120301',
    Bat = 'rbxassetid://3333907347',
    TF2Critical = 'rbxassetid://296102734',
    Saber = 'rbxassetid://8415678813',
    Baimware = 'rbxassetid://3124331820',
    Osu = 'rbxassetid://7149255551',
    TF2 = 'rbxassetid://2868331684',
    Slime = 'rbxassetid://6916371803',
    AmongUs = 'rbxassetid://5700183626',
    One = 'rbxassetid://7380502345',
}

hs_enabled = false
hs_selected = 'Bubble'
hs_volume = 1
_lastHealth = {}
selectedPlayer = nil

function playHitsound()
    if not hs_enabled then
        return
    end
    local id = hitsounds[hs_selected]
    if not id then
        return
    end
    local sound = Instance.new('Sound')
    sound.SoundId = id
    sound.Volume = hs_volume
    sound.Parent = workspace
    sound:Play()
    local connected
    connected = sound.Ended:Connect(function()
        sound:Destroy()
        if connected then
            connected:Disconnect()
        end
    end)
end

Script.Functions.IsValidTarget = function(character)
    if not character then
        return false
    end
    local humanoid = character:FindFirstChildOfClass('Humanoid')
    if not humanoid or humanoid.Health <= 0 then
        return false
    end
    if character:FindFirstChildOfClass('ForceField') then
        return false
    end
    local bodyEffects = character:FindFirstChild('BodyEffects')
    if bodyEffects then
        local ko = bodyEffects:FindFirstChild('K.O')
        if ko and ko:IsA('BoolValue') and ko.Value then
            return false
        end
    end
    if character:FindFirstChild('GRABBING_CONSTRAINT') then
        return false
    end
    return true
end

Script.Functions.IsAuraWhiteListed = function(player)
    return Script.AuraWhiteList[player.UserId] == true
end

Script.Functions.ApplyAuraWhiteListVisuals = function(player)
    if not player or not player.Character then
        return
    end
    local char = player.Character

    local highlight = char:FindFirstChild('AuraWhiteListHighlight')
    if not highlight then
        highlight = Instance.new('Highlight')
        highlight.Name = 'AuraWhiteListHighlight'
        highlight.FillColor = Color3.fromRGB(0, 255, 0)
        highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = char
    end

    local head = char:FindFirstChild('Head')
        or char:FindFirstChildWhichIsA('BasePart')
    if head and not head:FindFirstChild('AuraWhiteListBillboard') then
        local billboard = Instance.new('BillboardGui')
        billboard.Name = 'AuraWhiteListBillboard'
        billboard.Size = UDim2.new(0, 120, 0, 25)
        billboard.AlwaysOnTop = true
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Parent = head

        local textLabel = Instance.new('TextLabel')
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = 'Whitelisted'
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextSize = 14
        textLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        textLabel.TextStrokeTransparency = 0
        textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        textLabel.Parent = billboard
    end
end

Script.Functions.RemoveAuraWhiteListVisuals = function(player)
    if not player or not player.Character then
        return
    end
    local char = player.Character

    local highlight = char:FindFirstChild('AuraWhiteListHighlight')
    if highlight then
        highlight:Destroy()
    end

    local head = char:FindFirstChild('Head')
        or char:FindFirstChildWhichIsA('BasePart')
    if head then
        local billboard = head:FindFirstChild('AuraWhiteListBillboard')
        if billboard then
            billboard:Destroy()
        end
    end
end

Script.Functions.SetupAuraWhiteListRefresh = function(player)
    if not player then
        return
    end
    if Script.Connections[player] then
        pcall(function()
            Script.Connections[player]:Disconnect()
        end)
    end
    Script.Connections[player] = player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if Script.Functions.IsAuraWhiteListed(player) then
            Script.Functions.ApplyAuraWhiteListVisuals(player)
        end
    end)
end

Script.Functions.GetClosestPlayer = function()
    if
        not Client.Character
        or not Client.Character:FindFirstChild('HumanoidRootPart')
    then
        return nil
    end
    local closestPlayer = nil
    local shortestDistance = Table.Aiming.SilentConfig.Kill_Aura_Range
    for _, target in pairs(Players:GetPlayers()) do
        if
            target ~= Client
            and target.Character
            and target.Character:FindFirstChild('HumanoidRootPart')
            and not Script.Functions.IsAuraWhiteListed(target)
            and Script.Functions.IsValidTarget(target.Character)
        then
            local distance = (
                target.Character.HumanoidRootPart.Position
                - Client.Character.HumanoidRootPart.Position
            ).Magnitude
            if distance <= shortestDistance then
                closestPlayer = target
                shortestDistance = distance
            end
        end
    end
    return closestPlayer
end

Script.Functions.ShootRemote = function(tool, enemy)
    if not tool or not enemy or not enemy.Character then
        return
    end
    if enemy.Character:FindFirstChild('Head') then
        ReplicatedStorage.MainEvent:FireServer(
            'ShootGun',
            tool:FindFirstChild('Handle'),
            tool.Handle and tool.Handle.CFrame.Position
                or tool:GetPrimaryPartCFrame().p,
            enemy.Character.HumanoidRootPart.Position,
            enemy.Character.Head,
            Vector3.new(0, 0, -1)
        )
        local hum = enemy.Character:FindFirstChildOfClass('Humanoid')
        if hum then
            if _lastHealth[enemy.Name] == nil then
                _lastHealth[enemy.Name] = hum.Health
            else
                if hum.Health < _lastHealth[enemy.Name] then
                    playHitsound()
                end
                _lastHealth[enemy.Name] = hum.Health
            end
        end
    end
end

Script.Functions.KillAura = function()
    local closestPlayer = Script.Functions.GetClosestPlayer()
    if not closestPlayer then
        return
    end

    local tool = Client.Character
        and Client.Character:FindFirstChildOfClass('Tool')
    if not tool then
        return
    end

    Script.Functions.ShootRemote(tool, closestPlayer)
end

RunService.Heartbeat:Connect(function()
    if Table.Aiming.SilentConfig.Kill_Aura then
        Script.Functions.KillAura()
    end
end)

function getPlayerNames(filter)
    local t = {}
    local filterLower = filter and filter:lower() or nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Client then
            local name = plr.Name or ''
            local display = plr.DisplayName or ''
            if
                not filterLower
                or name:lower():find(filterLower)
                or display:lower():find(filterLower)
            then
                table.insert(t, name)
            end
        end
    end
    table.sort(t)
    return t
end

KillAuraToggle = KillAuraGroup:AddToggle('MainToggle', {
    Text = 'Enable',
    Default = false,
    Callback = function(state)
        Table.Aiming.SilentConfig.Kill_Aura = state
    end,
})

if KillAuraToggle and type(KillAuraToggle.AddKeyPicker) == 'function' then
    KillAuraToggle:AddKeyPicker('Keybind', {
        Default = '',
        Text = 'Kill Aura',
        Mode = 'Toggle',
        Callback = function(state)
            if UserInputService:GetFocusedTextBox() then
                return
            end
            Table.Aiming.SilentConfig.Kill_Aura = state
            if KillAuraToggle.SetValue then
                pcall(function()
                    KillAuraToggle:SetValue(state)
                end)
            end
        end,
    })
end

KillAuraGroup:AddSlider('KillAuraRange', {
    Text = 'Kill Aura Range',
    Min = 10,
    Max = 200,
    Default = Table.Aiming.SilentConfig.Kill_Aura_Range,
    Rounding = 0,
    Callback = function(value)
        Table.Aiming.SilentConfig.Kill_Aura_Range = value
    end,
})

KillAuraGroup:AddToggle('HS_Toggle', {
    Text = 'Hitsounds',
    Default = false,
    Callback = function(state)
        hs_enabled = state
    end,
})

KillAuraGroup:AddDropdown('HS_Select', {
    Text = 'Select Hitsound',
    Values = (function()
        local t = {}
        for k, _ in pairs(hitsounds) do
            table.insert(t, k)
        end
        table.sort(t)
        return t
    end)(),
    Default = hs_selected,
    Callback = function(val)
        hs_selected = val
    end,
})

KillAuraGroup:AddSlider('HS_Vol', {
    Text = 'Volume',
    Min = 0,
    Max = 5,
    Default = hs_volume,
    Rounding = 2,
    Callback = function(v)
        hs_volume = v
    end,
})

playerDropdown = KillAuraGroup:AddDropdown('PlayerDropdown', {
    Text = 'Select Player',
    Values = getPlayerNames(),
    Default = getPlayerNames()[1] or '',
    Multi = false,
    Callback = function(val)
        Script.Targeting.Target = val
        selectedPlayer = val
    end,
})

KillAuraGroup:AddInput('PlayerSearch', {
    Text = 'Search Player',
    Default = '',
    Placeholder = 'Enter player name...',
    Numeric = false,
    Finished = true,
    Callback = function(text)
        local matches = getPlayerNames(text)
        if #matches > 0 then
            if playerDropdown.SetValues then
                playerDropdown:SetValues(matches)
            end
            local lowerText = text:lower()
            for _, name in ipairs(matches) do
                if name:lower() == lowerText then
                    if playerDropdown.SetValue then
                        playerDropdown:SetValue(name)
                        Script.Targeting.Target = name
                        selectedPlayer = name
                    end
                    break
                end
            end
            if #matches == 1 then
                if playerDropdown.SetValue then
                    playerDropdown:SetValue(matches[1])
                    Script.Targeting.Target = matches[1]
                    selectedPlayer = matches[1]
                end
            end
        end
    end,
})

KillAuraGroup:AddButton('Whitelist', function()
    local selName = selectedPlayer
    if not selName or selName == '' then
        return
    end
    local plr = Players:FindFirstChild(selName)
    if plr then
        Script.AuraWhiteList[plr.UserId] = true
        Script.Functions.ApplyAuraWhiteListVisuals(plr)
        Script.Functions.SetupAuraWhiteListRefresh(plr)
    end
end)

KillAuraGroup:AddButton('Clear Whitelist', function()
    for userId, _ in pairs(Script.AuraWhiteList) do
        Script.AuraWhiteList[userId] = nil
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        Script.Functions.RemoveAuraWhiteListVisuals(plr)
    end
end)

Players.PlayerAdded:Connect(function(plr)
    task.wait(0.05)
    local vals = getPlayerNames()
    if playerDropdown.SetValues then
        playerDropdown:SetValues(vals)
    end
    Script.Functions.SetupAuraWhiteListRefresh(plr)
end)

Players.PlayerRemoving:Connect(function(plr)
    task.wait(0.05)
    local vals = getPlayerNames()
    if playerDropdown.SetValues then
        playerDropdown:SetValues(vals)
    end
    Script.Functions.RemoveAuraWhiteListVisuals(plr)
end)

for _, plr in pairs(Players:GetPlayers()) do
    Script.Functions.SetupAuraWhiteListRefresh(plr)
end

if playerDropdown then
    local vals = getPlayerNames()
    if vals[1] then
        if playerDropdown.SetValue then
            playerDropdown:SetValue(vals[1])
            Script.Targeting.Target = vals[1]
            selectedPlayer = vals[1]
        end
    end
end

TabBox = PlayerTab:AddRightTabbox()

Tab1 = TabBox:AddTab('Emotes')
Tab2 = TabBox:AddTab('Animations')

DancesStored = {
    Dances = {
        ['Floss'] = 10714340543,
        ['Hyper Flex'] = 10714369624,
        ['Yung Blud'] = 15609995579,
    },
}

CurrentDanceTracks = {}

function PlayDance(danceName)
    playerCharacter = player.Character
    if not playerCharacter then
        return
    end
    humanoid = playerCharacter:FindFirstChildOfClass('Humanoid')
    if not humanoid then
        return
    end
    if not DancesStored.Dances[danceName] then
        return
    end

    for otherDance, track in pairs(CurrentDanceTracks) do
        if track then
            track:Stop()
            track:Destroy()
            CurrentDanceTracks[otherDance] = nil
            if otherDance ~= danceName then
                Tab2:SetToggle(otherDance .. 'Toggle', false)
            end
        end
    end

    animation = Instance.new('Animation')
    animation.AnimationId = 'rbxassetid://'
        .. tostring(DancesStored.Dances[danceName])
    track = humanoid:LoadAnimation(animation)
    track:Play()
    CurrentDanceTracks[danceName] = track
end

function StopDance(danceName)
    if CurrentDanceTracks[danceName] then
        CurrentDanceTracks[danceName]:Stop()
        CurrentDanceTracks[danceName]:Destroy()
        CurrentDanceTracks[danceName] = nil
    end
end

function AddDanceToggle(danceName, keyName)
    Tab1:AddToggle(danceName .. 'Toggle', {
        Text = danceName,
        Default = false,
        Callback = function(state)
            if state then
                PlayDance(danceName)
            else
                StopDance(danceName)
            end
        end,
    }):AddKeyPicker(keyName, {
        Default = '',
        Mode = 'Toggle',
        Text = danceName .. ' Dance',
        NoUI = false,
        SyncToggleState = false,
        Callback = function()
            if UserInputService:GetFocusedTextBox() then
                return
            end
            if not Toggles[danceName .. 'Toggle'].Value then
                return
            end

            if CurrentDanceTracks[danceName] then
                StopDance(danceName)
            else
                PlayDance(danceName)
            end
        end,
    })
end

AddDanceToggle('Floss', 'Floss')
AddDanceToggle('Hyper Flex', 'HyperDance')
AddDanceToggle('Yung Blud', 'YungBlud')

CustomDanceId = ''
CurrentDanceTracks = {}

preventDefaultWalk = false
removeAnimConn = nil
animPlayedConn = nil
legsAnchored = false
player = game.Players.LocalPlayer

Tab1:AddToggle('DisableDefaultWalking', {
    Text = 'Freeze Character',
    Default = false,
    Callback = function(state)
        preventDefaultWalk = state
        local char = player.Character
        if not char then
            return
        end
        local defaultAnimateScript = char:FindFirstChild('Animate')

        if preventDefaultWalk then
            if defaultAnimateScript then
                defaultAnimateScript.Disabled = true
            end
        else
            if defaultAnimateScript then
                defaultAnimateScript.Disabled = false
            end
            if currentEmoteTrack then
                currentEmoteTrack:Stop()
                currentEmoteTrack = nil
            end
        end
    end,
})

animationPackFunction = nil
animationPackActive = false

function AnimationPack(Character)
    repeat
        wait()
    until game:IsLoaded()
        and Character:FindFirstChild('FULLY_LOADED_CHAR')
        and game.Players.LocalPlayer.PlayerGui.MainScreenGui:FindFirstChild(
            'AnimationPack'
        )
        and game.Players.LocalPlayer.PlayerGui.MainScreenGui:FindFirstChild(
            'AnimationPlusPack'
        )

    local Animations = game.ReplicatedStorage.ClientAnimations

    local toRemove = {
        'Lean',
        'Lay',
        'Dance1',
        'Dance2',
        'Greet',
        'Chest Pump',
        'Praying',
        'TheDefault',
        'Sturdy',
        'Rossy',
        'Griddy',
        'TPose',
        'SpeedBlitz',
    }
    for _, name in pairs(toRemove) do
        local anim = Animations:FindFirstChild(name)
        if anim then
            anim:Destroy()
        end
    end

    local newAnims = {
        Lean = 'rbxassetid://3152375249',
        Lay = 'rbxassetid://3152378852',
        Dance1 = 'rbxassetid://3189773368',
        Dance2 = 'rbxassetid://3189776546',
        Greet = 'rbxassetid://3189777795',
        ['Chest Pump'] = 'rbxassetid://3189779152',
        Praying = 'rbxassetid://3487719500',
        TheDefault = 'rbxassetid://11710529975',
        Sturdy = 'rbxassetid://11710524717',
        Rossy = 'rbxassetid://11710527244',
        Griddy = 'rbxassetid://11710529220',
        TPose = 'rbxassetid://11710524200',
        SpeedBlitz = 'rbxassetid://11710541744',
    }

    for name, id in pairs(newAnims) do
        local anim = Instance.new('Animation', Animations)
        anim.Name = name
        anim.AnimationId = id
    end

    local player = game.Players.LocalPlayer
    local guiMain = player.PlayerGui.MainScreenGui
    local AnimationPackGui = guiMain.AnimationPack
    local AnimationPackPlusGui = guiMain.AnimationPlusPack

    AnimationPackGui.Visible = true
    AnimationPackPlusGui.Visible = true

    local humanoid = Character:WaitForChild('Humanoid')

    local loadedAnims = {}
    for name, _ in pairs(newAnims) do
        loadedAnims[name] =
            humanoid:LoadAnimation(Animations:WaitForChild(name))
    end

    local function RenameButtons(frame)
        for _, v in pairs(frame:GetChildren()) do
            if v:IsA('TextButton') then
                local cleanName = v.Text
                    :gsub(' ', '')
                    :gsub('TheDefault', 'TheDefault')
                    :gsub('TPose', 'TPose')
                v.Name = cleanName .. 'Button'
            end
        end
    end

    RenameButtons(AnimationPackGui.ScrollingFrame)
    RenameButtons(AnimationPackPlusGui.ScrollingFrame)

    local function StopAll()
        for _, anim in pairs(loadedAnims) do
            anim:Stop()
        end
    end

    local function ConnectButton(frame, animName)
        local button = frame:FindFirstChild(animName .. 'Button')
        if button and loadedAnims[animName] then
            button.MouseButton1Click:Connect(function()
                StopAll()
                loadedAnims[animName]:Play()
            end)
        end
    end

    for name, _ in pairs(newAnims) do
        ConnectButton(AnimationPackGui.ScrollingFrame, name)
        ConnectButton(AnimationPackPlusGui.ScrollingFrame, name)
    end

    AnimationPackGui.MouseButton1Click:Connect(function()
        if not AnimationPackGui.ScrollingFrame.Visible then
            AnimationPackGui.ScrollingFrame.Visible = true
            AnimationPackGui.CloseButton.Visible = true
            AnimationPackPlusGui.Visible = false
        end
    end)
    AnimationPackPlusGui.MouseButton1Click:Connect(function()
        if not AnimationPackPlusGui.ScrollingFrame.Visible then
            AnimationPackPlusGui.ScrollingFrame.Visible = true
            AnimationPackPlusGui.CloseButton.Visible = true
            AnimationPackGui.Visible = false
        end
    end)
    AnimationPackGui.CloseButton.MouseButton1Click:Connect(function()
        if AnimationPackGui.ScrollingFrame.Visible then
            AnimationPackGui.ScrollingFrame.Visible = false
            AnimationPackGui.CloseButton.Visible = false
            AnimationPackPlusGui.Visible = true
        end
    end)
    AnimationPackPlusGui.CloseButton.MouseButton1Click:Connect(function()
        if AnimationPackPlusGui.ScrollingFrame.Visible then
            AnimationPackPlusGui.ScrollingFrame.Visible = false
            AnimationPackPlusGui.CloseButton.Visible = false
            AnimationPackGui.Visible = true
        end
    end)

    humanoid.Running:Connect(StopAll)
    player.CharacterAdded:Connect(function(newChar)
        StopAll()
        AnimationPack(newChar)
    end)
end

function EnableAnimationPack()
    if animationPackActive then
        return
    end
    local player = game.Players.LocalPlayer
    animationPackActive = true
    AnimationPack(player.Character)
end

function DisableAnimationPack()
    if not animationPackActive then
        return
    end
    local player = game.Players.LocalPlayer
    local humanoid = player.Character
        and player.Character:FindFirstChildOfClass('Humanoid')
    if humanoid then
        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
            track:Stop()
        end
    end
    local gui = player.PlayerGui.MainScreenGui:FindFirstChild('AnimationPack')
    if gui then
        gui.Visible = false
    end
    local guiPlus =
        player.PlayerGui.MainScreenGui:FindFirstChild('AnimationPlusPack')
    if guiPlus then
        guiPlus.Visible = false
    end
    animationPackActive = false
end

player = game.Players.LocalPlayer

targetAnimSpeed = 1
isEnabled = false

function calculateSpeed(value)
    if value >= 0 then
        return math.max(value, 0.01)
    else
        return 1 / math.abs(value)
    end
end

function updateAnimationSpeed(humanoid)
    local speed = calculateSpeed(targetAnimSpeed)
    for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
        track:AdjustSpeed(speed)
    end
end

function setupAnimator(humanoid)
    local animator = humanoid:FindFirstChildOfClass('Animator')
    if animator and not animPlayedConn then
        animPlayedConn = animator.AnimationPlayed:Connect(function(track)
            if isEnabled then
                track:AdjustSpeed(calculateSpeed(targetAnimSpeed))
            end
        end)
    end
end

Tab1:AddToggle('AnimSpeedBoost', {
    Text = 'Fast Animations',
    Default = false,
    Callback = function(state)
        local char = player.Character or player.CharacterAdded:Wait()
        local humanoid = char:FindFirstChildOfClass('Humanoid')
        if not humanoid then
            return
        end

        isEnabled = state
        setupAnimator(humanoid)

        if isEnabled then
            updateAnimationSpeed(humanoid)
        else
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                track:AdjustSpeed(1)
            end
        end
    end,
})

Tab1:AddSlider('AnimSpeedMultiplier', {
    Text = 'Animation Speed Multiplier',
    Default = 1,
    Min = -10,
    Max = 1000,
    Rounding = 0,
    Callback = function(value)
        targetAnimSpeed = value
        if isEnabled then
            local char = player.Character or player.CharacterAdded:Wait()
            local humanoid = char:FindFirstChildOfClass('Humanoid')
            if humanoid then
                updateAnimationSpeed(humanoid)
            end
        end
    end,
})

Tab1:AddInput('CustomDanceInput', {
    Text = 'Custom Dance Emote',
    Default = '',
    Numeric = true,
    Placeholder = 'Enter AnimationClip ID',
    Callback = function(value)
        CustomDanceId = value
    end,
})

Tab1:AddButton('Play Custom Dance', function()
    if CustomDanceId == '' or not tonumber(CustomDanceId) then
        warn('Invalid AnimationId!')
        return
    end

    local char = player.Character
    if not char then
        return
    end
    local humanoid = char:FindFirstChildOfClass('Humanoid')
    if not humanoid then
        return
    end

    for danceName, track in pairs(CurrentDanceTracks) do
        if track then
            track:Stop()
            track:Destroy()
            CurrentDanceTracks[danceName] = nil
            Tab2:SetToggle(danceName .. 'Toggle', false)
        end
    end

    local anim = Instance.new('Animation')
    anim.AnimationId = 'rbxassetid://' .. CustomDanceId
    local track = humanoid:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Action
    track:Play()
    CurrentDanceTracks['CustomDance'] = track
end)

Tab1:AddButton('Stop Custom Dance', function()
    local track = CurrentDanceTracks['CustomDance']
    if track then
        track:Stop()
        track:Destroy()
        CurrentDanceTracks['CustomDance'] = nil
    end
end)

KeepOnDeath = false

AnimationOptions = {
    ['Idle1'] = 'http://www.roblox.com/asset/?id=180435571',
    ['Idle2'] = 'http://www.roblox.com/asset/?id=180435792',
    ['Walk'] = 'http://www.roblox.com/asset/?id=180426354',
    ['Run'] = 'http://www.roblox.com/asset/?id=180426354',
    ['Jump'] = 'http://www.roblox.com/asset/?id=125750702',
    ['Climb'] = 'http://www.roblox.com/asset/?id=180436334',
    ['Fall'] = 'http://www.roblox.com/asset/?id=180436148',
}

AnimationSets = {
    ['Default'] = {
        idle1 = 'http://www.roblox.com/asset/?id=180435571',
        idle2 = 'http://www.roblox.com/asset/?id=180435792',
        walk = 'http://www.roblox.com/asset/?id=180426354',
        run = 'http://www.roblox.com/asset/?id=180426354',
        jump = 'http://www.roblox.com/asset/?id=125750702',
        climb = 'http://www.roblox.com/asset/?id=180436334',
        fall = 'http://www.roblox.com/asset/?id=180436148',
    },
    ['Ninja'] = {
        idle1 = 'http://www.roblox.com/asset/?id=656117400',
        idle2 = 'http://www.roblox.com/asset/?id=656118341',
        walk = 'http://www.roblox.com/asset/?id=656121766',
        run = 'http://www.roblox.com/asset/?id=656118852',
        jump = 'http://www.roblox.com/asset/?id=656117878',
        climb = 'http://www.roblox.com/asset/?id=656114359',
        fall = 'http://www.roblox.com/asset/?id=656115606',
    },
    ['Superhero'] = {
        idle1 = 'http://www.roblox.com/asset/?id=616111295',
        idle2 = 'http://www.roblox.com/asset/?id=616113536',
        walk = 'http://www.roblox.com/asset/?id=616122287',
        run = 'http://www.roblox.com/asset/?id=616117076',
        jump = 'http://www.roblox.com/asset/?id=616115533',
        climb = 'http://www.roblox.com/asset/?id=616104706',
        fall = 'http://www.roblox.com/asset/?id=616108001',
    },
    ['Robot'] = {
        idle1 = 'http://www.roblox.com/asset/?id=616088211',
        idle2 = 'http://www.roblox.com/asset/?id=616089559',
        walk = 'http://www.roblox.com/asset/?id=616095330',
        run = 'http://www.roblox.com/asset/?id=616091570',
        jump = 'http://www.roblox.com/asset/?id=616090535',
        climb = 'http://www.roblox.com/asset/?id=616086039',
        fall = 'http://www.roblox.com/asset/?id=616087089',
    },
    ['Cartoon'] = {
        idle1 = 'http://www.roblox.com/asset/?id=742637544',
        idle2 = 'http://www.roblox.com/asset/?id=742638445',
        walk = 'http://www.roblox.com/asset/?id=742640026',
        run = 'http://www.roblox.com/asset/?id=742638842',
        jump = 'http://www.roblox.com/asset/?id=742637942',
        climb = 'http://www.roblox.com/asset/?id=742636889',
        fall = 'http://www.roblox.com/asset/?id=742637151',
    },
    ['Catwalk'] = {
        idle1 = 'http://www.roblox.com/asset/?id=133806214992291',
        idle2 = 'http://www.roblox.com/asset/?id=94970088341563',
        walk = 'http://www.roblox.com/asset/?id=109168724482748',
        run = 'http://www.roblox.com/asset/?id=81024476153754',
        jump = 'http://www.roblox.com/asset/?id=116936326516985',
        climb = 'http://www.roblox.com/asset/?id=119377220967554',
        fall = 'http://www.roblox.com/asset/?id=92294537340807',
    },
    ['Zombie'] = {
        idle1 = 'http://www.roblox.com/asset/?id=616158929',
        idle2 = 'http://www.roblox.com/asset/?id=616160636',
        walk = 'http://www.roblox.com/asset/?id=616168032',
        run = 'http://www.roblox.com/asset/?id=616163682',
        jump = 'http://www.roblox.com/asset/?id=616161997',
        climb = 'http://www.roblox.com/asset/?id=616156119',
        fall = 'http://www.roblox.com/asset/?id=616157476',
    },
    ['Mage'] = {
        idle1 = 'http://www.roblox.com/asset/?id=707742142',
        idle2 = 'http://www.roblox.com/asset/?id=707855907',
        walk = 'http://www.roblox.com/asset/?id=707897309',
        run = 'http://www.roblox.com/asset/?id=707861613',
        jump = 'http://www.roblox.com/asset/?id=707853694',
        climb = 'http://www.roblox.com/asset/?id=707826056',
        fall = 'http://www.roblox.com/asset/?id=707829716',
    },
    ['Pirate'] = {
        idle1 = 'http://www.roblox.com/asset/?id=750785693',
        idle2 = 'http://www.roblox.com/asset/?id=750782770',
        walk = 'http://www.roblox.com/asset/?id=750785693',
        run = 'http://www.roblox.com/asset/?id=750782770',
        jump = 'http://www.roblox.com/asset/?id=750782770',
        climb = 'http://www.roblox.com/asset/?id=750782770',
        fall = 'http://www.roblox.com/asset/?id=750782770',
    },
    ['Knight'] = {
        idle1 = 'http://www.roblox.com/asset/?id=657595757',
        idle2 = 'http://www.roblox.com/asset/?id=657568135',
        walk = 'http://www.roblox.com/asset/?id=657552124',
        run = 'http://www.roblox.com/asset/?id=657564596',
        jump = 'http://www.roblox.com/asset/?id=657560148',
        climb = 'http://www.roblox.com/asset/?id=657556206',
        fall = 'http://www.roblox.com/asset/?id=657552124',
    },
    ['Vampire'] = {
        idle1 = 'http://www.roblox.com/asset/?id=1083465857',
        idle2 = 'http://www.roblox.com/asset/?id=1083465857',
        walk = 'http://www.roblox.com/asset/?id=1083465857',
        run = 'http://www.roblox.com/asset/?id=1083465857',
        jump = 'http://www.roblox.com/asset/?id=1083465857',
        climb = 'http://www.roblox.com/asset/?id=1083465857',
        fall = 'http://www.roblox.com/asset/?id=1083465857',
    },
    ['Bubbly'] = {
        idle1 = 'http://www.roblox.com/asset/?id=910004836',
        idle2 = 'http://www.roblox.com/asset/?id=910009958',
        walk = 'http://www.roblox.com/asset/?id=910034870',
        run = 'http://www.roblox.com/asset/?id=910025107',
        jump = 'http://www.roblox.com/asset/?id=910016857',
        climb = 'http://www.roblox.com/asset/?id=910009958',
        fall = 'http://www.roblox.com/asset/?id=910009958',
    },
    ['Elder'] = {
        idle1 = 'http://www.roblox.com/asset/?id=845386501',
        idle2 = 'http://www.roblox.com/asset/?id=845397899',
        walk = 'http://www.roblox.com/asset/?id=845403856',
        run = 'http://www.roblox.com/asset/?id=845386501',
        jump = 'http://www.roblox.com/asset/?id=845386501',
        climb = 'http://www.roblox.com/asset/?id=845386501',
        fall = 'http://www.roblox.com/asset/?id=845386501',
    },
    ['Toy'] = {
        idle1 = 'http://www.roblox.com/asset/?id=782841498',
        idle2 = 'http://www.roblox.com/asset/?id=782841498',
        walk = 'http://www.roblox.com/asset/?id=782841498',
        run = 'http://www.roblox.com/asset/?id=782841498',
        jump = 'http://www.roblox.com/asset/?id=782841498',
        climb = 'http://www.roblox.com/asset/?id=782841498',
        fall = 'http://www.roblox.com/asset/?id=782841498',
    },
}

function applyCustomAnimations(character)
    if not character then
        return
    end

    local Animate = character:FindFirstChild('Animate')
    if not Animate then
        return
    end

    local ClonedAnimate = Animate:Clone()

    ClonedAnimate.idle.Animation1.AnimationId = AnimationOptions['Idle1']
    ClonedAnimate.idle.Animation2.AnimationId = AnimationOptions['Idle2']
    ClonedAnimate.walk.WalkAnim.AnimationId = AnimationOptions['Walk']
    ClonedAnimate.run.RunAnim.AnimationId = AnimationOptions['Run']
    ClonedAnimate.jump.JumpAnim.AnimationId = AnimationOptions['Jump']
    ClonedAnimate.climb.ClimbAnim.AnimationId = AnimationOptions['Climb']
    ClonedAnimate.fall.FallAnim.AnimationId = AnimationOptions['Fall']

    Animate:Destroy()
    ClonedAnimate.Parent = character
end

LocalPlayer.CharacterAdded:Connect(function(character)
    if KeepOnDeath then
        task.wait(1)
        applyCustomAnimations(character)
    end
end)

animationNames = {
    'Default',
    'Ninja',
    'Superhero',
    'Robot',
    'Cartoon',
    'Catwalk',
    'Zombie',
    'Mage',
    'Pirate',
    'Knight',
    'Vampire',
    'Bubbly',
    'Elder',
    'Toy',
}

Tab2:AddDropdown('Idle1Dropdown', {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = 'Idle1',
    Callback = function(Value)
        AnimationOptions['Idle1'] = AnimationSets[Value].idle1
        applyCustomAnimations(LocalPlayer.Character)
    end,
})

Tab2:AddDropdown('Idle2Dropdown', {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = 'Idle2',
    Callback = function(Value)
        AnimationOptions['Idle2'] = AnimationSets[Value].idle2
        applyCustomAnimations(LocalPlayer.Character)
    end,
})

Tab2:AddDropdown('WalkDropdown', {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = 'Walk',
    Callback = function(Value)
        AnimationOptions['Walk'] = AnimationSets[Value].walk
        applyCustomAnimations(LocalPlayer.Character)
    end,
})

Tab2:AddDropdown('RunDropdown', {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = 'Run',
    Callback = function(Value)
        AnimationOptions['Run'] = AnimationSets[Value].run
        applyCustomAnimations(LocalPlayer.Character)
    end,
})

Tab2:AddDropdown('JumpDropdown', {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = 'Jump',
    Callback = function(Value)
        AnimationOptions['Jump'] = AnimationSets[Value].jump
        applyCustomAnimations(LocalPlayer.Character)
    end,
})

Tab2:AddDropdown('ClimbDropdown', {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = 'Climb',
    Callback = function(Value)
        AnimationOptions['Climb'] = AnimationSets[Value].climb
        applyCustomAnimations(LocalPlayer.Character)
    end,
})

Tab2:AddDropdown('FallDropdown', {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = 'Fall',
    Callback = function(Value)
        AnimationOptions['Fall'] = AnimationSets[Value].fall
        applyCustomAnimations(LocalPlayer.Character)
    end,
})

Tab2:AddToggle('MyToggle', {
    Text = 'Keep On Death',
    Default = false,
    Callback = function(Value)
        KeepOnDeath = Value
    end,
})

Tab2:AddToggle('AnimationPack', {
    Text = 'Animation Packs',
    Default = false,
    Callback = function(state)
        if state then
            EnableAnimationPack()
        else
            DisableAnimationPack()
        end
    end,
})

BetaGroup = PlayerTab:AddRightGroupbox('Hitbox Expander')

hitboxEnabled = false
hitboxExpanderEnabled = false
hitboxSize = 5
autoDisableOnLowHP = false
disableOnKnocked = false
performanceMode = false
streamableMode = false

originalSizes = {}
lowHealthPlayers = {}
knockedPlayers = {}

function resetHitbox(hrp, player)
    if originalSizes[player] then
        hrp.Size = originalSizes[player]
        hrp.Transparency = 1
        hrp.Material = Enum.Material.Plastic
        hrp.BrickColor = BrickColor.new('Medium stone grey')
        hrp.CanCollide = true
    end
end

function updateHitboxes()
    for _, player in ipairs(Players:GetPlayers()) do
        if
            player ~= LocalPlayer
            and player.Character
            and player.Character:FindFirstChild('HumanoidRootPart')
            and player.Character:FindFirstChild('Humanoid')
        then
            local hrp = player.Character.HumanoidRootPart
            local humanoid = player.Character.Humanoid
            local bodyEffects = player.Character:FindFirstChild('BodyEffects')
            local koValue = bodyEffects and bodyEffects:FindFirstChild('K.O')

            if autoDisableOnLowHP and humanoid.Health <= 8 then
                lowHealthPlayers[player] = true
                resetHitbox(hrp, player)
            elseif disableOnKnocked and koValue and koValue.Value == true then
                knockedPlayers[player] = true
                resetHitbox(hrp, player)
            else
                lowHealthPlayers[player] = nil
                knockedPlayers[player] = nil

                if hitboxEnabled and hitboxExpanderEnabled then
                    if not originalSizes[player] then
                        originalSizes[player] = hrp.Size
                    end

                    hrp.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)

                    if streamableMode then
                        hrp.Transparency = 1
                        hrp.Material = Enum.Material.Plastic
                        hrp.BrickColor = BrickColor.new('Medium stone grey')
                        hrp.CanCollide = true
                    else
                        hrp.Transparency = 0.5
                        hrp.Material = Enum.Material.ForceField
                        hrp.BrickColor = BrickColor.new('Institutional white')
                        hrp.CanCollide = false
                    end
                else
                    resetHitbox(hrp, player)
                end
            end
        end
    end
end

performanceUpdateTimer = 0
RunService.RenderStepped:Connect(function(dt)
    if performanceMode then
        performanceUpdateTimer = performanceUpdateTimer + dt
        if performanceUpdateTimer >= 0.2 then
            pcall(updateHitboxes)
            performanceUpdateTimer = 0
        end
    else
        pcall(updateHitboxes)
    end
end)

hitboxExpanderBind = BetaGroup:AddToggle('HitboxToggle', {
    Text = 'Enable',
    Default = false,
    Callback = function(value)
        hitboxEnabled = value
        hitboxExpanderEnabled = value
        streamableMode = false
    end,
}):AddKeyPicker('HitboxExpanderBind', {
    Default = '',
    Mode = 'Toggle',
    Text = 'Hitbox Expander',
    NoUI = false,
    SyncToggleState = false,
    Callback = function(state)
        if UserInputService:GetFocusedTextBox() then
            hitboxExpanderBind:SetValue(false)
            hitboxExpanderEnabled = false
            return
        end

        if hitboxEnabled then
            hitboxExpanderEnabled = state
        else
            hitboxExpanderBind:SetValue(false)
            hitboxExpanderEnabled = false
        end
    end,
})

BetaGroup:AddToggle('StreamableMode', {
    Text = 'Streamable',
    Default = false,
    Callback = function(value)
        streamableMode = value
    end,
})

BetaGroup:AddToggle('PerformanceMode', {
    Text = 'Performance Mode',
    Default = false,
    Callback = function(value)
        performanceMode = value
    end,
})

BetaGroup:AddToggle('AutoDisableLowHP', {
    Text = 'Disable on Low HP',
    Default = false,
    Callback = function(value)
        autoDisableOnLowHP = value
    end,
})

BetaGroup:AddToggle('DisableOnKnocked', {
    Text = 'Disable on Knocked',
    Default = false,
    Callback = function(value)
        disableOnKnocked = value
    end,
})

BetaGroup:AddSlider('HitboxSlider', {
    Text = 'Hitbox Size',
    Min = 1,
    Max = 25,
    Default = 5,
    Rounding = 0,
    Compact = false,
    Callback = function(value)
        hitboxSize = value
    end,
})

BetaaGroup = PlayerTab:AddLeftGroupbox('Tool Pos')

offsetEnabled = false
offsetX, offsetY, offsetZ = 0, 0, 0

BetaaGroup:AddToggle('Enable', {
    Text = 'Enable',
    Default = false,
}):OnChanged(function(v)
    offsetEnabled = v

    if not v then
        local char = LocalPlayer.Character
        if char then
            local rightHand = char:FindFirstChild('RightHand')
                or char:FindFirstChild('Right Arm')
            if rightHand then
                local cg = rightHand:FindFirstChild('CustomGrip')
                if cg then
                    cg:Destroy()
                end
            end
        end
    end
end)

BetaaGroup:AddSlider('Tool_X', {
    Text = 'Custom X',
    Default = 0,
    Min = -99,
    Max = 100,
    Rounding = 1,
}):OnChanged(function(v)
    offsetX = v
end)

BetaaGroup:AddSlider('Tool_Y', {
    Text = 'Custom Y',
    Default = 0,
    Min = -99,
    Max = 100,
    Rounding = 1,
}):OnChanged(function(v)
    offsetY = v
end)

BetaaGroup:AddSlider('Tool_Z', {
    Text = 'Custom Z',
    Default = 0,
    Min = -99,
    Max = 100,
    Rounding = 1,
}):OnChanged(function(v)
    offsetZ = v
end)

function getRightHand(char)
    return char
        and (
            char:FindFirstChild('RightHand')
            or char:FindFirstChild('Right Arm')
        )
end

function setupManualWeld(tool)
    local char = LocalPlayer.Character
    if not char then
        return
    end

    local rightHand = getRightHand(char)
    local handle = tool and tool:FindFirstChild('Handle')
    if not (rightHand and handle) then
        return
    end

    local grip = rightHand:FindFirstChild('RightGrip')
    if grip then
        grip:Destroy()
    end

    local old = rightHand:FindFirstChild('CustomGrip')
    if old then
        old:Destroy()
    end

    local weld = Instance.new('Weld')
    weld.Name = 'CustomGrip'
    weld.Part0 = rightHand
    weld.Part1 = handle
    weld.C0 = CFrame.new(offsetX, offsetY, offsetZ)
    weld.Parent = rightHand
end

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then
        return
    end

    local rightHand = getRightHand(char)
    if not rightHand then
        return
    end

    local tool = char:FindFirstChildOfClass('Tool')
    if not tool then
        local cg = rightHand:FindFirstChild('CustomGrip')
        if cg then
            cg:Destroy()
        end
        return
    end

    if not offsetEnabled then
        return
    end

    local handle = tool:FindFirstChild('Handle')
    if not handle then
        return
    end

    local existingWeld = rightHand:FindFirstChild('CustomGrip')

    if existingWeld then
        if existingWeld.Part1 ~= handle or existingWeld.Part0 ~= rightHand then
            existingWeld:Destroy()
            setupManualWeld(tool)
        else
            existingWeld.C0 = CFrame.new(offsetX, offsetY, offsetZ)
        end
    else
        setupManualWeld(tool)
    end
end)

EspGroup = VisualsTab:AddLeftGroupbox('ESP')

espActive = false
rainbowESP = false
fadingESP = false

espModes = {
    ['Names'] = false,
    ['Distance'] = false,
    ['Chams'] = false,
    ['Tracers'] = false,
    ['Box'] = false,
    ['HealthBar'] = false,
}

espColors = {
    ['Names'] = {
        Color1 = Color3.fromRGB(255, 255, 255),
        Color2 = Color3.fromRGB(255, 255, 255),
    },
    ['Distance'] = {
        Color1 = Color3.fromRGB(255, 255, 255),
        Color2 = Color3.fromRGB(255, 255, 255),
    },
    ['Chams'] = {
        Color1 = Color3.fromRGB(255, 255, 255),
        Color2 = Color3.fromRGB(255, 255, 255),
    },
    ['Tracers'] = {
        Color1 = Color3.fromRGB(255, 255, 255),
        Color2 = Color3.fromRGB(255, 255, 255),
    },
    ['Box'] = {
        Color1 = Color3.fromRGB(255, 255, 255),
        Color2 = Color3.fromRGB(255, 255, 255),
    },
    ['HealthBar'] = {
        Color1 = Color3.fromRGB(0, 255, 0),
        Color2 = Color3.fromRGB(255, 255, 255),
    },
}

espObjects = {}

function color3ToHex(color)
    return string.format(
        '#%02X%02X%02X',
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
end

function getRainbowColor()
    local hue = (tick() * 60) % 360 / 360
    return Color3.fromHSV(hue, 1, 1)
end

function getFadingAlpha()
    return (math.sin(tick() * 2) + 1) / 2
end

function applyEffects(color1, color2)
    local finalColor = Color3.new(
        (color1.R + color2.R) / 2,
        (color1.G + color2.G) / 2,
        (color1.B + color2.B) / 2
    )
    if rainbowESP then
        finalColor = getRainbowColor()
    end
    local alpha = 1
    if fadingESP then
        alpha = getFadingAlpha()
    end
    return finalColor, alpha
end

function clearESPForPlayer(player)
    local objs = espObjects[player.UserId]
    if objs then
        if objs.LabelGui then
            objs.LabelGui:Destroy()
        end
        if objs.Highlight then
            objs.Highlight:Destroy()
        end
        if objs.TracerLine then
            objs.TracerLine.Visible = false
            objs.TracerLine:Remove()
        end
        if objs.Box then
            objs.Box:Remove()
        end
        if objs.BoxOutline then
            objs.BoxOutline:Remove()
        end
        if objs.HealthBar then
            objs.HealthBar:Remove()
        end
        if objs.HealthBarOutline then
            objs.HealthBarOutline:Remove()
        end
        espObjects[player.UserId] = nil
    end
end

function clearAllESP()
    for _, player in pairs(Players:GetPlayers()) do
        clearESPForPlayer(player)
    end
end

function createBoxObjects(userId)
    local outline = Drawing.new('Square')
    outline.Visible = false
    outline.Color = Color3.new(0, 0, 0)
    outline.Thickness = 2
    outline.Filled = false

    local box = Drawing.new('Square')
    box.Visible = false
    box.Color = espColors['Box'].Color1
    box.Thickness = 1
    box.Filled = false
    box.Transparency = 1

    local hbOutline = Drawing.new('Square')
    hbOutline.Visible = false
    hbOutline.Color = Color3.new(0, 0, 0)
    hbOutline.Thickness = 2
    hbOutline.Filled = false

    local hb = Drawing.new('Square')
    hb.Visible = false
    hb.Color = espColors['HealthBar'].Color1
    hb.Thickness = 1
    hb.Filled = true
    hb.Transparency = 1

    espObjects[userId].BoxOutline = outline
    espObjects[userId].Box = box
    espObjects[userId].HealthBarOutline = hbOutline
    espObjects[userId].HealthBar = hb
end

function applyChams(player)
    local function attach()
        if not espModes['Chams'] or not espActive then
            return
        end
        if not player.Character then
            return
        end
        local old = player.Character:FindFirstChild('ESP_Chams')
        if old then
            old:Destroy()
        end

        local hl = Instance.new('Highlight')
        hl.Name = 'ESP_Chams'
        hl.Adornee = player.Character
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillColor = espColors['Chams'].Color1
        hl.FillTransparency = 0.5
        hl.OutlineColor = Color3.new(0, 0, 0)
        hl.OutlineTransparency = 0
        hl.Parent = player.Character
        espObjects[player.UserId].Highlight = hl
    end
    attach()
    player.CharacterAdded:Connect(function()
        task.wait(0.2)
        attach()
    end)
end

function createESPForPlayer(player)
    if player == LocalPlayer then
        return
    end
    clearESPForPlayer(player)
    espObjects[player.UserId] = {}

    local screenGui = Instance.new('ScreenGui')
    screenGui.Name = 'ESP_GUI_' .. player.Name
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    screenGui.Parent = game.CoreGui

    local label = Instance.new('TextLabel')
    label.Size = UDim2.new(0, 150, 0, 50)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Code
    label.TextSize = 14
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Text = ''
    label.RichText = true
    label.Visible = false
    label.Parent = screenGui

    espObjects[player.UserId].LabelGui = screenGui
    espObjects[player.UserId].Label = label

    if espModes['Chams'] then
        applyChams(player)
    end
    if espModes['Tracers'] then
        local line = Drawing.new('Line')
        line.Thickness = 1.5
        line.Transparency = 1
        line.Color = espColors['Tracers'].Color1
        line.Visible = false
        espObjects[player.UserId].TracerLine = line
    end
    if espModes['Box'] or espModes['HealthBar'] then
        createBoxObjects(player.UserId)
    end
end

function updateESPForPlayer(player)
    local objs = espObjects[player.UserId]
    if not objs then
        return
    end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass('Humanoid')
    local rootPart = character
        and (
            character:FindFirstChild('UpperTorso')
            or character:FindFirstChild('HumanoidRootPart')
        )
    if not rootPart then
        if objs.Label then
            objs.Label.Visible = false
        end
        if objs.TracerLine then
            objs.TracerLine.Visible = false
        end
        if objs.Highlight then
            objs.Highlight.Enabled = false
        end
        if objs.Box then
            objs.Box.Visible = false
        end
        if objs.BoxOutline then
            objs.BoxOutline.Visible = false
        end
        if objs.HealthBar then
            objs.HealthBar.Visible = false
        end
        if objs.HealthBarOutline then
            objs.HealthBarOutline.Visible = false
        end
        return
    end

    local nameDistanceScreenPos, nameDistanceOnScreen =
        Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 2.5, 0))
    local boxScreenPos, boxOnScreen =
        Camera:WorldToViewportPoint(rootPart.Position)
    if not nameDistanceOnScreen and not boxOnScreen then
        if objs.Label then
            objs.Label.Visible = false
        end
        if objs.TracerLine then
            objs.TracerLine.Visible = false
        end
        if objs.Highlight then
            objs.Highlight.Enabled = false
        end
        if objs.Box then
            objs.Box.Visible = false
        end
        if objs.BoxOutline then
            objs.BoxOutline.Visible = false
        end
        if objs.HealthBar then
            objs.HealthBar.Visible = false
        end
        if objs.HealthBarOutline then
            objs.HealthBarOutline.Visible = false
        end
        return
    end

    local dist = (Camera.CFrame.Position - rootPart.Position).Magnitude
    local info = ''
    if espModes['Names'] then
        local c, a =
            applyEffects(espColors['Names'].Color1, espColors['Names'].Color2)
        objs.Label.TextColor3 = c
        objs.Label.TextTransparency = 1 - a
        info = info
            .. string.format(
                '<font color="%s">%s</font>\n',
                color3ToHex(c),
                player.DisplayName
            )
    end
    if espModes['Distance'] then
        local c, a = applyEffects(
            espColors['Distance'].Color1,
            espColors['Distance'].Color2
        )
        info = info
            .. string.format(
                '<font color="%s">Dist: %.1f m</font>\n',
                color3ToHex(c),
                dist
            )
    end
    if objs.Label then
        objs.Label.Text = info
        objs.Label.Position = UDim2.new(
            0,
            nameDistanceScreenPos.X - 75,
            0,
            nameDistanceScreenPos.Y - 30
        )
        objs.Label.Visible = info ~= ''
    end

    local head = character:FindFirstChild('Head')
    if head and (espModes['Box'] or espModes['HealthBar']) and objs.Box then
        local topOffset = Vector3.new(0, 1, 0)
        local bottomOffset = Vector3.new(0, -2, 0)
        local headPos = Camera:WorldToViewportPoint(head.Position + topOffset)
        local legPos =
            Camera:WorldToViewportPoint(rootPart.Position + bottomOffset)
        local height = headPos.Y - legPos.Y
        local width = 2500 / boxScreenPos.Z

        local boxColor, alpha =
            applyEffects(espColors['Box'].Color1, espColors['Box'].Color2)
        objs.Box.Size = Vector2.new(width, height)
        objs.Box.Position =
            Vector2.new(boxScreenPos.X - width / 2, boxScreenPos.Y - height / 2)
        objs.Box.Color = boxColor
        objs.Box.Transparency = alpha
        objs.Box.Visible = espModes['Box']

        objs.BoxOutline.Size = objs.Box.Size
        objs.BoxOutline.Position = objs.Box.Position
        objs.BoxOutline.Visible = espModes['Box']

        if espModes['HealthBar'] and humanoid then
            local hbHeight = height * (humanoid.Health / humanoid.MaxHealth)
            local hbColor, alpha2 = applyEffects(
                espColors['HealthBar'].Color1,
                espColors['HealthBar'].Color2
            )
            objs.HealthBar.Size = Vector2.new(2, hbHeight)
            objs.HealthBar.Position = Vector2.new(
                objs.Box.Position.X - 5,
                objs.Box.Position.Y + (height - hbHeight)
            )
            objs.HealthBar.Color = hbColor
            objs.HealthBar.Transparency = alpha2
            objs.HealthBar.Visible = true

            objs.HealthBarOutline.Size = Vector2.new(2, height)
            objs.HealthBarOutline.Position =
                Vector2.new(objs.Box.Position.X - 5, objs.Box.Position.Y)
            objs.HealthBarOutline.Visible = true
        else
            objs.HealthBar.Visible = false
            objs.HealthBarOutline.Visible = false
        end
    end

    if objs.TracerLine then
        if espModes['Tracers'] then
            local tracerColor, alpha = applyEffects(
                espColors['Tracers'].Color1,
                espColors['Tracers'].Color2
            )
            local screenSize = Camera.ViewportSize
            objs.TracerLine.From = Vector2.new(screenSize.X / 2, screenSize.Y)
            objs.TracerLine.To = Vector2.new(boxScreenPos.X, boxScreenPos.Y)
            objs.TracerLine.Color = tracerColor
            objs.TracerLine.Transparency = alpha
            objs.TracerLine.Visible = true
        else
            objs.TracerLine.Visible = false
        end
    end

    if objs.Highlight and objs.Highlight.Parent then
        if espModes['Chams'] then
            local chamColor, alpha = applyEffects(
                espColors['Chams'].Color1,
                espColors['Chams'].Color2
            )
            objs.Highlight.FillColor = chamColor
            objs.Highlight.FillTransparency = 1 - alpha
            objs.Highlight.Enabled = true
        else
            objs.Highlight.Enabled = false
        end
    end
end

function refreshAllPlayers()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            createESPForPlayer(player)
        end
    end
end

RunService.RenderStepped:Connect(function()
    if not espActive then
        return
    end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            updateESPForPlayer(player)
        end
    end
end)

Players.PlayerRemoving:Connect(clearESPForPlayer)
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if espActive then
            createESPForPlayer(player)
        end
    end)
end)

EspGroup:AddToggle('EnableESP', {
    Text = 'Enable',
    Default = false,
    Callback = function(state)
        espActive = state
        if espActive then
            refreshAllPlayers()
        else
            clearAllESP()
        end
    end,
})

EspGroup:AddToggle('RainbowESP', {
    Text = 'Rainbow',
    Default = false,
    Callback = function(state)
        rainbowESP = state
    end,
})

EspGroup:AddToggle('FadingESP', {
    Text = 'Fading',
    Default = false,
    Callback = function(state)
        fadingESP = state
    end,
})

function CreateESPModeToggle(modeName)
    local toggle = EspGroup:AddToggle(modeName .. 'Toggle', {
        Text = modeName,
        Default = false,
        Callback = function(state)
            espModes[modeName] = state
            if espActive then
                refreshAllPlayers()
            end
        end,
    })
    toggle:AddColorPicker(modeName .. 'Color1', {
        Default = espColors[modeName].Color1,
        Title = modeName .. ' Color 1',
        Callback = function(color)
            espColors[modeName].Color1 = color
        end,
    })
    toggle:AddColorPicker(modeName .. 'Color2', {
        Default = espColors[modeName].Color2,
        Title = modeName .. ' Color 2',
        Callback = function(color)
            espColors[modeName].Color2 = color
        end,
    })
end

CreateESPModeToggle('Names')
CreateESPModeToggle('Distance')
CreateESPModeToggle('Chams')
CreateESPModeToggle('Tracers')
CreateESPModeToggle('Box')
CreateESPModeToggle('HealthBar')

Lighting = game:GetService('Lighting')

TabBox = VisualsTab:AddLeftTabbox()

Tab1 = TabBox:AddTab('World')
Tab2 = TabBox:AddTab('SkyBox')

selectedSoundName = 'Thunder Storm'
backgroundNoisesEnabled = false
volumeValue = 5
rainbowLighting = false

timeControlEnabled = false
currentGameTime = 12
currentSound = nil
customSoundId = nil

soundIDs = {
    ['Thunder Storm'] = 92640524897440,
    ['Light Rain'] = 1516791621,
    ['Morning'] = 6189453706,
    ['Windy Winter'] = 596046130,
    ['Anime Music'] = 88503293218755,
    ['Balerina'] = 70455732863262,
    ['Toma Phonk'] = 97231051040304,
    ['Bitch Pleasure'] = 98680556755606,
    ['Atom Explode'] = 92446468726259,
    ['Cry Sound'] = 7014161416,
    ['Call of Duty'] = 413424521,
    ['Beauty Normal'] = 96760299701814,
    ['Crash keyboard'] = 6735766439,
    ['Annoying'] = 9116270881,
    ['Fuckyall niggers'] = 1843497734,
}

function playSound()
    if currentSound then
        currentSound:Stop()
        currentSound:Destroy()
        currentSound = nil
    end
    if backgroundNoisesEnabled then
        local sound = Instance.new('Sound')
        sound.Looped = true
        sound.Volume = volumeValue
        sound.Name = 'BackgroundNoise'
        sound.Parent = workspace
        if customSoundId and customSoundId ~= '' then
            sound.SoundId = 'rbxassetid://' .. tostring(customSoundId)
        elseif selectedSoundName and soundIDs[selectedSoundName] then
            sound.SoundId = 'rbxassetid://'
                .. tostring(soundIDs[selectedSoundName])
        else
            sound:Destroy()
            return
        end
        sound.Loaded:Connect(function()
            sound:Play()
        end)
        sound:Play()
        currentSound = sound
    end
end

Tab1:AddToggle('BackgroundNoisesToggle', {
    Text = 'Background Noises',
    Default = false,
    Callback = function(value)
        backgroundNoisesEnabled = value
        playSound()
    end,
})

Tab1:AddDropdown('BackgroundSoundDropdown', {
    Values = {
        'Thunder Storm',
        'Light Rain',
        'Morning',
        'Windy Winter',
        'Anime Music',
        'Balerina',
        'Toma Phonk',
        'Bitch Pleasure',
        'Atom Explode',
        'Cry Sound',
        'Call of Duty',
        'Beauty Normal',
        'Crash keyboard',
        'Annoying',
        'Fuckyall niggers',
    },
    Default = 1,
    Multi = false,
    Text = 'Select Sound',
    Callback = function(value)
        selectedSoundName = value
        playSound()
    end,
})

Tab1:AddSlider('VolumeSlider', {
    Text = 'Volume',
    Default = 5,
    Min = 0,
    Max = 10,
    Rounding = 0,
    Compact = false,
    Callback = function(value)
        volumeValue = value
        if currentSound then
            currentSound.Volume = volumeValue
        end
    end,
})

Tab1:AddInput('CustomSoundInput', {
    Text = 'Custom Sound ID',
    Placeholder = 'Assest ID',
    Callback = function(value)
        if value and value ~= '' then
            customSoundId = value
        else
            customSoundId = nil
        end
        playSound()
    end,
})

Tab1:AddToggle('DisableShadows', {
    Text = 'Disable Shadows',
    Callback = function(state)
        Lighting.GlobalShadows = not state
    end,
    Enabled = false,
})

Tab1:AddToggle('RainbowLightning', {
    Text = 'Rainbow Lighting',
    Callback = function(state)
        rainbowLighting = state
    end,
    Enabled = false,
})

cc = Lighting:FindFirstChildOfClass('ColorCorrectionEffect')
if not cc then
    cc = Instance.new('ColorCorrectionEffect')
    cc.Parent = Lighting
end

brightnessValue = Lighting.Brightness
saturationValue = cc.Saturation
contrastValue = cc.Contrast

function round(value)
    return math.floor(value * 100 + 0.5) / 100
end

function setGameTime(timeValue)
    timeValue = math.clamp(timeValue, 0, 24)
    Lighting.ClockTime = timeValue
end

Tab1:AddToggle('TimeControlToggle', {
    Text = 'Enable Time Control',
    Default = false,
    Callback = function(value)
        timeControlEnabled = value
    end,
})

Tab1:AddSlider('TimeSlider', {
    Text = 'Time Clock',
    Min = 0,
    Max = 24,
    Default = currentGameTime,
    Rounding = 2,
    Compact = false,
    Callback = function(value)
        currentGameTime = value
        if timeControlEnabled then
            setGameTime(currentGameTime)
        end
    end,
})

Tab1:AddSlider('Brightness', {
    Text = 'Brightness',
    Min = -1,
    Max = 10,
    Default = brightnessValue,
    Rounding = 1,
    Callback = function(value)
        local mappedValue = round(value)
        Lighting.Brightness = math.clamp(mappedValue, -1, 10)
    end,
})

Tab1:AddSlider('Saturation', {
    Text = 'Saturation',
    Min = -1,
    Max = 10,
    Default = saturationValue,
    Rounding = 1,
    Callback = function(value)
        cc.Saturation = math.clamp(round(value), -1, 10)
    end,
})

Tab1:AddSlider('Contrast', {
    Text = 'Contrast',
    Min = -1,
    Max = 10,
    Default = contrastValue,
    Rounding = 1,
    Callback = function(value)
        cc.Contrast = math.clamp(round(value), -1, 10)
    end,
})

Tab2:AddDropdown('SkyboxDropdown', {
    Values = {
        'Default',
        'Rainy',
        'Space v2',
        'Dahood',
        'Cosmo',
        'Neon',
        'Minecraft',
        'Nightless',
        'Old skybox',
    },
    Default = 1,
    Multi = false,
    Text = 'Skybox',
    Callback = function(value)
        for _, obj in pairs(Lighting:GetChildren()) do
            if obj:IsA('Sky') then
                obj:Destroy()
            end
        end

        if value ~= 'Default' then
            local sky = Instance.new('Sky')

            if value == 'Rainy' then
                sky.SkyboxBk = 'rbxassetid://1666456837'
                sky.SkyboxDn = 'rbxassetid://1666455881'
                sky.SkyboxFt = 'rbxassetid://1666457447'
                sky.SkyboxLf = 'rbxassetid://1666455318'
                sky.SkyboxRt = 'rbxassetid://1666456385'
                sky.SkyboxUp = 'rbxassetid://1666458034'
            elseif value == 'Space v2' then
                sky.SkyboxBk = 'rbxassetid://76948125119932'
                sky.SkyboxDn = 'rbxassetid://117865148129754'
                sky.SkyboxFt = 'rbxassetid://77181996912050'
                sky.SkyboxLf = 'rbxassetid://130317898320211'
                sky.SkyboxRt = 'rbxassetid://105669495538162'
                sky.SkyboxUp = 'rbxassetid://128363212769327'
            elseif value == 'Dahood' then
                sky.SkyboxBk = 'rbxassetid://600830446'
                sky.SkyboxDn = 'rbxassetid://600831635'
                sky.SkyboxFt = 'rbxassetid://600832720'
                sky.SkyboxLf = 'rbxassetid://600886090'
                sky.SkyboxRt = 'rbxassetid://600833862'
                sky.SkyboxUp = 'rbxassetid://600835177'
            elseif value == 'Cosmo' then
                sky.SkyboxBk = 'rbxassetid://15753305495'
                sky.SkyboxDn = 'rbxassetid://15753362674'
                sky.SkyboxFt = 'rbxassetid://15753305823'
                sky.SkyboxLf = 'rbxassetid://15753310707'
                sky.SkyboxRt = 'rbxassetid://15753304774'
                sky.SkyboxUp = 'rbxassetid://15753304473'
            elseif value == 'Neon' then
                sky.SkyboxBk = 'rbxassetid://271042516'
                sky.SkyboxDn = 'rbxassetid://271077243'
                sky.SkyboxFt = 'rbxassetid://271042556'
                sky.SkyboxLf = 'rbxassetid://271042310'
                sky.SkyboxRt = 'rbxassetid://271042467'
                sky.SkyboxUp = 'rbxassetid://271077958'
            elseif value == 'Minecraft' then
                sky.SkyboxBk = 'rbxassetid://1876545003'
                sky.SkyboxDn = 'rbxassetid://1876544331'
                sky.SkyboxFt = 'rbxassetid://1876542941'
                sky.SkyboxLf = 'rbxassetid://1876543392'
                sky.SkyboxRt = 'rbxassetid://1876543764'
                sky.SkyboxUp = 'rbxassetid://1876544642'
            elseif value == 'Old skybox' then
                sky.SkyboxBk = 'rbxassetid://15436783'
                sky.SkyboxDn = 'rbxassetid://15436796'
                sky.SkyboxFt = 'rbxassetid://15436831'
                sky.SkyboxLf = 'rbxassetid://15437157'
                sky.SkyboxRt = 'rbxassetid://15437166'
                sky.SkyboxUp = 'rbxassetid://15437184'
            elseif value == 'Nightless' then
                sky.SkyboxBk = 'rbxassetid://48020371'
                sky.SkyboxDn = 'rbxassetid://48020144'
                sky.SkyboxFt = 'rbxassetid://48020234'
                sky.SkyboxLf = 'rbxassetid://48020211'
                sky.SkyboxRt = 'rbxassetid://48020254'
                sky.SkyboxUp = 'rbxassetid://48020383'
            end

            sky.Parent = Lighting
        end
    end,
})

customSky = {
    Bk = '',
    Dn = '',
    Ft = '',
    Lf = '',
    Rt = '',
    Up = '',
}

function applyCustomSky()
    for _, obj in pairs(Lighting:GetChildren()) do
        if obj:IsA('Sky') then
            obj:Destroy()
        end
    end

    local anyFilled = false
    for _, v in pairs(customSky) do
        if v ~= '' then
            anyFilled = true
            break
        end
    end

    if anyFilled then
        local sky = Instance.new('Sky')
        sky.SkyboxBk = customSky.Bk ~= '' and 'rbxassetid://' .. customSky.Bk
            or ''
        sky.SkyboxDn = customSky.Dn ~= '' and 'rbxassetid://' .. customSky.Dn
            or ''
        sky.SkyboxFt = customSky.Ft ~= '' and 'rbxassetid://' .. customSky.Ft
            or ''
        sky.SkyboxLf = customSky.Lf ~= '' and 'rbxassetid://' .. customSky.Lf
            or ''
        sky.SkyboxRt = customSky.Rt ~= '' and 'rbxassetid://' .. customSky.Rt
            or ''
        sky.SkyboxUp = customSky.Up ~= '' and 'rbxassetid://' .. customSky.Up
            or ''
        sky.Parent = Lighting
    end
end

Tab2:AddInput('SkyboxBk', {
    Text = 'Skybox Back (Bk)',
    Placeholder = 'Asset ID',
    Callback = function(value)
        customSky.Bk = value
    end,
})
Tab2:AddInput('SkyboxDn', {
    Text = 'Skybox Down (Dn)',
    Placeholder = 'Asset ID',
    Callback = function(value)
        customSky.Dn = value
    end,
})
Tab2:AddInput('SkyboxFt', {
    Text = 'Skybox Front (Ft)',
    Placeholder = 'Asset ID',
    Callback = function(value)
        customSky.Ft = value
    end,
})
Tab2:AddInput('SkyboxLf', {
    Text = 'Skybox Left (Lf)',
    Placeholder = 'Asset ID',
    Callback = function(value)
        customSky.Lf = value
    end,
})
Tab2:AddInput('SkyboxRt', {
    Text = 'Skybox Right (Rt)',
    Placeholder = 'Asset ID',
    Callback = function(value)
        customSky.Rt = value
    end,
})
Tab2:AddInput('SkyboxUp', {
    Text = 'Skybox Up (Up)',
    Placeholder = 'Asset ID',
    Callback = function(value)
        customSky.Up = value
    end,
})

Tab2:AddButton('Apply Changes', function()
    applyCustomSky()
end)

RunService.Heartbeat:Connect(function()
    if rainbowLighting then
        local hue = (tick() * 30) % 360 / 360
        local color = Color3.fromHSV(hue, 1, 1)
        Lighting.Ambient = color
        Lighting.OutdoorAmbient = color
    else
        Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end

    if timeControlEnabled then
        setGameTime(currentGameTime)
    end
end)

SelfChamsGroup = VisualsTab:AddRightGroupbox('Self Chams')

local azure = {
    UISettings = {
        Rainbow = false,
    },
    Visuals = {
        Local = {
            Chams = nil,
            ChamsColor = nil,
            CloneChams = {
                Enabled = nil,
                Duration = nil,
                Color = nil,
            },
            GunChams = {
                Enabled = nil,
                Color = nil,
            },
        },
    },
}

local OriginalAppearance = {}

local function saveOriginalAppearance(character)
    for _, v in ipairs(character:GetDescendants()) do
        if v:IsA('BasePart') then
            OriginalAppearance[v] = {
                Material = v.Material,
                Color = v.Color,
            }
        end
    end
end

local function restoreOriginalAppearance(character)
    for _, v in ipairs(character:GetDescendants()) do
        if v:IsA('BasePart') and OriginalAppearance[v] then
            v.Material = OriginalAppearance[v].Material
            v.Color = OriginalAppearance[v].Color
        end
    end
end

SelfChamsGroup:AddToggle('ChamsEnabledTggle', {
    Text = 'Enable',
    Default = false,
})

Toggles.ChamsEnabledTggle:OnChanged(function()
    azure.Visuals.Local.Chams = Toggles.ChamsEnabledTggle.Value
end)

Toggles.ChamsEnabledTggle:AddColorPicker('ChamsColorPicker', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Self Chams Color',
})

Options.ChamsColorPicker:OnChanged(function()
    azure.Visuals.Local.ChamsColor = Options.ChamsColorPicker.Value
end)

SelfChamsGroup:AddToggle('CloneChamsEnabled', {
    Text = 'Clone',
    Default = false,
})

Toggles.CloneChamsEnabled:OnChanged(function()
    azure.Visuals.Local.CloneChams.Enabled = Toggles.CloneChamsEnabled.Value
end)

Toggles.CloneChamsEnabled:AddColorPicker('CloneChamsColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Clone Chams Color',
})

Options.CloneChamsColor:OnChanged(function()
    azure.Visuals.Local.CloneChams.Color = Options.CloneChamsColor.Value
end)

SelfChamsGroup:AddSlider('DurationSliderWHAT', {
    Text = 'Duration',
    Default = 0.1,
    Min = 0.1,
    Max = 3,
    Rounding = 2,
    Compact = false,
})

Options.DurationSliderWHAT:OnChanged(function()
    azure.Visuals.Local.CloneChams.Duration = Options.DurationSliderWHAT.Value
end)

SelfChamsGroup:AddToggle('GunChamsTggle', {
    Text = 'Tool',
    Default = false,
})

Toggles.GunChamsTggle:OnChanged(function()
    azure.Visuals.Local.GunChams.Enabled = Toggles.GunChamsTggle.Value
end)

Toggles.GunChamsTggle:AddColorPicker('GunChamsColr', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Gun Chams Color',
})

Options.GunChamsColr:OnChanged(function()
    azure.Visuals.Local.GunChams.Color = Options.GunChamsColr.Value
end)

SelfChamsGroup:AddToggle('RainbowToggle', {
    Text = 'Rainbow',
    Default = false,
})

Toggles.RainbowToggle:OnChanged(function()
    azure.UISettings.Rainbow = Toggles.RainbowToggle.Value
end)

local function getRainbowColor(offset)
    return Color3.fromHSV((tick() + (offset or 0)) % 5 / 5, 1, 1)
end

task.spawn(function()
    local player = game.Players.LocalPlayer
    player.CharacterAdded:Connect(function(char)
        task.wait(1)
        saveOriginalAppearance(char)
    end)
    if player.Character then
        task.wait(1)
        saveOriginalAppearance(player.Character)
    end
    while true do
        task.wait()
        if azure.Visuals.Local.Chams then
            local color = azure.UISettings.Rainbow and getRainbowColor()
                or (
                    azure.Visuals.Local.ChamsColor
                    or Color3.fromRGB(255, 255, 255)
                )
            for i, v in pairs(player.Character:GetDescendants()) do
                if v:IsA('BasePart') then
                    v.Material = Enum.Material.ForceField
                    v.Color = color
                end
            end
        else
            if player.Character then
                restoreOriginalAppearance(player.Character)
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait()
        if azure.Visuals.Local.CloneChams.Enabled then
            local player = game.Players.LocalPlayer
            if not player.Character then
                continue
            end
            player.Character.Archivable = true
            local Clone = player.Character:Clone()
            for _, Obj in ipairs(Clone:GetDescendants()) do
                if
                    Obj:IsA('Humanoid')
                    or Obj:IsA('HumanoidRootPart')
                    or Obj:IsA('LocalScript')
                    or Obj:IsA('Script')
                    or Obj:IsA('Decal')
                then
                    Obj:Destroy()
                elseif
                    Obj:IsA('BasePart')
                    or Obj:IsA('MeshPart')
                    or Obj:IsA('Part')
                then
                    if Obj.Transparency < 1 then
                        Obj.CanCollide = false
                        Obj.Anchored = true
                        Obj.Material = Enum.Material.ForceField
                        Obj.Color = azure.UISettings.Rainbow
                                and getRainbowColor(1)
                            or (
                                azure.Visuals.Local.CloneChams.Color
                                or Color3.fromRGB(255, 255, 255)
                            )
                        Obj.Transparency = 0
                        Obj.Size += Vector3.new(0.03, 0.03, 0.03)
                    else
                        Obj:Destroy()
                    end
                end
            end
            Clone.Parent = workspace
            task.wait(azure.Visuals.Local.CloneChams.Duration or 0.1)
            Clone:Destroy()
        end
    end
end)

task.spawn(function()
    while true do
        task.wait()
        local player = game.Players.LocalPlayer
        if not player.Character then
            continue
        end
        local tool = player.Character:FindFirstChildWhichIsA('Tool')
        if azure.Visuals.Local.GunChams.Enabled then
            if tool and tool:FindFirstChild('Default') then
                tool.Default.Material = Enum.Material.ForceField
                tool.Default.Color = azure.UISettings.Rainbow
                        and getRainbowColor(2)
                    or (
                        azure.Visuals.Local.GunChams.Color
                        or Color3.fromRGB(255, 255, 255)
                    )
            end
        else
            if tool and tool:FindFirstChild('Default') then
                tool.Default.Material = Enum.Material.Plastic
            end
        end
    end
end)

AuraVisualGroup = VisualsTab:AddRightGroupbox('Effects')

player = Players.LocalPlayer
character = player.Character or player.CharacterAdded:Wait()

angelAuraModel = nil
cloakAuraModel = nil
sweetHearthModel = nil
etherealAuraModel = nil

selectedAura = 'Angel Aura'
auraEnabled = false

function clearAuras()
    for _, model in pairs({
        angelAuraModel,
        cloakAuraModel,
        sweetHearthModel,
        etherealAuraModel,
    }) do
        if model then
            model:Destroy()
        end
    end
    angelAuraModel, cloakAuraModel, sweetHearthModel, etherealAuraModel =
        nil, nil, nil, nil
end

function attachModel(modelId)
    local torso = character:FindFirstChild('UpperTorso')
        or character:FindFirstChild('Torso')
    if not torso then
        warn('Torso not found')
        return nil
    end

    local success, model = pcall(function()
        return game:GetObjects('rbxassetid://' .. modelId)[1]
    end)

    if not success or not model then
        warn('Failed to load model with ID:', modelId)
        return nil
    end

    model.Parent = character

    if model:IsA('Accessory') then
        local humanoid = character:FindFirstChildWhichIsA('Humanoid')
        if humanoid then
            humanoid:AddAccessory(model)
            return model
        else
            warn('Humanoid not found to add accessory')
            model:Destroy()
            return nil
        end
    end

    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA('BasePart') then
            part.CanCollide = false
            part.Massless = true
            part.Anchored = false
            part.CanTouch = false
            part.CanQuery = false
        end
    end

    if model:IsA('Model') then
        model:PivotTo(torso.CFrame)
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA('BasePart') then
                local motor = Instance.new('Motor6D')
                motor.Part0 = torso
                motor.Part1 = part
                motor.C0 = torso.CFrame:ToObjectSpace(part.CFrame)
                motor.Parent = torso
            end
        end
    elseif model:IsA('BasePart') then
        model.CFrame = torso.CFrame
        local motor = Instance.new('Motor6D')
        motor.Part0 = torso
        motor.Part1 = model
        motor.C0 = torso.CFrame:ToObjectSpace(model.CFrame)
        motor.Parent = torso
    end

    return model
end

function enableAngelAura()
    angelAuraModel = attachModel(90022969696073)
end

function enableCloakAura()
    cloakAuraModel = attachModel(99046723611000)
end

function enableSweetHearth()
    sweetHearthModel = attachModel(91724768175470)
end

function enableEtherealAura()
    etherealAuraModel = attachModel(97041568674250)
end

function updateAura()
    clearAuras()
    if auraEnabled then
        if selectedAura == 'Angel Aura' then
            enableAngelAura()
        elseif selectedAura == 'Cloak Aura' then
            enableCloakAura()
        elseif selectedAura == 'Sweet Hearth' then
            enableSweetHearth()
        elseif selectedAura == 'Ethereal' then
            enableEtherealAura()
        end
    end
end

player.CharacterAdded:Connect(function(char)
    character = char
    char:WaitForChild('Humanoid', 5)
    char:WaitForChild('UpperTorso', 5)
    task.wait(1)
    updateAura()
end)

AuraVisualGroup:AddToggle('AuraToggle', {
    Text = 'Enable Aura',
    Default = auraEnabled,
    Callback = function(state)
        auraEnabled = state
        updateAura()
    end,
})

AuraVisualGroup:AddDropdown('AuraDropdown', {
    Text = 'Select Aura',
    Default = selectedAura,
    Values = { 'Angel Aura', 'Cloak Aura', 'Sweet Hearth', 'Ethereal' },
    Callback = function(value)
        selectedAura = value
        updateAura()
    end,
})

Settings = {
    Visuals = {
        SelfESP = {
            Trail = {
                Color = Color3.fromRGB(255, 110, 0),
                Color2 = Color3.fromRGB(255, 0, 0),
                LifeTime = 1.6,
                Width = 0.1,
            },
            Aura = {
                Color = Color3.fromRGB(152, 0, 252),
            },
        },
    },
}

utility = {}

utility.trail_character = function(Bool)
    character = player.Character or player.CharacterAdded:Wait()
    humanoidRootPart = character:WaitForChild('HumanoidRootPart')

    if Bool then
        if not humanoidRootPart:FindFirstChild('BlaBla') then
            BlaBla = Instance.new('Trail', humanoidRootPart)
            BlaBla.Name = 'BlaBla'
            humanoidRootPart.Material = Enum.Material.Neon

            attachment0 = Instance.new('Attachment', humanoidRootPart)
            attachment0.Position = Vector3.new(0, 1, 0)

            attachment1 = Instance.new('Attachment', humanoidRootPart)
            attachment1.Position = Vector3.new(0, -1, 0)

            BlaBla.Attachment0 = attachment0
            BlaBla.Attachment1 = attachment1
            BlaBla.Color = ColorSequence.new(
                Settings.Visuals.SelfESP.Trail.Color,
                Settings.Visuals.SelfESP.Trail.Color2
            )
            BlaBla.Lifetime = Settings.Visuals.SelfESP.Trail.LifeTime
            BlaBla.Transparency = NumberSequence.new(0, 0)
            BlaBla.LightEmission = 0.2
            BlaBla.Brightness = 10
            BlaBla.WidthScale = NumberSequence.new({
                NumberSequenceKeypoint.new(
                    0,
                    Settings.Visuals.SelfESP.Trail.Width
                ),
                NumberSequenceKeypoint.new(1, 0),
            })
        end
    else
        children = humanoidRootPart:GetChildren()
        for i = 1, #children do
            if children[i]:IsA('Trail') and children[i].Name == 'BlaBla' then
                children[i]:Destroy()
            end
        end
    end
end

function onCharacterAdded(character)
    if getgenv().trailEnabled then
        utility.trail_character(true)
    end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
    onCharacterAdded(player.Character)
end

AuraVisualGroup:AddToggle('TrailToggle', {
    Text = 'Trail',
    Default = false,
    Callback = function(state)
        getgenv().trailEnabled = state
        utility.trail_character(state)
    end,
})
    :AddColorPicker('TrailColor', {
        Text = 'Trail Color',
        Default = Settings.Visuals.SelfESP.Trail.Color,
        Callback = function(color)
            Settings.Visuals.SelfESP.Trail.Color = color
            if getgenv().trailEnabled then
                utility.trail_character(false)
                utility.trail_character(true)
            end
        end,
    })
    :AddColorPicker('TrailColor2', {
        Text = 'Trail Color 2',
        Default = Settings.Visuals.SelfESP.Trail.Color2,
        Callback = function(color)
            Settings.Visuals.SelfESP.Trail.Color2 = color
            if getgenv().trailEnabled then
                utility.trail_character(false)
                utility.trail_character(true)
            end
        end,
    })

AuraVisualGroup:AddSlider('TrailLifetime', {
    Text = 'Trail Lifetime',
    Default = 1.6,
    Min = 0.1,
    Max = 5,
    Rounding = 1,
    Callback = function(value)
        Settings.Visuals.SelfESP.Trail.LifeTime = value
        if getgenv().trailEnabled then
            utility.trail_character(false)
            utility.trail_character(true)
        end
    end,
})

FoggGroup = VisualsTab:AddRightGroupbox('Fog')

fogEnabled = false
rainbowFog = false
fogStart = 0
fogEnd = 1000
hue = 0
fogColor = Color3.new(1, 1, 1)

originalFogStart = game.Lighting.FogStart
originalFogEnd = game.Lighting.FogEnd
originalFogColor = game.Lighting.FogColor

function updateFog()
    if fogEnabled then
        game.Lighting.FogStart = fogStart
        game.Lighting.FogEnd = fogEnd

        if rainbowFog then
            hue = (hue + 1) % 360
            game.Lighting.FogColor = Color3.fromHSV(hue / 360, 1, 1)
        else
            game.Lighting.FogColor = fogColor
        end
    else
        game.Lighting.FogStart = originalFogStart
        game.Lighting.FogEnd = originalFogEnd
        game.Lighting.FogColor = originalFogColor
    end
end

fogToggle = FoggGroup:AddToggle('EnableFog', {
    Text = 'Enable',
    Default = false,
    Callback = function(state)
        fogEnabled = state
        updateFog()
    end,
})

fogToggle:AddColorPicker('FogColorPicker', {
    Default = fogColor,
    Title = 'Fog Color',
    Callback = function(color)
        fogColor = color
        if fogEnabled and not rainbowFog then
            updateFog()
        end
    end,
})

FoggGroup:AddToggle('RainbowFog', {
    Text = 'Rainbow',
    Default = false,
    Callback = function(state)
        rainbowFog = state
        updateFog()
    end,
})

FoggGroup:AddToggle('RemoveFog', {
    Text = 'Remove Fog',
    Callback = function(state)
        if state then
            game.Lighting.FogEnd = 1e6
            game.Lighting.FogStart = 100
        else
            game.Lighting.FogEnd = fogEnd
            game.Lighting.FogStart = fogStart
        end
    end,
})

FoggGroup:AddSlider('FogStart', {
    Text = 'Start',
    Default = fogStart,
    Min = 0,
    Max = 1000,
    Rounding = 0,
    Callback = function(value)
        fogStart = value
        updateFog()
    end,
})

FoggGroup:AddSlider('FogEnd', {
    Text = 'End',
    Default = fogEnd,
    Min = 0,
    Max = 1000,
    Rounding = 0,
    Callback = function(value)
        fogEnd = value
        updateFog()
    end,
})

game:GetService('RunService').RenderStepped:Connect(function()
    if fogEnabled and rainbowFog then
        updateFog()
    end
end)

getgenv().Lighting = game:GetService('Lighting')

getgenv().DefaultAmbient = Lighting.Ambient
getgenv().DefaultTechnology = Lighting.Technology.Name

FoggGroup:AddToggle('AmbientToggle', {
    Text = 'Ambient',
    Default = false,

    Callback = function(Value)
        if Value then
            Lighting.Ambient = getgenv().AmbientColor or DefaultAmbient
        else
            Lighting.Ambient = DefaultAmbient
        end
    end,
}):AddColorPicker('AmbientColor', {
    Default = DefaultAmbient,
    Title = 'Ambient Color',

    Callback = function(Value)
        getgenv().AmbientColor = Value
        Lighting.Ambient = Value
    end,
})

FoggGroup:AddDropdown('LightingTech', {
    Text = 'Technology',
    Values = { 'Voxel', 'Compatibility', 'ShadowMap', 'Future' },
    Default = table.find(
        { 'Voxel', 'Compatibility', 'ShadowMap', 'Future' },
        DefaultTechnology
    ) or 1,

    Callback = function(Value)
        Lighting.Technology = Enum.Technology[Value]
    end,
})

camera = workspace.CurrentCamera
defaultFOV = camera.FieldOfView
fovEnabled = false
currentFOV = defaultFOV

FOVGroup = VisualsTab:AddRightGroupbox('Field of View')

FOVGroup:AddToggle('EnableFOV', {
    Text = 'Enable',
    Default = false,
    Callback = function(state)
        fovEnabled = state
        if fovEnabled then
            camera.FieldOfView = currentFOV
        else
            camera.FieldOfView = defaultFOV
        end
    end,
})

FOVGroup:AddSlider('FOVSlider', {
    Text = 'Amount',
    Default = defaultFOV,
    Min = 70,
    Max = 120,
    Rounding = 1,
    Compact = false,
    Callback = function(value)
        currentFOV = value
        if fovEnabled then
            camera.FieldOfView = currentFOV
        end
    end,
})

HudGroup = VisualsTab:AddRightGroupbox('Hotbar Changer')

defaultTextHP = 'Health '
defaultTextArmor = 'Armor'
defaultTextEnergy = 'Dark Energy'

defaultColorHP = Color3.new(0.941176, 0.031373, 0.819608)
defaultColorArmor = Color3.new(0.376471, 0.031373, 0.933333)
defaultColorEnergy = Color3.new(0.768627, 0.039216, 0.952941)

textHP, textArmor, textEnergy =
    defaultTextHP, defaultTextArmor, defaultTextEnergy
colorHP, colorArmor, colorEnergy =
    defaultColorHP, defaultColorArmor, defaultColorEnergy

toggleHP, toggleArmor, toggleEnergy = false, false, false
rainbowMode = false

function skibiditoilet()
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild('PlayerGui')
    local gui = playerGui:WaitForChild('MainScreenGui').Bar

    if toggleHP then
        gui.HP.TextLabel.Text = textHP
        gui.HP.bar.BackgroundColor3 = rainbowMode
                and Color3.fromHSV(tick() % 5 / 5, 1, 1)
            or colorHP
    end

    if toggleArmor then
        gui.Armor.TextLabel.Text = textArmor
        gui.Armor.bar.BackgroundColor3 = rainbowMode
                and Color3.fromHSV(tick() % 5 / 5, 1, 1)
            or colorArmor
    end

    if toggleEnergy then
        gui.Energy.TextLabel.Text = textEnergy
        gui.Energy.bar.BackgroundColor3 = rainbowMode
                and Color3.fromHSV(tick() % 5 / 5, 1, 1)
            or colorEnergy
    end
end

HudGroup:AddToggle('RainbowMode', {
    Text = 'Rainbow Color',
    Default = false,
    Callback = function(state)
        rainbowMode = state
    end,
})

HudGroup:AddToggle('ToggleHP', {
    Text = 'Customize Health',
    Default = false,
    Callback = function(state)
        toggleHP = state
        skibiditoilet()
    end,
}):AddColorPicker('ColorHP', {
    Text = 'Health Color',
    Default = defaultColorHP,
    Callback = function(value)
        if toggleHP and not rainbowMode then
            colorHP = value
            skibiditoilet()
        end
    end,
})

HudGroup:AddToggle('ToggleArmor', {
    Text = 'Customize Armor',
    Default = false,
    Callback = function(state)
        toggleArmor = state
        skibiditoilet()
    end,
}):AddColorPicker('ColorArmor', {
    Text = 'Armor Color',
    Default = defaultColorArmor,
    Callback = function(value)
        if toggleArmor and not rainbowMode then
            colorArmor = value
            skibiditoilet()
        end
    end,
})

HudGroup:AddToggle('ToggleEnergy', {
    Text = 'Customize Energy',
    Default = false,
    Callback = function(state)
        toggleEnergy = state
        skibiditoilet()
    end,
}):AddColorPicker('ColorEnergy', {
    Text = 'Energy Color',
    Default = defaultColorEnergy,
    Callback = function(value)
        if toggleEnergy and not rainbowMode then
            colorEnergy = value
            skibiditoilet()
        end
    end,
})

HudGroup:AddInput('TextHP', {
    Text = 'Health Text',
    Default = defaultTextHP,
    Callback = function(value)
        if toggleHP then
            textHP = value
            skibiditoilet()
        end
    end,
})

HudGroup:AddInput('TextArmor', {
    Text = 'Armor Text',
    Default = defaultTextArmor,
    Callback = function(value)
        if toggleArmor then
            textArmor = value
            skibiditoilet()
        end
    end,
})

HudGroup:AddInput('TextEnergy', {
    Text = 'Energy Text',
    Default = defaultTextEnergy,
    Callback = function(value)
        if toggleEnergy then
            textEnergy = value
            skibiditoilet()
        end
    end,
})

game:GetService('RunService').RenderStepped:Connect(function()
    if rainbowMode and (toggleHP or toggleArmor or toggleEnergy) then
        skibiditoilet()
    end
end)

Ignored = Workspace:FindFirstChild('Ignored')
ShopFolder = Ignored and Ignored:FindFirstChild('Shop')

isValidGame = false
if ShopFolder then
    neededItems = {
        '[Rifle] - $1694',
        '[Medium Armor] - $1366',
        '[Pizza] - $11',
        '[Surgeon Mask] - 27$',
        '[Bat] - 300$',
    }
    index = 1
    while index <= #neededItems do
        itemName = neededItems[index]
        if ShopFolder:FindFirstChild(itemName) then
            isValidGame = true
            break
        end
        index = index + 1
    end
end

AutoBuy = TeleportTab:AddLeftGroupbox('Legit Auto Buy')
LocalPlayer = Players.LocalPlayer

AutoBuy:AddLabel('[Money Method] use this button')

webhook = AutoBuy:AddButton('Redeem Codes', function()
    codes = { 'BRAINROT', 'LUXE', 'TURBO' }
    mainEvent = game:GetService('ReplicatedStorage'):WaitForChild('MainEvent')
        or nil
    i = 1
    while i <= #codes do
        code = codes[i]
        mainEvent:FireServer('EnterPromoCode', code)
        Library:Notify('Redeeming ' .. code, 1)
        task.wait(4.2)
        i = i + 1
    end
end)

autoAfterDie = false
AutoBuy:AddToggle('AutoAfterDie', {
    Text = 'Auto After Die',
    Default = false,
    Callback = function(state)
        autoAfterDie = state
    end,
})

function HasItem(itemName)
    local backpack = LocalPlayer:FindFirstChild('Backpack')
    local character = LocalPlayer.Character

    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item.Name == itemName then
                return true
            end
        end
    end

    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA('Tool') and item.Name == itemName then
                return true
            end
        end
    end

    return false
end

function TryBuyItem(itemName, attempts, delay)
    attempts = attempts or 3
    delay = delay or 0.7

    for i = 1, attempts do
        BuyItem(itemName)
        task.wait(delay)
        if HasItem(itemName) then
            return true
        end
    end
    return false
end

function AutoBuySelectedItems()
    if SelectedGun and not HasItem(SelectedGun) then
        TryBuyItem(SelectedGun, 3, 0.7)
    end

    if SelectedAmmo then
        for i = 1, 5 do
            TryBuyItem(SelectedAmmo, 2, 0.5)
        end
    end

    if SelectedArmor and not HasItem(SelectedArmor) then
        TryBuyItem(SelectedArmor, 2, 1)
        task.wait(4)
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(3)
    if autoAfterDie then
        AutoBuySelectedItems()
    end
end)

Guns = {
    '[Rifle] - $1694',
    '[AUG] - $2131',
    '[Flintlock] - $1421',
    '[Revolver] - $1421',
    '[SilencerAR] - $1366',
    '[Double-Barrel SG] - $1475',
    '[TacticalShotgun] - $1912',
    '[P90] - $1093',
    '[RPG] - $21855',
    '[Flamethrower] - $9835',
    '[LMG] - $4098',
    '[Drum-Shotgun] - $1202',
    '[DrumGun] - $3278',
    '[GrenadeLauncher] - $10927',
    '[Taser] - $1093',
}

Ammo = {
    '5 [Rifle Ammo] - $273',
    '90 [AUG Ammo] - $87',
    '6 [Flintlock Ammo] - $163',
    '12 [Revolver Ammo] - $82',
    '120 [SilencerAR Ammo] - $82',
    '18 [Double-Barrel SG Ammo] - $55',
    '20 [TacticalShotgun Ammo] - $66',
    '120 [P90 Ammo] - $66',
    '5 [RPG Ammo] - $1093 ',
    '140 [Flamethrower Ammo] - $1093',
    '200 [LMG Ammo] - $328',
    '18 [Drum-Shotgun Ammo] - $71',
    '100 [DrumGun Ammo] - $219',
    '12 [GrenadeLauncher Ammo] - $3278',
}

Armors = {
    '[Medium Armor] - $1366',
    '[High-Medium Armor] - $2513',
    '[Fire Armor] - $2623',
}

Foods = {
    '[Pizza] - $11',
    '[Hamburger] - $11',
    '[Popcorn] - $8',
    '[Donut] - $11',
    '[Chicken] - $8',
    '[Pizza] - $5',
    '[Taco] - $2',
    '[Starblox Latte] - $5',
    '[Cranberry] - $3',
}

Mask = {
    '[Surgeon Mask] - $27',
    '[Skull Mask] - $66',
    '[Pumpkin Mask] - $66',
    '[Hockey Mask] - $66',
    '[Paintball Mask] - $66',
    '[Ninja Mask] - $66',
    '[Riot Mask] - $66',
}

Item = {
    '[SledgeHammer] - $382',
    '[Bat] - $300',
    '[StopSign] - $328',
    '[Shovel] - $350',
    '[Pitchfork] - $350',
    '[Knife] - $164',
    '[PepperSpray] - $82',
    '[LockPicker] - $137',
    '[Key] - $137',
    '[Firework] - $10927',
}

SelectedGun = Guns[1]
SelectedAmmo = Ammo[1]
SelectedArmor = Armors[1]
SelectedFood = Foods[1]
SelectedMask = Mask[1]
SelectedItem = Item[1]

Debounce = false

function GetCharacterRoot()
    char = LocalPlayer.Character
    if char then
        return char:FindFirstChild('HumanoidRootPart')
    end
    return nil
end

AutoBuy:AddDropdown('GunDropdown', {
    Values = Guns,
    Default = 1,
    Multi = false,
    Text = 'Select Gun',
    Callback = function(Value)
        SelectedGun = Value
        if Value == '[Rifle] - $1694' then
            SelectedAmmo = '5 [Rifle Ammo] - $273'
        end
        if Value == '[AUG] - $2131' then
            SelectedAmmo = '90 [AUG Ammo] - $87'
        end
        if Value == '[Flintlock] - $1421' then
            SelectedAmmo = '6 [Flintlock Ammo] - $163'
        end
        if Value == '[Revolver] - $1421' then
            SelectedAmmo = '12 [Revolver Ammo] - $82'
        end
        if Value == '[SilencerAR] - $1366' then
            SelectedAmmo = '120 [SilencerAR Ammo] - $82'
        end
        if Value == '[Double-Barrel SG] - $1475' then
            SelectedAmmo = '18 [Double-Barrel SG Ammo] - $55'
        end
        if Value == '[TacticalShotgun] - $1912' then
            SelectedAmmo = '20 [TacticalShotgun Ammo] - $66'
        end
        if Value == '[P90] - $1093' then
            SelectedAmmo = '120 [P90 Ammo] - $66'
        end
        if Value == '[RPG] - $21855' then
            SelectedAmmo = '5 [RPG Ammo] - $1093'
        end
        if Value == '[Flamethrower] - $9835' then
            SelectedAmmo = '140 [Flamethrower Ammo] - $1093'
        end
        if Value == '[LMG] - $4098' then
            SelectedAmmo = '200 [LMG Ammo] - $328'
        end
        if Value == '[Drum-Shotgun] - $1202' then
            SelectedAmmo = '18 [Drum-Shotgun Ammo] - $71'
        end
        if Value == '[DrumGun] - $3278' then
            SelectedAmmo = '100 [DrumGun Ammo] - $219'
        end
        if Value == '[GrenadeLauncher] - $10927' then
            SelectedAmmo = '12 [GrenadeLauncher Ammo] - $3278'
        end
        if Value == '[Taser] - $1093' then
            SelectedAmmo = ''
        end
    end,
})

AutoBuy:AddDropdown('AmmoDropdown', {
    Values = Ammo,
    Default = 1,
    Multi = false,
    Text = 'Select Ammo',
    Callback = function(Value)
        SelectedAmmo = Value
    end,
})

AutoBuy:AddDropdown('ArmorDropdown', {
    Values = Armors,
    Default = 1,
    Multi = false,
    Text = 'Select Armor',
    Callback = function(Value)
        SelectedArmor = Value
    end,
})

AutoBuy:AddDropdown('FoodDropdown', {
    Values = Foods,
    Default = 1,
    Multi = false,
    Text = 'Select Food',
    Callback = function(Value)
        SelectedFood = Value
    end,
})

AutoBuy:AddDropdown('MaskDropdown', {
    Values = Mask,
    Default = 1,
    Multi = false,
    Text = 'Select Mask',
    Callback = function(Value)
        SelectedMask = Value
    end,
})

AutoBuy:AddDropdown('MaskDropdown', {
    Values = Item,
    Default = 1,
    Multi = false,
    Text = 'Select Item',
    Callback = function(Value)
        SelectedItem = Value
    end,
})

function BuyItem(itemName)
    if not isValidGame or not ShopFolder then
        Library:Notify('Not for this game!', 3)
        return
    end
    if Debounce then
        return
    end
    Debounce = true

    success, err = pcall(function()
        RootPart = GetCharacterRoot()
        if not RootPart then
            error('[ERROR] No HumanoidRootPart found!')
        end

        ItemModel = ShopFolder:FindFirstChild(itemName)
        if not ItemModel then
            error('[ERROR] Item not found: ' .. itemName)
        end

        ClickDetector = ItemModel:FindFirstChildOfClass('ClickDetector')
        if not ClickDetector then
            error('[ERROR] ClickDetector not found in ' .. itemName)
        end

        OriginalCFrame = RootPart.CFrame
        RootPart.CFrame =
            CFrame.new(ItemModel.Head.Position + Vector3.new(0, 3, 0))
        task.wait(0.15)
        fireclickdetector(ClickDetector)
        Library:Notify('Purchased: ' .. itemName, 3)
        RootPart.CFrame = OriginalCFrame
    end)

    if not success then
        Library:Notify(err, 3)
    end

    Debounce = false
end

AutoBuy:AddButton('Buy Gun', function()
    BuyItem(SelectedGun)
end)
AutoBuy:AddButton('Buy Ammo', function()
    BuyItem(SelectedAmmo)
end)
AutoBuy:AddButton('Buy Armor', function()
    BuyItem(SelectedArmor)
end)
AutoBuy:AddButton('Buy Food', function()
    BuyItem(SelectedFood)
end)
AutoBuy:AddButton('Buy Mask', function()
    BuyItem(SelectedMask)
end)
AutoBuy:AddButton('Buy Item', function()
    BuyItem(SelectedItem)
end)

getgenv().PlayerInfo = TeleportTab:AddLeftGroupbox('Player Info')

PlayerInfo:AddToggle('view', {
    Text = 'View',
    Default = false,
    Callback = function(state)
        if state and getgenv().SelectedTarget then
            local targetPlayer =
                Players:FindFirstChild(getgenv().SelectedTarget)
            if
                targetPlayer
                and targetPlayer.Character
                and targetPlayer.Character:FindFirstChild('Humanoid')
            then
                Workspace.CurrentCamera.CameraSubject =
                    targetPlayer.Character.Humanoid
            end
        else
            if
                LocalPlayer.Character
                and LocalPlayer.Character:FindFirstChild('Humanoid')
            then
                Workspace.CurrentCamera.CameraSubject =
                    LocalPlayer.Character.Humanoid
            end
        end
    end,
})

PlayerInfo:AddButton('Teleport', function()
    local targetPlayer = Players:FindFirstChild(getgenv().SelectedTarget)
    if
        targetPlayer
        and targetPlayer.Character
        and targetPlayer.Character:FindFirstChild('HumanoidRootPart')
        and LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    then
        LocalPlayer.Character.HumanoidRootPart.CFrame =
            targetPlayer.Character.HumanoidRootPart.CFrame
    end
end)

getgenv().TargetDropdown = PlayerInfo:AddDropdown('yepyep', {
    SpecialType = 'Player',
    Text = 'Select a Player',
    Tooltip = 'Select a player to perform actions on.',
    Callback = function(value)
        getgenv().SelectedTarget = value
    end,
})

PlayerInfo:AddInput('playerSearch', {
    Text = 'Search Player',
    Tooltip = 'Type to search for a player.',
    Callback = function(value)
        local matches = {}
        value = string.lower(value)

        for _, player in ipairs(Players:GetPlayers()) do
            local playerName = string.lower(player.Name)
            local displayName = string.lower(player.DisplayName)

            if
                string.find(playerName, value)
                or string.find(displayName, value)
            then
                table.insert(matches, player.Name)
            end
        end

        Options.yepyep:SetValues(matches)

        if #matches == 1 then
            Options.yepyep:SetValue(matches[1])
            getgenv().SelectedTarget = matches[1]
        end
    end,
})

SettingsrGroup = TeleportTab:AddLeftGroupbox('idk bruh')

SettingsrGroup:AddButton('(DA HOOD) NeckGrab', function()
    loadstring(
        game:HttpGet(
            'https://raw.githubusercontent.com/zesty-create/rescue/refs/heads/main/neckgrab.lua'
        )
    )()
end)

SettingsrGroup:AddButton('Control Body', function()
    loadstring(
        game:HttpGet(
            'https://raw.githubusercontent.com/zesty-create/rescue/refs/heads/main/telepathy.lua'
        )
    )()
end)

SettingsrGroup:AddButton('FE Cock', function()
    local Players = game:GetService('Players')
    local LocalPlayer = Players.LocalPlayer
    local char = LocalPlayer.Character
    if not char then
        return
    end

    local backpack = LocalPlayer:FindFirstChild('Backpack')
    if not backpack then
        Library:Notify('Backpack not found!', 3)
        return
    end

    local tool = backpack:FindFirstChild('[StopSign]')
    if not tool then
        Library:Notify('[StopSign] buy first SIGN!', 3)
        return
    end

    tool.Parent = char

    local handle = tool:FindFirstChild('Handle')
    if not handle then
        Library:Notify('Tool doesnt have handle!', 3)
        return
    end

    local xOffset = -0.8
    local yOffset = 1.4
    local zOffset = 1
    local yaw = 273.1
    local pitch = 1.6
    local roll = 0

    local cframe = CFrame.new(xOffset, yOffset, zOffset)
        * CFrame.Angles(math.rad(pitch), math.rad(yaw), math.rad(roll))

    tool.Grip = cframe
    tool.GripForward = cframe.LookVector
    tool.GripRight = cframe.RightVector
    tool.GripUp = cframe.UpVector

    Library:Notify('[StopSign] ready for destroy!', 3)
end)

SettingsrGroup:AddButton('FE Bat', function()
    local Players = game:GetService('Players')
    local LocalPlayer = Players.LocalPlayer
    local char = LocalPlayer.Character
    if not char then
        return
    end

    local backpack = LocalPlayer:FindFirstChild('Backpack')
    if not backpack then
        Library:Notify('Backpack not found!', 3)
        return
    end

    local tool = backpack:FindFirstChild('[Bat]')
    if not tool then
        Library:Notify('[Bat] buy first BAT!', 3)
        return
    end

    tool.Parent = char

    local handle = tool:FindFirstChild('Handle')
    if not handle then
        Library:Notify('Tool doesnt have handle!', 3)
        return
    end

    local xOffset = -0.8
    local yOffset = -0.6
    local zOffset = 1.7
    local yaw = -180
    local pitch = -90
    local roll = -117.9

    local cframe = CFrame.new(xOffset, yOffset, zOffset)
        * CFrame.Angles(math.rad(pitch), math.rad(yaw), math.rad(roll))

    tool.Grip = cframe
    tool.GripForward = cframe.LookVector
    tool.GripRight = cframe.RightVector
    tool.GripUp = cframe.UpVector

    Library:Notify('[Bat] ready for destroy!', 3)
end)

SettingsrGroup:AddButton('BTools', function()
    local player = game:GetService('Players').LocalPlayer
    local backpack = player:FindFirstChild('Backpack')
    local character = player.Character or player.CharacterAdded:Wait()

    local function giveTool(name, binType)
        local tool = Instance.new('HopperBin')
        tool.Name = name
        tool.BinType = binType

        if backpack then
            tool.Parent = backpack
        else
            tool.Parent = character
        end
    end

    for _, toolName in pairs({ 'Hammer', 'Clone', 'Grab' }) do
        if backpack and backpack:FindFirstChild(toolName) then
            backpack[toolName]:Destroy()
        end
        if character and character:FindFirstChild(toolName) then
            character[toolName]:Destroy()
        end
    end

    giveTool('Hammer', 4)
    giveTool('Clone', 3)
    giveTool('Grab', 2)
end)

Tp1Group = TeleportTab:AddRightGroupbox('Main Places')

Tp1Group:AddButton('Teleport to School', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(-606, 47, 253)
    end
end)

Tp1Group:AddButton('Teleport to Bank', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(-465, 39, -284)
    end
end)

Tp1Group:AddButton('Teleport to Safe', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(-657, -31, -286)
    end
end)

Tp1Group:AddButton('Teleport to Roof', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(-323, 80, -256)
    end
end)

Tp1Group:AddButton('Teleport to UFO', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(50, 138, -671)
    end
end)

Tp1Group:AddButton('Teleport to Military', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(37, 50, -826)
    end
end)

Tp1Group:AddButton('Teleport to Casino', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame =
            CFrame.new(-866.04, 43.80, -155.50)
    end
end)

Tp1Group:AddButton('Teleport to Gas Station', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(537, 47, -248)
    end
end)

Tp1Group:AddButton('Teleport to Fitness', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(-77, 22, -622)
    end
end)

Tp2Group = TeleportTab:AddRightGroupbox('Food Store')

Tp2Group:AddButton('Teleport to Food #1', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(-336, 23, -298)
    end
end)

Tp2Group:AddButton('Teleport to Food #2', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(299, 49, -617)
    end
end)

Tp2Group:AddButton('Teleport to Food #3', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(-279, 22, -807)
    end
end)

Tp2Group:AddButton('Teleport to Food #4', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(584, 51, -477)
    end
end)

Tp2Group:AddButton('Teleport to Food #5', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame =
            CFrame.new(-994.81, 24.60, -157.16)
    end
end)

Tp2Group:AddButton('Teleport to Food #6', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame =
            CFrame.new(-902.51, 22.01, -670.25)
    end
end)

Tp3Group = TeleportTab:AddRightGroupbox('Gun Store')

Tp3Group:AddButton('Teleport to GunShop #1 Downhill', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(-579, 8, -736)
    end
end)

Tp3Group:AddButton('Teleport to GunShop #2 Uphill', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(481, 48, -619)
    end
end)

Tp3Group:AddButton('Teleport to GunShop #3 Garage', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(-1183, 28, -519)
    end
end)

Tp3Group:AddButton('Teleport to Aug, Rifle', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(-266, 52, -215)
    end
end)

Tp3Group:AddButton('Teleport to Rpg, Grenade', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(111, -26, -271)
    end
end)

Tp3Group:AddButton('Teleport to GrenadeLauncher', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame =
            CFrame.new(-966.02, -1.23, 468.68)
    end
end)

Tp3Group:AddButton('Teleport to LMG', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(-618, 23, -301)
    end
end)

Tp4Group = TeleportTab:AddRightGroupbox('Armor')

Tp4Group:AddButton('Teleport to Armor #1', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(-605, 10, -788)
    end
end)

Tp4Group:AddButton('Teleport to Armor #2', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(532, 50, -637)
    end
end)

Tp4Group:AddButton('Teleport to Armor #3', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(-933, -28, 565)
    end
end)

Tp4Group:AddButton('Teleport to Armor #4', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(409, 48, -50)
    end
end)

Tp4Group:AddButton('Teleport to Armor #5', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(-257, 21, -78)
    end
end)

Tp4Group:AddButton('Teleport to Armor #6', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame =
            CFrame.new(97.21, 22.75, -302.63)
    end
end)

Tp5Group = TeleportTab:AddRightGroupbox('Safe Zones')

Tp5Group:AddButton('Teleport to Safe #1', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(-55, -58, 146)
    end
end)

Tp5Group:AddButton('Teleport to Safe #2', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(-124, -58, 130)
    end
end)

Tp5Group:AddButton('Teleport to Safe #3', function()
    local player = game.Players.LocalPlayer
    if
        player
        and player.Character
        and player.Character:FindFirstChild('HumanoidRootPart')
    then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(-547, 173, -2)
    end
end)

Tabs = {
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

SettingsGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

Library:SetWatermarkVisibility(true)

FrameTimer = tick()
FrameCounter = 0
FPS = 60
showWatermark = true

WatermarkConnection = game:GetService('RunService').RenderStepped
    :Connect(function()
        FrameCounter = FrameCounter + 1

        if (tick() - FrameTimer) >= 1 then
            FPS = FrameCounter
            FrameTimer = tick()
            FrameCounter = 0
        end

        if showWatermark then
            Library:SetWatermark(
                ('Rescue Experimental | Premium Sexy Version | %s fps | %s ms'):format(
                    math.floor(FPS),
                    math.floor(
                        game:GetService('Stats').Network.ServerStatsItem['Data Ping']
                            :GetValue()
                    )
                )
            )
        else
            Library:SetWatermarkVisibility(false)
        end
    end)

Library.KeybindFrame.Visible = true

Library:OnUnload(function()
    WatermarkConnection:Disconnect()
    UserInputService.MouseIconEnabled = true
    Library.Unloaded = true
end)

SettingsGroup:AddButton('Unload', function()
    UserInputService.MouseIconEnabled = true
    Library:Unload()
end)

SettingsGroup:AddLabel('Menu bind'):AddKeyPicker(
    'MenuKeybind',
    { Default = 'Insert', NoUI = true, Text = 'Menu keybind' }
)

Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('RescueTheme')
SaveManager:SetFolder('RescueConfig')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()

SettingsgGroup = Tabs['UI Settings']:AddRightGroupbox('UI Functions')

SettingsgGroup:AddToggle('Toggle_Watermark', {
    Text = 'Show Watermark',
    Default = true,
    Callback = function(state)
        showWatermark = state
        Library:SetWatermarkVisibility(state)
    end,
})

SettingsgGroup:AddToggle('Toggle_KeybindList', {
    Text = 'Show Keybind List',
    Default = true,
    Callback = function(state)
        Library.KeybindFrame.Visible = state
    end,
})

damageConnection = nil
lastHealth = {}

SettingsgGroup:AddToggle('Toggle_DamageNotify', {
    Text = 'Show Player Damage',
    Default = false,
    Callback = function(state)
        if state then
            damageConnection = game:GetService('RunService').Heartbeat
                :Connect(function()
                    for _, player in pairs(game.Players:GetPlayers()) do
                        if player ~= game.Players.LocalPlayer then
                            local character = player.Character
                            if character then
                                local humanoid =
                                    character:FindFirstChildOfClass('Humanoid')
                                if humanoid then
                                    local currentHealth = humanoid.Health
                                    local previousHealth = lastHealth[player]
                                        or currentHealth

                                    if currentHealth < previousHealth then
                                        Library:Notify(
                                            player.Name .. ' took damage!',
                                            2
                                        )
                                    end

                                    lastHealth[player] = currentHealth
                                end
                            end
                        end
                    end
                end)
        else
            if damageConnection then
                damageConnection:Disconnect()
                damageConnection = nil
            end
            lastHealth = {}
        end
    end,
})

notifyEnabled = true
originalNotify = Library.Notify or function() end

SettingsgGroup:AddToggle('Toggle_NotifyList', {
    Text = 'Notifications UI',
    Default = true,
    Callback = function(state)
        notifyEnabled = state

        if state then
            Library.Notify = originalNotify
            Library:Notify('Notifications Enabled', 3)
        else
            Library.Notify = function() end
        end
    end,
})

SettingsrrGroup = Tabs['UI Settings']:AddRightGroupbox('Other')

SettingsrrGroup:AddButton('Fix Rejoining Before', function()
    game.Players.LocalPlayer:Kick('Fixed Bug (Rejoin Before)')
end)

SettingsrrGroup:AddButton('Hop on another Server', function()
    local TeleportService = game:GetService('TeleportService')
    local PlaceId = game.PlaceId
    local HttpService = game:GetService('HttpService')

    local success, servers = pcall(function()
        local url = ('https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100'):format(
            PlaceId
        )
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    if not (success and servers and servers.data) then
        warn('Failed to get server list')
        return
    end

    local currentJobId = game.JobId
    for _, srv in ipairs(servers.data) do
        if srv.playing < srv.maxPlayers and srv.id ~= currentJobId then
            TeleportService:TeleportToPlaceInstance(
                PlaceId,
                srv.id,
                game.Players.LocalPlayer
            )
            print('Teleporting to server:', srv.id)
            return
        end
    end
    warn('No other server found')
end)

SettingsrrGroup:AddButton('Rejoin the same Server', function()
    game:GetService('TeleportService')
        :Teleport(game.PlaceId, game.Players.LocalPlayer)
end)

DefaultChatEvents =
    ReplicatedStorage:FindFirstChild('DefaultChatSystemChatEvents')

ADMINS = {
    ['xxtxxxtxiixixtttixix'] = '[👑] real developer experimental',
    ['XxnarchxX'] = '[😈] sex cornball',
}

benxActive = false
benxConnection = nil
currentSound = nil

function applyDisplayName(player)
    local display = ADMINS[player.Name]
    if not display then
        return
    end
    local function setName(char)
        local humanoid = char:WaitForChild('Humanoid', 10)
        if humanoid then
            humanoid.DisplayName = display
        end
    end
    player.CharacterAdded:Connect(setName)
    if player.Character then
        setName(player.Character)
    end
end

function getAdmin()
    for name in pairs(ADMINS) do
        local p = Players:FindFirstChild(name)
        if p then
            return p
        end
    end
    return nil
end

function teleportInFrontFacingForward()
    local admin = getAdmin()
    local adminHRP = admin
        and admin.Character
        and admin.Character:FindFirstChild('HumanoidRootPart')
    local playerHRP = LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    if not adminHRP or not playerHRP then
        return
    end
    local offset = adminHRP.CFrame.LookVector * 2
    local targetPosition = adminHRP.Position + offset
    playerHRP.CFrame =
        CFrame.new(targetPosition, targetPosition + adminHRP.CFrame.LookVector)
end

function startBenx()
    if benxActive then
        return
    end
    benxActive = true
    teleportInFrontFacingForward()
    task.wait(0.1)
    local char = LocalPlayer.Character
    if not char then
        return
    end
    local humanoid = char:FindFirstChildOfClass('Humanoid')
    if humanoid then
        humanoid.PlatformStand = true
    end
    pcall(function()
        VirtualInputManager:SendKeyEvent(
            true,
            Enum.KeyCode.LeftControl,
            false,
            game
        )
    end)
    local step, maxStep = 0, 60
    benxConnection = RunService.Heartbeat:Connect(function()
        local admin = getAdmin()
        local hrp = LocalPlayer.Character
            and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
        local adminHRP = admin
            and admin.Character
            and admin.Character:FindFirstChild('HumanoidRootPart')
        if not adminHRP or not hrp then
            return
        end
        local basePos = adminHRP.Position + adminHRP.CFrame.LookVector * 2
        local oscillation = 0.3 * math.sin((step / maxStep) * math.pi * 2)
        local targetCFrame =
            CFrame.new(basePos, basePos + adminHRP.CFrame.LookVector)
        hrp.CFrame = targetCFrame * CFrame.new(0, 0, oscillation)
        step = (step + 1) % maxStep
    end)
end

function stopBenx()
    if benxConnection then
        benxConnection:Disconnect()
        benxConnection = nil
    end
    benxActive = false
    local humanoid = LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
    if humanoid then
        humanoid.PlatformStand = false
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
    end
    pcall(function()
        VirtualInputManager:SendKeyEvent(
            false,
            Enum.KeyCode.LeftControl,
            false,
            game
        )
    end)
end

function freeze()
    local humanoid = LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
    if humanoid then
        humanoid.PlatformStand = true
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
    end
end

function unfreeze()
    local humanoid = LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
    if humanoid then
        humanoid.PlatformStand = false
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
    end
end

function betraySelf()
    local head = LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild('Head')
    if head then
        head:Destroy()
    end
end

function findPlayerByName(name)
    name = name:lower()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower() == name or p.DisplayName:lower() == name then
            return p
        end
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():find(name) or p.DisplayName:lower():find(name) then
            return p
        end
    end
    return nil
end

function startCustomBenx(targetPlayer, behind, useCtrl, speedMultiplier)
    if not targetPlayer or not targetPlayer.Character then
        return
    end
    local tHRP = targetPlayer.Character:FindFirstChild('HumanoidRootPart')
    local pHRP = LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    local humanoid = LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
    if not tHRP or not pHRP or not humanoid then
        return
    end
    local offsetDir = behind and -1 or 1
    local offset = tHRP.CFrame.LookVector * 2 * offsetDir
    local targetPos = tHRP.Position + offset
    pHRP.CFrame = CFrame.new(targetPos, tHRP.Position)
    task.wait(0.1)
    humanoid.PlatformStand = true
    if useCtrl then
        pcall(function()
            VirtualInputManager:SendKeyEvent(
                true,
                Enum.KeyCode.LeftControl,
                false,
                game
            )
        end)
    end
    local step, maxStep = 0, 60
    if benxConnection then
        benxConnection:Disconnect()
    end
    benxConnection = RunService.Heartbeat:Connect(function()
        local tHRP = targetPlayer.Character
            and targetPlayer.Character:FindFirstChild('HumanoidRootPart')
        local pHRP = LocalPlayer.Character
            and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
        if not tHRP or not pHRP then
            return
        end
        local basePos = tHRP.Position + tHRP.CFrame.LookVector * 2 * offsetDir
        local oscillation = 0.3 * math.sin((step / maxStep) * math.pi * 2)
        local targetCFrame =
            CFrame.new(basePos, basePos + tHRP.CFrame.LookVector)
        pHRP.CFrame = targetCFrame * CFrame.new(0, 0, oscillation)
        step = (step + speedMultiplier) % maxStep
    end)
end

function spawnPrankCubes()
    for _ = 1, 1000 do
        local part = Instance.new('Part')
        part.Size = Vector3.new(2, 2, 2)
        part.Position = LocalPlayer.Character
                and LocalPlayer.Character:GetPivot().Position + Vector3.new(
                    0,
                    100 + math.random() * 50,
                    0
                )
            or Vector3.new(0, 100, 0)
        part.Anchored = false
        part.BrickColor = BrickColor.Random()
        part.Parent = Workspace
    end
end

function onMessageReceived(message, sender)
    if not ADMINS[sender] then
        return
    end
    local text = message:lower()
    local args = {}
    for word in string.gmatch(text, '[^%s]+') do
        table.insert(args, word)
    end

    if text == '/kick .' and LocalPlayer.Name ~= sender then
        LocalPlayer:Kick('Kicked by Developer')
    elseif text == '/bring .' then
        teleportInFrontFacingForward()
    elseif text == '/freeze .' then
        freeze()
    elseif text == '/unfreeze .' then
        unfreeze()
    elseif text == '/benx .' then
        startBenx()
    elseif text == '/unbenx .' then
        stopBenx()
    elseif text == '/betray .' then
        betraySelf()
    elseif text == '/prank .' then
        spawnPrankCubes()
    elseif args[1] == '/pbenx' and args[2] then
        local target = findPlayerByName(args[2])
        if target then
            startCustomBenx(target, false, true, 1.5)
        end
    elseif args[1] == '/pbang' and args[2] then
        local target = findPlayerByName(args[2])
        if target then
            startCustomBenx(target, true, false, 1.5)
        end
    end
end

if DefaultChatEvents then
    DefaultChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(
        function(data)
            onMessageReceived(data.Message, data.FromSpeaker)
        end
    )
end

TextChatService.OnIncomingMessage = function(message)
    if message.TextSource and message.TextSource.Name then
        onMessageReceived(message.Text, message.TextSource.Name)
    end
end
