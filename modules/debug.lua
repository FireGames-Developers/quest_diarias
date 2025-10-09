local function DebugPrint(msg)
    if Config and Config.DevMode then
        print("[FireGames Debug] " .. tostring(msg))
    end
end

local function DebugError(err)
    if Config and Config.DevMode then
        print("[FireGames ERROR] " .. tostring(err))
    end
end
