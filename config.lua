Config              = {}

-- DEBUG
Config.DevMode      = true
Config.Version      = "2.1.0"
Config.MoreOne     = false -- true = permite repetir ilimitado no dia; false = uma por dia

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
    },
    {
        name = "Karine",
        model = "msp_saloon1_females_01",
        position = { x = -1523.831, y = 2518.854, z = 395.698, h = 18.69 },
    },
    {
        name = "Leonor",
        model = "msp_saintdenis1_females_01",
        position = { x = -352.380, y = 812.168, z = 116.487, h = 182.34 },
    },
    {
        name = "Jaciaria",
        model = "msp_industry3_females_01",
        position = { x = -344.097, y = 806.359, z = 116.885, h = 140.088 },
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
