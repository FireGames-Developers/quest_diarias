-- ============================================================================
-- TESTE DE MISSÃO (CLIENTE)
-- ============================================================================
-- Spawna um faisão à frente do jogador. Se "dead" for true,
-- o faisão será criado já morto no chão para testes de entrega.
-- ============================================================================

RegisterNetEvent('quest_diarias:testMission:spawnPheasant')
AddEventHandler('quest_diarias:testMission:spawnPheasant', function(distance, dead)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local spawnDist = (type(distance) == 'number' and distance or 6.0)
    local spawnPos = vector3(
        coords.x + forward.x * spawnDist,
        coords.y + forward.y * spawnDist,
        coords.z + forward.z * spawnDist
    )

    local model = `A_C_PHEASANT_01`
    if not IsModelInCdimage(model) then
        TriggerEvent('vorp:TipBottom', 'Modelo de faisão indisponível', 3000)
        return
    end

    RequestModel(model, false)
    repeat Wait(0) until HasModelLoaded(model)

    local created = CreatePed(model, spawnPos.x, spawnPos.y, spawnPos.z, GetEntityHeading(ped), true, false, false, false)
    if not DoesEntityExist(created) then
        TriggerEvent('vorp:TipBottom', 'Falha ao spawnar faisão', 3000)
        SetModelAsNoLongerNeeded(model)
        return
    end

    Citizen.InvokeNative(0x283978A15512B2FE, created, true) -- Random outfit
    PlaceEntityOnGroundProperly(created, true)
    SetEntityAsMissionEntity(created, true, true)
    -- Opcional: definir como animal
    -- Citizen.InvokeNative(0x77FF8D35EEC6BBC4, created, 1, 0)

    if dead then
        -- Evitar que voe: congelar e matar em seguida, então posicionar no chão.
        FreezeEntityPosition(created, false)
        -- Reduz saúde e aplica dano fatal
        SetEntityHealth(created, 0)
        -- Alternativamente, usar native para matar o ped
        -- Citizen.InvokeNative(0x697157CED63F7C8B, created) -- Kill Ped (RDR2 native)
        -- Garantir que está deitado no chão
        PlaceEntityOnGroundProperly(created, true)
        -- Remover qualquer tarefa para evitar animações
        ClearPedTasksImmediately(created)
        TriggerEvent('vorp:TipBottom', 'Carcaça de faisão posicionada no chão', 3000)
    else
        TriggerEvent('vorp:TipBottom', 'Faisão spawnado à sua frente', 3000)
    end

    SetModelAsNoLongerNeeded(model)
end)