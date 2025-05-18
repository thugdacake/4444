-- Tokyo Box Server Songs Handler
local QBCore = nil
TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)

-- Cache para pesquisas de músicas
local searchCache = {}
local youtubeCache = {}

-- Pesquisar músicas
RegisterNetEvent('tokyo_box:searchTracks')
AddEventHandler('tokyo_box:searchTracks', function(query)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Verificar permissão VIP
    if not CheckPlayerVIP(src) then
        TriggerClientEvent('QBCore:Notify', src, 'Acesso negado: Apenas VIPs podem pesquisar músicas!', 'error')
        return
    end
    
    -- Verificar se já temos esse resultado em cache
    local cacheKey = string.lower(query)
    if Config.MusicAPI.EnableCache and searchCache[cacheKey] and 
       searchCache[cacheKey].timestamp > (os.time() - Config.MusicAPI.CacheTime) then
        TriggerClientEvent('tokyo_box:searchResults', src, searchCache[cacheKey].results)
        return
    end
    
    -- Chamar API externa para pesquisar
    local results = SearchExternalAPI(query)
    
    -- Salvar no cache
    if Config.MusicAPI.EnableCache then
        searchCache[cacheKey] = {
            timestamp = os.time(),
            results = results
        }
    end
    
    -- Enviar resultados para o cliente
    TriggerClientEvent('tokyo_box:searchResults', src, results)
end)

-- Processar URL do Youtube para obter URL de streaming
RegisterNetEvent('tokyo_box:getStreamUrl')
AddEventHandler('tokyo_box:getStreamUrl', function(videoId, trackData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Verificar permissão VIP
    if not CheckPlayerVIP(src) then
        TriggerClientEvent('QBCore:Notify', src, 'Acesso negado: Apenas VIPs podem reproduzir músicas!', 'error')
        return
    end
    
    -- Verificar se já temos esse resultado em cache
    if Config.MusicAPI.EnableCache and youtubeCache[videoId] and 
       youtubeCache[videoId].timestamp > (os.time() - Config.MusicAPI.CacheTime) then
        local cachedData = youtubeCache[videoId]
        
        -- Adicionar URL ao objeto da faixa
        trackData.url = cachedData.url
        trackData.duration = cachedData.duration
        
        -- Enviar para o cliente
        TriggerClientEvent('tokyo_box:receiveStreamUrl', src, trackData)
        return
    end
    
    -- Função para extrair URL de streaming do YouTube
    local streamUrl, duration = GetYoutubeStreamUrl(videoId)
    
    -- Se não conseguir obter URL, usar URL padrão para testes
    if not streamUrl then
        streamUrl = Config.DefaultMusicURL
        duration = 180
        
        -- Notificar erro
        TriggerClientEvent('QBCore:Notify', src, 'Não foi possível obter URL de streaming!', 'error')
    end
    
    -- Salvar no cache
    if Config.MusicAPI.EnableCache then
        youtubeCache[videoId] = {
            timestamp = os.time(),
            url = streamUrl,
            duration = duration
        }
    end
    
    -- Adicionar URL ao objeto da faixa
    trackData.url = streamUrl
    trackData.duration = duration
    
    -- Enviar para o cliente
    TriggerClientEvent('tokyo_box:receiveStreamUrl', src, trackData)
end)

-- Pesquisar na API externa
function SearchExternalAPI(query)
    if not Config.MusicAPI.Key or not Config.MusicAPI.URL then
        return {}
    end
    
    -- Formatar para consulta API do YouTube
    local apiKey = Config.MusicAPI.Key
    local searchUrl = Config.MusicAPI.URL .. "/search?part=snippet&q=" .. encodeURI(query) .. "&maxResults=20&key=" .. apiKey
    
    local success, response = pcall(function()
        return PerformHttpRequest(searchUrl, function(errorCode, resultData, resultHeaders)
            if errorCode ~= 200 then
                print("Tokyo Box API Error: " .. tostring(errorCode))
                return {}
            end
            
            return json.decode(resultData)
        end, "GET")
    end)
    
    -- Se falhar, retornar array vazio
    if not success or not response or not response.items then
        return {}
    end
    
    -- Processar resultados
    local results = {}
    for i, item in ipairs(response.items) do
        if item.id.kind == "youtube#video" then
            local videoInfo = {
                id = item.id.videoId,
                title = item.snippet.title,
                artist = item.snippet.channelTitle,
                thumbnail = item.snippet.thumbnails.medium.url,
                source = "youtube"
            }
            
            table.insert(results, videoInfo)
        end
    end
    
    return results
end

-- Obter URL de streaming do YouTube
function GetYoutubeStreamUrl(videoId)
    -- Obter informações detalhadas do vídeo
    local apiKey = Config.MusicAPI.Key
    local videoUrl = Config.MusicAPI.URL .. "/videos?part=contentDetails,snippet&id=" .. videoId .. "&key=" .. apiKey
    
    local videoData = nil
    local success, response = pcall(function()
        return PerformHttpRequest(videoUrl, function(errorCode, resultData, resultHeaders)
            if errorCode ~= 200 then
                print("Tokyo Box API Error: " .. tostring(errorCode))
                return nil
            end
            
            return json.decode(resultData)
        end, "GET")
    end)
    
    -- Se falhar, retornar nil
    if not success or not response or not response.items or #response.items == 0 then
        return nil, nil
    end
    
    -- Extrair informações do vídeo
    videoData = response.items[1]
    
    -- URL base do YouTube
    local youtubeBase = "https://www.youtube.com/watch?v=" .. videoId
    
    -- Extrair duração (formato ISO 8601)
    local duration = 0
    local durationStr = videoData.contentDetails.duration
    
    -- Converter formato ISO 8601 para segundos
    -- Exemplo: PT1H30M45S = 1 hora, 30 minutos, 45 segundos
    local hours = string.match(durationStr, "(%d+)H")
    local minutes = string.match(durationStr, "(%d+)M")
    local seconds = string.match(durationStr, "(%d+)S")
    
    hours = hours and tonumber(hours) or 0
    minutes = minutes and tonumber(minutes) or 0
    seconds = seconds and tonumber(seconds) or 0
    
    duration = hours * 3600 + minutes * 60 + seconds
    
    -- Retornar URL do YouTube e duração
    return youtubeBase, duration
end

-- Função auxiliar para codificar URL
function encodeURI(str)
    if str then
        str = string.gsub(str, "\n", "\r\n")
        str = string.gsub(str, "([^%w %-%_%.%~])",
            function(c) return string.format("%%%02X", string.byte(c)) end)
        str = string.gsub(str, " ", "+")
    end
    return str
end

-- Verificar permissão VIP do jogador
function CheckPlayerVIP(source)
    local Player = QBCore.Functions.GetPlayer(source)
    
    -- Se a verificação VIP estiver desativada, todos têm acesso
    if not Config.EnableVIPCheck then
        return true
    end
    
    -- Se não encontrar jogador, negar acesso
    if not Player then
        return false
    end
    
    -- Verificar grupo do jogador
    if Player.PlayerData.group then
        for i=1, #Config.VIPGroups, 1 do
            if Player.PlayerData.group == Config.VIPGroups[i] then
                return true
            end
        end
    end
    
    -- Verificar job do jogador se configurado
    if Config.VIPJobName and Player.PlayerData.job and Player.PlayerData.job.name == Config.VIPJobName then
        return true
    end
    
    -- Verificar se o jogador possui o item VIP se configurado
    if Config.VIPItemName then
        local item = Player.Functions.GetItemByName(Config.VIPItemName)
        if item and item.amount > 0 then
            return true
        end
    end
    
    -- Se nenhuma condição for satisfeita, negar acesso
    return false
end

-- Exportar funções
exports('SearchExternalAPI', SearchExternalAPI)
exports('GetYoutubeStreamUrl', GetYoutubeStreamUrl)
exports('CheckPlayerVIP', CheckPlayerVIP)