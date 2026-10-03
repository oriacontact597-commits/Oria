-- V2 : Référentiel multi-pays
-- Tables pour supporter l'orientation scolaire dans plusieurs pays (TG, BJ, CI, etc.)
-- Indépendant de l'ORM JPA : on crée le schéma, l'app adaptera ensuite.

-- 1. referentiel_country — pays supportés
CREATE TABLE IF NOT EXISTS referentiel_country (
    id              BIGSERIAL       PRIMARY KEY,
    tracking_id     UUID            NOT NULL UNIQUE,
    code            VARCHAR(2)      NOT NULL UNIQUE,  -- ISO 3166-1 alpha-2 (TG, BJ, CI, SN, BF)
    name_fr         VARCHAR(100)    NOT NULL,
    name_en         VARCHAR(100),
    name_local      VARCHAR(100),                    -- ex. "Togo" en Ewe
    currency        VARCHAR(3),                      -- XOF, EUR...
    language_primary VARCHAR(5),                     -- fr, en, pt
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP,
    updated_at      TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_rc_active ON referentiel_country (is_active);

-- 2. referentiel_education_system — système éducatif du pays
CREATE TABLE IF NOT EXISTS referentiel_education_system (
    id              BIGSERIAL       PRIMARY KEY,
    tracking_id     UUID            NOT NULL UNIQUE,
    country_code    VARCHAR(2)      NOT NULL REFERENCES referentiel_country(code),
    level           VARCHAR(30)     NOT NULL,         -- PRIMAIRE, COLLEGE, LYCEE, SUPERIEUR
    series          JSONB,                            -- ["A", "C", "D", "E", "F", "G"]
    diploma         VARCHAR(50),                      -- BAC, BEPC, CAP
    duration_years  INTEGER,
    description     TEXT,
    created_at      TIMESTAMP,
    updated_at      TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_res_country_level ON referentiel_education_system (country_code, level);

-- 3. referentiel_series — séries du secondaire (détails)
CREATE TABLE IF NOT EXISTS referentiel_series (
    id              BIGSERIAL       PRIMARY KEY,
    tracking_id     UUID            NOT NULL UNIQUE,
    country_code    VARCHAR(2)      NOT NULL,
    code            VARCHAR(10)     NOT NULL,         -- "A", "C", "D", "S", "L"
    name            VARCHAR(100)    NOT NULL,
    description     TEXT,
    required_subjects JSONB,                         -- ["Mathématiques", "Physique"]
    career_paths    JSONB,                           -- ["Ingénieur", "Médecin"]
    created_at      TIMESTAMP,
    updated_at      TIMESTAMP,
    UNIQUE(country_code, code)
);
CREATE INDEX IF NOT EXISTS idx_rs_country ON referentiel_series (country_code);

-- 4. referentiel_admission_rule — règles d'admission université (par série + université)
CREATE TABLE IF NOT EXISTS referentiel_admission_rule (
    id              BIGSERIAL       PRIMARY KEY,
    tracking_id     UUID            NOT NULL UNIQUE,
    country_code    VARCHAR(2)      NOT NULL,
    series_code     VARCHAR(10)     NOT NULL,
    university_id   UUID,                            -- référence vers bibliotheque.fiches
    min_grade       DECIMAL(4,2),                    -- note minimale /20
    required_average DECIMAL(4,2),
    notes           TEXT,
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP,
    updated_at      TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_aru_country_series ON referentiel_admission_rule (country_code, series_code, is_active);

-- 5. Données seed : Togo (TG)
INSERT INTO referentiel_country (tracking_id, code, name_fr, name_en, name_local, currency, language_primary, is_active)
VALUES (gen_random_uuid(), 'TG', 'Togo', 'Togo', 'Togo', 'XOF', 'fr', TRUE)
ON CONFLICT (code) DO NOTHING;

INSERT INTO referentiel_country (tracking_id, code, name_fr, name_en, name_local, currency, language_primary, is_active)
VALUES (gen_random_uuid(), 'BJ', 'Bénin', 'Benin', 'Bénin', 'XOF', 'fr', TRUE)
ON CONFLICT (code) DO NOTHING;

INSERT INTO referentiel_country (tracking_id, code, name_fr, name_en, name_local, currency, language_primary, is_active)
VALUES (gen_random_uuid(), 'CI', 'Côte d''Ivoire', 'Ivory Coast', 'Côte d''Ivoire', 'XOF', 'fr', TRUE)
ON CONFLICT (code) DO NOTHING;

INSERT INTO referentiel_education_system (tracking_id, country_code, level, series, diploma, duration_years, description)
VALUES
  (gen_random_uuid(), 'TG', 'LYCEE', '["A","C","D","E","F","G"]', 'BAC', 3, 'Lycée togolais : 3 ans en Seconde, Première, Terminale'),
  (gen_random_uuid(), 'TG', 'COLLEGE', '["6e","5e","4e","3e"]', 'BEPC', 4, 'Collège togolais'),
  (gen_random_uuid(), 'BJ', 'LYCEE', '["A","C","D","E","F","G"]', 'BAC', 3, 'Lycée béninois'),
  (gen_random_uuid(), 'CI', 'LYCEE', '["A","C","D","E","F","G"]', 'BAC', 3, 'Lycée ivoirien')
ON CONFLICT DO NOTHING;

INSERT INTO referentiel_series (tracking_id, country_code, code, name, description, required_subjects, career_paths)
VALUES
  (gen_random_uuid(), 'TG', 'C', 'Sciences Mathématiques', 'Sciences dures', '["Mathématiques","Physique-Chimie"]', '["Ingénieur","Médecin"]'),
  (gen_random_uuid(), 'TG', 'D', 'Sciences de la Nature', 'Sciences de la vie', '["SVT","Mathématiques"]', '["Médecine","Pharmacie"]'),
  (gen_random_uuid(), 'TG', 'A', 'Lettres-Langues', 'Langues et littérature', '["Français","Anglais"]', '["Lettres","Communication"]'),
  (gen_random_uuid(), 'TG', 'G', 'Sciences Économiques', 'Économie et gestion', '["Mathématiques","Économie"]', '["Commerce","Gestion"]')
ON CONFLICT DO NOTHING;
