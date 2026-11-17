/*
PROJECT 3: HEALTHCARE DATA ANALYSIS
Database: PostgreSQL
Dataset: Synthetic COVID-19 / Synthetic healthcare dataset

Workflow:
1. Create/import the selected tables.
2. Run data-quality checks.
3. Run the business-focused analyses.
4. Review findings and limitations before building the Python and Power BI stages.

IMPORTANT:
- The CREATE TABLE statements below document the table structures used.
- If the tables already exist in your database, do not run the CREATE TABLE statements again.
- CSV imports were performed separately through pgAdmin.
- COVID groups mean patients WITH or WITHOUT a recorded COVID-19 diagnosis.
  They do not prove that a service or procedure was caused by COVID-19.
*/


/* ============================================================
   0. DATABASE CHECK
   ============================================================ */

SELECT current_database();


/* ============================================================
   1. TABLE STRUCTURES
   Run only when creating the tables for the first time.
   ============================================================ */

-- 1.1 Patients
CREATE TABLE patients (
    id VARCHAR(100) PRIMARY KEY,
    birthdate DATE,
    deathdate DATE,
    ssn VARCHAR(50),
    drivers VARCHAR(50),
    passport VARCHAR(50),
    prefix VARCHAR(20),
    first VARCHAR(100),
    last VARCHAR(100),
    suffix VARCHAR(20),
    maiden VARCHAR(100),
    marital VARCHAR(10),
    race VARCHAR(50),
    ethnicity VARCHAR(50),
    gender VARCHAR(10),
    birthplace TEXT,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    county VARCHAR(100),
    zip VARCHAR(20),
    lat DOUBLE PRECISION,
    lon DOUBLE PRECISION,
    healthcare_expenses NUMERIC(15,2),
    healthcare_coverage NUMERIC(15,2)
);

-- 1.2 Encounters
CREATE TABLE encounters (
    id VARCHAR(100) PRIMARY KEY,
    start TIMESTAMPTZ,
    stop TIMESTAMPTZ,
    patient VARCHAR(100),
    organization VARCHAR(100),
    provider VARCHAR(100),
    payer VARCHAR(100),
    encounterclass VARCHAR(50),
    code VARCHAR(50),
    description TEXT,
    base_encounter_cost NUMERIC(15,2),
    total_claim_cost NUMERIC(15,2),
    payer_coverage NUMERIC(15,2),
    reasoncode VARCHAR(50),
    reasondescription TEXT
);

-- 1.3 Conditions
CREATE TABLE conditions (
    start DATE,
    stop DATE,
    patient VARCHAR(100),
    encounter VARCHAR(100),
    code VARCHAR(50),
    description TEXT
);

-- 1.4 Medications
CREATE TABLE medications (
    start DATE,
    stop DATE,
    patient VARCHAR(100),
    payer VARCHAR(100),
    encounter VARCHAR(100),
    code VARCHAR(50),
    description TEXT,
    base_cost NUMERIC(15,2),
    payer_coverage NUMERIC(15,2),
    dispenses INTEGER,
    totalcost NUMERIC(15,2),
    reasoncode VARCHAR(50),
    reasondescription TEXT
);

-- 1.5 Procedures
CREATE TABLE procedures (
    date DATE,
    patient VARCHAR(100),
    encounter VARCHAR(100),
    code VARCHAR(50),
    description TEXT,
    base_cost NUMERIC(15,2),
    reasoncode VARCHAR(50),
    reasondescription TEXT
);

-- 1.6 Observations
CREATE TABLE observations (
    date DATE,
    patient VARCHAR(100),
    encounter VARCHAR(100),
    code VARCHAR(50),
    description TEXT,
    value TEXT,
    units VARCHAR(50),
    type VARCHAR(50)
);

/* ============================================================
   2. DATA PROFILING AND QUALITY CHECKS
   ============================================================ */

-- 2.1 Row counts for the selected tables
SELECT 'patients' AS table_name, COUNT(*) AS total_rows FROM patients
UNION ALL
SELECT 'encounters', COUNT(*) FROM encounters
UNION ALL
SELECT 'conditions', COUNT(*) FROM conditions
UNION ALL
SELECT 'medications', COUNT(*) FROM medications
UNION ALL
SELECT 'procedures', COUNT(*) FROM procedures
UNION ALL
SELECT 'observations', COUNT(*) FROM observations
ORDER BY table_name;


-- 2.2 Patients: check key missing values and invalid values
SELECT
    COUNT(*) AS total_patients,
    COUNT(*) FILTER (WHERE id IS NULL) AS null_patient_ids,
    COUNT(*) FILTER (WHERE birthdate IS NULL) AS null_birthdates,
    COUNT(*) FILTER (WHERE gender IS NULL) AS null_gender,
    COUNT(*) FILTER (WHERE healthcare_expenses IS NULL) AS null_expenses,
    COUNT(*) FILTER (WHERE healthcare_coverage IS NULL) AS null_coverage,
    COUNT(*) FILTER (WHERE healthcare_expenses < 0) AS negative_expenses,
    COUNT(*) FILTER (WHERE healthcare_coverage < 0) AS negative_coverage,
    COUNT(*) FILTER (WHERE birthdate > CURRENT_DATE) AS future_birthdates,
    COUNT(*) FILTER (WHERE deathdate < birthdate) AS invalid_deathdates
FROM patients;

-- 2.3 Encounters: check missing values, invalid dates, and negative costs
SELECT
    COUNT(*) AS total_encounters,
    COUNT(*) FILTER (WHERE patient IS NULL) AS null_patients,
    COUNT(*) FILTER (WHERE start IS NULL) AS null_start_dates,
    COUNT(*) FILTER (WHERE stop IS NULL) AS null_stop_dates,
    COUNT(*) FILTER (WHERE encounterclass IS NULL) AS null_encounter_classes,
    COUNT(*) FILTER (WHERE reasoncode IS NULL) AS missing_reason_codes,
    COUNT(*) FILTER (WHERE stop < start) AS invalid_encounter_dates,
    COUNT(*) FILTER (WHERE base_encounter_cost < 0) AS negative_base_costs,
    COUNT(*) FILTER (WHERE total_claim_cost < 0) AS negative_claim_costs,
    COUNT(*) FILTER (WHERE payer_coverage < 0) AS negative_payer_coverage
FROM encounters;

-- 2.4 Encounters: missing reason codes by encounter class
SELECT
    encounterclass,
    COUNT(*) AS total_encounters,
    COUNT(*) FILTER (WHERE reasoncode IS NULL) AS missing_reason_codes,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE reasoncode IS NULL) / COUNT(*),
        0
    ) AS missing_percentage
FROM encounters
GROUP BY encounterclass
ORDER BY total_encounters DESC;


-- 2.5 Conditions: check missing values and invalid dates
SELECT
    COUNT(*) AS total_condition_records,
    COUNT(*) FILTER (WHERE start IS NULL) AS null_start_dates,
    COUNT(*) FILTER (WHERE patient IS NULL) AS null_patient_ids,
    COUNT(*) FILTER (WHERE encounter IS NULL) AS null_encounter_ids,
    COUNT(*) FILTER (WHERE code IS NULL) AS null_codes,
    COUNT(*) FILTER (WHERE description IS NULL) AS null_descriptions,
    COUNT(*) FILTER (WHERE start > CURRENT_DATE) AS future_start_dates,
    COUNT(*) FILTER (WHERE stop IS NOT NULL AND stop < start) AS invalid_stop_dates
FROM conditions;

-- 2.6 Medications: check missing values, invalid dates, and negative costs
SELECT
    COUNT(*) AS total_medication_records,
    COUNT(*) FILTER (WHERE patient IS NULL) AS null_patient_ids,
    COUNT(*) FILTER (WHERE encounter IS NULL) AS null_encounter_ids,
    COUNT(*) FILTER (WHERE start IS NULL) AS null_start_dates,
    COUNT(*) FILTER (WHERE description IS NULL) AS null_descriptions,
    COUNT(*) FILTER (WHERE totalcost IS NULL) AS null_total_costs,
    COUNT(*) FILTER (WHERE stop < start) AS invalid_stop_dates,
    COUNT(*) FILTER (WHERE base_cost < 0) AS negative_base_costs,
    COUNT(*) FILTER (WHERE totalcost < 0) AS negative_total_costs,
    COUNT(*) FILTER (WHERE payer_coverage < 0) AS negative_payer_coverage
FROM medications;

-- 2.7 Procedures: check missing values
SELECT
    COUNT(*) AS total_procedure_records,
    COUNT(*) FILTER (WHERE date IS NULL) AS missing_dates,
    COUNT(*) FILTER (WHERE patient IS NULL) AS missing_patient_ids,
    COUNT(*) FILTER (WHERE encounter IS NULL) AS missing_encounter_ids,
    COUNT(*) FILTER (WHERE code IS NULL) AS missing_codes,
    COUNT(*) FILTER (WHERE description IS NULL) AS missing_descriptions,
    COUNT(*) FILTER (WHERE base_cost IS NULL) AS missing_base_costs,
    COUNT(*) FILTER (WHERE reasoncode IS NULL) AS missing_reason_codes
FROM procedures;

-- 2.8 Observations: check missing values and invalid dates
SELECT
    COUNT(*) AS total_observation_records,
    COUNT(*) FILTER (WHERE date IS NULL) AS missing_dates,
    COUNT(*) FILTER (WHERE patient IS NULL) AS missing_patient_ids,
    COUNT(*) FILTER (WHERE encounter IS NULL) AS missing_encounter_ids,
    COUNT(*) FILTER (WHERE code IS NULL) AS missing_codes,
    COUNT(*) FILTER (WHERE description IS NULL) AS missing_descriptions,
    COUNT(*) FILTER (WHERE value IS NULL) AS missing_values,
    COUNT(*) FILTER (WHERE units IS NULL) AS missing_units,
    COUNT(*) FILTER (WHERE date > CURRENT_DATE) AS future_dates
FROM observations;

-- 2.9 Check patient and encounter references across tables

SELECT
    'encounters' AS table_name,
    COUNT(*) FILTER (
        WHERE e.patient IS NOT NULL AND p.id IS NULL
    ) AS unmatched_patient_ids,
    0 AS unmatched_encounter_ids,
    0 AS patient_encounter_mismatches
FROM encounters e
LEFT JOIN patients p ON e.patient = p.id

UNION ALL

SELECT
    'conditions',
    COUNT(*) FILTER (
        WHERE c.patient IS NOT NULL AND p.id IS NULL
    ),
    COUNT(*) FILTER (
        WHERE c.encounter IS NOT NULL AND e.id IS NULL
    ),
    COUNT(*) FILTER (
        WHERE e.id IS NOT NULL AND c.patient <> e.patient
    )
FROM conditions c
LEFT JOIN patients p ON c.patient = p.id
LEFT JOIN encounters e ON c.encounter = e.id

UNION ALL

SELECT
    'medications',
    COUNT(*) FILTER (
        WHERE m.patient IS NOT NULL AND p.id IS NULL
    ),
    COUNT(*) FILTER (
        WHERE m.encounter IS NOT NULL AND e.id IS NULL
    ),
    COUNT(*) FILTER (
        WHERE e.id IS NOT NULL AND m.patient <> e.patient
    )
FROM medications m
LEFT JOIN patients p ON m.patient = p.id
LEFT JOIN encounters e ON m.encounter = e.id

UNION ALL

SELECT
    'procedures',
    COUNT(*) FILTER (
        WHERE pr.patient IS NOT NULL AND p.id IS NULL
    ),
    COUNT(*) FILTER (
        WHERE pr.encounter IS NOT NULL AND e.id IS NULL
    ),
    COUNT(*) FILTER (
        WHERE e.id IS NOT NULL AND pr.patient <> e.patient
    )
FROM procedures pr
LEFT JOIN patients p ON pr.patient = p.id
LEFT JOIN encounters e ON pr.encounter = e.id

UNION ALL

SELECT
    'observations',
    COUNT(*) FILTER (
        WHERE o.patient IS NOT NULL AND p.id IS NULL
    ),
    COUNT(*) FILTER (
        WHERE o.encounter IS NOT NULL AND e.id IS NULL
    ),
    COUNT(*) FILTER (
        WHERE e.id IS NOT NULL AND o.patient <> e.patient
    )
FROM observations o
LEFT JOIN patients p ON o.patient = p.id
LEFT JOIN encounters e ON o.encounter = e.id;
/* ============================================================
   3. PATIENT PROFILE AND HEALTHCARE EXPENSES
   ============================================================ */

-- 3.1 Patient demographics by gender
SELECT
    gender,
    COUNT(*) AS total_patients,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 0) AS patient_percentage
FROM patients
GROUP BY gender
ORDER BY total_patients DESC;


-- 3.2 Healthcare expenses and coverage summary
SELECT
    ROUND(MIN(healthcare_expenses), 2) AS min_healthcare_expenses,
    ROUND(MAX(healthcare_expenses), 2) AS max_healthcare_expenses,
    ROUND(AVG(healthcare_expenses), 2) AS avg_healthcare_expenses,
    ROUND(MIN(healthcare_coverage), 2) AS min_healthcare_coverage,
    ROUND(MAX(healthcare_coverage), 2) AS max_healthcare_coverage,
    ROUND(AVG(healthcare_coverage), 2) AS avg_healthcare_coverage,
    ROUND(
        100.0 * SUM(healthcare_coverage) /
        NULLIF(SUM(healthcare_expenses), 0),
        0
    ) AS coverage_percentage
FROM patients;

-- 3.3 Distribution of patients by healthcare expense category
WITH patient_expense_groups AS (
    SELECT
        CASE
            WHEN healthcare_expenses < 100000 THEN 'Very Low'
            WHEN healthcare_expenses < 500000 THEN 'Low'
            WHEN healthcare_expenses < 1000000 THEN 'Medium'
            WHEN healthcare_expenses < 2000000 THEN 'High'
            ELSE 'Very High'
        END AS expense_category,
        CASE
            WHEN healthcare_expenses < 100000 THEN 1
            WHEN healthcare_expenses < 500000 THEN 2
            WHEN healthcare_expenses < 1000000 THEN 3
            WHEN healthcare_expenses < 2000000 THEN 4
            ELSE 5
        END AS category_order
    FROM patients
)
SELECT
    expense_category,
    COUNT(*) AS total_patients,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 0) AS patient_percentage
FROM patient_expense_groups
GROUP BY expense_category, category_order
ORDER BY category_order;

-- 3.4 Healthcare expenses and coverage by gender
SELECT
    gender,
    COUNT(*) AS total_patients,
    ROUND(AVG(healthcare_expenses), 2) AS avg_healthcare_expenses,
    ROUND(AVG(healthcare_coverage), 2) AS avg_healthcare_coverage,
    ROUND(
        100.0 * SUM(healthcare_coverage) /
        NULLIF(SUM(healthcare_expenses), 0),
        0
    ) AS coverage_percentage
FROM patients
GROUP BY gender
ORDER BY gender;

 /* ============================================================
    4. HEALTHCARE ENCOUNTER TRENDS
    ============================================================ */

-- 4.1 Encounter date range
SELECT
    MIN(start) AS earliest_encounter,
    MAX(start) AS latest_encounter
FROM encounters;

-- 4.2 Monthly encounter trend from 2018
SELECT
    DATE_TRUNC('month', start)::DATE AS encounter_month,
    COUNT(*) AS total_encounters
FROM encounters
WHERE start >= DATE '2018-01-01'
GROUP BY encounter_month
ORDER BY encounter_month;


-- 4.3 Encounter type distribution during March 2020
SELECT
    encounterclass,
    COUNT(*) AS total_encounters
FROM encounters
WHERE start >= DATE '2020-03-01'
  AND start < DATE '2020-04-01'
GROUP BY encounterclass
ORDER BY total_encounters DESC;

-- 4.4 Patient healthcare utilization and encounter cost
-- Patients are retained even if they have no recorded encounters.
WITH patient_utilization AS (
    SELECT
        p.id AS patient_id,
        COUNT(e.id) AS encounter_count,
        COALESCE(SUM(e.total_claim_cost), 0) AS total_claim_cost,
        p.healthcare_expenses
    FROM patients p
    LEFT JOIN encounters e
        ON p.id = e.patient
    GROUP BY p.id, p.healthcare_expenses
),
utilization_groups AS (
    SELECT
        *,
        CASE
            WHEN encounter_count = 0 THEN 'No encounters'
            WHEN encounter_count BETWEEN 1 AND 5 THEN '1-5 encounters'
            WHEN encounter_count BETWEEN 6 AND 10 THEN '6-10 encounters'
            WHEN encounter_count BETWEEN 11 AND 20 THEN '11-20 encounters'
            ELSE 'More than 20 encounters'
        END AS utilization_group
    FROM patient_utilization
)
SELECT
    utilization_group,
    COUNT(*) AS patient_count,
    SUM(encounter_count) AS total_encounters,
    ROUND(AVG(encounter_count), 2) AS avg_encounters_per_patient,
    ROUND(AVG(total_claim_cost), 0) AS avg_claim_cost_per_patient,
    ROUND(AVG(healthcare_expenses), 0) AS avg_healthcare_expenses
FROM utilization_groups
GROUP BY utilization_group
ORDER BY MIN(encounter_count);

-- 4.5 Encounter types used by each patient-utilization group
WITH patient_utilization AS (
    SELECT
        patient,
        COUNT(*) AS encounter_count
    FROM encounters
    GROUP BY patient
),
patient_groups AS (
    SELECT
        patient,
        CASE
            WHEN encounter_count BETWEEN 1 AND 5 THEN '1-5 encounters'
            WHEN encounter_count BETWEEN 6 AND 10 THEN '6-10 encounters'
            WHEN encounter_count BETWEEN 11 AND 20 THEN '11-20 encounters'
            ELSE 'More than 20 encounters'
        END AS utilization_group
    FROM patient_utilization
)
SELECT
    pg.utilization_group,
    e.encounterclass,
    COUNT(*) AS encounter_count,
    COUNT(DISTINCT e.patient) AS patient_count,
    ROUND(AVG(e.total_claim_cost), 0) AS avg_claim_cost,
    ROUND(SUM(e.total_claim_cost), 0) AS total_claim_cost
FROM patient_groups pg
JOIN encounters e
    ON pg.patient = e.patient
GROUP BY pg.utilization_group, e.encounterclass
ORDER BY
    CASE pg.utilization_group
        WHEN '1-5 encounters' THEN 1
        WHEN '6-10 encounters' THEN 2
        WHEN '11-20 encounters' THEN 3
        ELSE 4
    END,
    encounter_count DESC;

/* ============================================================
   5. CONDITION AND COVID-19 ANALYSIS
   ============================================================ */

-- 5.1 Most frequently recorded conditions
SELECT
    code,
    description,
    COUNT(*) AS condition_records,
    COUNT(DISTINCT patient) AS unique_patients
FROM conditions
GROUP BY code, description
ORDER BY condition_records DESC
LIMIT 10;


-- 5.2 Monthly trend of recorded COVID-19 diagnoses
SELECT
    DATE_TRUNC('month', start)::DATE AS diagnosis_month,
    COUNT(*) AS covid_diagnosis_records,
    COUNT(DISTINCT patient) AS unique_patients
FROM conditions
WHERE code = '840539006'
GROUP BY diagnosis_month
ORDER BY diagnosis_month;


-- 5.3 Recorded COVID-19 patients by age group and gender
WITH covid_patients AS (
    SELECT DISTINCT
        p.id,
        p.gender,
        DATE_PART('year', AGE(DATE '2020-12-31', p.birthdate)) AS age
    FROM patients p
    JOIN conditions c
        ON p.id = c.patient
    WHERE c.code = '840539006'
),
age_groups AS (
    SELECT
        gender,
        CASE
            WHEN age < 18 THEN 'Under 18'
            WHEN age < 30 THEN '18-29'
            WHEN age < 45 THEN '30-44'
            WHEN age < 60 THEN '45-59'
            ELSE '60+'
        END AS age_group,
        CASE
            WHEN age < 18 THEN 1
            WHEN age < 30 THEN 2
            WHEN age < 45 THEN 3
            WHEN age < 60 THEN 4
            ELSE 5
        END AS age_order
    FROM covid_patients
    WHERE age >= 0
)
SELECT
    age_group,
    gender,
    COUNT(*) AS patient_count
FROM age_groups
GROUP BY age_group, age_order, gender
ORDER BY age_order, gender;

-- 5.4 Encounter claim costs by recorded COVID-19 diagnosis status
WITH patient_groups AS (
    SELECT
        p.id AS patient_id,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM conditions c
                WHERE c.patient = p.id
                  AND c.code = '840539006'
            )
            THEN 'Recorded COVID-19'
            ELSE 'No recorded COVID-19'
        END AS covid_group
    FROM patients p
)
SELECT
    pg.covid_group,
    COUNT(DISTINCT e.patient) AS patient_count,
    COUNT(e.id) AS encounter_count,
    ROUND(SUM(e.total_claim_cost), 0) AS total_encounter_cost,
    ROUND(AVG(e.total_claim_cost), 0) AS avg_cost_per_encounter
FROM patient_groups pg
JOIN encounters e
    ON e.patient = pg.patient_id
GROUP BY pg.covid_group
ORDER BY pg.covid_group;


/* ============================================================
   6. MEDICATION UTILIZATION AND COST
   ============================================================ */

-- 6.1 Medication ranking by total recorded cost, with frequency and coverage
SELECT
    description AS medication_name,
    COUNT(*) AS medication_records,
    ROUND(SUM(totalcost), 0) AS total_medication_cost,
    ROUND(SUM(payer_coverage), 0) AS total_payer_coverage,
    ROUND(
        100.0 * SUM(payer_coverage) / NULLIF(SUM(totalcost), 0),
        0
    ) AS coverage_percentage
FROM medications
GROUP BY description
ORDER BY total_medication_cost DESC
LIMIT 10;


/* ============================================================
   7. PROCEDURE UTILIZATION AND COST
   ============================================================ */

-- 7.1 Top procedures by total recorded base cost
SELECT
    p.description AS procedure_name,
	count(distinct p.patient) as patient_count,
    COUNT(*) AS procedure_count,
    ROUND(SUM(p.base_cost), 0) AS total_procedure_cost,
    ROUND(AVG(p.base_cost), 0) AS avg_procedure_cost
FROM procedures p
GROUP BY procedure_name  
ORDER BY total_procedure_cost DESC
LIMIT 10;

-- 7.2 Procedure volume and top cost-driving procedures by recorded COVID status
WITH patient_groups AS (
    SELECT
        p.id AS patient_id,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM conditions c
                WHERE c.patient = p.id
                  AND c.code = '840539006'
            )
            THEN 'Recorded COVID-19'
            ELSE 'No recorded COVID-19'
        END AS covid_group
    FROM patients p
),
procedure_costs AS (
    SELECT
        pg.covid_group,
        pr.description AS procedure_name,
        COUNT(*) AS procedure_count,
        SUM(pr.base_cost) AS total_cost,
        AVG(pr.base_cost) AS avg_cost
    FROM patient_groups pg
    JOIN procedures pr
        ON pg.patient_id = pr.patient
    GROUP BY pg.covid_group, pr.description
),
ranked_procedures AS (
    SELECT
        *,
        SUM(procedure_count) OVER (
            PARTITION BY covid_group
        ) AS total_procedures,
        SUM(total_cost) OVER (
            PARTITION BY covid_group
        ) AS total_procedure_cost,
        DENSE_RANK() OVER (
            PARTITION BY covid_group
            ORDER BY total_cost DESC
        ) AS cost_rank
    FROM procedure_costs
)
SELECT
    covid_group,
    total_procedures,
    ROUND(total_procedure_cost, 0) AS total_procedure_cost,
    ROUND(total_procedure_cost / NULLIF(total_procedures, 0), 0)
        AS avg_cost_per_procedure,
    procedure_name,
    procedure_count,
    ROUND(total_cost, 0) AS procedure_total_cost,
    ROUND(avg_cost, 0) AS procedure_avg_cost,
    cost_rank
FROM ranked_procedures
WHERE cost_rank <= 5
ORDER BY covid_group, cost_rank;

/* ============================================================
   8. CLINICAL OBSERVATIONS AND MONITORING
   ============================================================ */

-- 8.1 Most frequently recorded observation types
SELECT
    description,
    type,
    units,
    COUNT(*) AS observation_count
FROM observations
GROUP BY description, type, units
ORDER BY observation_count DESC
LIMIT 20;

-- 8.2 Healthcare utilization and observation patterns by patient group.
-- Observation and encounter data are aggregated separately at patient level
-- before joining, preventing row multiplication (fanout).
WITH patient_utilization AS (
    SELECT
        patient,
        COUNT(*) AS encounter_count,
        SUM(total_claim_cost) AS total_claim_cost
    FROM encounters
    GROUP BY patient
),
patient_observations AS (
    SELECT
        patient,
        COUNT(*) AS observation_count,
        COUNT(DISTINCT description) AS measurement_types
    FROM observations
    GROUP BY patient
),
patient_analysis AS (
    SELECT
        p.id AS patient_id,
        COALESCE(u.encounter_count, 0) AS encounter_count,
        COALESCE(u.total_claim_cost, 0) AS total_claim_cost,
        COALESCE(o.observation_count, 0) AS observation_count,
        COALESCE(o.measurement_types, 0) AS measurement_types,
        p.healthcare_expenses,
        CASE
            WHEN COALESCE(u.encounter_count, 0) = 0 THEN 'No encounters'
            WHEN u.encounter_count BETWEEN 1 AND 5 THEN '1-5 encounters'
            WHEN u.encounter_count BETWEEN 6 AND 10 THEN '6-10 encounters'
            WHEN u.encounter_count BETWEEN 11 AND 20 THEN '11-20 encounters'
            ELSE 'More than 20 encounters'
        END AS utilization_group
    FROM patients p
    LEFT JOIN patient_utilization u
        ON p.id = u.patient
    LEFT JOIN patient_observations o
        ON p.id = o.patient
),

utilization_summary AS (
    SELECT
        utilization_group,
        COUNT(*) AS patient_count,
        SUM(encounter_count) AS total_encounters,
        SUM(observation_count) AS total_observations,
        ROUND(AVG(observation_count), 0) AS avg_observations_per_patient,
        ROUND(AVG(measurement_types), 0) AS avg_measurement_types,
        ROUND(AVG(total_claim_cost), 0) AS avg_claim_cost_per_patient,
        ROUND(AVG(healthcare_expenses), 0) AS avg_healthcare_expenses
    FROM patient_analysis
    GROUP BY utilization_group
),
encounter_analysis AS (
    SELECT
        pa.utilization_group,
        e.encounterclass,
        COUNT(*) AS encounter_count,
        COUNT(DISTINCT e.patient) AS patient_count,
        ROUND(AVG(e.total_claim_cost), 0) AS avg_claim_cost_per_encounter,
        ROUND(SUM(e.total_claim_cost), 0) AS total_claim_cost
    FROM patient_analysis pa
    JOIN encounters e
        ON pa.patient_id = e.patient
    GROUP BY pa.utilization_group, e.encounterclass
)
SELECT
    us.utilization_group,
    us.patient_count AS group_patient_count,
    us.total_encounters AS group_total_encounters,
    us.total_observations,
    us.avg_observations_per_patient,
    us.avg_measurement_types,
    us.avg_claim_cost_per_patient,
    us.avg_healthcare_expenses,
    ea.encounterclass,
    ea.encounter_count,
    ea.patient_count AS encounter_type_patient_count,
    ea.avg_claim_cost_per_encounter,
    ea.total_claim_cost
FROM utilization_summary us
LEFT JOIN encounter_analysis ea
    ON us.utilization_group = ea.utilization_group
ORDER BY
    CASE us.utilization_group
        WHEN 'No encounters' THEN 1
        WHEN '1-5 encounters' THEN 2
        WHEN '6-10 encounters' THEN 3
        WHEN '11-20 encounters' THEN 4
        ELSE 5
    END,
    ea.encounter_count DESC NULLS LAST;

-- 8.3 Observation volume and key measurement pairs by encounter type.
-- The first average includes encounters with zero observations.
-- The second average and median include only encounters with observations.
WITH observation_by_encounter AS (
    SELECT
        encounter,
        COUNT(*) AS observation_count,
        BOOL_OR(description = 'Systolic Blood Pressure') AS has_systolic_bp,
        BOOL_OR(description = 'Diastolic Blood Pressure') AS has_diastolic_bp,
        BOOL_OR(description = 'Oxygen saturation in Arterial blood') AS has_oxygen,
        BOOL_OR(description = 'Respiratory rate') AS has_respiratory_rate
    FROM observations
    GROUP BY encounter
)
SELECT
    e.encounterclass,
    COUNT(*) AS total_encounters,
    COUNT(*) FILTER (
        WHERE o.observation_count IS NOT NULL
    ) AS encounters_with_observations,
    ROUND(AVG(COALESCE(o.observation_count, 0)), 0)
        AS avg_observations_all_encounters,
    ROUND(AVG(o.observation_count), 0)
        AS avg_observations_when_recorded,
    PERCENTILE_CONT(0.50) WITHIN GROUP (
        ORDER BY o.observation_count
    ) FILTER (
        WHERE o.observation_count IS NOT NULL
    ) AS median_observations_when_recorded,
    MAX(o.observation_count) AS max_observations,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE COALESCE(o.has_systolic_bp, FALSE)
              AND COALESCE(o.has_diastolic_bp, FALSE)
        ) / COUNT(*),
        0
    ) AS pct_with_both_bp,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE COALESCE(o.has_oxygen, FALSE)
              AND COALESCE(o.has_respiratory_rate, FALSE)
        ) / COUNT(*),
        0
    ) AS pct_with_both_oxygen_and_respiratory_rate
FROM encounters e
LEFT JOIN observation_by_encounter o
    ON e.id = o.encounter
GROUP BY e.encounterclass
ORDER BY total_encounters DESC;

/* ============================================================
   9. PROJECT NOTES AND LIMITATIONS
   ============================================================ */

-- 1. This is a synthetic healthcare dataset, not real patient data.
-- 2. A recorded diagnosis does not prove that a procedure or encounter
--    was caused by that diagnosis.
-- 3. Healthcare expenses, encounter claim costs, procedure base costs,
--    medication costs, and payer coverage are different measures.
--    Do not add them together as if they were the same financial metric.
-- 4. Observation counts measure recorded rows, not clinical quality
--    or patient severity.
-- 5. Missing encounter reason codes limit conclusions about why
--    some healthcare services occurred.
-- 6. Age calculations use 2020-12-31 as the reference date.
