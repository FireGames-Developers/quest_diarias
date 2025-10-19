Config              = {}

-- DEBUG
Config.DevMode      = true
Config.Version      = "2.1.0"
Config.MoreOne     = true -- true = permite repetir ilimitado no dia; false = uma por dia

-- AUTO UPDATE SYSTEM
Config.AutoUpdate = {
    Enabled = true,                                                    -- Ativar sistema de auto-update
    Repository = "FireGames-Developers/quest_diarias", -- Repositório GitHub (formato owner/repo)
    Branch = "main",                                                   -- Branch para verificar updates
    CheckInterval = 0,                                                -- 0 = checar apenas uma vez no start/restart
    AutoDownload = false,                                             -- Download automático (recomendado: false)
    BackupBeforeUpdate = true,                                        -- Criar backup antes de atualizar
    NotifyAdmins = true                                               -- Notificar admins sobre updates
}


-- Color BLIP
--0	Branco (default)	Padrão
--1	Vermelho	Hostil / Alvo
--2	Azul claro	Amigável
--3	Verde	Loja / Local útil
--4	Amarelo	Missão
--5	Roxo	Especial / Evento
--6	Laranja	Dinâmico / alerta
--7	Cinza	Desativado
--8	Azul escuro	Missão alternativa
--9	Ciano	Secundário

-- Blip
Config.blipAllowed  = true
Config.Name         = "Missões diárias"
Config.blipModel    = 1664425300 -- native blip creator param
Config.blipsprite   = -352964861 -- blip_mp_location_k
Config.blipColor    = 1

-- NPCs (nome, modelo e posição)
Config.NPCs = {
    {
        name = "Eloah",
        model = "rcsp_odriscolls2_females_01",
        position = { x = -360.810, y = 807.450, z = 116.167, h = 219.017 },
        -- voiceName = "0140_U_F_O_BlWHouseWife_01" -- opcional: defina a voz do NPC
    },
    {
        name = "Leonor",
        model = "msp_saintdenis1_females_01",
        position = { x = -352.380, y = 812.168, z = 116.487, h = 182.34 },
        -- voiceName = "0140_U_F_O_BlWHouseWife_01"
    },
    {
        name = "Karine",
        model = "msp_industry3_females_01",
        position = { x = -344.097, y = 806.359, z = 116.885, h = 140.088 },
        -- voiceName = "0140_U_F_O_BlWHouseWife_01"
    }    
}

-- Prompt / UI
Config.Key          = 0xCEFD9220 -- tecla E
Config.distOpen     = 2.0

Config.mission = 1 -- 1 = Missão 1, 2 = Missão 2

-- Menu base (elementos montados dinamicamente com nome do NPC atual)
Config.elementsMenu = {
    {
        label = "Ajudar NPC",
        value = 'getQuest',
        desc = "Ajudar NPC"
    },
    {
        label = "Entregar Itens",
        value = 'deliveryQuest',
        desc = "Entregar Itens"
    }
}

Config.text         = {
    welcome = "Bem vindo",
    openmenu = "Falar com NPC",
    store = "Missões diárias"
}

-- Animações de NPC (controle geral)
-- Preencha com dict/name válidos para animar o NPC atual em eventos.
-- Caso estejam vazios, o cliente usará um fallback leve ou não animará.
Config.NPCAnimations = {
    -- Ao aceitar/iniciar a missão
    start = { dict = "script_campfire@lighting_fire@male_male", name = "light_fire_b_p2_male_b", flag = 17, duration = 2500 },
    -- Ao tentar entregar e ainda não tiver concluído ou for NPC/objeto inválido
    notReady = { dict = "amb_misc@world_human_wash_kneel_river@female_a@idle_a", name = "idle_c", flag = 17, duration = 2000 },
    -- Ao concluir a missão (comemoração)
    complete = { dict = "mech_inventory@crafting@fallbacks", name = "full_craft_and_stow", flag = 27, duration = 3000 }
}

-- Falas de NPC (áudio nativo)
-- Ajuste os nomes de fala e a voz padrão conforme preferir.
-- É possível definir voiceName por NPC acima em Config.NPCs.
Config.NPCSpeech = {
    -- Ao abrir o menu de conversa com o NPC
    openMenu = { speech = "GENERIC_HI",          param = "SPEECH_PARAMS_FORCE_NORMAL" },
    -- Ao aceitar/iniciar a missão
    start    = { speech = "GREET_PLAYER",        param = "SPEECH_PARAMS_FORCE_NORMAL" },
    -- Ao tentar entregar sem estar pronto/errado
    notReady = { speech = "FAREWELL_NO_SALE",    param = "SPEECH_PARAMS_FORCE_NORMAL" },
    -- Ao concluir a missão
    complete = { speech = "GENERIC_THANKS",      param = "SPEECH_PARAMS_FORCE_NORMAL" },
    -- Ao fechar o menu do NPC
    closeMenu = { speech = "GENERIC_BYE",        param = "SPEECH_PARAMS_FORCE_NORMAL" }
}

-- Voz padrão usada se o NPC não tiver voiceName definido (ajuste conforme seu gosto)
Config.NPCSpeechDefaultVoice = "0140_U_F_O_BlWHouseWife_01"
