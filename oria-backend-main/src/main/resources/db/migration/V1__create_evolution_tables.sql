-- V1: Création des 4 tables du module evolution/
-- Ce module a été introduit pendant le hackaton AI4GOOD (Session 2026-07-25).
-- Les tables étaient créées manuellement en SQL à cause d'un bug de ddl-auto=update
-- qui ne scannait pas le package evolution/. Cette migration les officialise.

-- 1. evolution_bulletin_history — bulletins scolaires trimestriels (append-only)
CREATE TABLE IF NOT EXISTS evolution_bulletin_history (
    id              BIGSERIAL       PRIMARY KEY,
    tracking_id     UUID            NOT NULL UNIQUE,
    student_id      UUID            NOT NULL,
    trimester       INTEGER         NOT NULL CHECK (trimester BETWEEN 1 AND 3),
    academic_year   VARCHAR(9)      NOT NULL,
    subject         VARCHAR(100)    NOT NULL,
    grade           DECIMAL(4,2)    NOT NULL,
    class_average   DECIMAL(4,2),
    rank_in_class   INTEGER,
    appreciation    TEXT,
    is_official     BOOLEAN         NOT NULL DEFAULT TRUE,
    received_at     TIMESTAMP       NOT NULL DEFAULT NOW(),
    sent_by_establishment_id UUID,
    validated_by    UUID,
    created_at      TIMESTAMP,
    updated_at      TIMESTAMP,
    created_by      VARCHAR(255),
    updated_by      VARCHAR(255)
);
CREATE INDEX IF NOT EXISTS idx_bh_student        ON evolution_bulletin_history (student_id);
CREATE INDEX IF NOT EXISTS idx_bh_year_trimester  ON evolution_bulletin_history (academic_year, trimester);
CREATE INDEX IF NOT EXISTS idx_bh_subject         ON evolution_bulletin_history (subject);

-- 2. evolution_interview_history — entretiens ORIA avec l'élève
CREATE TABLE IF NOT EXISTS evolution_interview_history (
    id                  BIGSERIAL       PRIMARY KEY,
    tracking_id         UUID            NOT NULL UNIQUE,
    student_id          UUID            NOT NULL,
    interview_session_id UUID           NOT NULL,
    question_id         VARCHAR(50)     NOT NULL,
    response            JSONB           NOT NULL,
    asked_at            TIMESTAMP       NOT NULL DEFAULT NOW(),
    context             VARCHAR(50)     NOT NULL,
    created_at          TIMESTAMP,
    updated_at          TIMESTAMP,
    created_by          VARCHAR(255),
    updated_by          VARCHAR(255)
);
CREATE INDEX IF NOT EXISTS idx_ih_student  ON evolution_interview_history (student_id);
CREATE INDEX IF NOT EXISTS idx_ih_session  ON evolution_interview_history (interview_session_id);
CREATE INDEX IF NOT EXISTS idx_ih_context  ON evolution_interview_history (context);

-- 3. evolution_student_profile — cache JSONB du SEP (Student Evolution Profile)
CREATE TABLE IF NOT EXISTS evolution_student_profile (
    id              BIGSERIAL       PRIMARY KEY,
    tracking_id     UUID            NOT NULL UNIQUE,
    student_id      UUID            NOT NULL UNIQUE,
    version         INTEGER         NOT NULL DEFAULT 1,
    computed_at     TIMESTAMP       NOT NULL DEFAULT NOW(),
    payload         JSONB           NOT NULL,
    created_at      TIMESTAMP,
    updated_at      TIMESTAMP,
    created_by      VARCHAR(255),
    updated_by      VARCHAR(255)
);
CREATE INDEX IF NOT EXISTS idx_esp_student ON evolution_student_profile (student_id);

-- 4. evolution_scoring_config — pondérations modifiables par admin
CREATE TABLE IF NOT EXISTS evolution_scoring_config (
    id              BIGSERIAL       PRIMARY KEY,
    tracking_id     UUID            NOT NULL UNIQUE,
    country_code    VARCHAR(2)      NOT NULL,
    config_name     VARCHAR(50)     NOT NULL,
    weights         JSONB           NOT NULL,
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP,
    updated_at      TIMESTAMP,
    created_by      VARCHAR(255),
    updated_by      VARCHAR(255)
);
CREATE INDEX IF NOT EXISTS idx_sc_country_active ON evolution_scoring_config (country_code, is_active);
