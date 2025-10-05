
local RSGCore = exports['rsg-core']:GetCoreObject()
local PlayerData = RSGCore.Functions.GetPlayerData()

local robberyInProgress = false
local blips = {}
local zones = {}
local promptRegistry = {} 


local function NormalizeType(t)
    if not t then return nil end
    local s = tostring(t):lower()
    if s == 'vault' or s == 'vaults' then return 'vault' end
    return nil
end


RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    PlayerData = RSGCore.Functions.GetPlayerData()
    
    CreateBankZones()
end)

RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    RemoveZones()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        PlayerData = RSGCore.Functions.GetPlayerData()
       
        CreateBankZones()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        
        RemoveZones()
    end
end)





function CreateBankZones()
    if not Config or not Config.Banks then return end

    for bankId, bank in pairs(Config.Banks) do
        -- vaults only
        if bank.vaults then
            for vaultId, vault in pairs(bank.vaults) do
                local zoneId = bankId .. '_vault_' .. tostring(vaultId)
                zones[zoneId] = lib.zones.sphere({
                    coords = vault.coords,
                    radius = 1.5,
                    debug = Config.Debug,
                    onEnter = function()
                        if vault.robbed or robberyInProgress then return end

                        local promptId = zoneId .. '_prompt'
                        promptRegistry[promptId] = {
                            bankId = bankId,
                            targetType = 'vault',
                            targetId = vaultId,
                            coords = vault.coords,
                            zoneId = zoneId
                        }

                        local promptHandle = exports['rsg-core']:createPrompt(
                            promptId,
                            vault.coords,
                            RSGCore.Shared.Keybinds['E'],
                            '[E] Rob Vault',
                            {
                                type = 'client',
                                event = 'rsg-bankrobbery:client:PromptInteract',
                                args = { promptId = promptId }
                            }
                        )

                        zones[zoneId].promptHandle = promptHandle
                        zones[zoneId].promptId = promptId

                        if Config.Debug then
                            print(('^2[RSG-BankRobbery]^7 Created prompt %s for vault %s @ %s'):format(promptId, tostring(vaultId), bankId))
                        end
                    end,
                    onExit = function()
                        if zones[zoneId] and zones[zoneId].promptHandle then
                            exports['rsg-core']:deletePrompt(zones[zoneId].promptHandle)
                            if zones[zoneId].promptId then
                                promptRegistry[zones[zoneId].promptId] = nil
                                zones[zoneId].promptId = nil
                            end
                            zones[zoneId].promptHandle = nil
                        end
                    end
                })
            end
        end
    end
end

function RemoveZones()
    for zoneId, zone in pairs(zones) do
        if zone and zone.promptHandle then
            exports['rsg-core']:deletePrompt(zone.promptHandle)
            if zone.promptId then promptRegistry[zone.promptId] = nil end
        end
        if zone and type(zone.remove) == 'function' then
            zone:remove()
        end
    end
    zones = {}
    promptRegistry = {}
end


RegisterNetEvent('rsg-bankrobbery:client:PromptInteract', function(data)
   
    local bank = nil

    if data and type(data) == 'table' then
        if data.promptId and promptRegistry[data.promptId] then
            bank = promptRegistry[data.promptId]
        elseif data.bankId and data.targetType and data.targetId then
            
            bank = {
                bankId = data.bankId,
                targetType = NormalizeType(data.targetType) or data.targetType,
                targetId = data.targetId,
                coords = data.coords
            }
        end
    end

   
    if not bank then
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)
        local closest, closestData, dist = nil, nil, 9999
        for pid, meta in pairs(promptRegistry) do
            local d = #(vector3(meta.coords.x, meta.coords.y, meta.coords.z) - pcoords)
            if d < dist then
                dist = d
                closest = pid
                closestData = meta
            end
        end
        if closestData and dist <= 2.0 then
            bank = closestData
        end
    end

    if not bank then
        lib.notify({
            title = 'Bank Robbery',
            description = 'Invalid bank target or prompt data.',
            type = 'error'
        })
        if Config.Debug then print('^1[RSG-BankRobbery]^7 PromptInteract fired with no valid bank data; data:', json and json.encode(data) or tostring(data)) end
        return
    end

    
    local nType = NormalizeType(bank.targetType)
    if not nType then
        lib.notify({
            title = 'Bank Robbery',
            description = 'Invalid bank type: ' .. tostring(bank.targetType),
            type = 'error'
        })
        if Config.Debug then print('^1[RSG-BankRobbery]^7 Invalid bank type for prompt: ' .. tostring(bank.targetType)) end
        return
    end
    bank.targetType = nType

    OpenRobberyMenu(bank)
end)


function OpenRobberyMenu(bank)
    if robberyInProgress then
        lib.notify({ title = 'Bank Robbery', description = 'A robbery is already in progress.', type = 'error' })
        return
    end
    if not bank or not bank.targetType then return end

    
    if Config.Banks[bank.bankId] and Config.Banks[bank.bankId].vaults and Config.Banks[bank.bankId].vaults[bank.targetId] and Config.Banks[bank.bankId].vaults[bank.targetId].robbed then
        lib.notify({ title = 'Bank Robbery', description = 'This vault has already been robbed recently. Try again later.', type = 'error' })
        return
    end

    local targetName = 'Vault'

    lib.registerContext({
        id = 'bankrobbery_menu',
        title = 'Bank Robbery - ' .. targetName,
        options = {
            {
                title = 'Place TNT',
                description = 'Use TNT to blow up the ' .. targetName:lower(),
                icon = 'bomb',
                onSelect = function() PlaceDynamite(bank) end
            },
            {
                title = 'Cancel',
                description = 'Leave the area',
                icon = 'times',
                onSelect = function() lib.hideContext() end
            }
        }
    })
    lib.showContext('bankrobbery_menu')
end

function PlaceDynamite(bank)
    if not bank then return end

    RSGCore.Functions.TriggerCallback('rsg-bankrobbery:server:HasItem', function(hasItem)
        if not hasItem then
            lib.notify({ title = 'Bank Robbery', description = 'You need dynamite to blow up this vault', type = 'error' })
            return
        end

        RSGCore.Functions.TriggerCallback('rsg-bankrobbery:server:GetPoliceCount', function(policeCount)
            if policeCount < Config.PoliceRequired then
                lib.notify({ title = 'Bank Robbery', description = 'Not enough lawmen in the area. Need at least ' .. Config.PoliceRequired, type = 'error' })
                return
            end

            
            RSGCore.Functions.TriggerCallback('rsg-bankrobbery:server:ConfirmRobberyStart', function(success, reason)
                if not success then
                    lib.notify({
                        title = 'Bank Robbery',
                        description = reason or 'Cannot start robbery at this time.',
                        type = 'error'
                    })
                    return
                end

                
                StartRobbery(bank)
            end, bank)
        end)
    end, Config.ExplosiveItem)
end

function StartRobbery(bank)
    if not bank then return end

    robberyInProgress = true
    lib.hideTextUI()

   
    if bank.zoneId and zones[bank.zoneId] and zones[bank.zoneId].promptHandle then
        exports['rsg-core']:deletePrompt(zones[bank.zoneId].promptHandle)
        zones[bank.zoneId].promptHandle = nil
        zones[bank.zoneId].promptId = nil
        promptRegistry[bank.zoneId .. '_prompt'] = nil
        if Config.Debug then
            print(('^2[RSG-BankRobbery]^7 Deleted prompt for zone %s during robbery start'):format(bank.zoneId))
        end
    end

    lib.notify({
        title = 'Bank Robbery',
        description = 'Dynamite placed! Get to cover!',
        type = 'inform'
    })

    
    local ped = PlayerPedId()
    
    
	TriggerServerEvent('rsg-lawman:server:lawmanAlert', 'Bank robbery!')

    
    local countdown = 10
    CreateThread(function()
        while countdown > 0 do
            lib.notify({
                title = 'Explosion in...',
                description = tostring(countdown) .. ' seconds',
                type = 'inform'
            })
            countdown = countdown - 1
            Wait(1000)
        end

       
        local expSettings = Config.ExplosionSettings or {}
        local explosionType = GetHashKey(expSettings.explosionType or 'EXPLOSION_DYNAMITE')
        local damageScale = expSettings.damageScale or 1.0
        local cameraShake = expSettings.cameraShake or 1.0
        local shakeType = 'SMALL_EXPLOSION_SHAKE'
        local shakeAmp = 0.3

        if Config.explosion and bank.targetType then
            local expKey = (bank.targetType == 'vault') and 'vault' or 'door'
            local expConfig = Config.explosion[expKey]
            if expConfig then
                explosionType = expConfig.type  
                damageScale = expConfig.radius
                cameraShake = expConfig.shake
                shakeAmp = expConfig.shake
            end
        end

      
        AddExplosion(
            bank.coords.x,
            bank.coords.y,
            bank.coords.z,
            explosionType,
            damageScale,
            expSettings.isAudible or true,
            expSettings.isInvisible or false,
            cameraShake
        )

       
        ShakeGameplayCam(shakeType, shakeAmp)

        lib.notify({
            title = 'Bank Robbery',
            description = 'The vault is open! Return to collect the loot.',
            type = 'inform'
        })

        
        local player = PlayerPedId()
        local inZone = false

        CreateThread(function()
            while robberyInProgress do
                local pCoords = GetEntityCoords(player)
                local dist = #(pCoords - bank.coords)

                if dist <= 1.5 and not inZone then
                    inZone = true
                    ShowLootPrompt(bank)
                elseif dist > 1.5 and inZone then
                    inZone = false
                end

                Wait(500)
            end
        end)
    end)
end


function ShowLootPrompt(bank)
    lib.registerContext({
        id = 'loot_menu',
        title = 'Collect Loot',
        options = {
            {
                title = 'Grab the Money',
                description = 'Quickly collect the loot before lawmen arrive',
                icon = 'money-bill',
                onSelect = function() CollectLoot(bank) end
            }
        }
    })
    lib.showContext('loot_menu')
end

function CollectLoot(bank)
    lib.progressCircle({
        duration = 5000,
        position = 'bottom',
        label = 'Collecting loot...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        TaskStartScenarioInPlace(PlayerPedId(), GetHashKey('WORLD_HUMAN_CROUCH_INSPECT'), -1, true, false, false, false)  -- Remove this line if you don't want it restarting here
    })

    Wait(1000)

    TriggerServerEvent('rsg-bankrobbery:server:GiveReward', bank)
    robberyInProgress = false

   
    ClearPedTasksImmediately(PlayerPedId())

    lib.notify({
        title = 'Bank Robbery',
        description = 'You’ve grabbed the loot! Time to get out of here!',
        type = 'success'
    })
end



RegisterNetEvent('rsg-bankrobbery:client:UpdateBankStatus', function(bankId, targetType, targetId, robbed)
    if not bankId or not targetType then return end
    local nType = NormalizeType(targetType)
    if not nType then
        if Config.Debug then print('^1[RSG-BankRobbery]^7 Received invalid targetType from server: ' .. tostring(targetType)) end
        return
    end

    if Config.Banks[bankId] then
        if nType == 'vault' and Config.Banks[bankId].vaults and Config.Banks[bankId].vaults[targetId] then
            Config.Banks[bankId].vaults[targetId].robbed = robbed
        end
    end
end)

