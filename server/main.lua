local registeredSuggestions = {}

local function normalizeName(name)
    return name:sub(1, 1) == '/' and name or ('/' .. name)
end

local function syncAllCommandsToPlayer(sourcePlayer)
    local merged = {}


    for _, cmd in ipairs(GetRegisteredCommands()) do
        merged[('/' .. cmd.name):lower()] = { name = '/' .. cmd.name, help = '', params = {} }
    end


    for _, item in pairs(registeredSuggestions) do
        local name = normalizeName(item.name)
        merged[name:lower()] = { name = name, help = item.help or '', params = item.params or {} }
    end

    merged['/testchat'] = { name = '/testchat', help = 'Générer 30 messages de test', params = {} }

    local sendQueue = {}
    for _, item in pairs(merged) do
        sendQueue[#sendQueue + 1] = item
    end

    TriggerClientEvent('chat:addSuggestions', sourcePlayer, sendQueue)
end

RegisterNetEvent('_chat:messageEntered', function(author, color, message)
    if not Config.EnableMessages then return end
    if not message or string.len(message) == 0 then return end
    local sourcePlayer = source
    local playerName = GetPlayerName(sourcePlayer) or author
    local displayName = string.format("%s (%s)", playerName, sourcePlayer)
    TriggerClientEvent('chat:addMessage', -1, {
        args = { displayName, message },
        color = { 102, 178, 255 }
    })
end)

AddEventHandler('chat:addSuggestion', function(name, help, params)
    registeredSuggestions[name] = {
        name = name,
        help = help or '',
        params = params or {}
    }
    TriggerClientEvent('chat:addSuggestion', -1, name, help, params)
end)

AddEventHandler('chat:addSuggestions', function(data)
    if type(data) ~= 'table' then return end

    if data.name then
        registeredSuggestions[data.name] = {
            name = data.name,
            help = data.help or '',
            params = data.params or data.arguments or {}
        }
    else
        for _, item in pairs(data) do
            if type(item) == 'table' and item.name then
                registeredSuggestions[item.name] = {
                    name = item.name,
                    help = item.help or '',
                    params = item.params or item.arguments or {}
                }
            end
        end
    end

    TriggerClientEvent('chat:addSuggestions', -1, data)
end)

AddEventHandler('chat:removeSuggestion', function(name)
    registeredSuggestions[name] = nil
    TriggerClientEvent('chat:removeSuggestion', -1, name)
end)

RegisterNetEvent('chat:init', function()
    local sourcePlayer = source
    syncAllCommandsToPlayer(sourcePlayer)
end)

AddEventHandler('__cfx_internal:commandFallback', function(command)
    local src = source

    TriggerEvent('chatMessage', src, GetPlayerName(src), '/' .. command)

    if not WasEventCanceled() then
        TriggerClientEvent('chat:addMessage', src, {
            args = { 'Serveur', "Cette commande n'existe pas" },
            color = '#ef4444'
        })
    end

    CancelEvent()
end)

AddEventHandler('onServerResourceStart', function()
    Wait(500)
    for _, id in ipairs(GetPlayers()) do
        syncAllCommandsToPlayer(tonumber(id))
    end
end)

RegisterCommand('clear', function(source)
    if source > 0 then
        TriggerClientEvent('chat:clear', source)
    end
end, false)

RegisterCommand('testchat', function(source)
    local dummyNames = {
        'Alexandre', 'Sarah_C', 'Lucas92', 'Emma_R', 'Jhon',
        'Basd', 'Chloe_V', 'Maxime_K', 'Lea_M', 'Julien_B'
    }

    local dummyMessages = {
        'Quelqu un a une trousse de secours secteur Legion ?',
        'Je vends une Sultan RS custom full perf, contactez par mail.',
        'Les flics tournent vers Vinewood faites gaffe.',
        'Dispo pour des courses poursuites amicales à l\'aéroport.',
        'Quelqu un sait si le Benny s\'est ouvert actuellement ?',
        'Recrutement ouvert pour les ambulanciers passez au poste.',
        'Besoin d\'un dépanneur d\'urgence sur l\'autoroute nord.',
        'C\'est calme ce soir en ville, tout le monde est où ?',
        'Attention contrôle radar mobile sur le pont est.',
        'Bon jeu à tous et bon RP !'
    }

    CreateThread(function()
        for i = 1, 30 do
            local randomName = dummyNames[math.random(1, #dummyNames)]
            local randomId = math.random(1, 128)
            local randomMsg = dummyMessages[math.random(1, #dummyMessages)]
            local displayName = string.format('%s (%s)', randomName, randomId)

            TriggerClientEvent('chat:addMessage', -1, {
                args = { displayName, randomMsg },
                color = { 102, 178, 255 }
            })
            Wait(100)
        end
    end)
end, false)
