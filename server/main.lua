-- Tokyo Box Server Main Handler
local QBCore = exports['qb-core']:GetCoreObject()

-- Event Handlers
RegisterNetEvent('tokyo_box:getPlayerPlaylists')
AddEventHandler('tokyo_box:getPlayerPlaylists', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Verificar permissão VIP
    if not exports["tokyo_box"]:CheckPlayerVIP(src) then
        TriggerClientEvent('QBCore:Notify', src, 'Acesso negado: Apenas VIPs podem usar o Tokyo Box!', 'error')
        return
    end
    
    -- Obter playlists
    local playlists = exports["tokyo_box"]:GetPlayerPlaylists(src)
    
    -- Enviar para o cliente
    TriggerClientEvent('tokyo_box:receivePlayerPlaylists', src, playlists)
    
    -- Enviar configurações
    local settings = exports["tokyo_box"]:GetPlayerSettings(src)
    if settings then
        TriggerClientEvent('tokyo_box:receivePlayerSettings', src, settings)
    end
end)

RegisterNetEvent('tokyo_box:createPlaylist')
AddEventHandler('tokyo_box:createPlaylist', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Verificar permissão VIP
    if not exports["tokyo_box"]:CheckPlayerVIP(src) then
        TriggerClientEvent('QBCore:Notify', src, 'Acesso negado: Apenas VIPs podem criar playlists!', 'error')
        return
    end
    
    -- Validar dados
    if not data.name or data.name:len() < 3 then
        TriggerClientEvent('QBCore:Notify', src, 'O nome da playlist deve ter pelo menos 3 caracteres!', 'error')
        return
    end
    
    -- Criar playlist
    local success, result = exports["tokyo_box"]:CreatePlaylist(src, data.name, data.description or '')
    
    if success then
        TriggerClientEvent('QBCore:Notify', src, 'Playlist criada com sucesso!', 'success')
        
        -- Atualizar playlists do jogador
        local playlists = exports["tokyo_box"]:GetPlayerPlaylists(src)
        TriggerClientEvent('tokyo_box:receivePlayerPlaylists', src, playlists)
    else
        TriggerClientEvent('QBCore:Notify', src, 'Erro ao criar playlist: ' .. (result or 'Desconhecido'), 'error')
    end
end)

RegisterNetEvent('tokyo_box:getPlaylistTracks')
AddEventHandler('tokyo_box:getPlaylistTracks', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Verificar permissão VIP
    if not exports["tokyo_box"]:CheckPlayerVIP(src) then
        TriggerClientEvent('QBCore:Notify', src, 'Acesso negado: Apenas VIPs podem ver playlists!', 'error')
        return
    end
    
    -- Validar dados
    if not data.playlistId then
        TriggerClientEvent('QBCore:Notify', src, 'ID da playlist inválido!', 'error')
        return
    end
    
    -- Obter informações da playlist
    local playlistInfo = exports["tokyo_box"]:GetPlaylistInfo(data.playlistId)
    if not playlistInfo then
        TriggerClientEvent('QBCore:Notify', src, 'Playlist não encontrada!', 'error')
        return
    end
    
    -- Obter faixas
    local tracks = exports["tokyo_box"]:GetPlaylistTracks(data.playlistId)
    
    -- Enviar para o cliente
    TriggerClientEvent('tokyo_box:playlistTracks', src, {
        tracks = tracks,
        playlistInfo = playlistInfo
    })
end)

RegisterNetEvent('tokyo_box:addToPlaylist')
AddEventHandler('tokyo_box:addToPlaylist', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Verificar permissão VIP
    if not exports["tokyo_box"]:CheckPlayerVIP(src) then
        TriggerClientEvent('QBCore:Notify', src, 'Acesso negado: Apenas VIPs podem adicionar músicas!', 'error')
        return
    end
    
    -- Validar dados
    if not data.trackId or not data.playlistId then
        TriggerClientEvent('QBCore:Notify', src, 'Dados inválidos!', 'error')
        return
    end
    
    -- Buscar detalhes da faixa se não fornecidos
    local trackData = data.trackData
    if not trackData and data.trackId then
        -- Em uma implementação real, você buscaria esses dados de algum lugar
        -- Aqui vamos criar um objeto mínimo
        trackData = {
            id = data.trackId,
            title = "Música " .. data.trackId,
            artist = "Artista Desconhecido"
        }
    end
    
    -- Adicionar à playlist
    local success, result = exports["tokyo_box"]:AddTrackToPlaylist(src, data.playlistId, trackData)
    
    if success then
        TriggerClientEvent('QBCore:Notify', src, 'Música adicionada à playlist com sucesso!', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Erro ao adicionar música: ' .. (result or 'Desconhecido'), 'error')
    end
end)

RegisterNetEvent('tokyo_box:getFavorites')
AddEventHandler('tokyo_box:getFavorites', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Verificar permissão VIP
    if not exports["tokyo_box"]:CheckPlayerVIP(src) then
        TriggerClientEvent('QBCore:Notify', src, 'Acesso negado: Apenas VIPs podem ver favoritos!', 'error')
        return
    end
    
    -- Obter favoritos
    local favorites = exports["tokyo_box"]:GetPlayerFavorites(src)
    
    -- Enviar para o cliente
    TriggerClientEvent('tokyo_box:favorites', src, {
        favorites = favorites
    })
end)

RegisterNetEvent('tokyo_box:toggleFavorite')
AddEventHandler('tokyo_box:toggleFavorite', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Verificar permissão VIP
    if not exports["tokyo_box"]:CheckPlayerVIP(src) then
        TriggerClientEvent('QBCore:Notify', src, 'Acesso negado: Apenas VIPs podem favoritar músicas!', 'error')
        return
    end
    
    -- Validar dados
    if not data.trackId then
        TriggerClientEvent('QBCore:Notify', src, 'ID da faixa inválido!', 'error')
        return
    end
    
    -- Buscar detalhes da faixa se não fornecidos
    local trackData = data.trackData
    if not trackData and data.trackId then
        -- Em uma implementação real, você buscaria esses dados de algum lugar
        -- Aqui vamos criar um objeto mínimo
        trackData = {
            id = data.trackId,
            title = "Música " .. data.trackId,
            artist = "Artista Desconhecido"
        }
    end
    
    -- Verificar se já é favorito
    local isFavorite = exports["tokyo_box"]:IsTrackFavorite(src, data.trackId)
    
    -- Alternar status
    local success, _ = exports["tokyo_box"]:ToggleFavoriteTrack(src, trackData)
    
    if success then
        local message = isFavorite and "Música removida dos favoritos!" or "Música adicionada aos favoritos!"
        TriggerClientEvent('QBCore:Notify', src, message, 'success')
        
        -- Atualizar favoritos
        local favorites = exports["tokyo_box"]:GetPlayerFavorites(src)
        TriggerClientEvent('tokyo_box:favorites', src, {
            favorites = favorites
        })
    else
        TriggerClientEvent('QBCore:Notify', src, 'Erro ao alterar favorito!', 'error')
    end
end)

RegisterNetEvent('tokyo_box:savePlayerSettings')
AddEventHandler('tokyo_box:savePlayerSettings', function(settings)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Salvar configurações
    exports["tokyo_box"]:SavePlayerSettings(src, settings)
end)

RegisterNetEvent('tokyo_box:checkVIPItem')
AddEventHandler('tokyo_box:checkVIPItem', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then 
        TriggerClientEvent('tokyo_box:setVIPStatus', src, false)
        return
    end
    
    -- Verificar se o jogador possui o item VIP
    local hasItem = false
    if Config.VIPItemName then
        local item = Player.Functions.GetItemByName(Config.VIPItemName)
        hasItem = item and item.amount > 0
    end
    
    TriggerClientEvent('tokyo_box:setVIPStatus', src, hasItem)
end)

-- Tocar música
RegisterNetEvent('tokyo_box:playTrack')
AddEventHandler('tokyo_box:playTrack', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Verificar permissão VIP
    if not exports["tokyo_box"]:CheckPlayerVIP(src) then
        TriggerClientEvent('QBCore:Notify', src, 'Acesso negado: Apenas VIPs podem reproduzir músicas!', 'error')
        return
    end
    
    -- Validar dados
    if not data.trackId then
        TriggerClientEvent('QBCore:Notify', src, 'ID da faixa inválido!', 'error')
        return
    end
    
    -- Obter URL de streaming (Evento 'getStreamUrl' retornará a URL para o cliente)
    TriggerClientEvent('tokyo_box:getStreamUrl', src, data.trackId, data.playlistId)
end)

-- Pausar música
RegisterNetEvent('tokyo_box:pauseTrack')
AddEventHandler('tokyo_box:pauseTrack', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Verificar permissão VIP
    if not exports["tokyo_box"]:CheckPlayerVIP(src) then
        TriggerClientEvent('QBCore:Notify', src, 'Acesso negado: Apenas VIPs podem controlar a música!', 'error')
        return
    end
    
    -- Notificar cliente para pausar
    TriggerClientEvent('tokyo_box:pauseTrack', src)
end)

-- Retomar música
RegisterNetEvent('tokyo_box:resumeTrack')
AddEventHandler('tokyo_box:resumeTrack', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Verificar permissão VIP
    if not exports["tokyo_box"]:CheckPlayerVIP(src) then
        TriggerClientEvent('QBCore:Notify', src, 'Acesso negado: Apenas VIPs podem controlar a música!', 'error')
        return
    end
    
    -- Notificar cliente para retomar
    TriggerClientEvent('tokyo_box:resumeTrack', src)
end)

-- Próxima música
RegisterNetEvent('tokyo_box:nextTrack')
AddEventHandler('tokyo_box:nextTrack', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Verificar permissão VIP
    if not exports["tokyo_box"]:CheckPlayerVIP(src) then
        TriggerClientEvent('QBCore:Notify', src, 'Acesso negado: Apenas VIPs podem controlar a música!', 'error')
        return
    end
    
    -- Notificar cliente para próxima música
    TriggerClientEvent('tokyo_box:nextTrack', src)
end)

-- Música anterior
RegisterNetEvent('tokyo_box:previousTrack')
AddEventHandler('tokyo_box:previousTrack', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Verificar permissão VIP
    if not exports["tokyo_box"]:CheckPlayerVIP(src) then
        TriggerClientEvent('QBCore:Notify', src, 'Acesso negado: Apenas VIPs podem controlar a música!', 'error')
        return
    end
    
    -- Notificar cliente para música anterior
    TriggerClientEvent('tokyo_box:previousTrack', src)
end)