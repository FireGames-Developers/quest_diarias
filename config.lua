Config              = {}

-- DEBUG
Config.DevMode      = true


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
Config.Name         = "Mercado negro"
Config.blipModel    = 1664425300 -- native blip creator param
Config.blipsprite   = -2128054417 -- sprite (teste), mude se quiser
Config.blipColor    = 1

-- NPC
Config.NpcModel     = "mp_a_f_m_saloonband_females_01"
Config.NpcPosition  = { x = -1523.831, y = 2518.854, z = 395.698, h = 18.69 }

-- Prompt / UI
Config.Key          = 0xCEFD9220 -- tecla E
Config.distOpen     = 2.0

Config.mission = 1 -- 1 = Missão 1, 2 = Missão 2

Config.elementsMenu = {
    {
        label = "Pegar missão",
        value = 'getQuest',
        desc = "Pegar missão"
    },
    {
        label = "Entregar missão",
        value = 'deliveryQuest',
        desc = "Entregar missão"
    }
}

Config.text         = {
    welcome = "Bem vindo",
    openmenu = "Falar com a Karine",
    store = "Missões diárias"
}
