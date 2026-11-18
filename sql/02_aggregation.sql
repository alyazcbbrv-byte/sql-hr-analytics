-- ============================================================================
-- 02  AGGREGATION: COUNT / SUM / AVG, GROUP BY, HAVING, CASE, date parts
-- ============================================================================

-- name: q06_department_summary
-- title: Headcount and payroll by department
-- question: How big is each department and what does it cost per month?
SELECT COALESCE(d.department_name, '(no department)') AS department,
       COUNT(*)                         AS headcount,
       SUM(e.salary)                    AS payroll,
       ROUND(AVG(e.salary), 0)          AS avg_salary,
       MIN(e.salary)                    AS min_salary,
       MAX(e.salary)                    AS max_salary
FROM employees e
LEFT JOIN departments d ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name
ORDER BY payroll DESC;

-- name: q07_departments_above_average_payroll
-- title: Departments whose payroll exceeds the average department payroll
-- question: Which departments are more expensive than a typical department? (HAVING + subquery)
SELECT d.department_name,
       SUM(e.salary) AS payroll
FROM employees e
JOIN departments d ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name
HAVING SUM(e.salary) > (SELECT AVG(dept_payroll)
                        FROM (SELECT SUM(salary) AS dept_payroll
                              FROM employees
                              WHERE department_id IS NOT NULL
                              GROUP BY department_id))
ORDER BY payroll DESC;

-- name: q08_hires_by_year
-- title: Hiring by year
-- question: In which years did the company hire most, and what do those cohorts earn today?
SELECT CAST(strftime('%Y', hire_date) AS INTEGER) AS hire_year,
       COUNT(*)                AS hires,
       ROUND(AVG(salary), 0)   AS avg_salary_today,
       SUM(salary)             AS cohort_payroll
FROM employees
GROUP BY hire_year
ORDER BY hire_year;

-- name: q09_hires_by_month
-- title: Hiring seasonality
-- question: Which calendar months see the most hiring (all years combined)?
SELECT strftime('%m', hire_date) AS month,
       COUNT(*)                  AS hires
FROM employees
GROUP BY month
ORDER BY hires DESC, month
LIMIT 6;

-- name: q10_salary_bands
-- title: Salary bands
-- question: How is the workforce distributed across pay bands and how much payroll does each band take?
SELECT CASE
           WHEN salary < 3000  THEN '1) under 3,000'
           WHEN salary < 5000  THEN '2) 3,000 - 4,999'
           WHEN salary < 8000  THEN '3) 5,000 - 7,999'
           WHEN salary < 12000 THEN '4) 8,000 - 11,999'
           WHEN salary < 20000 THEN '5) 12,000 - 19,999'
           ELSE                     '6) 20,000 and above'
       END AS salary_band,
       COUNT(*)                                             AS headcount,
       SUM(salary)                                          AS payroll,
       ROUND(100.0 * SUM(salary) / (SELECT SUM(salary) FROM employees), 1) AS pct_of_payroll
FROM employees
GROUP BY salary_band
ORDER BY salary_band;

-- name: q11_job_summary
-- title: Headcount and pay by job
-- question: Which jobs are the largest and what is the pay spread inside each job?
SELECT j.job_title,
       COUNT(*)                AS headcount,
       ROUND(AVG(e.salary), 0) AS avg_salary,
       MIN(e.salary)           AS min_salary,
       MAX(e.salary)           AS max_salary
FROM employees e
JOIN jobs j ON j.job_id = e.job_id
GROUP BY j.job_id, j.job_title
ORDER BY headcount DESC, avg_salary DESC;
