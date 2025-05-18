-- Tokyo Box NUI Handlers
local QBCore = exports['qb-core']:GetCoreObject()

-- NUI Callbacks
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    TriggerEvent('tokyo_box:closeUI')
    cb('ok')
end)

RegisterNUICallback('playTrack', function(data, cb)
    TriggerServerEvent('tokyo_box:playTrack', data)
    cb('ok')
end)

RegisterNUICallback('pauseTrack', function(data, cb)
    TriggerServerEvent('tokyo_box:pauseTrack')
    cb('ok')
end)

RegisterNUICallback('resumeTrack', function(data, cb)
    TriggerServerEvent('tokyo_box:resumeTrack')
    cb('ok')
end)

RegisterNUICallback('nextTrack', function(data, cb)
    TriggerServerEvent('tokyo_box:nextTrack')
    cb('ok')
end)

RegisterNUICallback('previousTrack', function(data, cb)
    TriggerServerEvent('tokyo_box:previousTrack')
    cb('ok')
end)

RegisterNUICallback('seekTrack', function(data, cb)
    TriggerEvent('tokyo_box:seekTrack', data.position)
    cb('ok')
end)

RegisterNUICallback('getPlayerPlaylists', function(data, cb)
    TriggerServerEvent('tokyo_box:getPlayerPlaylists')
    cb('ok')
end)

RegisterNUICallback('createPlaylist', function(data, cb)
    TriggerServerEvent('tokyo_box:createPlaylist', data)
    cb('ok')
end)

RegisterNUICallback('getPlaylistTracks', function(data, cb)
    TriggerServerEvent('tokyo_box:getPlaylistTracks', data)
    cb('ok')
end)

RegisterNUICallback('addToPlaylist', function(data, cb)
    TriggerServerEvent('tokyo_box:addToPlaylist', data)
    cb('ok')
end)

RegisterNUICallback('getFavorites', function(data, cb)
    TriggerServerEvent('tokyo_box:getFavorites')
    cb('ok')
end)

RegisterNUICallback('toggleFavorite', function(data, cb)
    TriggerServerEvent('tokyo_box:toggleFavorite', data)
    cb('ok')
end)

RegisterNUICallback('searchTracks', function(data, cb)
    TriggerServerEvent('tokyo_box:searchTracks', data.query)
    cb('ok')
end)

RegisterNUICallback('toggleBluetooth', function(data, cb)
    ToggleBluetooth(data.enabled)
    cb('ok')
end)

RegisterNUICallback('setVolume', function(data, cb)
    -- Defina o volume local e no xSound
    local newVolume = tonumber(data.volume) / 100
    if currentTrack and newVolume then
        volume = tonumber(data.volume)
        if isPlaying then
            exports['xsound']:setVolume("tokyo_box_music", newVolume)
        end
    end
    cb('ok')
end)

RegisterNUICallback('setAudioRange', function(data, cb)
    SetAudioRange(tonumber(data.range))
    cb('ok')
end)

RegisterNUICallback('goBack', function(data, cb)
    -- Pode ser usado para gerenciar o histórico do aplicativo
    cb('ok')
end)

-- Eventos do cliente
RegisterNetEvent('tokyo_box:searchResults')
AddEventHandler('tokyo_box:searchResults', function(results)
    -- Enviar resultados para o NUI
    SendNUIMessage({
        type = "searchResults",
        results = results
    })
end)

RegisterNetEvent('tokyo_box:receiveStreamUrl')
AddEventHandler('tokyo_box:receiveStreamUrl', function(trackData)
    -- Iniciar reprodução da faixa
    if not trackData or not trackData.url then
        QBCore.Functions.Notify('Erro ao obter URL da música!', 'error')
        return
    end
    
    -- Parar qualquer música que esteja tocando
    if exports['xsound']:soundExists("tokyo_box_music") then
        exports['xsound']:destroy("tokyo_box_music")
    end
    
    -- Iniciar nova música
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    if bluetoothEnabled then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if vehicle ~= 0 then
            -- Se estiver em um veículo, reproduzir pelo veículo
            exports['xsound']:PlayUrlPos("tokyo_box_music", trackData.url, volume / 100, GetEntityCoords(vehicle), false, {
                soundId = "tokyo_box_music",
                distance = audioRange
            })
        else
            -- Caso contrário, reproduzir pela posição do jogador
            exports['xsound']:PlayUrlPos("tokyo_box_music", trackData.url, volume / 100, coords, false, {
                soundId = "tokyo_box_music",
                distance = audioRange
            })
        end
    else
        -- Reproduzir apenas para o jogador
        exports['xsound']:PlayUrl("tokyo_box_music", trackData.url, volume / 100, false)
    end
    
    -- Atualizar variáveis de estado
    currentTrack = trackData
    isPlaying = true
    isPaused = false
    
    -- Notificar UI
    SendNUIMessage({
        type = "updatePlayer",
        track = currentTrack,
        playlist = currentPlaylist
    })
    
    -- Atualizar estado do player
    SendNUIMessage({
        type = "playerState",
        isPlaying = isPlaying,
        isPaused = isPaused
    })
end)

RegisterNetEvent('tokyo_box:closeUI')
AddEventHandler('tokyo_box:closeUI', function()
    CloseTokyoBox()
end)

RegisterNetEvent('tokyo_box:pauseTrack')
AddEventHandler('tokyo_box:pauseTrack', function()
    if exports['xsound']:soundExists("tokyo_box_music") then
        exports['xsound']:Pause("tokyo_box_music")
        isPaused = true
        
        -- Notificar UI
        SendNUIMessage({
            type = "playerState",
            isPlaying = true,
            isPaused = true
        })
    end
end)

RegisterNetEvent('tokyo_box:resumeTrack')
AddEventHandler('tokyo_box:resumeTrack', function()
    if exports['xsound']:soundExists("tokyo_box_music") and isPaused then
        exports['xsound']:Resume("tokyo_box_music")
        isPaused = false
        
        -- Notificar UI
        SendNUIMessage({
            type = "playerState",
            isPlaying = true,
            isPaused = false
        })
    end
end)

RegisterNetEvent('tokyo_box:seekTrack')
AddEventHandler('tokyo_box:seekTrack', function(position)
    if exports['xsound']:soundExists("tokyo_box_music") then
        exports['xsound']:setTimeStamp("tokyo_box_music", position)
    end
end)

RegisterNetEvent('tokyo_box:nextTrack')
AddEventHandler('tokyo_box:nextTrack', function()
    -- Em uma implementação real, isso buscaria a próxima faixa da playlist atual
    -- Por enquanto, apenas notificar que não há próxima faixa
    QBCore.Functions.Notify('Não foi possível encontrar a próxima música', 'error')
end)

RegisterNetEvent('tokyo_box:previousTrack')
AddEventHandler('tokyo_box:previousTrack', function()
    -- Em uma implementação real, isso buscaria a faixa anterior da playlist atual
    -- Por enquanto, apenas notificar que não há faixa anterior
    QBCore.Functions.Notify('Não foi possível encontrar a música anterior', 'error')
end)

-- Thread para atualizar o tempo de reprodução
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000) -- Atualizar a cada segundo
        
        if isPlaying and not isPaused and not isMuted then
            if exports['xsound']:soundExists("tokyo_box_music") then
                local pos = exports['xsound']:getTimeStamp("tokyo_box_music")
                local dur = exports['xsound']:getMaxDuration("tokyo_box_music")
                
                if pos and dur and dur > 0 then
                    SendNUIMessage({
                        type = "position",
                        position = pos,
                        duration = dur
                    })
                end
            end
        end
    end
end)

-- Thread para gerenciar áudio posicional quando o Bluetooth está ativado
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000) -- Verificar a cada segundo
        
        if bluetoothEnabled and isPlaying and not isPaused and exports['xsound']:soundExists("tokyo_box_music") then
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            if vehicle ~= 0 then
                -- Atualizar posição para o veículo
                exports['xsound']:Position("tokyo_box_music", GetEntityCoords(vehicle))
            else
                -- Atualizar posição para o jogador
                exports['xsound']:Position("tokyo_box_music", coords)
            end
        end
    end
end)