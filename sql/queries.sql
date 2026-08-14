-- ============================================================
-- PMB Solutions - Sample Analytical Queries
-- ============================================================
-- Demonstrates common PBM reporting and analysis use cases
-- built on top of the schema defined in schema.sql
-- ============================================================


-- ------------------------------------------------------------
-- 1. Total plan-paid amount by drug tier
-- Use case: understand cost distribution across formulary tiers
-- ------------------------------------------------------------
SELECT
    d.tier,
    COUNT(c.claim_id)              AS total_claims,
    SUM(c.plan_paid_amount)        AS total_plan_paid,
    ROUND(AVG(c.plan_paid_amount), 2) AS avg_plan_paid_per_claim
FROM claims c
JOIN drugs d ON c.drug_id = d.drug_id
GROUP BY d.tier
ORDER BY total_plan_paid DESC;


-- ------------------------------------------------------------
-- 2. Top 10 prescribers by claim volume
-- Use case: identify high-volume prescribers for utilization review
-- ------------------------------------------------------------
SELECT
    p.prescriber_id,
    p.first_name || ' ' || p.last_name AS prescriber_name,
    p.specialty,
    COUNT(c.claim_id)              AS total_claims
FROM claims c
JOIN prescribers p ON c.prescriber_id = p.prescriber_id
GROUP BY p.prescriber_id, p.first_name, p.last_name, p.specialty
ORDER BY total_claims DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 3. Member-level cost summary
-- Use case: total cost share (copay) vs. plan liability per member
-- ------------------------------------------------------------
SELECT
    m.member_id,
    m.first_name || ' ' || m.last_name AS member_name,
    m.plan_id,
    COUNT(c.claim_id)              AS total_claims,
    SUM(c.copay_amount)            AS total_copay_paid,
    SUM(c.plan_paid_amount)        AS total_plan_paid,
    SUM(c.copay_amount + c.plan_paid_amount) AS total_cost
FROM members m
JOIN claims c ON m.member_id = c.member_id
GROUP BY m.member_id, m.first_name, m.last_name, m.plan_id
ORDER BY total_cost DESC;


-- ------------------------------------------------------------
-- 4. Generic vs. brand drug utilization
-- Use case: track generic substitution rate, a key PBM cost metric
-- ------------------------------------------------------------
SELECT
    d.is_generic,
    COUNT(c.claim_id)              AS total_claims,
    SUM(c.plan_paid_amount)        AS total_plan_paid,
    ROUND(
        100.0 * COUNT(c.claim_id) / SUM(COUNT(c.claim_id)) OVER (), 2
    )                       AS pct_of_total_claims
FROM claims c
JOIN drugs d ON c.drug_id = d.drug_id
GROUP BY d.is_generic
ORDER BY d.is_generic DESC;


-- ------------------------------------------------------------
-- 5. Monthly claims trend
-- Use case: track claim volume and spend over time for reporting
-- ------------------------------------------------------------
SELECT
    DATE_TRUNC('month', c.fill_date) AS claim_month,
    COUNT(c.claim_id)              AS total_claims,
    SUM(c.plan_paid_amount)        AS total_plan_paid
FROM claims c
GROUP BY DATE_TRUNC('month', c.fill_date)
ORDER BY claim_month;


-- ------------------------------------------------------------
-- 6. Top 5 most-prescribed drugs
-- Use case: formulary management, identify high-utilization drugs
-- ------------------------------------------------------------
SELECT
    d.drug_name,
    d.tier,
    d.is_generic,
    COUNT(c.claim_id)              AS total_fills,
    SUM(c.quantity)                 AS total_quantity_dispensed
FROM claims c
JOIN drugs d ON c.drug_id = d.drug_id
GROUP BY d.drug_name, d.tier, d.is_generic
ORDER BY total_fills DESC
LIMIT 5;


-- ------------------------------------------------------------
-- 7. Members with no claims in the last 90 days
-- Use case: identify inactive members for outreach or engagement review
-- ------------------------------------------------------------
SELECT
    m.member_id,
    m.first_name || ' ' || m.last_name AS member_name,
    m.plan_id,
    MAX(c.fill_date)               AS last_fill_date
FROM members m
LEFT JOIN claims c ON m.member_id = c.member_id
GROUP BY m.member_id, m.first_name, m.last_name, m.plan_id
HAVING MAX(c.fill_date) IS NULL
    OR MAX(c.fill_date) < CURRENT_DATE - INTERVAL '90 days'
ORDER BY last_fill_date NULLS FIRST;


-- ------------------------------------------------------------
-- 8. Average days supply and copay by pharmacy
-- Use case: compare pharmacy-level dispensing patterns
-- ------------------------------------------------------------
SELECT
    c.pharmacy_name,
    COUNT(c.claim_id)              AS total_claims,
    ROUND(AVG(c.days_supply), 1)   AS avg_days_supply,
    ROUND(AVG(c.copay_amount), 2)  AS avg_copay
FROM claims c
GROUP BY c.pharmacy_name
ORDER BY total_claims DESC;


-- ------------------------------------------------------------
-- 9. Specialty drug claims (Tier = 'Specialty') with member and prescriber detail
-- Use case: specialty drug case management and high-cost claim monitoring
-- ------------------------------------------------------------
SELECT
    c.claim_id,
    c.fill_date,
    m.first_name || ' ' || m.last_name AS member_name,
    d.drug_name,
    p.first_name || ' ' || p.last_name AS prescriber_name,
    c.plan_paid_amount
FROM claims c
JOIN drugs d       ON c.drug_id = d.drug_id
JOIN members m     ON c.member_id = m.member_id
JOIN prescribers p ON c.prescriber_id = p.prescriber_id
WHERE d.tier = 'Specialty'
ORDER BY c.plan_paid_amount DESC;


-- ------------------------------------------------------------
-- 10. Plan-level summary (all metrics rolled up by plan_id)
-- Use case: client-facing reporting, one row per plan sponsor
-- ------------------------------------------------------------
SELECT
    m.plan_id,
    COUNT(DISTINCT m.member_id)    AS total_members,
    COUNT(c.claim_id)              AS total_claims,
    SUM(c.plan_paid_amount)        AS total_plan_paid,
    ROUND(SUM(c.plan_paid_amount) / NULLIF(COUNT(DISTINCT m.member_id), 0), 2) AS avg_cost_per_member
FROM members m
LEFT JOIN claims c ON m.member_id = c.member_id
GROUP BY m.plan_id
ORDER BY total_plan_paid DESC;
