-- V5 : Historique append-only des configurations de scoring (P2.1 ORIA — MlRegistry)
-- Permet l'audit, le rollback et l'A/B testing futur des pondérations de l'orchestrateur.
-- Pas de FK vers evolution_scoring_config : l'historique survit aux suppressions de la table principale.

CREATE TABLE IF NOT EXISTS evolution_scoring_config_history (
    id                  BIGSERIAL       PRIMARY KEY,
    tracking_id         UUID            NOT NULL UNIQUE,
    country_code        VARCHAR(2)      NOT NULL,
    config_name         VARCHAR(50)     NOT NULL,
    weights             JSONB           NOT NULL,
    action              VARCHAR(20)     NOT NULL,  -- 'PROMOTE' | 'ROLLBACK'
    rolled_back_from    UUID,                       -- tracking_id de l'historique source (rollback uniquement)
    comment             TEXT,                       -- optionnel, ex: "Régression après push 2026-08-25"
    changed_by          VARCHAR(255)    NOT NULL,   -- email de l'admin
    changed_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_current          BOOLEAN         NOT NULL DEFAULT FALSE  -- pointe vers la config active courante
);

-- Index pour lister l'historique par (pays, name) ordonné par date desc
CREATE INDEX IF NOT EXISTS idx_scch_country_name_time
    ON evolution_scoring_config_history (country_code, config_name, changed_at DESC);

-- Index partiel : un seul is_current=true par (pays, name)
CREATE INDEX IF NOT EXISTS idx_scch_current
    ON evolution_scoring_config_history (country_code, config_name) WHERE is_current = TRUE;
