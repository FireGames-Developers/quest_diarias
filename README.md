# Quest Diárias - Sistema de Missões Diárias para VORP

Sistema modular e extensível de missões diárias para servidores RedM usando VORP Core, com sistema de auto-atualização via GitHub.

## 🚀 Características

- ✅ Sistema modular e extensível
- ✅ Controle diário automático de missões
- ✅ Interface integrada com VORP Menu
- ✅ Sistema de recompensas configurável
- ✅ Blips automáticos no mapa
- ✅ Banco de dados com limpeza automática
- ✅ Sistema de debug para desenvolvimento
- ✅ **Auto-atualização via GitHub**
- ✅ **Backup automático antes de atualizações**
- ✅ **Comandos administrativos para controle**
- ✅ **Sistema de inicialização inteligente com VORP Core**

## 📋 Dependências

### Dependências Obrigatórias
- `vorp_core` - Framework principal (**CRÍTICO**)
- `vorp_menu` - Sistema de menus
- `oxmysql` - Conexão com banco de dados

### ⚠️ Importante - Dependência do VORP Core

Este recurso utiliza um **sistema de inicialização inteligente** que aguarda o VORP Core estar totalmente carregado antes de inicializar seus módulos. 

**Como funciona:**
- O sistema monitora o evento `vorp:SelectedCharacter` para detectar quando o VORP está pronto
- Implementa múltiplas tentativas de inicialização com fallback automático
- Utiliza `LoadResourceFile` em vez de `require()` para evitar problemas de dependência circular
- Garante compatibilidade mesmo com ordens de carregamento diferentes

**Configuração no server.cfg:**
```cfg
# Certifique-se de que o VORP Core seja carregado ANTES
ensure vorp_core
ensure vorp_menu
ensure oxmysql

# Quest Diárias pode ser carregado em qualquer ordem após as dependências
ensure quest_diarias
```

## 🔧 Instalação

1. Extraia o recurso para a pasta `resources/[standalone]/`
2. **IMPORTANTE**: Certifique-se de que `vorp_core`, `vorp_menu` e `oxmysql` estejam carregados antes
3. Adicione `ensure quest_diarias` ao seu `server.cfg`
4. Reinicie o servidor

> **Nota:** O sistema criará automaticamente as tabelas necessárias no banco de dados na primeira inicialização e aguardará o VORP Core estar pronto.

## 📁 Estrutura de Arquivos

```
quest_diarias/
├── client/
│   └── quest_client.lua      # Gerenciamento client-side das missões
├── server/
│   ├── init.lua             # Inicialização inteligente com VORP Core
│   ├── database.lua         # Gerenciamento automático do banco de dados
│   ├── updater.lua          # Sistema de auto-atualização via GitHub
│   └── quest_handler.lua    # Manipulação server-side das missões
├── modules/
│   ├── blips.lua           # Sistema de blips no mapa
│   ├── menu.lua            # Interface do menu
│   ├── debug.lua           # Ferramentas de debug
│   └── quest_manager.lua   # Gerenciador dinâmico de missões
├── quests/
│   └── quest1.lua          # Missão exemplo: Caça ao Faisão
├── config.lua              # Configurações principais
├── fxmanifest.lua         # Manifesto do recurso
└── README.md              # Este arquivo
```

## ⚙️ Configuração

### Config.lua Principal

```lua
Config = {}
Config.DevMode = true -- Ativar logs de debug
Config.Version = "2.1.0" -- Versão atual do sistema

-- Configurações do NPC
Config.npc = {
    model = "A_M_M_UniBoatCrew_01",
    coords = vector4(-1807.52, -374.13, 158.15, 205.71)
}

-- Configurações de Auto-Update
Config.AutoUpdate = {
    Enabled = true,                                                    -- Ativar sistema de auto-update
    Repository = "https://github.com/FireGames-Developers/quest_diarias", -- Repositório GitHub
    Branch = "main",                                                   -- Branch para verificar
    CheckInterval = 60,                                               -- Intervalo de verificação (em minutos)
    AutoDownload = false,                                             -- Download automático (recomendado: false)
    BackupBeforeUpdate = true,                                        -- Criar backup antes da atualização
    NotifyAdmins = true                                               -- Notificar admins sobre atualizações
}
```

### Configuração de Missões Individuais

Cada missão em `quests/` deve seguir este padrão:

```lua
local Quest = {}

Quest.id = 1
Quest.name = "Nome da Missão"
Quest.description = "Descrição da missão"

Quest.requirements = {
    item = "item_necessario",
    amount = 1
}

Quest.rewards = {
    money = 50,
    xp = 100,
    items = {
        {name = "item_recompensa", amount = 1}
    }
}

-- Outras configurações...

return Quest
```

## 🔄 Sistema de Auto-Atualização

O sistema inclui verificação automática de atualizações via GitHub API:

### Comandos Administrativos

- `/quest_checkupdate` - Verificar manualmente por atualizações
- `/quest_update` - Obter detalhes da atualização disponível

### Configurações de Auto-Update

- **enabled**: Ativar/desativar o sistema
- **repository**: URL do repositório GitHub
- **checkInterval**: Intervalo entre verificações (em ms)
- **autoDownload**: Download automático (desabilitado por segurança)
- **backupBeforeUpdate**: Criar backup antes de atualizar
- **notifyAdmins**: Notificar administradores sobre atualizações

### Funcionamento

1. **Verificação Automática**: O sistema verifica por atualizações no intervalo configurado
2. **Notificação**: Administradores são notificados quando há atualizações disponíveis
3. **Backup**: Sistema cria backup automático antes de qualquer atualização
4. **Segurança**: Download automático desabilitado por questões de segurança

## 📊 Banco de Dados

O sistema gerencia automaticamente duas tabelas:

```sql
-- Tabela principal de quests
CREATE TABLE IF NOT EXISTS quest_diarias (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(50) NOT NULL,
    charid INT NOT NULL,
    quest_id VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    progress JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    INDEX idx_identifier_charid (identifier, charid),
    INDEX idx_quest_id (quest_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);

-- Histórico de quests completadas
CREATE TABLE IF NOT EXISTS quest_diarias_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(50) NOT NULL,
    charid INT NOT NULL,
    quest_id VARCHAR(100) NOT NULL,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    rewards_given TEXT,
    INDEX idx_identifier_charid (identifier, charid),
    INDEX idx_quest_id (quest_id),
    INDEX idx_completed_at (completed_at)
);
```

### Limpeza Automática

- Limpeza de quests antigas via função `Database.CleanupOldQuests`
- Limpeza de histórico antiga via função `Database.CleanupOldHistory`
- Comando manual (se configurado): `/questdb_cleanup`

## 🎮 Como Usar

1. **Jogadores**: Interajam com o NPC para acessar o menu de missões
2. **Administradores**: Usem os comandos de debug e gerenciamento
3. **Desenvolvedores**: Adicionem novas missões na pasta `quests/`

## 🔧 Comandos

### Jogador/Admin
- `/quest_list` — Lista suas últimas quests e status (ativa/completada)

### Teste de Missão
- `/quest_test [distância]` — Spawna um faisão morto à sua frente (padrão 3.0m). Restrito via ACE.
  - Uso: `/quest_test` ou `/quest_test 6.0`
  - Permissão ACE: `command.quest_test`

### Auto-Update
- `/quest_checkupdate` — Verificar atualizações disponíveis
- `/quest_update` — Obter detalhes da atualização

### Reset de Missão
- `/quest_reset [questId]` — Remove a conclusão de hoje para a missão informada (ou a última missão completada hoje, se não informado) e reabre a missão para refazer.

### Observações sobre ACE
Adicione no `server.cfg` para liberar o comando de teste para um grupo/usuário específico:

```
# Exemplo: permitir para admin
add_ace group.admin command.quest_test allow
# Opcional: atribuir players ao grupo admin
add_principal identifier.steam:110000112345678 group.admin
```

## 🆕 Adicionando Novas Missões

1. Crie um novo arquivo em `quests/quest[numero].lua`
2. Siga o padrão da `quest1.lua`
3. Configure o `Config.mission` para a nova missão
4. Reinicie o recurso

Exemplo de nova missão:

```lua
local Quest = {}

Quest.id = 2
Quest.name = "Coleta de Ervas"
Quest.description = "Colete 5 ervas medicinais"

Quest.requirements = {
    item = "herb_medicine",
    amount = 5
}

Quest.rewards = {
    money = 75,
    xp = 150,
    items = {
        {name = "health_potion", amount = 2}
    }
}

-- Implementar funções necessárias...

return Quest
```

## 🐛 Debug

Ative `Config.DevMode = true` para ver logs detalhados:

- Carregamento de missões
- Verificações de itens
- Operações de banco de dados
- Verificações de atualização
- Status do sistema

## 📞 Suporte

- **Desenvolvedor**: FTx3g
- **Repositório**: https://github.com/FireGames-Developers/quest_diarias
- **Versão**: 2.1.0

## 📝 Changelog

### v2.0.0
- ✅ Reestruturação completa do código
- ✅ Sistema modular implementado
- ✅ Inicialização automática do banco de dados
- ✅ Sistema de auto-atualização via GitHub
- ✅ Comandos administrativos expandidos
- ✅ Sistema de backup automático
- ✅ Melhorias na documentação

### v1.0.0
- ✅ Versão inicial do sistema
- ✅ Missão básica de caça ao faisão
- ✅ Sistema de recompensas
- ✅ Integração com VORP
