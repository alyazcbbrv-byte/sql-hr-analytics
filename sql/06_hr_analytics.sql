-- ============================================================================
-- 06  HR ANALYTICS: business questions answered with multi-step SQL
-- Snapshot date = the latest hire date in the data (2018-04-21), so results are reproducible.
-- ============================================================================

-- name: q28_compa_ratio_by_job
-- title: Compa-ratio by job
-- question: Relative to the midpoint of its pay band, is each job paid fairly? (compa-ratio = salary / band midpoint)
WITH c AS (
    SELECT j.job_title,
           e.salary,
           e.salary * 1.0 / ((j.min_salary + j.max_salary) / 2.0) AS compa
    FROM employees e
    JOIN jobs j ON j.job_id = e.job_id
)
SELECT job_title,
       COUNT(*)                          AS headcount,
       ROUND(AVG(compa), 2)              AS avg_compa_ratio,
       SUM(compa < 0.80)                 AS below_80pct,
       SUM(compa > 1.20)                 AS above_120pct
FROM c
GROUP BY job_title
HAVING COUNT(*) >= 2
ORDER BY avg_compa_ratio DESC;

-- name: q29_sales_total_compensation
-- title: Sales: salary plus commission
-- question: How much do commissions add to the sales payroll, and who earns the most in total? (monthly figures)
WITH s AS (
    SELECT e.employee_id,
           e.first_name || ' ' || e.last_name AS employee,
           j.job_title,
           e.salary,
           e.commission_pct,
           ROUND(e.salary * (1 + COALESCE(e.commission_pct, 0)), 0) AS total_comp
    FROM employees e
    JOIN jobs j ON j.job_id = e.job_id
    WHERE e.department_id = 80
)
SELECT job_title,
       COUNT(*)                                   AS headcount,
       SUM(salary)                                AS base_payroll,
       SUM(total_comp)                            AS total_comp,
       ROUND(100.0 * (SUM(total_comp) - SUM(salary)) / SUM(salary), 1) AS commission_uplift_pct,
       MAX(total_comp)                            AS highest_total_comp
FROM s
GROUP BY job_title
ORDER BY total_comp DESC;

-- name: q30_tenure_vs_salary
-- title: Tenure buckets and salary
-- question: Do longer-serving employees earn more? (tenure measured at the snapshot date)
WITH snap AS (SELECT MAX(hire_date) AS d FROM employees),
t AS (
    SELECT e.salary,
           (julianday(snap.d) - julianday(e.hire_date)) / 365.25 AS tenure_years
    FROM employees e, snap
)
SELECT CASE WHEN tenure_years < 2 THEN '1) under 2 years'
            WHEN tenure_years < 4 THEN '2) 2 - 4 years'
            WHEN tenure_years < 6 THEN '3) 4 - 6 years'
            ELSE                       '4) 6 years and more' END AS tenure_bucket,
       COUNT(*)                   AS headcount,
       ROUND(AVG(salary), 0)      AS avg_salary,
       ROUND(AVG(tenure_years), 1) AS avg_tenure_years
FROM t
GROUP BY tenure_bucket
ORDER BY tenure_bucket;

-- name: q31_career_moves
-- title: Career moves (job history)
-- question: Who changed roles before, how long did they stay in each, and where did they end up?
SELECT e.employee_id,
       e.first_name || ' ' || e.last_name AS employee,
       COUNT(*)                                              AS previous_roles,
       SUM(CAST(julianday(h.end_date) - julianday(h.start_date) AS INTEGER)) AS days_in_previous_roles,
       GROUP_CONCAT(j.job_title, ' > ')                      AS previous_jobs,
       (SELECT job_title FROM jobs WHERE job_id = e.job_id)  AS current_job
FROM job_history h
JOIN employees e ON e.employee_id = h.employee_id
JOIN jobs j      ON j.job_id = h.job_id
GROUP BY e.employee_id, e.first_name, e.last_name, e.job_id
ORDER BY previous_roles DESC, days_in_previous_roles DESC;

-- name: q32_department_scorecard
-- title: Department scorecard (capstone query)
-- question: One table for management: size, cost, share of payroll, tenure, commission and location of each department.
WITH snap AS (SELECT MAX(hire_date) AS d FROM employees),
stats AS (
    SELECT e.department_id,
           COUNT(*)                                                       AS headcount,
           SUM(e.salary)                                                  AS payroll,
           ROUND(AVG(e.salary), 0)                                        AS avg_salary,
           ROUND(AVG((julianday(snap.d) - julianday(e.hire_date)) / 365.25), 1) AS avg_tenure_years,
           SUM(e.commission_pct IS NOT NULL)                              AS on_commission
    FROM employees e, snap
    WHERE e.department_id IS NOT NULL
    GROUP BY e.department_id
)
SELECT d.department_name,
       m.first_name || ' ' || m.last_name AS manager,
       l.city || ', ' || c.country_name   AS location,
       s.headcount,
       s.payroll,
       ROUND(100.0 * s.payroll / SUM(s.payroll) OVER (), 1) AS pct_of_payroll,
       s.avg_salary,
       s.avg_tenure_years,
       s.on_commission
FROM stats s
JOIN departments d     ON d.department_id = s.department_id
LEFT JOIN employees m  ON m.employee_id = d.manager_id
JOIN locations l       ON l.location_id = d.location_id
JOIN countries c       ON c.country_id = l.country_id
ORDER BY s.payroll DESC;
