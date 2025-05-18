-- Tokyo Box Client Permissions
local QBCore = exports['qb-core']:GetCoreObject()

-- Check if player has VIP permission
function IsPlayerVIP()
    local Player = QBCore.Functions.GetPlayerData()
    
    -- Skip check if VIP check is disabled
    if not Config.EnableVIPCheck then
        return true
    end
    
    -- Check group permission
    if Config.VIPGroup and Player.group == Config.VIPGroup then
        return true
    end
    
    -- Check job if configured
    if Config.VIPJobName and Player.job and Player.job.name == Config.VIPJobName then
        return true
    end
    
    -- If we reach here, final check is done via server-side check for items
    if Config.VIPItemName then
        -- The result will come through the 'tokyo_box:setVIPStatus' event
        return false
    end
    
    return false
end

-- Request server to check for VIP item
function CheckVIPItem()
    if Config.VIPItemName then
        TriggerServerEvent('tokyo_box:checkVIPItem')
    end
end

-- Exports for other resources
exports('IsPlayerVIP', IsPlayerVIP)
exports('CheckVIPItem', CheckVIPItem)