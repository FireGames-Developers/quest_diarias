# Sistema de Missões Diárias - Quest Diarias

**Desenvolvido por:** FTx3g  
**Versão:** 2.0.0

## Descrição

Sistema completo de missões diárias para RedM/VORP Core que permite aos jogadores realizar missões uma vez por dia com recompensas configuráveis. O sistema foi completamente reestruturado para melhor organização e manutenibilidade.

## Características

- ✅ Sistema de missões dinâmico e modular
- ✅ Controle diário de missões (uma vez por dia)
- ✅ Recompensas configuráveis (dinheiro, XP, itens)
- ✅ Sistema de blips automático
- ✅ Interface de menu integrada com VORP Menu
- ✅ Sistema de debug integrado
- ✅ Limpeza automática do banco de dados (30 dias)
- ✅ Estrutura modular para fácil manutenção

## Dependências

- **vorp_core** - Sistema principal do VORP
- **vorp_menu** - Sistema de menus
- **oxmysql** - Sistema de banco de dados

## Instalação

1. **Baixe e extraia** o recurso na pasta `resources/[standalone]/`
2. **Adicione** `ensure quest_diarias` no seu `server.cfg`
3. **Reinicie** o servidor

> **Nota:** Não é mais necessário executar scripts SQL manualmente! O sistema cria automaticamente as tabelas necessárias na primeira inicialização.

## Estrutura de Arquivos

```
quest_diarias/
├── client/
│   ├── npc.lua              # Gerenciamento de NPCs
│   └── quest_client.lua     # Sistema de quests do cliente
├── server/
│   ├── init.lua             # Inicialização automática do sistema
│   ├── database.lua         # Gerenciador de banco de dados
│   ├── npc.lua              # Lógica do servidor para NPCs
│   └── quest_handler.lua    # Gerenciador de quests do servidor
├── modules/
│   ├── blips.lua            # Sistema de blips/marcadores
│   ├── debug.lua            # Sistema de debug
│   ├── menu.lua             # Interface de menu
│   ├── npc.lua              # Spawn e controle de NPCs
│   └── quest_manager.lua    # Gerenciador principal de quests
├── quests/
│   └── quest1.lua           # Missão 1 - Caça ao Faisão
├── sql/
│   └── create_tables.sql    # Script de criação das tabelas
├── config.lua               # Configurações principais
├── fxmanifest.lua          # Manifest do recurso
└── README.md               # Este arquivo
```

## Configuração

### Configuração Principal (config.lua)

```lua
Config.mission = 1  -- Define qual missão está ativa (1, 2, 3, etc.)
```

### Configuração de Missões

Cada missão é um arquivo separado na pasta `quests/`. Exemplo de estrutura:

```lua
-- quests/quest1.lua
local Quest = {}

Quest.Config = {
    id = 1,
    name = "Caça ao Faisão",
    description = "Cace um faisão e traga sua carcaça",
    requiredItem = "carcass_pheasant_perfect",
    rewards = {
        money = 25.0,
        xp = 100,
        items = {
            { name = "consumable_herb_ginseng", amount = 2 }
        }
    },
    -- ... outras configurações
}

-- Funções da missão
function Quest.StartQuest(source) end
function Quest.CompleteQuest(source) end
function Quest.CanDoQuest(source, callback) end

return Quest
```

## Como Adicionar Novas Missões

1. **Crie um novo arquivo** na pasta `quests/` seguindo o padrão `questX.lua` (onde X é o número da missão)

2. **Copie a estrutura** do `quest1.lua` como base

3. **Configure os parâmetros** da missão:
   - `id`: Número único da missão
   - `name`: Nome da missão
   - `description`: Descrição da missão
   - `requiredItem`: Item necessário para completar
   - `rewards`: Recompensas (dinheiro, XP, itens)
   - `huntingArea`: Área de caça (se aplicável)
   - `texts`: Textos da missão

4. **Implemente as funções**:
   - `StartQuest(source)`: Lógica para iniciar a missão
   - `CompleteQuest(source)`: Lógica para completar a missão
   - `CanDoQuest(source, callback)`: Verificação se pode fazer a missão

5. **Atualize o config.lua** para definir `Config.mission = X` (número da sua nova missão)

### Exemplo de Nova Missão

```lua
-- quests/quest2.lua
local Quest = {}

Quest.Config = {
    id = 2,
    name = "Coleta de Ervas",
    description = "Colete 5 ervas medicinais",
    requiredItem = "herb_ginseng",
    requiredAmount = 5,
    rewards = {
        money = 15.0,
        xp = 75,
        items = {
            { name = "consumable_medicine", amount = 1 }
        }
    },
    texts = {
        started = "Colete 5 ervas medicinais",
        completed = "Ervas entregues com sucesso!",
        alreadyCompleted = "Você já completou esta missão hoje",
        noItems = "Você não tem as ervas necessárias"
    }
}

function Quest.StartQuest(source)
    TriggerClientEvent('vorp:TipBottom', source, Quest.Config.texts.started, 5000)
end

function Quest.CompleteQuest(source)
    -- Implementar lógica de verificação e recompensa
end

function Quest.CanDoQuest(source, callback)
    -- Implementar verificação diária
end

return Quest
```

## Sistema de Banco de Dados

O sistema utiliza uma tabela `daily_quests` para controlar as missões completadas:

```sql
CREATE TABLE IF NOT EXISTS `daily_quests` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `identifier` varchar(50) NOT NULL,
    `quest_id` int(11) NOT NULL,
    `completed_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_identifier_quest` (`identifier`, `quest_id`),
    KEY `idx_completed_at` (`completed_at`)
);
```

### Limpeza Automática

O sistema inclui um evento automático que limpa registros antigos a cada 24 horas:

```sql
CREATE EVENT IF NOT EXISTS `cleanup_daily_quests`
ON SCHEDULE EVERY 1 DAY
DO DELETE FROM `daily_quests` WHERE `completed_at` < DATE_SUB(NOW(), INTERVAL 30 DAY);
```

## Comandos Administrativos

O sistema inclui comandos úteis para administradores:

- `/questdb_status` - Exibe estatísticas do banco de dados (total de registros, jogadores únicos, etc.)
- `/questdb_cleanup` - Executa limpeza manual de registros antigos

> **Nota:** Estes comandos só funcionam para usuários com grupo 'admin'

## Sistema de Inicialização Automática

O sistema possui inicialização automática que:

- ✅ Verifica se as tabelas existem na inicialização
- ✅ Cria automaticamente as tabelas se não existirem  
- ✅ Configura eventos de limpeza automática
- ✅ Executa verificações de saúde do sistema
- ✅ Exibe logs detalhados quando `Config.DevMode = true`

## Comandos de Debug

Quando `Config.DevMode = true`, o sistema exibe informações detalhadas no console para facilitar o debug.

## Suporte

Para suporte ou dúvidas sobre o sistema, entre em contato com **FTx3g**.

## Changelog

### v2.0.0
- Reestruturação completa do sistema
- Sistema modular de missões
- Controle diário de missões
- Sistema de recompensas aprimorado
- Limpeza automática do banco de dados
- Melhor organização de arquivos

### v1.0.0
- Versão inicial do sistema
