-- ============================================================================
-- MÓDULO: Menu e Prompt
-- Configura o prompt de interação perto do NPC e abre o menu
-- usando `vorp_menu`. Oferece opções para iniciar missão ou
-- entregar itens da missão atual.
-- Dependências: `Config`, `DebugPrint`, `DebugError`, `vorp_menu`.
-- ============================================================================
inmenu = false
prompts = GetRandomIntInRange(0, 0xffffff)
MenuData = exports.vorp_menu:GetMenuData()
openmenu = nil

---------------- PROMPT ---------------------
function PromptSetUp()
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
function CloseStore()
    MenuData.CloseAll()
    ClearPedTasks(PlayerPedId())
    DisplayRadar(true)
    inmenu = false
end

function OpenStore()

    MenuData.CloseAll()
    local npcName = (Config.CurrentNPC and Config.CurrentNPC.name) or "NPC"
    local deliverLabel, deliverDesc
    if Config.mission == 1 then
        deliverLabel = "Entregar Faisão"
        deliverDesc  = "Entregar faisão nas mãos"
    else
        deliverLabel = "Entregar Itens"
        deliverDesc  = "Entregar Itens"
    end

    local elements = {
        { label = "Ajudar " .. npcName, value = 'getQuest', desc = "Ajudar " .. npcName },
        { label = deliverLabel,          value = 'deliveryQuest', desc = deliverDesc }
    }
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
                DebugPrint(("Opção Ajudar %s selecionada"):format(npcName))
                -- Solicitar verificação de elegibilidade diária antes de iniciar
                TriggerServerEvent('quest_diarias:canDoQuest', Config.mission)
                CloseStore()
            elseif data.current.value == 'deliveryQuest' then
                DebugPrint("Opção Entregar selecionada")
                -- Aciona evento específico da missão atual (dinâmico por ID)
                local evt = ('quest_diarias:quest%d:attemptDelivery'):format(Config.mission)
                TriggerEvent(evt)
                CloseStore()
            end
        end,
        function(_, menu)
            CloseStore()
        end)
end
