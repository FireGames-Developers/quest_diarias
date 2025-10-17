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
    local ped = PlayerPedId()
    VorpCore.Callback.TriggerAsync('quest_diarias:getQuestInfo', function(questInfo)
        local npcName = (Config.CurrentNPC and Config.CurrentNPC.name) or 'NPC'
        local texts = questInfo and questInfo.texts or {}

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
            -- Missão 2: entrega via inventário (requiredItem)
            if delivery and delivery.requiredItem then
                TriggerServerEvent('quest_diarias:attemptDeliveryInventory', questId, npcIdx)
                return
            end

            -- Missão 1: entrega segurando a carcaça (modelos aceitos)
            if not isPedCarryingSomething(ped) then
                TriggerEvent('vorp:TipBottom', texts and texts.notDelivered or 'Você não me trouxe o faisão ainda, pegue o mais rápido possível pois estou com fome', 5000)
                return
            end

            local accepted = (delivery and delivery.acceptedModels) or {'A_C_PHEASANT_01', 'P_FOXPHEASANT01X'}
            local carried = getFirstEntityPedIsCarrying(ped)

            if carried and isAcceptedModel(carried, accepted) then
                local ok = deleteCarriedEntity(carried)
                if ok then
                    TriggerEvent('vorp:TipBottom', texts and texts.complete or ('Obrigado pela ajuda, ' .. npcName .. ' vai usar isso agora.'), 5000)
                    TriggerServerEvent('quest_diarias:completeQuest', questId, npcIdx)
                else
                    TriggerEvent('vorp:TipBottom', texts and texts.error or 'Falha ao entregar o item.', 4000)
                end
            else
                TriggerEvent('vorp:TipBottom', texts and texts.notDelivered or 'Você não me trouxe o faisão ainda, pegue o mais rápido possível pois estou com fome', 5000)
            end
        end, questId)
    end, questId)
end)

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
        if texts and texts.complete then
            TriggerEvent('vorp:TipBottom', texts.complete, 5000)
        end
        TriggerServerEvent('quest_diarias:completeQuest', questId, npcIdx)
    end, questId)
end)