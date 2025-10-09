-- ============================================================================
-- TESTE DE MISSÃO (CLIENTE)
-- ============================================================================
-- Spawna um faisão à frente do jogador para teste de combate.
-- ============================================================================

RegisterNetEvent('quest_diarias:testMission:spawnPheasant')
AddEventHandler('quest_diarias:testMission:spawnPheasant', function(distance)
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

    TriggerEvent('vorp:TipBottom', 'Faisão spawnado à sua frente', 3000)
    SetModelAsNoLongerNeeded(model)
end)