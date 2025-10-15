
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

local currentWeapons = {}
local firing = false
local connection

local WEAPON_LIST = {
    "[Double-Barrel SG]",
    "[Revolver]", 
    "[TacticalShotgun]"
}

local GUN_COMPONENTS = {
    "GunScript",
    "GunClientShotgun",
    "GunClient"
}

local function maintainAllStats(weapon)
    RunService.Heartbeat:Connect(function()
        if weapon and weapon.Parent then
            pcall(function()
                weapon.Ammo.Value = 2
                weapon.MaxAmmo.Value = 2
                weapon.Range.Value = 999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
                weapon.ShootingCooldown.Value = -99999999
                if weapon:FindFirstChild("StoredAmmo") then
                    weapon.StoredAmmo.Value = 999
                end
                if weapon:FindFirstChild("ReloadTime") then
                    weapon.ReloadTime.Value = 0
                end
            end)
        end
    end)
end

local function toggleGunComponents(weapon, enabled)
    for _, compName in ipairs(GUN_COMPONENTS) do
        local comp = weapon:FindFirstChild(compName)
        if comp then
            comp.Enabled = enabled
        end
    end
end

local function updateWeapons()
    currentWeapons = {}
    for _, location in {localPlayer.Backpack, localPlayer.Character} do
        if location then
            for _, weaponName in ipairs(WEAPON_LIST) do
                local weapon = location:FindFirstChild(weaponName)
                if weapon then
                    table.insert(currentWeapons, weapon)
                    maintainAllStats(weapon)
                    if location == localPlayer.Backpack then
                        toggleGunComponents(weapon, false)
                    else
                        toggleGunComponents(weapon, true)
                    end
                end
            end
        end
    end
end

local function onWeaponEquipped(weapon)
    toggleGunComponents(weapon, true)
end

local function onWeaponUnequipped(weapon)
    toggleGunComponents(weapon, false)
end

local function connectWeaponEvents(weapon)
    if weapon:IsA("Tool") then
        weapon.Equipped:Connect(function() onWeaponEquipped(weapon) end)
        weapon.Unequipped:Connect(function() onWeaponUnequipped(weapon) end)
    end
end

localPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    updateWeapons()
    for _, weapon in ipairs(currentWeapons) do
        connectWeaponEvents(weapon)
    end
end)

localPlayer.Backpack.ChildAdded:Connect(function(child)
    if table.find(WEAPON_LIST, child.Name) then
        updateWeapons()
        for _, weapon in ipairs(currentWeapons) do
            connectWeaponEvents(weapon)
        end
    end
end)

updateWeapons()
for _, weapon in ipairs(currentWeapons) do
    connectWeaponEvents(weapon)
end

local function startFiring()
    if connection then connection:Disconnect() end
    connection = RunService.Heartbeat:Connect(function()
        if firing then
            for _, weapon in ipairs(currentWeapons) do
                for _, v in ipairs(weapon:GetDescendants()) do
                    if v:IsA("RemoteEvent") then
                        pcall(function() v:FireServer() end)
                        pcall(function() v:FireServer(localPlayer:GetMouse().Hit.Position) end)
                    end
                end
                pcall(function() weapon:Activate() end)
                pcall(function() 
                    if weapon:FindFirstChild("ShootingCooldown") then
                        weapon.ShootingCooldown.Value = -99999999 
                    end
                end)
            end
        end
    end)
end

UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        firing = true
        startFiring()
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        firing = false
    end
end)
