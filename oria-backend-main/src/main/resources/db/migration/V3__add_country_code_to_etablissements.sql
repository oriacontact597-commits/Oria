-- V3 : Filtrage par pays des établissements (P1.1 ORIA)
-- Ajoute la colonne country_code à fiches_etablissement et backfill
-- les 363 fiches existantes comme Togolaises (projet hackaton = 100% TG).

ALTER TABLE fiches_etablissement
    ADD COLUMN country_code VARCHAR(2) NOT NULL DEFAULT 'TG';

-- Backfill explicite (le DEFAULT ne peuple pas rétroactivement les lignes existantes en PG).
UPDATE fiches_etablissement
SET country_code = 'TG'
WHERE country_code IS NULL OR country_code = '';

-- Index pour accélérer le filtre /pays/{code} (utilisé par l'app mobile).
CREATE INDEX IF NOT EXISTS idx_fe_country_publie
    ON fiches_etablissement (country_code, est_publie);
