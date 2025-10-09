---------------- UTIL NATIVE BLIP ---------------------
local function CreateNativeBlip(x, y, z)
    -- Nativo seguro para criar blip (compatível)
    local blip = N_0x554d9d53f696d002(Config.blipModel or 1664425300, x, y, z)
    return blip
end

---------------- BLIPS ---------------------
function AddBlip()
    local ok, err = pcall(function()
        if Config.blipAllowed then
            local blip = BlipAddForCoords(Config.blipModel, Config.NpcPosition.x, Config.NpcPosition.y,
                Config.NpcPosition.z)
            if blip then
                SetBlipSprite(blip, Config.blipsprite, true)
                SetBlipScale(blip, 0.2)
                SetBlipName(blip, Config.Name)
                Config.BlipHandle = blip
            else
                DebugPrint("Falha ao criar blip nativo (retornou nil)")
            end
        end
    end)
    if not ok then DebugError(err) end
end