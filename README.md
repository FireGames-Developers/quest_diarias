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

## 📋 Dependências

- `vorp_core` - Framework principal
- `vorp_menu` - Sistema de menus
- `oxmysql` - Conexão com banco de dados

## 🔧 Instalação

1. Extraia o recurso para a pasta `resources/[standalone]/`
2. Adicione `ensure quest_diarias` ao seu `server.cfg`
3. Reinicie o servidor

> **Nota:** O sistema criará automaticamente as tabelas necessárias no banco de dados na primeira inicialização.

## 📁 Estrutura de Arquivos

```
quest_diarias/
├── client/
│   └── quest_client.lua      # Gerenciamento client-side das missões
├── server/
│   ├── init.lua             # Inicialização automática do sistema
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

-- Configurações do NPC
Config.npc = {
    model = "A_M_M_UniBoatCrew_01",
    coords = vector4(-1807.52, -374.13, 158.15, 205.71)
}

-- Configurações de Auto-Update
Config.AutoUpdate = {
    enabled = true,                                                    -- Ativar sistema de auto-update
    repository = "https://github.com/FireGames-Developers/quest_diarias", -- Repositório GitHub
    branch = "main",                                                   -- Branch para verificar
    checkInterval = 3600000,                                          -- Intervalo de verificação (1 hora)
    autoDownload = false,                                             -- Download automático (recomendado: false)
    backupBeforeUpdate = true,                                        -- Criar backup antes da atualização
    notifyAdmins = true                                               -- Notificar admins sobre atualizações
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

O sistema gerencia automaticamente uma tabela `daily_quests`:

```sql
CREATE TABLE IF NOT EXISTS daily_quests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(50) NOT NULL,
    quest_id INT NOT NULL,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Limpeza Automática

- Registros são automaticamente removidos após 30 dias
- Event automático executa diariamente à meia-noite
- Comando manual: `/questdb_cleanup`

## 🎮 Como Usar

1. **Jogadores**: Interajam com o NPC para acessar o menu de missões
2. **Administradores**: Usem os comandos de debug e gerenciamento
3. **Desenvolvedores**: Adicionem novas missões na pasta `quests/`

## 🔧 Comandos Administrativos

### Banco de Dados
- `/questdb_status` - Verificar estatísticas do banco de dados
- `/questdb_cleanup` - Executar limpeza manual dos registros

### Auto-Update
- `/quest_checkupdate` - Verificar atualizações disponíveis
- `/quest_update` - Obter detalhes da atualização

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
- **Versão**: 2.0.0

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
