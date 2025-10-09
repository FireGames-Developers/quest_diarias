local inmenu = false
local prompts = GetRandomIntInRange(0, 0xffffff)
local MenuData = exports.vorp_menu:GetMenuData()
local openmenu = nil

---------------- PROMPT ---------------------
local function PromptSetUp()
    local ok, err = pcall(function()
        local str = Config.text.openmenu
        openmenu = PromptRegisterBegin()
        PromptSetControlAction(openmenu, Config.Key)
        local vstr = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(openmenu, vstr)
        PromptSetEnabled(openmenu, true)
        PromptSetVisible(openmenu, true)
        PromptSetStandardMode(openmenu, true)
        PromptSetGroup(openmenu, prompts)
        PromptRegisterEnd(openmenu)
        DebugPrint("Prompt criado: " .. tostring(str) .. " com tecla " .. tostring(Config.Key))
    end)
    if not ok then DebugError(err) end
end

----------------- MENU ----------------------
local function CloseStore()
    MenuData.CloseAll()
    ClearPedTasks(PlayerPedId())
    DisplayRadar(true)
    inmenu = false
end

function OpenStore()

    MenuData.CloseAll()
    local elements = Config.elementsMenu
    inmenu = true

    MenuData.Open('default', GetCurrentResourceName(), 'menuapi',
        {
            title    = Config.Name,
            subtext  = Config.text.welcome,
            align    = 'top-left',
            elements = elements,
        },
        function(data, menu)
            if data.current.value == 'getQuest' then
                DebugPrint("Opção Pegar missão selecionada")
                -- Iniciar a missão configurada
                TriggerServerEvent('quest_diarias:startQuest', Config.mission)
                CloseStore()
            elseif data.current.value == 'deliveryQuest' then
                DebugPrint("Opção Entregar missão selecionada")
                -- Completar a missão configurada
                TriggerServerEvent('quest_diarias:completeQuest', Config.mission)
                CloseStore()
            end
        end,
        function(_, menu)
            CloseStore()
        end)
end
