local function a(b, c)
    -- В Roblox сейчас нет getfenv/setfenv, так что просто возвращаем функцию без изменения окружения
    -- Чтобы не ломать структуру, возвращаем функцию с фиксированной ссылкой на script (b)
    return function(...)
        local script = b
        return c(...)
    end
end

local g = {}

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local h = Instance.new("Model", Lighting)
local i = Instance.new("Tool")
local j = Instance.new("Part")
local k = Instance.new("Script")
local l = Instance.new("LocalScript")

-- Использование sethiddenproperty или аналога убираем, так как не всегда доступно
--local m = sethiddenproperty or set_hidden_property

i.Name = "Telekinesis"
i.Parent = h
i.Grip = CFrame.new(0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0)
i.GripForward = Vector3.new(0, -1, 0)
i.GripRight = Vector3.new(0, 0, 1)
i.GripUp = Vector3.new(1, 0, 0)

j.Name = "Handle"
j.Parent = i
j.CFrame = CFrame.new(-17.2635937, 15.4915619, 46) * CFrame.Angles(0, math.rad(180), math.rad(90))
j.Color = Color3.new(0.0666667, 0.0666667, 0.0666667)
j.Transparency = 1
j.Size = Vector3.new(1, 1.2, 1)
j.BottomSurface = Enum.SurfaceType.Weld
j.BrickColor = BrickColor.new("Really black")
j.Material = Enum.Material.Metal
j.TopSurface = Enum.SurfaceType.Smooth

k.Name = "LineConnect"
k.Parent = i

table.insert(
    g,
    a(
        k,
        function()
            wait()
            local script = k -- теперь локальная ссылка на скрипт
            local n = script.Part2
            local o = script.Part1.Value
            local p = script.Part2.Value
            local q = script.Par.Value
            local color = script.Color
            local r = Instance.new("Part")
            r.TopSurface = Enum.SurfaceType.Smooth
            r.BottomSurface = Enum.SurfaceType.Smooth
            r.Reflectance = 0.5
            r.Name = "Laser"
            r.Locked = true
            r.CanCollide = false
            r.Anchored = true
            r.FormFactor = Enum.FormFactor.Custom
            r.Size = Vector3.new(1, 1, 1)
            local s = Instance.new("BlockMesh")
            s.Parent = r

            while true do
                if n.Value == nil then
                    break
                end
                if o == nil or p == nil or q == nil then
                    break
                end
                if not o.Parent or not p.Parent or not q.Parent then
                    break
                end
                local t = CFrame.new(o.Position, p.Position)
                local dist = (o.Position - p.Position).Magnitude
                r.Parent = q
                r.BrickColor = color.Value.BrickColor
                r.Reflectance = color.Value.Reflectance
                r.Transparency = color.Value.Transparency
                r.CFrame = CFrame.new(o.Position + t.LookVector * dist / 2, p.Position)
                s.Scale = Vector3.new(0.25, 0.25, dist)
                wait()
            end

            r:Destroy()
            script:Destroy()
        end
    )
)

k.Disabled = true

l.Name = "MainScript"
l.Parent = i

table.insert(
    g,
    a(
        l,
        function()
            wait()
            local script = l
            local tool = script.Parent
            local lineconnect = tool.LineConnect
            local object = nil
            local mousedown = false
            local objval = nil
            local dist = nil

            local BP = Instance.new("BodyPosition")
            BP.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            BP.P = 1100 -- чуть повышаем P (чем выше, тем сильнее позиционирование)

            local point = Instance.new("Part")
            point.Locked = true
            point.Anchored = true
            point.FormFactor = Enum.FormFactor.Custom
            point.Shape = Enum.PartType.Ball
            point.BrickColor = BrickColor.new("Black")
            point.Size = Vector3.new(1, 1, 1)
            point.CanCollide = false
            local s = Instance.new("SpecialMesh", point)
            s.MeshType = Enum.MeshType.Sphere
            s.Scale = Vector3.new(0.7, 0.7, 0.7)

            local handle = tool.Handle
            local front = handle
            local color = handle

            local BPClone = BP:Clone()
            BPClone.MaxForce = Vector3.new(30000, 30000, 30000)

            local function LineConnect(o, p, q)
                local w = Instance.new("ObjectValue")
                w.Value = o
                w.Name = "Part1"
                local x = Instance.new("ObjectValue")
                x.Value = p
                x.Name = "Part2"
                local y = Instance.new("ObjectValue")
                y.Value = q
                y.Name = "Par"
                local z = Instance.new("ObjectValue")
                z.Value = color
                z.Name = "Color"
                local A = lineconnect:Clone()
                A.Disabled = false
                w.Parent = A
                x.Parent = A
                y.Parent = A
                z.Parent = A
                A.Parent = workspace
                if p == object then
                    objval = x
                end
            end

            local function onButton1Down(B)
                if mousedown then
                    return
                end
                mousedown = true

                coroutine.wrap(function()
                    local C = point:Clone()
                    C.Parent = tool
                    LineConnect(front, C, workspace)
                    while mousedown do
                        C.Parent = tool
                        if object == nil then
                            if B.Target == nil then
                                local t = CFrame.new(front.Position, B.Hit.p)
                                C.CFrame = CFrame.new(front.Position + t.LookVector * 1000)
                            else
                                C.CFrame = CFrame.new(B.Hit.p)
                            end
                        else
                            LineConnect(front, object, workspace)
                            break
                        end
                        wait()
                    end
                    C:Destroy()
                end)()

                while mousedown do
                    if B.Target and not B.Target.Anchored then
                        object = B.Target
                        dist = (object.Position - front.Position).Magnitude
                        break
                    end
                    wait()
                end

                while mousedown do
                    if not object or not object.Parent then
                        break
                    end
                    local t = CFrame.new(front.Position, B.Hit.p)
                    BP.Parent = object
                    BP.Position = front.Position + t.LookVector * dist
                    wait()
                end
                BP:Destroy()
                object = nil
                if objval then
                    objval.Value = nil
                end
            end

            local function onKeyDown(E)
                E = E:lower()
                if E == "q" then
                    if dist and dist > 10 then
                        dist = dist - 10
                    else
                        dist = 10
                    end
                elseif E == "r" then
                    if not object then return end
                    for _, child in pairs(object:GetChildren()) do
                        if child:IsA("BodyGyro") then
                            return
                        end
                    end
                    local BG = Instance.new("BodyGyro")
                    BG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                    BG.CFrame = object.CFrame
                    BG.Parent = object
                    wait(0.1) -- дождёмся эффекта
                    BG:Destroy()

                    -- Очистка остальных BodyGyro
                    for _, child in pairs(object:GetChildren()) do
                        if child:IsA("BodyGyro") then
                            child:Destroy()
                        end
                    end
                    if object then
                        object.Velocity = Vector3.new(0, 0, 0)
                        object.RotVelocity = Vector3.new(0, 0, 0)
                        object.Orientation = Vector3.new(0, 0, 0)
                    end
                elseif E == "e" then
                    if dist then dist = dist + 10 end
                elseif E == "t" then
                    dist = 10
                elseif E == "y" then
                    dist = 200
                elseif E == "=" then
                    BP.P = BP.P * 1.5
                elseif E == "-" then
                    BP.P = BP.P * 0.5
                end
            end

            local function onEquipped(B)
                local I = tool.Parent
                local human = I:FindFirstChildOfClass("Humanoid")
                if human then
                    human.Changed:Connect(function()
                        if human.Health == 0 then
                            mousedown = false
                            if BP.Parent then BP:Destroy() end
                            if point.Parent then point:Destroy() end
                            if tool.Parent then tool:Destroy() end
                        end
                    end)
                end

                B.Button1Down:Connect(function()
                    onButton1Down(B)
                end)
                B.Button1Up:Connect(function()
                    mousedown = false
                end)
                B.KeyDown:Connect(function(key)
                    onKeyDown(key)
                end)
                B.Icon = "rbxasset://textures/GunCursor.png"
            end

            tool.Equipped:Connect(onEquipped)
        end
    )
)

-- Перемещаем модели из Lighting в игрока
for _, H in pairs(h:GetChildren()) do
    H.Parent = LocalPlayer.Backpack
    pcall(function()
        H:MakeJoints()
    end)
end
h:Destroy()

-- Запускаем все функции из таблицы g в отдельных потоках
for _, func in pairs(g) do
    spawn(function()
        pcall(func)
    end)
end
