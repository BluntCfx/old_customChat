local chatOpen = false
local cursorActive = false
local chatLoaded = false
local suggestionsCache = {}

local function rgbToHex(r, g, b)
    return string.format('#%02x%02x%02x', math.floor(r or 255), math.floor(g or 255), math.floor(b or 255))
end

local function parseColor(color)
    if type(color) == 'table' then
        return rgbToHex(color[1], color[2], color[3])
    elseif type(color) == 'string' and string.sub(color, 1, 1) == '#' then
        return color
    end
    return '#66b2ff'
end

local function parseParams(params)
    if not params or type(params) ~= 'table' then return '' end
    local parts = {}
    for _, param in pairs(params) do
        if type(param) == 'table' and param.name then
            table.insert(parts, '<' .. tostring(param.name) .. '>')
        elseif type(param) == 'string' then
            table.insert(parts, '<' .. param .. '>')
        end
    end
    return table.concat(parts, ' ')
end

local function sendSuggestionToUI(name, help, params)
    if not name then return end
    local formattedName = name:sub(1, 1) == '/' and name or ('/' .. name)
    local argsStr = parseParams(params)

    suggestionsCache[formattedName:lower()] = {
        name = formattedName,
        help = help or '',
        args = argsStr
    }

    if chatLoaded then
        SendNUIMessage({
            action = 'addSuggestion',
            data = {
                name = formattedName,
                help = help or '',
                args = argsStr
            }
        })
    end
end

local function sendConfigToUI()
    SendNUIMessage({
        action = 'initConfig',
        data = {
            enableMessages = Config.EnableMessages,
            placeholder = Config.Placeholder or "Écrire un message... (Échap pour fermer)",
            enableEmojis = Config.EnableEmojis,
            blacklistedEmojis = Config.BlacklistedEmojis or {},
            blacklistedWords = Config.BlacklistedWords or {},
            blacklistedCategories = Config.BlacklistedCategories or {},
            enableChatSettings = Config.EnableChatSettings,
            theme = Config.Theme or {
                background = 'rgba(10, 10, 10, 0.75)',
                accent = '#22c55e'
            }
        }
    })
end

local function flushCachedSuggestions()
    for _, item in pairs(suggestionsCache) do
        SendNUIMessage({
            action = 'addSuggestion',
            data = item
        })
    end
end

local function registerSystemCommands()
    for _, cmd in ipairs(GetRegisteredCommands()) do
        if cmd.name ~= 'open_custom_chat' then
            sendSuggestionToUI('/' .. cmd.name, '', {})
        end
    end

    if Config.EnableChatSettings then
        sendSuggestionToUI('/chatsettings', "Ouvrir les paramètres d'affichage du chat", {})
    end
end

RegisterNUICallback('uiLoaded', function(data, cb)
    chatLoaded = true
    sendConfigToUI()
    flushCachedSuggestions()
    registerSystemCommands()
    TriggerServerEvent('chat:init')
    cb('ok')
end)

AddEventHandler('onClientResourceStart', function(resName)
    Wait(500)
    registerSystemCommands()
end)

AddEventHandler('playerSpawned', function()
    Wait(1000)
    registerSystemCommands()
    TriggerServerEvent('chat:init')
end)

RegisterNetEvent('esx:playerLoaded', function()
    Wait(1000)
    registerSystemCommands()
    TriggerServerEvent('chat:init')
end)

RegisterKeyMapping('open_custom_chat', 'Ouvrir le chat', 'keyboard', 'T')

RegisterCommand('open_custom_chat', function()
    if not chatOpen then
        chatOpen = true
        cursorActive = false
        SetNuiFocus(true, false)
        SendNUIMessage({
            action = 'openChat'
        })
    end
end, false)

if Config.EnableChatSettings then
    RegisterCommand('chatsettings', function()
        chatOpen = false
        cursorActive = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openSettings'
        })
    end, false)
end

RegisterNUICallback('toggleCursor', function(data, cb)
    cursorActive = data.cursor == true
    if chatOpen or cursorActive then
        SetNuiFocus(true, cursorActive)
    else
        SetNuiFocus(false, false)
    end
    cb('ok')
end)

RegisterNUICallback('closeChat', function(data, cb)
    chatOpen = false
    cursorActive = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('sendMessage', function(data, cb)
    chatOpen = false
    cursorActive = false
    SetNuiFocus(false, false)

    local message = data.message
    if message and string.len(message) > 0 then
        if string.sub(message, 1, 1) == '/' then
            local cmdName = string.sub(message, 2):match('(%S+)')

            if cmdName then
                local formattedKey = ('/' .. cmdName):lower()
                local exists = suggestionsCache[formattedKey] ~= nil

                if not exists then
                    local lowerName = string.lower(cmdName)
                    for _, cmd in ipairs(GetRegisteredCommands()) do
                        if string.lower(cmd.name) == lowerName then
                            exists = true
                            break
                        end
                    end
                end

                if exists then
                    ExecuteCommand(string.sub(message, 2))
                else
                    SendNUIMessage({
                        action = 'addMessage',
                        data = {
                            author = 'Serveur',
                            message = "Cette commande n'existe pas",
                            color = '#ef4444'
                        }
                    })
                end
            end
        else
            if Config.EnableMessages then
                TriggerServerEvent('_chat:messageEntered', GetPlayerName(PlayerId()), { 102, 178, 255 }, message)
            end
        end
    end

    cb('ok')
end)

RegisterNetEvent('chat:addMessage', function(messageData)
    local author = ''
    local text = ''
    local color = '#66b2ff'

    if type(messageData) == 'table' then
        if messageData.args and #messageData.args > 0 then
            if #messageData.args == 1 then
                text = tostring(messageData.args[1])
            else
                author = tostring(messageData.args[1])
                text = tostring(messageData.args[2])
            end
        elseif messageData.templateId or messageData.template then
            text = messageData.multiline and table.concat(messageData.args or {}, ' ') or
                tostring(messageData.args and messageData.args[1] or '')
        end

        if messageData.color then
            color = parseColor(messageData.color)
        end
    elseif type(messageData) == 'string' then
        text = messageData
    end

    if string.len(text) > 0 or string.len(author) > 0 then
        SendNUIMessage({
            action = 'addMessage',
            data = {
                author = author,
                message = text,
                color = color
            }
        })
    end
end)

RegisterNetEvent('chatMessage', function(author, color, text)
    SendNUIMessage({
        action = 'addMessage',
        data = {
            author = author or '',
            message = text or '',
            color = parseColor(color)
        }
    })
end)

RegisterNetEvent('chat:clear', function()
    SendNUIMessage({
        action = 'clearChat'
    })
end)

RegisterNetEvent('chat:addSuggestion', function(name, help, params)
    sendSuggestionToUI(name, help, params)
end)

RegisterNetEvent('chat:addSuggestions', function(suggestions)
    if not suggestions or type(suggestions) ~= 'table' then return end

    if suggestions.name then
        sendSuggestionToUI(suggestions.name, suggestions.help, suggestions.params or suggestions.arguments)
        return
    end

    for _, suggestion in pairs(suggestions) do
        if type(suggestion) == 'table' and suggestion.name then
            sendSuggestionToUI(suggestion.name, suggestion.help, suggestion.params or suggestion.arguments)
        end
    end
end)

RegisterNetEvent('chat:removeSuggestion', function(name)
    if not name then return end
    local formatted = (name:sub(1, 1) == '/' and name or ('/' .. name)):lower()
    suggestionsCache[formatted] = nil
    if chatLoaded then
        SendNUIMessage({
            action = 'removeSuggestion',
            data = {
                name = formatted
            }
        })
    end
end)

RegisterNetEvent('chat:resetSuggestions', function()
    suggestionsCache = {}
    if chatLoaded then
        SendNUIMessage({
            action = 'resetSuggestions'
        })
    end
    registerSystemCommands()
end)

exports('addSuggestion', function(name, help, params)
    sendSuggestionToUI(name, help, params)
end)

exports('removeSuggestion', function(name)
    local formatted = (name:sub(1, 1) == '/' and name or ('/' .. name)):lower()
    suggestionsCache[formatted] = nil
    if chatLoaded then
        SendNUIMessage({
            action = 'removeSuggestion',
            data = {
                name = formatted
            }
        })
    end
end)
