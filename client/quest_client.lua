-- Quest Client - Sistema de Missões do Cliente
-- Desenvolvido por FTx3g

local VorpCore = exports.vorp_core:GetCore()
local activeQuest = nil
local questBlips = {}

-- Integração opcional com vorp_animations
local Animations = nil
local function InitAnimations()
    local ok, api = pcall(function()
        if exports and exports.vorp_animations and exports.vorp_animations.initiate then
            return exports.vorp_animations.initiate()
        end
    end)
    if ok and api then
        Animations = api
        if Config.DevMode then print('[Quest Client] vorp_animations iniciado') end
    else
        if Config.DevMode then print('[Quest Client] vorp_animations indisponível') end
    end
end

-- Utilitário: obter o ped do NPC atual
local function GetCurrentNpcPed()
    local idx = Config.CurrentNPCIdx
    if idx and Config.NPC_ENTS and Config.NPC_ENTS[idx] and DoesEntityExist(Config.NPC_ENTS[idx]) then
        return Config.NPC_ENTS[idx]
    end
    return nil
end

-- Utilitário: tocar animação no NPC atual (dict/name)
local function PlayNpcAnim(dict, name, flag, duration)
    local ped = GetCurrentNpcPed()
    if not ped or not dict or dict == '' or not name or name == '' then return false end
    RequestAnimDict(dict)
    local tries = 0
    while not HasAnimDictLoaded(dict) and tries < 100 do
        Wait(0)
        tries = tries + 1
    end
    if not HasAnimDictLoaded(dict) then return false end
    local f = (type(flag) == 'number') and flag or 17
    TaskPlayAnim(ped, dict, name, 1.0, 1.0, -1, f, 1.0, false, false, false, '', false)
    local dur = (type(duration) == 'number') and duration or 2000
    if dur > 0 then
        CreateThread(function()
            Wait(dur)
            StopAnimTask(ped, dict, name, 1.0)
            TaskStandStill(ped, -1)
            RemoveAnimDict(dict)
        end)
    end
    return true
end

-- Utilitário: tocar animação conforme configuração (start/notReady/complete)
local function PlayNpcAnimConfigured(kind)
    local conf = Config.NPCAnimations or {}
    local anim = conf[kind]
    if anim and anim.dict and anim.name then
        PlayNpcAnim(anim.dict, anim.name, anim.flag, anim.duration)
    end
end

-- Fala: obter config do NPC atual (para voiceName opcional)
local function GetCurrentNpcConf()
    local idx = Config.CurrentNPCIdx
    if idx and Config.NPCs and Config.NPCs[idx] then
        return Config.NPCs[idx]
    end
    return nil
end

-- Utilitário: tocar fala nativa no NPC atual
local function PlayNpcSpeech(speechName, voiceName, param)
    local ped = GetCurrentNpcPed()
    if not ped or not speechName or speechName == '' then return false end
    local voice = voiceName
    if not voice or voice == '' then
        local npc = GetCurrentNpcConf()
        voice = (npc and npc.voiceName) or (Config.NPCSpeechDefaultVoice or '')
    end
    local paramHash = GetHashKey(type(param) == 'string' and param or 'SPEECH_PARAMS_FORCE_NORMAL')
    local ok1 = pcall(function()
        Citizen.InvokeNative(0x3523634255FC3318, ped, speechName, voice, paramHash, 0)
    end)
    if not ok1 then
        pcall(function()
            Citizen.InvokeNative(0x8E04FEDD28D42462, ped, speechName, paramHash, true)
        end)
    end
    return true
end

-- Utilitário: tocar fala conforme configuração (start/notReady/complete)
local function PlayNpcSpeechConfigured(kind)
    local conf = Config.NPCSpeech or {}
    local s = conf[kind]
    if s and s.speech then
        PlayNpcSpeech(s.speech, s.voiceName, s.param)
    end
end

RegisterNetEvent('quest_diarias:questStarted')
AddEventHandler('quest_diarias:questStarted', function(questId)
    if Config.DevMode then
        print(('[Quest Client] Quest %d iniciada'):format(questId))
    end
    activeQuest = questId
    -- NPC animação de início
    PlayNpcAnimConfigured('start')
    -- NPC fala de início
    PlayNpcSpeechConfigured('start')
    -- Mensagens de início são exibidas pelos próprios arquivos de quest (texts.start)
end)

-- Event para quando uma quest é completada
RegisterNetEvent('quest_diarias:questCompleted')
AddEventHandler('quest_diarias:questCompleted', function(questId, rewards)
    if Config.DevMode then
        print(('[Quest Client] Quest %d completada'):format(questId))
    end
    activeQuest = nil
    -- NPC animação de conclusão
    PlayNpcAnimConfigured('complete')
    -- NPC fala de conclusão
    PlayNpcSpeechConfigured('complete')
    -- Remover blips da quest
    if questBlips[questId] then
        for _, blip in pairs(questBlips[questId]) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
        questBlips[questId] = nil
    end
    
    -- Notificar o jogador sobre as recompensas
    if rewards then
        local rewardText = 'Missão completada! Recompensas:'
        if rewards.money and rewards.money > 0 then
            rewardText = rewardText .. ('\n• $%.2f'):format(rewards.money)
        end
        -- XP removido; sem exibição de Gold, apenas Money
        TriggerEvent('vorp:TipBottom', rewardText, 5000)
    end
end)

-- Elegível: iniciar missão automaticamente (com NPC index)
RegisterNetEvent('quest_diarias:canDoQuestResponse')
AddEventHandler('quest_diarias:canDoQuestResponse', function(canDo)
    if not canDo then
        TriggerEvent('vorp:TipBottom', 'Você já fez uma missão hoje. Volte amanhã.', 5000)
        return
    end
    local questId = Config.mission
    -- Elegível: iniciar missão automaticamente (com NPC index)
    local function GetCurrentNpcIndex()
        if Config.CurrentNPCIdx then return Config.CurrentNPCIdx end
        local name = Config.CurrentNPC and Config.CurrentNPC.name
        if name and Config.NPCs then
            for i, npc in ipairs(Config.NPCs) do
                if npc.name == name then return i end
            end
        end
        return nil
    end
    local npcIdx = GetCurrentNpcIndex()
    TriggerServerEvent('quest_diarias:startQuest', questId, npcIdx)
end)

-- Função para obter a quest ativa
function GetActiveQuest()
    return activeQuest
end

-- Função para verificar se tem uma quest ativa
function HasActiveQuest()
    return activeQuest ~= nil
end

if Config.DevMode then
    print('[Quest Client] Sistema de quests do cliente inicializado')
end

-- =========================================================================
-- TESTE DE MISSÃO (GENÉRICO)
-- =========================================================================
RegisterNetEvent('quest_diarias:runMissionTest')
AddEventHandler('quest_diarias:runMissionTest', function(questId, payload)
    if questId == 1 and payload and payload.action == 'spawnAnimal' then
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local forward = GetEntityForwardVector(ped)
        local spawnDist = (type(payload.distance) == 'number' and payload.distance or 6.0)
        local spawnPos = vector3(
            coords.x + forward.x * spawnDist,
            coords.y + forward.y * spawnDist,
            coords.z + forward.z * spawnDist
        )
        local model = GetHashKey(payload.model or 'A_C_PHEASANT_01')
        if not IsModelInCdimage(model) then
            TriggerEvent('vorp:TipBottom', 'Modelo de animal indisponível', 5000)
            return
        end
        RequestModel(model, false)
        repeat Wait(0) until HasModelLoaded(model)
        local created = CreatePed(model, spawnPos.x, spawnPos.y, spawnPos.z, GetEntityHeading(ped), true, false, false, false)
        if not DoesEntityExist(created) then
            TriggerEvent('vorp:TipBottom', 'Falha ao spawnar animal de teste', 5000)
            SetModelAsNoLongerNeeded(model)
            return
        end
        Citizen.InvokeNative(0x283978A15512B2FE, created, true)
        PlaceEntityOnGroundProperly(created, true)
        SetEntityAsMissionEntity(created, true, true)
        if payload.dead then
            FreezeEntityPosition(created, false)
            SetEntityHealth(created, 0)
            PlaceEntityOnGroundProperly(created, true)
            ClearPedTasksImmediately(created)
            TriggerEvent('vorp:TipBottom', 'Carcaça posicionada no chão', 5000)
        else
            TriggerEvent('vorp:TipBottom', 'Animal spawnado à sua frente', 5000)
        end
        SetModelAsNoLongerNeeded(model)
    else
        if Config.DevMode then
            print('[Quest Client] Nenhuma rotina de teste configurada para esta missão')
        end
    end
end)
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        InitAnimations()
        activeQuest = nil
        for id, blips in pairs(questBlips) do
            for _, blip in pairs(blips) do
                if DoesBlipExist(blip) then
                    RemoveBlip(blip)
                end
            end
            questBlips[id] = nil
        end
        TriggerEvent('vorp:TipBottom', 'Sistema de quests reiniciado.', 5000)
    end
end)
AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        activeQuest = nil
        for id, blips in pairs(questBlips) do
            for _, blip in pairs(blips) do
                if DoesBlipExist(blip) then
                    RemoveBlip(blip)
                end
            end
            questBlips[id] = nil
        end
    end
end)

-- Utilitário: aplicar cor de blip via modificador (compat RedM)
local function ApplyBlipColor(blip, color)
    if not blip or not DoesBlipExist(blip) then return end
    if not color then return end
    local COLOR_MAP = {
        blue = 'BLIP_MODIFIER_MP_COLOR_1',
        red = 'BLIP_MODIFIER_MP_COLOR_2',
        purple = 'BLIP_MODIFIER_MP_COLOR_3',
        orange = 'BLIP_MODIFIER_MP_COLOR_4',
        aqua = 'BLIP_MODIFIER_MP_COLOR_5',
        yellow = 'BLIP_MODIFIER_MP_COLOR_6',
        pink = 'BLIP_MODIFIER_MP_COLOR_7',
        green = 'BLIP_MODIFIER_MP_COLOR_8',
        brown = 'BLIP_MODIFIER_MP_COLOR_9',
        lightgreen = 'BLIP_MODIFIER_MP_COLOR_10',
        turquoise = 'BLIP_MODIFIER_MP_COLOR_11',
        lightpurple = 'BLIP_MODIFIER_MP_COLOR_12',
        lightblue2 = 'BLIP_MODIFIER_MP_COLOR_13',
        lightorange = 'BLIP_MODIFIER_MP_COLOR_14',
        lightred = 'BLIP_MODIFIER_MP_COLOR_15',
        lightpink = 'BLIP_MODIFIER_MP_COLOR_16',
        lightgray = 'BLIP_MODIFIER_MP_COLOR_17',
        black = 'BLIP_MODIFIER_MP_COLOR_18',
        darkred = 'BLIP_MODIFIER_MP_COLOR_19',
        darkgreen = 'BLIP_MODIFIER_MP_COLOR_20',
        darkblue = 'BLIP_MODIFIER_MP_COLOR_21',
        darkyellow = 'BLIP_MODIFIER_MP_COLOR_22',
        darkpurple = 'BLIP_MODIFIER_MP_COLOR_23',
        darklightblue = 'BLIP_MODIFIER_MP_COLOR_24',
        darkwhite = 'BLIP_MODIFIER_MP_COLOR_25',
        darkgray = 'BLIP_MODIFIER_MP_COLOR_26',
        darkbrown = 'BLIP_MODIFIER_MP_COLOR_27',
        darklightgreen = 'BLIP_MODIFIER_MP_COLOR_28',
        darklightyellow = 'BLIP_MODIFIER_MP_COLOR_29',
        darklightpurple = 'BLIP_MODIFIER_MP_COLOR_30',
        lightyellow = 'BLIP_MODIFIER_MP_COLOR_31',
        white = 'BLIP_MODIFIER_MP_COLOR_32',
    }
    local modifierKey
    if type(color) == 'string' then
        modifierKey = COLOR_MAP[color]
        if not modifierKey then return end
    elseif type(color) == 'number' then
        modifierKey = ('BLIP_MODIFIER_MP_COLOR_%d'):format(color)
    else
        return
    end
    BlipAddModifier(blip, joaat(modifierKey))
end

-- Criar blips da missão (ponto + área opcional)
RegisterNetEvent('quest_diarias:createQuestBlip')
AddEventHandler('quest_diarias:createQuestBlip', function(questId, blipData)
    if not questBlips[questId] then
        questBlips[questId] = {}
    end

    local pointBlip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, blipData.x, blipData.y, blipData.z)
    SetBlipSprite(pointBlip, blipData.sprite or Config.blipsprite, true)
    Citizen.InvokeNative(0x9CB1A1623062F402, pointBlip, blipData.name or 'Missão')
    ApplyBlipColor(pointBlip, blipData.color)
    table.insert(questBlips[questId], pointBlip)

    if blipData.radius and type(blipData.radius) == 'number' and blipData.radius > 0 then
        local areaStyle = blipData.areaStyle or blipData.sprite or -1282792512
        local radiusBlip = Citizen.InvokeNative(0x45f13b7e0a15c880, areaStyle, blipData.x, blipData.y, blipData.z, blipData.radius)
        Citizen.InvokeNative(0x9CB1A1623062F402, radiusBlip, blipData.name or 'Área da Missão')
        ApplyBlipColor(radiusBlip, blipData.areaColor or blipData.color)
        table.insert(questBlips[questId], radiusBlip)
    end

    if Config.DevMode then
        print(('[Quest Client] Blips criados para quest %d (ponto%s)'):format(
            questId,
            blipData.radius and ' + área' or ''
        ))
    end
end)

-- Remover blips da missão
RegisterNetEvent('quest_diarias:removeQuestBlip')
AddEventHandler('quest_diarias:removeQuestBlip', function(questId)
    if questBlips[questId] then
        for _, blip in pairs(questBlips[questId]) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
        questBlips[questId] = nil
        if Config.DevMode then
            print(('[Quest Client] Blips removidos para quest %d'):format(questId))
        end
    end
end)

-- Evento utilitário para outros módulos acionarem animações no NPC
RegisterNetEvent('quest_diarias:playNpcAnimConfigured')
AddEventHandler('quest_diarias:playNpcAnimConfigured', function(kind)
    PlayNpcAnimConfigured(kind)
end)

-- Evento utilitário para outros módulos acionarem fala no NPC
RegisterNetEvent('quest_diarias:playNpcSpeechConfigured')
AddEventHandler('quest_diarias:playNpcSpeechConfigured', function(kind)
    PlayNpcSpeechConfigured(kind)
end)

-- Comandos de preview de animação (dev)
RegisterCommand('npcanim', function(_, args)
    local kind = args and args[1]
    if not kind then
        TriggerEvent('vorp:TipBottom', 'Uso: /npcanim start|complete|notReady', 5000)
        return
    end
    TriggerEvent('quest_diarias:playNpcAnimConfigured', kind)
end)

RegisterCommand('npcanim_raw', function(_, args)
    local dict = args and args[1]
    local name = args and args[2]
    local flag = args and tonumber(args[3]) or 17
    local duration = args and tonumber(args[4]) or 2000
    if not dict or not name then
        TriggerEvent('vorp:TipBottom', 'Uso: /npcanim_raw <dict> <name> [flag] [duration_ms]', 5000)
        return
    end
    local ok = PlayNpcAnim(dict, name, flag, duration)
    if not ok then
        TriggerEvent('vorp:TipBottom', 'Falha ao tocar animação no NPC. Verifique dict/name.', 5000)
    end
end)

-- Comandos de preview de fala (dev)
RegisterCommand('npcvoice', function(_, args)
    local kind = args and args[1]
    if not kind then
        TriggerEvent('vorp:TipBottom', 'Uso: /npcvoice start|complete|notReady|openMenu|closeMenu', 5000)
        return
    end
    TriggerEvent('quest_diarias:playNpcSpeechConfigured', kind)
end)

RegisterCommand('npcvoice_raw', function(_, args)
    local speech = args and args[1]
    local voiceName = args and args[2]
    local param = args and args[3] or 'SPEECH_PARAMS_FORCE_NORMAL'
    if not speech then
        TriggerEvent('vorp:TipBottom', 'Uso: /npcvoice_raw <speech> [voiceName] [param]', 5000)
        return
    end
    local ok = PlayNpcSpeech(speech, voiceName, param)
    if not ok then
        TriggerEvent('vorp:TipBottom', 'Falha ao tocar fala no NPC. Verifique speech/voz.', 5000)
    end
end)

RegisterCommand('playeranim', function(_, args)
    local anim = args and args[1]
    local time = args and tonumber(args[2]) or 2000
    if not anim then
        TriggerEvent('vorp:TipBottom', 'Uso: /playeranim <animation_name> [duration_ms]', 5000)
        return
    end
    if Animations then
        Animations.playAnimation(anim, time)
    else
        TriggerEvent('vorp:TipBottom', 'vorp_animations não iniciado.', 5000)
    end
end)

RegisterCommand('vorp_anim_list', function()
    print('[VORP Animations] Nomes comuns no config: campfire, craft, spindlecook, knifecooking, riverwash, hoeing, readnewspaper, gravedigging, sweeping, carry_box, carry_sugar, carry_barrel, carry_moonshine, carry_moonshine2')
    TriggerEvent('vorp:TipBottom', 'Abra resources/[VORP]/vorp_animations/config.lua para lista completa.', 6000)
end)