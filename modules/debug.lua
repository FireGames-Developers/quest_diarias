-- ============================================================================
-- MÓDULO: Debug helpers
-- Funções utilitárias de logging condicionadas por `Config.DevMode`.
-- ============================================================================
function DebugPrint(msg)
    if Config and Config.DevMode then
        print("[FireGames Debug] " .. tostring(msg))
    end
end

function DebugError(err)
    if Config and Config.DevMode then
        print("[FireGames ERROR] " .. tostring(err))
    end
end
