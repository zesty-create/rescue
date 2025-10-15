
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
