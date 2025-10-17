-- ============================================================================
-- MÓDULO: Blips utilitários
-- Cria e gerencia blips para o ponto do NPC/loja
-- respeitando `Config.blipAllowed`.
-- Dependências: `Config`, `DebugPrint`, `DebugError`.
-- ============================================================================
---------------- UTIL NATIVE BLIP ---------------------
local function CreateNativeBlip(x, y, z)
    -- Nativo seguro para criar blip (compatível)
    local blip = N_0x554d9d53f696d002(Config.blipModel or 1664425300, x, y, z)
    return blip
end

-- Removido suporte de blip single-NPC; utilizamos apenas AddBlipForNpc para múltiplos NPCs.

---------------- BLIPS (multi NPC) ---------------------
function AddBlipForNpc(idx, npc)
    local ok, err = pcall(function()
        if not Config.blipAllowed then return end
        Config.BlipHandles = Config.BlipHandles or {}
        if Config.BlipHandles[idx] then return end

        local pos = npc.position
        local blip = BlipAddForCoords(Config.blipModel, pos.x, pos.y, pos.z)
        if blip then
            SetBlipSprite(blip, Config.blipsprite, true)
            SetBlipScale(blip, 0.2)
            SetBlipName(blip, npc.name or Config.Name)
            Config.BlipHandles[idx] = blip
            DebugPrint("Blip criado: " .. tostring(npc.name or ("NPC #"..tostring(idx))))
        else
            DebugPrint("Falha ao criar blip nativo (retornou nil)")
        end
    end)
    if not ok then DebugError(err) end
end