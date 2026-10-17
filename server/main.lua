local registeredSuggestions = {}

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

RegisterNetEvent('chat:addSuggestion', function(name, help, params)
    registeredSuggestions[name] = {
        name = name,
        help = help or '',
        params = params or {}
    }
    TriggerClientEvent('chat:addSuggestion', -1, name, help, params)
end)

RegisterNetEvent('chat:addSuggestions', function(data)
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

RegisterNetEvent('chat:removeSuggestion', function(name)
    registeredSuggestions[name] = nil
    TriggerClientEvent('chat:removeSuggestion', -1, name)
end)

RegisterNetEvent('chat:init', function()
    local sourcePlayer = source

    local sendQueue = {}
    for _, item in pairs(registeredSuggestions) do
        table.insert(sendQueue, item)
    end

    if exports['es_extended'] then
        local success, ESX = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        if success and ESX and ESX.GetCommands then
            local commands = ESX.GetCommands()
            for cmdName, cmdData in pairs(commands) do
                local formatted = cmdName:sub(1, 1) == '/' and cmdName or ('/' .. cmdName)
                local help = (cmdData.suggestion and cmdData.suggestion.help) or ''
                local args = (cmdData.suggestion and cmdData.suggestion.arguments) or {}
                table.insert(sendQueue, {
                    name = formatted,
                    help = help,
                    params = args
                })
            end
        end
    end

    table.insert(sendQueue, {
        name = '/testchat',
        help = 'Générer 30 messages de test',
        params = {}
    })

    TriggerClientEvent('chat:addSuggestions', sourcePlayer, sendQueue)
    TriggerClientEvent('chat:reloadSuggestions', sourcePlayer)
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
