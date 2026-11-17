# Healthcare Data Analysis | PostgreSQL

## Project Overview

This project explores a synthetic healthcare dataset using PostgreSQL to understand patient demographics, healthcare expenses, encounter utilization, recorded conditions, medication costs, procedure costs, and clinical observations.

The objective is to demonstrate practical SQL skills, including data profiling, data quality validation, joins, Common Table Expressions (CTEs), aggregate functions, window functions, and healthcare data analysis.

## Dataset

- **Dataset:** Synthetic COVID-19 / Synthea healthcare dataset
- **Database:** PostgreSQL
- **Tables selected:** 6

The project uses the following tables:

| Table | Description |
|---|---|
| patients | Patient demographics and healthcare expenses |
| encounters | Healthcare visits and encounter costs |
| conditions | Recorded patient conditions and diagnoses |
| medications | Medication records, costs, and payer coverage |
| procedures | Medical procedures and recorded base costs |
| observations | Clinical measurements and laboratory observations |

CSV files were imported into PostgreSQL using pgAdmin.

## Tools and Technologies

- PostgreSQL
- pgAdmin 4
- SQL

## Data Preparation and Quality Checks

Before performing the analysis, data profiling and quality checks were conducted to understand the dataset and validate its consistency.

The checks included:

- Row counts across the six selected tables.
- Missing values and invalid dates.
- Negative financial values.
- Duplicate and missing patient identifiers.
- Patient and encounter reference integrity across related tables.
- Missing encounter reason codes.

The reference checks found no unmatched patient or encounter references in the checked child tables.

## SQL Analysis and Key Findings

### 1. Patient Profile and Healthcare Expenses

Analyzed patient demographics, healthcare expenses, and recorded healthcare coverage.

Key findings:
- The dataset contains **12,352 patients**.
- Approximately 51% of patients are female and 49% are male.
- The High healthcare expense category represents approximately 43% of patients.
- Average healthcare expenses were approximately $823,340 per patient.
- Average recorded healthcare coverage was approximately $13,144 per patient.

### 2. Healthcare Encounter Trends

Analyzed monthly encounter patterns, encounter types, patient utilization, and encounter costs.

Key findings:
- The dataset contains **321,528 encounter records**.
- March 2020 recorded the highest monthly encounter volume in the analyzed period, with 12,303 encounters.
- Ambulatory encounters represented approximately 68% of March 2020 encounters.
- Patients with more than 20 encounters accounted for approximately 82% of all encounters.
- Higher encounter-frequency groups generally had higher average encounter claim costs and healthcare expenses.

### 3. Condition and COVID-19 Analysis

Explored frequently recorded conditions, monthly COVID-19 diagnosis records, patient age and gender distributions, and encounter costs by recorded COVID-19 diagnosis status.

Key findings:
- Suspected COVID-19 and COVID-19 were the two most frequently recorded conditions.
- **8,820 patients** had a recorded COVID-19 diagnosis.
- March 2020 accounted for approximately 79% of recorded COVID-19 diagnosis records.
- The 60+ age group had the highest number of recorded COVID-19 patients among the age groups analyzed.
- Average encounter claim costs were approximately $129 in both recorded COVID-19 groups.

### 4. Medication Utilization and Cost

Ranked medications by total recorded medication cost while examining medication record frequency and payer coverage.

Key findings:
- Simvastatin had the highest total recorded medication cost, at approximately $155.3 million.
- Hydrochlorothiazide had the highest medication record count among the top 10 medications, with 53,716 records.
- Humulin had the highest recorded payer coverage percentage among the top 10 medications, at approximately 22%.

### 5. Procedure Utilization and Cost

Analyzed frequently recorded procedures, total procedure base costs, average costs, and procedure costs by recorded COVID-19 diagnosis status.

Key findings:
- Electrical cardioversion had the highest total recorded procedure base cost, at approximately $44.6 million.
- Coronary artery bypass grafting had the highest average base cost per procedure record among the top 10.
- Oxygen administration by mask had the highest procedure record count among the top 10.
- The highest-cost procedures differed between the recorded COVID-19 and no-recorded-COVID-19 groups.

### 6. Clinical Observations and Monitoring

Explored frequently recorded clinical observations and examined observation patterns by patient utilization group and encounter type.

Key findings:
- Systolic and diastolic blood pressure were the most frequently recorded observations, with 48,132 records each.
- Respiratory rate, body weight, and heart rate each had 46,332 records.
- Patients in the more-than-20-encounter group had the highest average observation count, at approximately 211 observations per patient.
- Inpatient encounters had the highest average observation count among encounter types when observations were recorded.

## Project Limitations

- This is a synthetic dataset and does not represent actual patient records.
- A recorded COVID-19 diagnosis does not establish that a procedure or encounter was caused by COVID-19.
- Healthcare expenses, encounter claim costs, procedure base costs, medication costs, and payer coverage represent different financial measures and should not be treated as interchangeable.
- Observation counts represent recorded data volume, not clinical quality or patient severity.
- Missing encounter reason codes limit the ability to determine why certain healthcare services occurred.
- Patient age calculations use December 31, 2020, as the reference date.
- Expense categories and encounter-frequency groups are analyst-defined categories used for this analysis.

## Project Structure

```text
project3-healthcare-analysis/
│
├── sql/
│   └── healthcare_analysis.sql
│
├── python/
│   └── healthcare_analysis.ipynb
│
├── powerbi/
│   └── healthcare_dashboard.pbix
│
├── screenshots/
│
└── README.md
```

## Future Work

- **Python:** Perform additional data exploration, analysis, and visualization.
- **Power BI:** Develop an interactive healthcare dashboard to present key findings and trends.

---

*This project is part of my Data Analytics portfolio, demonstrating SQL-based data preparation, validation, analysis, and interpretation using healthcare data.*
