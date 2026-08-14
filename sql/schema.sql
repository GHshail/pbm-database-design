-- ============================================================
-- PMB Solutions - Pharmacy Benefit Management Database Schema
-- ============================================================
-- Target: PostgreSQL (portable to most RDBMS with minor changes)
-- Tables: members, drugs, prescribers, claims
-- ============================================================

-- Drop tables if they exist (useful for re-running during development)
DROP TABLE IF EXISTS claims;
DROP TABLE IF EXISTS members;
DROP TABLE IF EXISTS drugs;
DROP TABLE IF EXISTS prescribers;

-- ------------------------------------------------------------
-- Table: members
-- Individuals enrolled under a client's pharmacy benefit plan
-- ------------------------------------------------------------
CREATE TABLE members (
    member_id        SERIAL PRIMARY KEY,
    first_name        VARCHAR(50)  NOT NULL,
    last_name        VARCHAR(50)  NOT NULL,
    dob            DATE       NOT NULL,
    plan_id            VARCHAR(20)  NOT NULL,
    enrollment_date        DATE       NOT NULL,
    CONSTRAINT chk_members_dob CHECK (dob <= CURRENT_DATE)
);

-- ------------------------------------------------------------
-- Table: drugs
-- Formulary of medications covered under plans
-- ------------------------------------------------------------
CREATE TABLE drugs (
    drug_id        SERIAL PRIMARY KEY,
    drug_name        VARCHAR(150) NOT NULL,
    ndc_code        VARCHAR(20)  NOT NULL UNIQUE,
    tier            VARCHAR(20)  NOT NULL,
    manufacturer        VARCHAR(100),
    is_generic        BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT chk_drugs_tier CHECK (tier IN ('Tier 1', 'Tier 2', 'Tier 3', 'Tier 4', 'Specialty'))
);

-- ------------------------------------------------------------
-- Table: prescribers
-- Physicians/providers who write prescriptions
-- ------------------------------------------------------------
CREATE TABLE prescribers (
    prescriber_id    SERIAL PRIMARY KEY,
    first_name        VARCHAR(50)  NOT NULL,
    last_name        VARCHAR(50)  NOT NULL,
    npi_number        VARCHAR(10)  NOT NULL UNIQUE,
    specialty        VARCHAR(100)
);

-- ------------------------------------------------------------
-- Table: claims
-- Transactional records generated when a member fills a prescription
-- Central "hub" table referencing members, drugs, and prescribers
-- ------------------------------------------------------------
CREATE TABLE claims (
    claim_id        SERIAL PRIMARY KEY,
    member_id        INTEGER      NOT NULL,
    drug_id            INTEGER      NOT NULL,
    prescriber_id        INTEGER      NOT NULL,
    fill_date        DATE       NOT NULL,
    quantity        INTEGER      NOT NULL,
    days_supply        INTEGER      NOT NULL,
    copay_amount        DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    plan_paid_amount    DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    pharmacy_name        VARCHAR(150) NOT NULL,

    CONSTRAINT fk_claims_member
        FOREIGN KEY (member_id) REFERENCES members(member_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_claims_drug
        FOREIGN KEY (drug_id) REFERENCES drugs(drug_id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_claims_prescriber
        FOREIGN KEY (prescriber_id) REFERENCES prescribers(prescriber_id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_claims_quantity CHECK (quantity > 0),
    CONSTRAINT chk_claims_days_supply CHECK (days_supply > 0),
    CONSTRAINT chk_claims_amounts CHECK (copay_amount >= 0 AND plan_paid_amount >= 0)
);

-- ------------------------------------------------------------
-- Indexes to speed up common lookups and joins
-- ------------------------------------------------------------
CREATE INDEX idx_claims_member_id      ON claims(member_id);
CREATE INDEX idx_claims_drug_id        ON claims(drug_id);
CREATE INDEX idx_claims_prescriber_id  ON claims(prescriber_id);
CREATE INDEX idx_claims_fill_date      ON claims(fill_date);
CREATE INDEX idx_members_plan_id       ON members(plan_id);
CREATE INDEX idx_drugs_ndc_code        ON drugs(ndc_code);
