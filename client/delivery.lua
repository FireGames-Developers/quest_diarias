-- ============================================================================
-- Entrega de Itens na Missão (Cliente)
-- ============================================================================
local VorpCore = exports.vorp_core:GetCore()

local function isPedCarryingSomething(ped)
    return Citizen.InvokeNative(0xA911EE21EDF69DAF, ped)
end

local function getFirstEntityPedIsCarrying(ped)
    return Citizen.InvokeNative(0xD806CD2A4F2C2996, ped)
end

local function isAcceptedModel(entity, acceptedModels)
    if not DoesEntityExist(entity) then return false end
    local model = GetEntityModel(entity)
    for _, name in ipairs(acceptedModels or {}) do
        local hash = GetHashKey(name)
        if model == hash then
            return true
        end
    end
    return false
end

local function deleteCarriedEntity(entity)
    if not DoesEntityExist(entity) then return false end
    SetEntityAsMissionEntity(entity, true, true)
    if IsEntityAPed(entity) then
        ClearPedTasksImmediately(entity)
        DeletePed(entity)
        return true
    elseif IsEntityAnObject(entity) then
        DeleteObject(entity)
        return true
    else
        DeleteEntity(entity)
        return true
    end
end

-- Entrega genérica de missão atual
RegisterNetEvent('quest_diarias:attemptDelivery')
AddEventHandler('quest_diarias:attemptDelivery', function(questId)
    DebugPrint(('[Delivery] attemptDelivery acionado (questId=%s)'):format(tostring(questId)))
    local ped = PlayerPedId()
    -- Feedback imediato para o jogador ao iniciar a validação de entrega
    TriggerEvent('vorp:TipBottom', 'Validando entrega...', 1500)
    
    VorpCore.Callback.TriggerAsync('quest_diarias:getQuestInfo', function(questInfo)
        DebugPrint('[Delivery] getQuestInfo retornou, seguindo com validações')
        -- Textos padrão caso o questInfo ou questInfo.texts não estejam disponíveis
        local defaultTexts = {
            notDelivered = 'Sem o item correto eu não consigo fazer nada. Volte com o faisão nas mãos.',
            deliverHint  = 'Traga o faisão nas mãos e fale comigo para entregar.',
            complete     = 'Entrega concluída com sucesso!',
            error        = 'Não foi possível validar a entrega. Tente novamente.'
        }
        local texts = (questInfo and questInfo.texts) or defaultTexts
        local npcName = (Config.CurrentNPC and Config.CurrentNPC.name) or 'NPC'
          -- texts already defined above with fallback

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

        VorpCore.Callback.TriggerAsync('quest_diarias:getDeliveryConfig', function(delivery)
            DebugPrint('[Delivery] getDeliveryConfig retornou')
            -- Missão 2: entrega via inventário (requiredItem)
            if delivery and delivery.requiredItem then
                DebugPrint('[Delivery] Entrega por inventário detectada, acionando servidor')
                TriggerServerEvent('quest_diarias:attemptDeliveryInventory', questId, npcIdx)
                return
            end

            -- Missão 1: entrega segurando a carcaça (modelos aceitos)
            if not isPedCarryingSomething(ped) then
                DebugPrint('[Delivery] Jogador não está carregando nada')
                local msg = (texts and (texts.notDelivered or texts.deliverHint))
                if msg and npcName then msg = msg:gsub('{npc}', npcName) end
                if msg then TriggerEvent('vorp:TipBottom', msg, 5000) end
                TriggerEvent('quest_diarias:playNpcAnimConfigured', 'notReady')
                TriggerEvent('quest_diarias:playNpcSpeechConfigured', 'notReady')
                return
            end

            local accepted = (delivery and delivery.acceptedModels) or {'A_C_PHEASANT_01', 'P_FOXPHEASANT01X', 'P_TAXIDERMYPHEASANT02X'}
            local carried = getFirstEntityPedIsCarrying(ped)

            if carried and isAcceptedModel(carried, accepted) then
                DebugPrint('[Delivery] Modelo carregado é aceito, validando NPC')
                VorpCore.Callback.TriggerAsync('quest_diarias:validateNpcForDelivery', function(valid)
                    DebugPrint(('[Delivery] validateNpcForDelivery=%s'):format(tostring(valid)))
                    if not valid then
                        local msg = (texts and (texts.deliverHint or texts.notDelivered))
                        if msg and npcName then msg = msg:gsub('{npc}', npcName) end
                        if msg then TriggerEvent('vorp:TipBottom', msg, 5000) end
                        TriggerEvent('quest_diarias:playNpcAnimConfigured', 'notReady')
                        TriggerEvent('quest_diarias:playNpcSpeechConfigured', 'notReady')
                        return
                    end

                    local ok = deleteCarriedEntity(carried)
                    DebugPrint(('[Delivery] deleteCarriedEntity=%s'):format(tostring(ok)))
                    if ok then
                        local msg = texts and texts.complete
                        if msg and npcName then msg = msg:gsub('{npc}', npcName) end
                        if msg then TriggerEvent('vorp:TipBottom', msg, 5000) end
                        TriggerServerEvent('quest_diarias:completeQuest', questId, npcIdx)
                    else
                        local msg = texts and texts.error
                        if msg then TriggerEvent('vorp:TipBottom', msg, 5000) end
                    end
                end, questId, npcIdx)
            else
                local modelHash = carried and GetEntityModel(carried)
                if Config.DevMode and modelHash then
                    print(('[Delivery] Modelo carregado não aceito: hash %s'):format(tostring(modelHash)))
                end
                local msg = (texts and (texts.notDelivered or texts.deliverHint))
                if msg and npcName then msg = msg:gsub('{npc}', npcName) end
                if msg then TriggerEvent('vorp:TipBottom', msg, 5000) end
                TriggerEvent('quest_diarias:playNpcAnimConfigured', 'notReady')
                TriggerEvent('quest_diarias:playNpcSpeechConfigured', 'notReady')

                end
        end, questId)
    end, questId) -- getQuestInfo
end) -- attemptDelivery

-- Sucesso de entrega via inventário: conclui missão e mostra feedback
RegisterNetEvent('quest_diarias:inventoryDeliverySuccess')
AddEventHandler('quest_diarias:inventoryDeliverySuccess', function(questId)
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

    VorpCore.Callback.TriggerAsync('quest_diarias:getQuestInfo', function(questInfo)
        local texts = questInfo and questInfo.texts or {}
        local npcName = (Config.CurrentNPC and Config.CurrentNPC.name) or nil
        local msg = texts and texts.complete
        if msg and npcName then msg = msg:gsub('{npc}', npcName) end
        if msg then TriggerEvent('vorp:TipBottom', msg, 5000) end
        TriggerServerEvent('quest_diarias:completeQuest', questId, npcIdx)
    end, questId)
end)