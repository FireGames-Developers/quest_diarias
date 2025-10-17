# Quest Diárias (RedM / VORP) — Estado Atual

Sistema modular de missões diárias com duas formas de entrega (item nas mãos ou via inventário), elegibilidade diária centralizada no servidor, validação de NPC, textos configuráveis e template pronto para criar novas quests.

## Principais Recursos
- Missões modulares em `quests/questN.lua` carregadas via `LoadResourceFile` (seguro)
- Duas entregas suportadas: carregando nas mãos (modelos) e inventário (item)
- Elegibilidade diária centralizada (`quest_diarias:canDoQuest`)
- Validação de NPC: entrega deve ocorrer no mesmo NPC usado para iniciar
- Menu dinâmico com `vorp_menu` e prompt “Falar com [NPC]” (imersão)
- Blips opcionais e textos 100% configuráveis
- Template genérico `quests/quest_modelo.lua` para criar novas quests
- Comandos para visualizar, listar, resetar e testar quests

## Dependências
- `vorp_core` (obrigatório)
- `vorp_menu` (menu do NPC)
- `vorp_inventory` (itens, armas, moedas)
- `oxmysql` (banco de dados)

### server.cfg (ordem sugerida)
```
ensure vorp_core
ensure vorp_menu
ensure vorp_inventory
ensure oxmysql
ensure quest_diarias
```

## Estrutura do Recurso
```
quest_diarias/
├── client/
│   ├── delivery.lua           # Fluxo genérico de entrega (mãos/inventário)
│   └── quest_client.lua       # Eventos de início/conclusão e blips
├── server/
│   ├── commands.lua           # /quest, /quest_list, /quest_reset, /quest_test
│   ├── database.lua           # Acesso e manutenção do banco
│   ├── quest_handler.lua      # Regras centrais de start/complete/entrega
│   ├── module_loader.lua      # Loader seguro de módulos
│   └── updater.lua            # Comandos de atualização (opcional)
├── modules/
│   ├── menu.lua               # Menu e prompt “Falar com [NPC]”
│   ├── npc.lua                # Spawn e estado do NPC atual
│   ├── blips.lua              # Utilidades de blip
│   └── quest_manager.lua      # Carrega quests e expõe metadados
├── quests/
│   ├── quest1.lua             # Caça ao Faisão (entrega nas mãos)
│   ├── quest2.lua             # Doces para Karine (inventário)
│   └── quest_modelo.lua       # Template para novas quests
├── config.lua                 # Configuração geral (NPCs, teclas, textos, missão ativa)
└── fxmanifest.lua
```

## Fluxo da Missão
- Aproximar do NPC: prompt dinâmico `Config.text.openmenu` → “Falar com [NPC]”
- Abrir menu:
  - “Ajudar [NPC]” → servidor valida com `quest_diarias:canDoQuest` e inicia com `quest_diarias:startQuest`
  - “Entregar Itens” (ou “Entregar Faisão” quando `Config.mission == 1`) → aciona `quest_diarias:quest<ID>:attemptDelivery`
- Entrega nas mãos: cliente valida modelos aceitos, remove entidade e chama `quest_diarias:completeQuest`
- Entrega via inventário: servidor valida item, subtrai e confirma com `quest_diarias:inventoryDeliverySuccess`; cliente chama `quest_diarias:completeQuest`
- Conclusão: servidor aplica recompensas e registra histórico; cliente mostra feedback e remove blips

## Configuração (config.lua)
- `Config.DevMode` — ativa logs de desenvolvimento
- `Config.MoreOne` — `false` = 1 missão/dia; `true` = várias por dia
- `Config.NPCs` — nome, modelo e posição dos NPCs
- `Config.Key` / `Config.distOpen` — tecla e distância para abrir o menu
- `Config.mission` — ID da missão ativa (o menu usa isso)
- `Config.text` — `welcome`, `openmenu` (“Falar com NPC”), `store`
- Blips: `Config.blipAllowed`, `Config.blipsprite`, `Config.blipColor`, etc.

## Criação de Quests com o Template
Use `quests/quest_modelo.lua` para começar rápido:
1. Copie para `quests/questN.lua` e ajuste `Quest.Config.id`, `name`, `description`, `rewards`.
2. Escolha o tipo de entrega:
   - Mãos: `delivery.acceptedModels = { 'MODEL_A', 'MODEL_B' }`
   - Inventário: `delivery.requiredItem = 'apple'`
3. Ajuste `texts`: `start`, `progress`, `deliverHint`, `complete`, `alreadyCompleted`, `notDelivered`, `error`.
4. Opcional: `markers` para criar blips ao iniciar (`StartQuest`).
5. O template registra o evento `quest_diarias:quest<ID>:attemptDelivery` no cliente e delega ao fluxo genérico.

### Contratos usados pelo sistema
- Cliente:
  - `quest_diarias:quest<ID>:attemptDelivery` → dispara fluxo genérico
  - `quest_diarias:questStarted`, `quest_diarias:questCompleted`, `quest_diarias:inventoryDeliverySuccess`
- Callbacks:
  - `quest_diarias:getQuestInfo` → metadados para mensagens
  - `quest_diarias:getDeliveryConfig` → decide mãos vs inventário
- Servidor:
  - `quest_diarias:canDoQuest`, `quest_diarias:startQuest`, `quest_diarias:completeQuest`
  - `quest_diarias:attemptDeliveryInventory` (quando `requiredItem`)

## Comandos
- `/quest` — mostra resumo da missão ativa
- `/quest_list` — lista últimas quests do personagem
- `/quest_reset [id]` — reseta a conclusão de hoje da missão informada (ou a última concluída hoje)
- `/quest_test [dist] [questId]` — teste rápido; spawna faisão (missão 1) ou dá item (missão 2). Requer ACE `command.quest_test`.
- (opcional) `/quest_checkupdate` e `/quest_update` — comandos do updater

### Permissões ACE (exemplo)
```
add_ace group.admin command.quest_test allow
add_principal identifier.steam:110000112345678 group.admin
```

## Banco de Dados (atualizado)
O sistema utiliza Unix epoch (segundos) em timestamps para compatibilidade com `FROM_UNIXTIME(...)` usado nas consultas.

### Tabelas
```sql
CREATE TABLE IF NOT EXISTS quest_diarias (
  id INT AUTO_INCREMENT PRIMARY KEY,
  identifier VARCHAR(50) NOT NULL,
  charid INT NOT NULL,
  quest_id INT NOT NULL,
  status VARCHAR(20) DEFAULT 'active',
  progress JSON NULL,
  created_at INT UNSIGNED,
  updated_at INT UNSIGNED NULL,
  completed_at INT UNSIGNED NULL,
  npc_index INT NULL,
  npc_name VARCHAR(64) NULL,
  INDEX idx_identifier_charid (identifier, charid),
  INDEX idx_quest_id (quest_id),
  INDEX idx_status (status),
  INDEX idx_created_at (created_at)
);

CREATE TABLE IF NOT EXISTS quest_diarias_history (
  id INT AUTO_INCREMENT PRIMARY KEY,
  identifier VARCHAR(50) NOT NULL,
  charid INT NOT NULL,
  quest_id INT NOT NULL,
  completed_at INT UNSIGNED,
  rewards_given TEXT,
  npc_index INT NULL,
  npc_name VARCHAR(64) NULL,
  INDEX idx_identifier_charid (identifier, charid),
  INDEX idx_quest_id (quest_id),
  INDEX idx_completed_at (completed_at)
);
```

### Migração (se já existir com TIMESTAMP)
```sql
ALTER TABLE quest_diarias 
  MODIFY created_at INT UNSIGNED,
  MODIFY updated_at INT UNSIGNED NULL,
  MODIFY completed_at INT UNSIGNED NULL,
  ADD COLUMN npc_index INT NULL,
  ADD COLUMN npc_name VARCHAR(64) NULL;

ALTER TABLE quest_diarias_history 
  MODIFY completed_at INT UNSIGNED,
  ADD COLUMN npc_index INT NULL,
  ADD COLUMN npc_name VARCHAR(64) NULL;
```

## Notas e Validações
- Entregue sempre no mesmo NPC da missão; o servidor valida e registra `npc_index`/`npc_name`.
- Missão 1: o menu exibe “Entregar Faisão” e aceita todos modelos configurados (`acceptedModels`).
- Missão 2: entrega via inventário (`requiredItem`), sem manipulação de entidade no cliente.
- Textos são lidos de `Quest.Config.texts` para mensagens coerentes.
- `Config.MoreOne = false` limita a 1 missão por dia (controle via histórico).

## Dicas de Desenvolvimento
- Ative `Config.DevMode` para logs úteis (carregamento de quests, hashes de modelos não aceitos, etc.).
- Use `/quest_test` para validar rapidamente o fluxo da missão ativa.

## Suporte
- Repositório: https://github.com/FireGames-Developers/quest_diarias
- Versão: 2.1.0

## Histórico (resumo)
- v2.1.0: textos claros de entrega, rótulo “Entregar Faisão” no menu para Missão 1, validação de proximidade/NPC, template `quest_modelo.lua`, fluxo genérico de inventário.
- v2.0.0: reestruturação, loader seguro, auto-update, comandos consolidados.
- v1.0.0: versão inicial e missão básica.
