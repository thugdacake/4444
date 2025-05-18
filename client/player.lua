-- Tokyo Box Client Player
local QBCore = exports['qb-core']:GetCoreObject()

-- Variáveis para controle do player de música
isPlaying = false
isPaused = false
isMuted = false
currentTrack = nil
currentPlaylist = nil
volume = Config.DefaultVolume
audioRange = Config.DefaultAudioRange
bluetoothEnabled = Config.DefaultBluetoothStatus
playbackPosition = 0

-- Controle do player de música
function PlayTrack(trackData, playlistData)
    if not trackData or not trackData.id then
        QBCore.Functions.Notify('Erro ao reproduzir música: Dados inválidos', 'error')
        return
    end
    
    -- Se não tivermos uma URL, solicitar do servidor
    if not trackData.url then
        TriggerServerEvent('tokyo_box:getStreamUrl', trackData.id, trackData)
        currentPlaylist = playlistData
        return
    end
    
    -- Parar qualquer música que esteja tocando
    if exports['xsound']:soundExists("tokyo_box_music") then
        exports['xsound']:destroy("tokyo_box_music")
    end
    
    -- Reproduzir música
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
    
    -- Atualizar estado
    currentTrack = trackData
    if playlistData then
        currentPlaylist = playlistData
    end
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
end

-- Pausar música atual
function PauseTrack()
    if not isPlaying or not currentTrack then
        return false
    end
    
    if exports['xsound']:soundExists("tokyo_box_music") then
        exports['xsound']:Pause("tokyo_box_music")
        isPaused = true
        
        -- Notificar UI
        SendNUIMessage({
            type = "playerState",
            isPlaying = isPlaying,
            isPaused = isPaused
        })
        
        return true
    end
    
    return false
end

-- Retomar música pausada
function ResumeTrack()
    if not isPlaying or not isPaused or not currentTrack then
        return false
    end
    
    if exports['xsound']:soundExists("tokyo_box_music") then
        exports['xsound']:Resume("tokyo_box_music")
        isPaused = false
        
        -- Notificar UI
        SendNUIMessage({
            type = "playerState",
            isPlaying = isPlaying,
            isPaused = isPaused
        })
        
        return true
    end
    
    return false
end

-- Parar música
function StopTrack()
    if not isPlaying and not currentTrack then
        return false
    end
    
    if exports['xsound']:soundExists("tokyo_box_music") then
        exports['xsound']:destroy("tokyo_box_music")
    end
    
    isPlaying = false
    isPaused = false
    
    -- Notificar UI
    SendNUIMessage({
        type = "playerState",
        isPlaying = isPlaying,
        isPaused = isPaused
    })
    
    return true
end

-- Ajustar posição da música
function SeekTrack(position)
    if not isPlaying or not currentTrack then
        return false
    end
    
    if position < 0 then position = 0 end
    
    if exports['xsound']:soundExists("tokyo_box_music") then
        exports['xsound']:setTimeStamp("tokyo_box_music", position)
        return true
    end
    
    return false
end

-- Definir volume
function SetVolume(newVolume)
    volume = math.max(0, math.min(100, newVolume))
    
    if isPlaying and exports['xsound']:soundExists("tokyo_box_music") then
        exports['xsound']:setVolume("tokyo_box_music", volume / 100)
    end
    
    -- Notificar UI
    SendNUIMessage({
        type = "volumeChanged",
        volume = volume
    })
    
    return true
end

-- Mutar/desmutar
function ToggleMute()
    isMuted = not isMuted
    
    if isPlaying and exports['xsound']:soundExists("tokyo_box_music") then
        if isMuted then
            exports['xsound']:setVolume("tokyo_box_music", 0)
        else
            exports['xsound']:setVolume("tokyo_box_music", volume / 100)
        end
    end
    
    -- Notificar UI
    SendNUIMessage({
        type = "muteChanged",
        muted = isMuted
    })
    
    return isMuted
end

-- Exportar funções para uso externo
exports('PlayTrack', PlayTrack)
exports('PauseTrack', PauseTrack)
exports('ResumeTrack', ResumeTrack)
exports('StopTrack', StopTrack)
exports('SeekTrack', SeekTrack)
exports('SetVolume', SetVolume)
exports('ToggleMute', ToggleMute)