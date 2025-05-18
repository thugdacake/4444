-- Tokyo Box Client Main
local QBCore = exports['qb-core']:GetCoreObject()
local isUIOpen = false
local currentTrack = nil
local currentPlaylist = nil
local volume = Config.DefaultVolume
local isMuted = false
local isPaused = false
local bluetoothEnabled = Config.DefaultBluetoothStatus
local audioRange = Config.DefaultAudioRange

-- Local player caching
local PlayerData = {}
local isVIP = false

-- Initialize the resource
Citizen.CreateThread(function()
    while QBCore == nil do
        TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
        Citizen.Wait(0)
    end

    while QBCore.Functions.GetPlayerData() == nil do
        Citizen.Wait(100)
    end

    PlayerData = QBCore.Functions.GetPlayerData()
    CheckVIPStatus()
    
    if Config.Debug then
        print("Tokyo Box initialized successfully!")
    end
end)

-- Update player data when it changes
RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    CheckVIPStatus()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate')
AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
    CheckVIPStatus()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload')
AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    isVIP = false
end)

-- Main command to open/close the Tokyo Box
RegisterCommand(Config.CommandName, function()
    ToggleTokyoBox()
end, false)

RegisterKeyMapping(Config.CommandName, 'Open Tokyo Box Music Player', 'keyboard', Config.ToggleKey)

-- Toggle the Tokyo Box UI
function ToggleTokyoBox()
    if isUIOpen then
        CloseTokyoBox()
    else
        OpenTokyoBox()
    end
end

-- Open the Tokyo Box UI
function OpenTokyoBox()
    if Config.EnableVIPCheck and not isVIP then
        TriggerEvent('QBCore:Notify', 'Acesso negado: Apenas VIPs podem usar o Tokyo Box!', 'error')
        return
    end
    
    isUIOpen = true
    -- Get player playlists before opening UI
    TriggerServerEvent('tokyo_box:getPlayerPlaylists')
    
    -- Open NUI
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "openUI",
        volume = volume,
        theme = Config.DefaultTheme,
        bluetooth = bluetoothEnabled,
        audioRange = audioRange
    })
end

-- Close the Tokyo Box UI
function CloseTokyoBox()
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "closeUI"
    })
    
    -- Save player settings
    TriggerServerEvent('tokyo_box:savePlayerSettings', {
        volume = volume,
        lastTrack = currentTrack,
        lastPlaylist = currentPlaylist,
        bluetooth = bluetoothEnabled,
        audioRange = audioRange
    })
end

-- Setting player VIP status
function CheckVIPStatus()
    isVIP = false
    
    if not Config.EnableVIPCheck then
        isVIP = true
        return
    end
    
    -- Check for custom permissions
    if PlayerData.group then
        for i=1, #Config.VIPGroups, 1 do
            if PlayerData.group == Config.VIPGroups[i] then
                isVIP = true
                return
            end
        end
    end
    
    -- Check for VIP job if configured
    if Config.VIPJobName and PlayerData.job and PlayerData.job.name == Config.VIPJobName then
        isVIP = true
        return
    end
    
    -- Check for VIP item if configured
    if Config.VIPItemName then
        TriggerServerEvent('tokyo_box:checkVIPItem')
    end
end

-- Toggle Bluetooth function
function ToggleBluetooth(state)
    bluetoothEnabled = state
    
    -- Update the player with new bluetooth state
    if currentTrack and isSoundStarted then
        if bluetoothEnabled then
            -- If in a vehicle, make sure the music plays through the vehicle
            local playerPed = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            
            if vehicle ~= 0 then
                -- Play through vehicle
                exports['xsound']:PlayUrlPos("tokyo_box_music", currentTrack.url, volume / 100, GetEntityCoords(vehicle), false, {
                    soundId = "tokyo_box_music",
                    distance = audioRange
                })
            else
                -- Play normal spatial audio around player
                local playerPos = GetEntityCoords(playerPed)
                exports['xsound']:PlayUrlPos("tokyo_box_music", currentTrack.url, volume / 100, playerPos, false, {
                    soundId = "tokyo_box_music",
                    distance = audioRange
                })
            end
        else
            -- Play only for the player (non-spatial)
            exports['xsound']:PlayUrl("tokyo_box_music", currentTrack.url, volume / 100, false)
        end
    end
    
    -- Notify UI of the bluetooth state change
    SendNUIMessage({
        type = "bluetoothState",
        enabled = bluetoothEnabled
    })
end

-- Set audio range
function SetAudioRange(range)
    audioRange = math.min(Config.MaxAudioRange, math.max(1.0, range))
    
    -- Update the range if sound is playing
    if currentTrack and isSoundStarted and bluetoothEnabled then
        exports['xsound']:Distance("tokyo_box_music", audioRange)
    end
    
    -- Notify UI of the range change
    SendNUIMessage({
        type = "audioRange",
        range = audioRange
    })
end

-- Event to receive VIP item check result
RegisterNetEvent('tokyo_box:setVIPStatus')
AddEventHandler('tokyo_box:setVIPStatus', function(status)
    isVIP = status
end)

-- Receive playlists from server
RegisterNetEvent('tokyo_box:receivePlayerPlaylists')
AddEventHandler('tokyo_box:receivePlayerPlaylists', function(playlists)
    if isUIOpen then
        SendNUIMessage({
            type = "setPlaylists",
            playlists = playlists
        })
    end
end)

-- Receive player settings from server
RegisterNetEvent('tokyo_box:receivePlayerSettings')
AddEventHandler('tokyo_box:receivePlayerSettings', function(settings)
    if settings then
        volume = settings.volume or Config.DefaultVolume
        currentTrack = settings.lastTrack
        currentPlaylist = settings.lastPlaylist
        bluetoothEnabled = settings.bluetooth or Config.DefaultBluetoothStatus
        audioRange = settings.audioRange or Config.DefaultAudioRange
        
        if isUIOpen then
            SendNUIMessage({
                type = "setSettings",
                settings = settings
            })
        end
    end
end)

-- Export functions for other resources
exports('IsTokyoBoxOpen', function()
    return isUIOpen
end)

exports('GetCurrentTrack', function()
    return currentTrack
end)

exports('GetCurrentPlaylist', function()
    return currentPlaylist
end)

exports('IsPlayerVIP', function()
    return isVIP
end)

exports('GetBluetoothStatus', function()
    return bluetoothEnabled
end)

exports('ToggleBluetoothStatus', function(status)
    ToggleBluetooth(status)
    return bluetoothEnabled
end)

exports('GetAudioRange', function()
    return audioRange
end)

exports('SetAudioRange', function(range)
    SetAudioRange(range)
    return audioRange
end)

-- Debug commands if enabled
if Config.Debug then
    RegisterCommand('tokyoboxdebug', function()
        print('Tokyo Box Debug Info:')
        print('isUIOpen: ' .. tostring(isUIOpen))
        print('isVIP: ' .. tostring(isVIP))
        print('volume: ' .. tostring(volume))
        print('currentTrack: ' .. (currentTrack and json.encode(currentTrack) or 'nil'))
        print('currentPlaylist: ' .. (currentPlaylist and json.encode(currentPlaylist) or 'nil'))
        print('bluetoothEnabled: ' .. tostring(bluetoothEnabled))
        print('audioRange: ' .. tostring(audioRange))
    end, false)
end