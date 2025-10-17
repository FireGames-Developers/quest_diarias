-- =========================================================================
-- Missão 1: Caça ao Faisão (Estrutura Modular)
-- =========================================================================
-- Estrutura com textos centralizados, eventos definidos e lógica isolada.
-- Permite reuso ao criar novas quests alterando apenas conteúdo.
-- =========================================================================

local Quest1 = {}

-- Configurações principais
Quest1.Config = {
    id = 1,
    name = "Caça ao Faisão",
    description = "Cace um faisão e traga a carcaça nas mãos para o NPC.",

    rewards = {
        money = 50,
        items = {
            -- { item = "bread", amount = 2 }
        }
    },

    markers = {
        huntingArea = {
            coords = vector3(-1200.0, 2400.0, 300.0),
            radius = 500.0,
            blip = {
                sprite = -1282792512,
                color = 3,
                name = "Área de Caça - Faisões"
            }
        }
    },

    delivery = {
        acceptedModels = {
            'A_C_PHEASANT_01',
            'P_FOXPHEASANT01X',
            'P_TAXIDERMYPHEASANT02X'
        }
    },

    texts = {
        start = "Vá até a área marcada e cace um faisão. Traga-o nas mãos para mim.",
        progress = "Cace um faisão e traga a carcaça nas mãos.",
        complete = "Obrigada pela ajuda, estou com muita fome, vou preparar esse faisão e me alimentar",
        alreadyCompleted = "Você já ajudou este NPC hoje. Volte amanhã para novas solicitações.",
        notDelivered = "Você não me trouxe o faisão ainda, pegue o mais rápido possível pois estou com fome",
        deliverHint = "Entregue o faisão nas mãos para concluir a missão.",
        error = "Ocorreu um erro ao processar a missão."
    }
}

-- Eventos para integração
Quest1.Events = {
    attemptDelivery = 'quest_diarias:attemptDelivery',
    questStartedClient = 'quest_diarias:questStarted',
    questCompletedClient = 'quest_diarias:questCompleted'
}

-- Iniciar missão
function Quest1.StartQuest(source)
    local area = Quest1.Config.markers.huntingArea
    local blipData = {
        x = area.coords.x,
        y = area.coords.y,
        z = area.coords.z,
        sprite = Config.blipsprite,
        color = area.blip.color,
        name = area.blip.name,
        radius = area.radius,
        areaStyle = area.blip.sprite
    }
    TriggerClientEvent('quest_diarias:createQuestBlip', source, Quest1.Config.id, blipData)
    TriggerClientEvent('vorp:TipBottom', source, Quest1.Config.texts.start, 6000)
    return true
end

-- Objetivos da missão (para /quest)
function Quest1.GetObjectives(progress)
    local objectives = {}
    table.insert(objectives, ('Missão: %s'):format(Quest1.Config.name))
    table.insert(objectives, Quest1.Config.description)
    table.insert(objectives, Quest1.Config.texts.progress)
    table.insert(objectives, Quest1.Config.texts.deliverHint)

    local status = (progress and progress.delivered) and 'Concluído' or 'Pendente'
    table.insert(objectives, ('Progresso: Entrega do faisão - %s'):format(status))

    local rewards = Quest1.Config.rewards
    if rewards then
        local items = {}
        if rewards.money and rewards.money > 0 then table.insert(items, ('$%d'):format(rewards.money)) end
        if rewards.items and #rewards.items > 0 then table.insert(items, ('%d item(ns)'):format(#rewards.items)) end
        if #items > 0 then
            table.insert(objectives, ('Recompensas: %s'):format(table.concat(items, ', ')))
        end
    end

    return objectives
end

-- Teste específico da missão (executado via /quest_test)
function Quest1.RunTest(source, params)
    local distance = (params and params.distance) or 3.0
    local dead = (params and params.dead) ~= false -- padrão: morto
    local payload = {
        action = 'spawnAnimal',
        model = 'A_C_PHEASANT_01',
        distance = distance,
        dead = dead
    }
    TriggerClientEvent('quest_diarias:runMissionTest', source, Quest1.Config.id, payload)
end

-- retorno movido para o final do arquivo para suportar cliente


-- =========================================================================
-- Guia de Criação de Quests (documentação)
-- Este arquivo serve de TEMPLATE. Ideia principal:
-- - A lógica de entrega fica dentro do arquivo da quest.
-- - O menu chama um evento dinâmico: 'quest_diarias:quest<ID>:attemptDelivery'.
-- - Recompensas e registro de conclusão são gerais via 'quest_diarias:completeQuest'.
-- - Controle diário (pode ou não fazer) é CENTRAL no servidor.
-- Como criar sua quest:
-- 1) Copie este arquivo para 'quests/questN.lua' e ajuste Config (id, textos, objetivos).
-- 2) Implemente o evento cliente 'quest_diarias:questN:attemptDelivery' com sua regra de entrega.
-- 3) Se sua entrega for por inventário, pode delegar ao servidor: crie também
--    'quest_diarias:questN:attemptDelivery' no servidor e, ao sucesso,
--    dispare um evento cliente próprio para acionar 'completeQuest'.
-- 4) Não implemente checagem diária aqui; o servidor decide se pode iniciar.
-- 5) Recompensas são lidas do Config e aplicadas no servidor ao completar a missão.
-- =========================================================================
if not IsDuplicityVersion() then
    -- Helpers locais para detectar e remover o item carregado nas mãos
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
            if model == hash then return true end
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

    -- Cliente: tentativa de entrega da missão 1
    RegisterNetEvent('quest_diarias:quest1:attemptDelivery')
    AddEventHandler('quest_diarias:quest1:attemptDelivery', function()
        local ped = PlayerPedId()
    
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
        local npcName = (Config.CurrentNPC and Config.CurrentNPC.name) or 'NPC'
        if not npcIdx then
            TriggerEvent('vorp:TipBottom', ('Aproxime-se de %s para entregar o faisão.'):format(npcName), 5000)
            return
        end

        VorpCore.Callback.TriggerAsync('quest_diarias:getDeliveryConfig', function(delivery)
            local accepted = (delivery and delivery.acceptedModels) or {'A_C_PHEASANT_01', 'P_FOXPHEASANT01X', 'P_TAXIDERMYPHEASANT02X'}

            if not Citizen.InvokeNative(0xA911EE21EDF69DAF, ped) then
                local msg = Quest1.Config.texts and (Quest1.Config.texts.deliverHint or Quest1.Config.texts.notDelivered) or 'Você não está carregando o item certo.'
                TriggerEvent('vorp:TipBottom', msg, 5000)
                return
            end

            local carried = Citizen.InvokeNative(0xD806CD2A4F2C2996, ped)
            local okModel = false
            local carriedHash = carried and GetEntityModel(carried)
            for _, name in ipairs(accepted) do
                if carriedHash == GetHashKey(name) then okModel = true break end
            end

            if okModel then
                SetEntityAsMissionEntity(carried, true, true)
                DeleteEntity(carried)
                local completeMsg = Quest1.Config.texts and Quest1.Config.texts.complete or ('Obrigado pela ajuda, ' .. npcName .. ' vai usar isso agora.')
                TriggerEvent('vorp:TipBottom', completeMsg, 5000)
                TriggerServerEvent('quest_diarias:completeQuest', Quest1.Config.id, npcIdx)
            else
                local notDeliveredMsg = Quest1.Config.texts and (Quest1.Config.texts.notDelivered or Quest1.Config.texts.deliverHint) or 'Modelo inválido para entrega.'
                TriggerEvent('vorp:TipBottom', notDeliveredMsg, 5000)
                if Config.DevMode and carriedHash then
                    print(('[Quest1] Modelo carregado não aceito: hash %s'):format(tostring(carriedHash)))
                end
            end
        end, Quest1.Config.id)
    end)
end

-- Retorno apenas no servidor para compatibilidade com QuestManager
if IsDuplicityVersion() then return Quest1 end