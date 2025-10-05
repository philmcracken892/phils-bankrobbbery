local RSGCore = exports['rsg-core']:GetCoreObject()
local robberyTimers = {}
local robbedBanks = {}


RSGCore.Functions.CreateCallback('rsg-bankrobbery:server:HasItem', function(source, cb, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then 
        cb(false)
        return 
    end
    
    local hasItem = Player.Functions.GetItemByName(item)
    cb(hasItem ~= nil and hasItem.amount > 0)
end)

RSGCore.Functions.CreateCallback('rsg-bankrobbery:server:GetPoliceCount', function(source, cb)
    local policeCount = 0
    local players = RSGCore.Functions.GetRSGPlayers()
    
    for _, player in pairs(players) do
        if player.PlayerData.job and (player.PlayerData.job.name == 'vallaw' or player.PlayerData.job.type == 'leo') then
            policeCount = policeCount + 1
        end
    end
    
    cb(policeCount)
end)


RSGCore.Functions.CreateCallback('rsg-bankrobbery:server:ConfirmRobberyStart', function(source, cb, bankData)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then 
        cb(false, 'Player not found')
        return 
    end

    local bankKey = bankData.bankId .. '_' .. bankData.targetType .. '_' .. bankData.targetId
    
    if Config.Debug then
        print(('^3[RSG-BankRobbery DEBUG]^7 Confirming start for key: %s | Data: %s'):format(bankKey, json.encode(bankData)))
        if robbedBanks[bankKey] then
            print(('^3[RSG-BankRobbery DEBUG]^7 Existing timestamp for %s: %d | Current time: %d'):format(bankKey, robbedBanks[bankKey], GetGameTimer()))
        else
            print(('^3[RSG-BankRobbery DEBUG]^7 No existing timestamp for %s'):format(bankKey))
        end
    end
    
   
    if robbedBanks[bankKey] and robbedBanks[bankKey] > GetGameTimer() then
        if Config.Debug then
            print(('^1[RSG-BankRobbery DEBUG]^7 COOLDOWN ACTIVE for %s - blocking robbery'):format(bankKey))
        end
        cb(false, 'This vault was recently robbed. Try again later.')
        return
    end

    if Config.Debug then
        print(('^2[RSG-BankRobbery DEBUG]^7 COOLDOWN PASSED - allowing robbery for %s'):format(bankKey))
    end

    
    Player.Functions.RemoveItem(Config.ExplosiveItem, 1)
    TriggerClientEvent('rsg-core:notify', source, 'You used tnt', 'primary')

    
    robberyTimers[source] = {
        bankData = bankData,
        startTime = GetGameTimer()
    }

    

   
    local newTimestamp = GetGameTimer() + Config.CooldownTime
    robbedBanks[bankKey] = newTimestamp
    if Config.Debug then
        print(('^2[RSG-BankRobbery DEBUG]^7 Set new cooldown timestamp for %s: %d (expires at ~%s)'):format(bankKey, newTimestamp, os.date('%Y-%m-%d %H:%M:%S', math.floor(newTimestamp / 1000))))
    end
    
    
    TriggerClientEvent('rsg-bankrobbery:client:UpdateBankStatus', -1, 
        bankData.bankId, bankData.targetType, bankData.targetId, true)

    
    SetTimeout(Config.CooldownTime, function()
        TriggerClientEvent('rsg-bankrobbery:client:UpdateBankStatus', -1, 
            bankData.bankId, bankData.targetType, bankData.targetId, false)
        robbedBanks[bankKey] = nil  
        if Config.Debug then
            print(('^2[RSG-BankRobbery DEBUG]^7 Cooldown expired for %s - reset robbed flag and cleared entry'):format(bankKey))
        end
    end)

    if Config.Debug then
        print('^2[RSG-BankRobbery]^7 Player ' .. Player.PlayerData.charinfo.firstname .. ' ' .. 
              Player.PlayerData.charinfo.lastname .. ' started robbing ' .. bankData.bankId)
    end

    cb(true)
end)

lib.callback.register('rsg-bankrobbery:server:StartCountdown', function(source)
    return true
end)


RegisterServerEvent('rsg-bankrobbery:server:GiveReward')
AddEventHandler('rsg-bankrobbery:server:GiveReward', function(bankData)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

   
    if not robberyTimers[src] then
        if Config.Debug then
            print('^1[RSG-BankRobbery]^7 Player tried to collect reward without active robbery')
        end
        return
    end

    local rewards = Config.Rewards[bankData.targetType]
    if not rewards then return end

    local lootMsg = {}
    
    
    local cashAmount = math.random(rewards.cash.min, rewards.cash.max)
    Player.Functions.AddMoney('cash', cashAmount)
    table.insert(lootMsg, '$' .. cashAmount)

   
    if math.random(100) <= rewards.gold_bar.chance then
        local goldAmount = math.random(rewards.gold_bar.min, rewards.gold_bar.max)
        Player.Functions.AddItem('gold_bar', goldAmount)
        table.insert(lootMsg, goldAmount .. ' Gold Bar' .. (goldAmount > 1 and 's' or ''))
    end

    
    if math.random(100) <= rewards.diamond.chance then
        local diamondAmount = math.random(rewards.diamond.min, rewards.diamond.max)
        if diamondAmount > 0 then
            Player.Functions.AddItem('diamond', diamondAmount)
            table.insert(lootMsg, diamondAmount .. ' Diamond' .. (diamondAmount > 1 and 's' or ''))
        end
    end

    
    robberyTimers[src] = nil

    
    local rewardText = table.concat(lootMsg, ', ')
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Bank Robbery',
        description = 'You got: ' .. rewardText,
        type = 'success',
        duration = 5000
    })

    
    local logData = {
        player = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        citizenid = Player.PlayerData.citizenid,
        bank = bankData.bankId,
        target = bankData.targetType,
        rewards = rewardText,
        coords = bankData.coords
    }

    if Config.Debug then
        print('^2[RSG-BankRobbery]^7 ' .. logData.player .. ' completed robbery at ' .. 
              logData.bank .. ' and received: ' .. logData.rewards)
    end

    
    -- TriggerEvent('rsg-log:server:CreateLog', 'bankrobbery', 'Bank Robbery Completed', 'green', logData)
end)



AddEventHandler('playerDropped', function()
    local src = source
    if robberyTimers[src] then
        robberyTimers[src] = nil
        if Config.Debug then
            print('^1[RSG-BankRobbery]^7 Cleaned up robbery timer for disconnected player: ' .. src)
        end
    end
end)






function GetTableLength(T)
    local count = 0
    for _ in pairs(T) do 
        count = count + 1 
    end
    return count
end