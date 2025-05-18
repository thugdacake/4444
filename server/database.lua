-- Tokyo Box Database Handler
local QBCore = nil
TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)

-- Inicializar banco de dados
function InitializeDatabase()
    -- Verificar se as tabelas necessárias existem
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `tokyo_box_playlists` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `owner` VARCHAR(50) NOT NULL,
            `name` VARCHAR(50) NOT NULL,
            `description` TEXT,
            `cover_url` VARCHAR(255),
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    ]], {}, function(success)
        if success then
            print("^2Tokyo Box: Tabela de playlists inicializada com sucesso^7")
        end
    end)
    
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `tokyo_box_playlist_tracks` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `playlist_id` INT NOT NULL,
            `track_id` VARCHAR(50) NOT NULL,
            `title` VARCHAR(100) NOT NULL,
            `artist` VARCHAR(100),
            `thumbnail` VARCHAR(255),
            `duration` INT DEFAULT 0,
            `added_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `position` INT DEFAULT 0,
            FOREIGN KEY (`playlist_id`) REFERENCES `tokyo_box_playlists`(`id`) ON DELETE CASCADE
        );
    ]], {}, function(success)
        if success then
            print("^2Tokyo Box: Tabela de faixas inicializada com sucesso^7")
        end
    end)
    
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `tokyo_box_favorites` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `owner` VARCHAR(50) NOT NULL,
            `track_id` VARCHAR(50) NOT NULL,
            `title` VARCHAR(100) NOT NULL,
            `artist` VARCHAR(100),
            `thumbnail` VARCHAR(255),
            `duration` INT DEFAULT 0,
            `added_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `owner_track` (`owner`, `track_id`)
        );
    ]], {}, function(success)
        if success then
            print("^2Tokyo Box: Tabela de favoritos inicializada com sucesso^7")
        end
    end)
    
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `tokyo_box_settings` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `owner` VARCHAR(50) NOT NULL,
            `volume` INT DEFAULT 70,
            `bluetooth` BOOLEAN DEFAULT FALSE,
            `range` FLOAT DEFAULT 10.0,
            `theme` VARCHAR(50) DEFAULT 'galaxy',
            `last_track` TEXT,
            `last_playlist` TEXT,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            UNIQUE KEY `owner_unique` (`owner`)
        );
    ]], {}, function(success)
        if success then
            print("^2Tokyo Box: Tabela de configurações inicializada com sucesso^7")
        end
    end)
end

-- Obter playlists do jogador
function GetPlayerPlaylists(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end
    
    local identifier = Player.PlayerData.citizenid
    
    local playlists = {}
    local result = exports.oxmysql:executeSync("SELECT * FROM tokyo_box_playlists WHERE owner = ? ORDER BY created_at DESC", {
        identifier
    })
    
    if result and #result > 0 then
        for i=1, #result do
            local playlist = result[i]
            
            -- Contar número de músicas na playlist
            local countResult = exports.oxmysql:executeSync("SELECT COUNT(*) as count FROM tokyo_box_playlist_tracks WHERE playlist_id = ?", {
                playlist.id
            })
            
            local songCount = 0
            if countResult and countResult[1] then
                songCount = countResult[1].count
            end
            
            table.insert(playlists, {
                id = playlist.id,
                name = playlist.name,
                description = playlist.description,
                cover_url = playlist.cover_url,
                songCount = songCount,
                created_at = playlist.created_at
            })
        end
    end
    
    return playlists
end

-- Obter faixas de uma playlist
function GetPlaylistTracks(playlistId)
    local tracks = {}
    local result = exports.oxmysql:executeSync("SELECT * FROM tokyo_box_playlist_tracks WHERE playlist_id = ? ORDER BY position ASC", {
        playlistId
    })
    
    if result and #result > 0 then
        for i=1, #result do
            local track = result[i]
            table.insert(tracks, {
                id = track.track_id,
                title = track.title,
                artist = track.artist,
                thumbnail = track.thumbnail,
                duration = track.duration,
                position = track.position
            })
        end
    end
    
    return tracks
end

-- Obter informações da playlist
function GetPlaylistInfo(playlistId)
    local result = exports.oxmysql:executeSync("SELECT * FROM tokyo_box_playlists WHERE id = ?", {
        playlistId
    })
    
    if result and result[1] then
        return {
            id = result[1].id,
            name = result[1].name,
            description = result[1].description,
            cover_url = result[1].cover_url,
            owner = result[1].owner
        }
    end
    
    return nil
end

-- Criar playlist
function CreatePlaylist(source, name, description)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local identifier = Player.PlayerData.citizenid
    
    -- Verificar se o jogador já tem o número máximo de playlists
    local playlistCount = exports.oxmysql:executeSync("SELECT COUNT(*) as count FROM tokyo_box_playlists WHERE owner = ?", {
        identifier
    })
    
    if playlistCount and playlistCount[1] and playlistCount[1].count >= Config.MaxPlaylists then
        return false, "Limite de playlists atingido"
    end
    
    -- Criar playlist
    local result = exports.oxmysql:insert("INSERT INTO tokyo_box_playlists (owner, name, description) VALUES (?, ?, ?)", {
        identifier, name, description
    })
    
    if result and result > 0 then
        return true, result
    end
    
    return false, "Erro ao criar playlist"
end

-- Adicionar faixa à playlist
function AddTrackToPlaylist(source, playlistId, trackData)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local identifier = Player.PlayerData.citizenid
    
    -- Verificar se o jogador é dono da playlist
    local playlistInfo = GetPlaylistInfo(playlistId)
    if not playlistInfo or playlistInfo.owner ~= identifier then
        return false, "Você não tem permissão para editar esta playlist"
    end
    
    -- Verificar se a playlist já tem o número máximo de faixas
    local trackCount = exports.oxmysql:executeSync("SELECT COUNT(*) as count FROM tokyo_box_playlist_tracks WHERE playlist_id = ?", {
        playlistId
    })
    
    if trackCount and trackCount[1] and trackCount[1].count >= Config.MaxSongsPerPlaylist then
        return false, "Limite de músicas na playlist atingido"
    end
    
    -- Verificar se a faixa já está na playlist
    local existingTrack = exports.oxmysql:executeSync("SELECT id FROM tokyo_box_playlist_tracks WHERE playlist_id = ? AND track_id = ?", {
        playlistId, trackData.id
    })
    
    if existingTrack and #existingTrack > 0 then
        return false, "Esta faixa já está na playlist"
    end
    
    -- Obter a próxima posição
    local nextPosition = exports.oxmysql:executeSync("SELECT COALESCE(MAX(position), 0) + 1 as next_pos FROM tokyo_box_playlist_tracks WHERE playlist_id = ?", {
        playlistId
    })
    
    local position = 1
    if nextPosition and nextPosition[1] then
        position = nextPosition[1].next_pos
    end
    
    -- Adicionar faixa
    local result = exports.oxmysql:insert("INSERT INTO tokyo_box_playlist_tracks (playlist_id, track_id, title, artist, thumbnail, duration, position) VALUES (?, ?, ?, ?, ?, ?, ?)", {
        playlistId, trackData.id, trackData.title, trackData.artist, trackData.thumbnail, trackData.duration or 0, position
    })
    
    if result and result > 0 then
        return true
    end
    
    return false, "Erro ao adicionar faixa à playlist"
end

-- Remover faixa da playlist
function RemoveTrackFromPlaylist(source, playlistId, trackId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local identifier = Player.PlayerData.citizenid
    
    -- Verificar se o jogador é dono da playlist
    local playlistInfo = GetPlaylistInfo(playlistId)
    if not playlistInfo or playlistInfo.owner ~= identifier then
        return false, "Você não tem permissão para editar esta playlist"
    end
    
    -- Remover faixa
    local result = exports.oxmysql:execute("DELETE FROM tokyo_box_playlist_tracks WHERE playlist_id = ? AND track_id = ?", {
        playlistId, trackId
    })
    
    if result and result.affectedRows > 0 then
        return true
    end
    
    return false, "Erro ao remover faixa da playlist"
end

-- Excluir playlist
function DeletePlaylist(source, playlistId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local identifier = Player.PlayerData.citizenid
    
    -- Verificar se o jogador é dono da playlist
    local playlistInfo = GetPlaylistInfo(playlistId)
    if not playlistInfo or playlistInfo.owner ~= identifier then
        return false, "Você não tem permissão para excluir esta playlist"
    end
    
    -- Excluir playlist (as faixas serão excluídas automaticamente pela chave estrangeira)
    local result = exports.oxmysql:execute("DELETE FROM tokyo_box_playlists WHERE id = ?", {
        playlistId
    })
    
    if result and result.affectedRows > 0 then
        return true
    end
    
    return false, "Erro ao excluir playlist"
end

-- Obter músicas favoritas do jogador
function GetPlayerFavorites(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end
    
    local identifier = Player.PlayerData.citizenid
    
    local favorites = {}
    local result = exports.oxmysql:executeSync("SELECT * FROM tokyo_box_favorites WHERE owner = ? ORDER BY added_at DESC", {
        identifier
    })
    
    if result and #result > 0 then
        for i=1, #result do
            local track = result[i]
            table.insert(favorites, {
                id = track.track_id,
                title = track.title,
                artist = track.artist,
                thumbnail = track.thumbnail,
                duration = track.duration
            })
        end
    end
    
    return favorites
end

-- Adicionar música aos favoritos
function AddFavoriteTrack(source, trackData)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local identifier = Player.PlayerData.citizenid
    
    -- Verificar se a música já está nos favoritos
    local existingTrack = exports.oxmysql:executeSync("SELECT id FROM tokyo_box_favorites WHERE owner = ? AND track_id = ?", {
        identifier, trackData.id
    })
    
    if existingTrack and #existingTrack > 0 then
        return false, "Esta música já está nos favoritos"
    end
    
    -- Adicionar aos favoritos
    local result = exports.oxmysql:insert("INSERT INTO tokyo_box_favorites (owner, track_id, title, artist, thumbnail, duration) VALUES (?, ?, ?, ?, ?, ?)", {
        identifier, trackData.id, trackData.title, trackData.artist, trackData.thumbnail, trackData.duration or 0
    })
    
    if result and result > 0 then
        return true
    end
    
    return false, "Erro ao adicionar música aos favoritos"
end

-- Remover música dos favoritos
function RemoveFavoriteTrack(source, trackId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local identifier = Player.PlayerData.citizenid
    
    -- Remover dos favoritos
    local result = exports.oxmysql:execute("DELETE FROM tokyo_box_favorites WHERE owner = ? AND track_id = ?", {
        identifier, trackId
    })
    
    if result and result.affectedRows > 0 then
        return true
    end
    
    return false, "Erro ao remover música dos favoritos"
end

-- Verificar se uma música está nos favoritos
function IsTrackFavorite(source, trackId)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local identifier = Player.PlayerData.citizenid
    
    local result = exports.oxmysql:executeSync("SELECT id FROM tokyo_box_favorites WHERE owner = ? AND track_id = ?", {
        identifier, trackId
    })
    
    return result and #result > 0
end

-- Alternar status favorito de uma música
function ToggleFavoriteTrack(source, trackData)
    local isFavorite = IsTrackFavorite(source, trackData.id)
    
    if isFavorite then
        return RemoveFavoriteTrack(source, trackData.id)
    else
        return AddFavoriteTrack(source, trackData)
    end
end

-- Obter configurações do jogador
function GetPlayerSettings(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end
    
    local identifier = Player.PlayerData.citizenid
    
    local result = exports.oxmysql:executeSync("SELECT * FROM tokyo_box_settings WHERE owner = ?", {
        identifier
    })
    
    if result and result[1] then
        local settings = result[1]
        
        -- Processar campos JSON
        local lastTrack = nil
        local lastPlaylist = nil
        
        if settings.last_track and settings.last_track ~= '' then
            lastTrack = json.decode(settings.last_track)
        end
        
        if settings.last_playlist and settings.last_playlist ~= '' then
            lastPlaylist = json.decode(settings.last_playlist)
        end
        
        return {
            volume = settings.volume,
            bluetooth = settings.bluetooth == 1,
            audioRange = settings.range,
            theme = settings.theme,
            lastTrack = lastTrack,
            lastPlaylist = lastPlaylist
        }
    end
    
    -- Se não existir, criar um registro padrão
    local defaultSettings = {
        volume = Config.DefaultVolume,
        bluetooth = Config.DefaultBluetoothStatus,
        audioRange = Config.DefaultAudioRange,
        theme = Config.DefaultTheme
    }
    
    exports.oxmysql:insert("INSERT INTO tokyo_box_settings (owner, volume, bluetooth, range, theme) VALUES (?, ?, ?, ?, ?)", {
        identifier, defaultSettings.volume, defaultSettings.bluetooth, defaultSettings.audioRange, defaultSettings.theme
    })
    
    return defaultSettings
end

-- Salvar configurações do jogador
function SavePlayerSettings(source, settings)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local identifier = Player.PlayerData.citizenid
    
    -- Processar campos complexos
    local lastTrackJson = 'NULL'
    local lastPlaylistJson = 'NULL'
    
    if settings.lastTrack then
        lastTrackJson = json.encode(settings.lastTrack)
    end
    
    if settings.lastPlaylist then
        lastPlaylistJson = json.encode(settings.lastPlaylist)
    end
    
    -- Verificar se já existe
    local exists = exports.oxmysql:executeSync("SELECT id FROM tokyo_box_settings WHERE owner = ?", {
        identifier
    })
    
    if exists and #exists > 0 then
        -- Atualizar registro existente
        exports.oxmysql:execute([[
            UPDATE tokyo_box_settings 
            SET volume = ?, bluetooth = ?, range = ?, theme = ?, last_track = ?, last_playlist = ?
            WHERE owner = ?
        ]], {
            settings.volume or Config.DefaultVolume, 
            settings.bluetooth or Config.DefaultBluetoothStatus, 
            settings.audioRange or Config.DefaultAudioRange,
            settings.theme or Config.DefaultTheme,
            lastTrackJson,
            lastPlaylistJson,
            identifier
        })
    else
        -- Criar novo registro
        exports.oxmysql:insert([[
            INSERT INTO tokyo_box_settings 
            (owner, volume, bluetooth, range, theme, last_track, last_playlist)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], {
            identifier,
            settings.volume or Config.DefaultVolume, 
            settings.bluetooth or Config.DefaultBluetoothStatus, 
            settings.audioRange or Config.DefaultAudioRange,
            settings.theme or Config.DefaultTheme,
            lastTrackJson,
            lastPlaylistJson
        })
    end
    
    return true
end

-- Chamada para inicializar banco de dados quando o servidor iniciar
Citizen.CreateThread(function()
    Citizen.Wait(1000) -- Aguardar para garantir que dependências estejam carregadas
    InitializeDatabase()
end)

-- Exportar funções
exports('GetPlayerPlaylists', GetPlayerPlaylists)
exports('GetPlaylistTracks', GetPlaylistTracks)
exports('GetPlaylistInfo', GetPlaylistInfo)
exports('CreatePlaylist', CreatePlaylist)
exports('AddTrackToPlaylist', AddTrackToPlaylist)
exports('RemoveTrackFromPlaylist', RemoveTrackFromPlaylist)
exports('DeletePlaylist', DeletePlaylist)
exports('GetPlayerFavorites', GetPlayerFavorites)
exports('AddFavoriteTrack', AddFavoriteTrack)
exports('RemoveFavoriteTrack', RemoveFavoriteTrack)
exports('IsTrackFavorite', IsTrackFavorite)
exports('ToggleFavoriteTrack', ToggleFavoriteTrack)
exports('GetPlayerSettings', GetPlayerSettings)
exports('SavePlayerSettings', SavePlayerSettings)