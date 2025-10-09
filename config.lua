Config              = {}

-- DEBUG
Config.DevMode      = true
Config.Version      = "2.1.0"

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

-- NPC
Config.NpcModel     = "rcsp_odriscolls2_females_01"
Config.NpcPosition  = { x = -1523.831, y = 2518.854, z = 395.698, h = 18.69 }
Config.NpcName      = "Karine"

-- Prompt / UI
Config.Key          = 0xCEFD9220 -- tecla E
Config.distOpen     = 2.0

Config.mission = 1 -- 1 = Missão 1, 2 = Missão 2

Config.elementsMenu = {
    {
        label = "Ajudar " .. (Config.NpcName or "NPC"),
        value = 'getQuest',
        desc = "Ajudar " .. (Config.NpcName or "NPC")
    },
    {
        label = "Entregar Itens",
        value = 'deliveryQuest',
        desc = "Entregar Itens"
    }
}

Config.text         = {
    welcome = "Bem vindo",
    openmenu = "Falar com " .. (Config.NpcName or "NPC"),
    store = "Missões diárias"
}
