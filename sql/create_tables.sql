-- Script SQL para Sistema de Missões Diárias
-- Desenvolvido por FTx3g

-- Criar tabela para controle de missões diárias
CREATE TABLE IF NOT EXISTS `daily_quests` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `identifier` varchar(50) NOT NULL,
    `quest_id` int(11) NOT NULL,
    `completed_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_identifier_quest` (`identifier`, `quest_id`),
    KEY `idx_completed_at` (`completed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Criar evento para limpeza automática de registros antigos (30 dias)
DELIMITER $$

CREATE EVENT IF NOT EXISTS `cleanup_daily_quests`
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    DELETE FROM `daily_quests` 
    WHERE `completed_at` < DATE_SUB(NOW(), INTERVAL 30 DAY);
END$$

DELIMITER ;

-- Ativar o scheduler de eventos (caso não esteja ativo)
SET GLOBAL event_scheduler = ON;

-- Inserir alguns dados de exemplo (opcional - remover em produção)
-- INSERT INTO `daily_quests` (`identifier`, `quest_id`, `completed_at`) VALUES
-- ('steam:110000000000000', 1, '2024-01-01 10:00:00');

-- Verificar se a tabela foi criada corretamente
SELECT 'Tabela daily_quests criada com sucesso!' as status;