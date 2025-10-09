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

RegisterNetEvent('quest_diarias:attemptDelivery')
AddEventHandler('quest_diarias:attemptDelivery', function(questId)
    local ped = PlayerPedId()

    VorpCore.Callback.TriggerAsync('quest_diarias:getQuestInfo', function(questInfo)
        local npcName = (Config and Config.NpcName) or 'NPC'
        local texts = questInfo and questInfo.texts or {}

        if not isPedCarryingSomething(ped) then
            TriggerEvent('vorp:TipBottom', texts and texts.notDelivered or 'Você não me trouxe o faisão ainda, pegue o mais rápido possível pois estou com fome', 5000)
            return
        end

        VorpCore.Callback.TriggerAsync('quest_diarias:getDeliveryConfig', function(delivery)
            local accepted = (delivery and delivery.acceptedModels) or {'A_C_PHEASANT_01', 'P_FOXPHEASANT01X'}
            local carried = getFirstEntityPedIsCarrying(ped)

            if carried and isAcceptedModel(carried, accepted) then
                local ok = deleteCarriedEntity(carried)
                if ok then
                    TriggerEvent('vorp:TipBottom', texts and texts.complete or ('Obrigado pela ajuda, ' .. npcName .. ' vai usar isso agora.'), 5000)
                    TriggerServerEvent('quest_diarias:completeQuest', questId)
                else
                    TriggerEvent('vorp:TipBottom', texts and texts.error or 'Falha ao entregar o item.', 4000)
                end
            else
                TriggerEvent('vorp:TipBottom', texts and texts.notDelivered or 'Você não me trouxe o faisão ainda, pegue o mais rápido possível pois estou com fome', 5000)
            end
        end, questId)
    end, questId)
end)