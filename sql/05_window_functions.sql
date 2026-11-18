-- ============================================================================
-- 05  WINDOW FUNCTIONS: ROW_NUMBER / RANK, AVG OVER, LAG, running totals, NTILE
-- ============================================================================

-- name: q23_top3_per_department
-- title: Top 3 earners in every department
-- question: Who are the three best-paid people of each department? (DENSE_RANK per partition)
WITH ranked AS (
    SELECT d.department_name,
           e.first_name || ' ' || e.last_name AS employee,
           e.salary,
           DENSE_RANK() OVER (PARTITION BY e.department_id ORDER BY e.salary DESC) AS rnk
    FROM employees e
    JOIN departments d ON d.department_id = e.department_id
)
SELECT department_name, rnk AS rank, employee, salary
FROM ranked
WHERE rnk <= 3
ORDER BY department_name, rnk, employee;

-- name: q24_salary_vs_department_average
-- title: Distance from the department average
-- question: How far is each person from the department average, and where do they sit in the pay ranking?
WITH x AS (
    SELECT d.department_name,
           e.first_name || ' ' || e.last_name AS employee,
           e.salary,
           ROUND(AVG(e.salary) OVER (PARTITION BY e.department_id), 0)  AS dept_avg,
           COUNT(*)            OVER (PARTITION BY e.department_id)      AS dept_size,
           ROUND(PERCENT_RANK() OVER (PARTITION BY e.department_id ORDER BY e.salary), 2) AS pay_percentile
    FROM employees e
    JOIN departments d ON d.department_id = e.department_id
)
SELECT department_name, employee, salary, dept_avg,
       salary - dept_avg AS diff_from_avg,
       pay_percentile
FROM x
WHERE dept_size >= 5
ORDER BY diff_from_avg DESC
LIMIT 10;

-- name: q25_hiring_trend
-- title: Hiring trend with running total and year-over-year change
-- question: How did the headcount build up year by year? (SUM OVER, LAG)
WITH yearly AS (
    SELECT CAST(strftime('%Y', hire_date) AS INTEGER) AS hire_year,
           COUNT(*) AS hires
    FROM employees
    GROUP BY hire_year
)
SELECT hire_year,
       hires,
       SUM(hires) OVER (ORDER BY hire_year)                               AS cumulative_headcount,
       hires - LAG(hires) OVER (ORDER BY hire_year)                       AS change_vs_prev_year,
       ROUND(100.0 * (hires - LAG(hires) OVER (ORDER BY hire_year))
             / LAG(hires) OVER (ORDER BY hire_year), 0)                   AS pct_change
FROM yearly
ORDER BY hire_year;

-- name: q26_payroll_concentration
-- title: Payroll concentration by pay decile
-- question: What share of the payroll goes to the top 10% earners? (NTILE)
WITH d AS (
    SELECT salary,
           NTILE(10) OVER (ORDER BY salary DESC, employee_id) AS decile
    FROM employees
)
SELECT decile,
       COUNT(*)                 AS employees,
       MIN(salary)              AS from_salary,
       MAX(salary)              AS to_salary,
       SUM(salary)              AS payroll,
       ROUND(100.0 * SUM(salary) / SUM(SUM(salary)) OVER (), 1)              AS pct_of_payroll,
       ROUND(100.0 * SUM(SUM(salary)) OVER (ORDER BY decile) / SUM(SUM(salary)) OVER (), 1) AS cumulative_pct
FROM d
GROUP BY decile
ORDER BY decile;

-- name: q27_salary_compression
-- title: Salary compression inside a job
-- question: Do newcomers earn as much as, or more than, the longest-serving colleagues in the same job? (FIRST_VALUE / LAST_VALUE)
WITH w AS (
    SELECT j.job_title,
           e.hire_date,
           e.salary,
           COUNT(*) OVER (PARTITION BY e.job_id) AS job_size,
           FIRST_VALUE(e.salary) OVER (PARTITION BY e.job_id ORDER BY e.hire_date, e.employee_id
                                       ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS salary_of_longest_serving,
           LAST_VALUE(e.salary)  OVER (PARTITION BY e.job_id ORDER BY e.hire_date, e.employee_id
                                       ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS salary_of_newest_hire,
           FIRST_VALUE(e.hire_date) OVER (PARTITION BY e.job_id ORDER BY e.hire_date, e.employee_id
                                       ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS first_hire
    FROM employees e
    JOIN jobs j ON j.job_id = e.job_id
)
SELECT DISTINCT job_title, job_size,
       salary_of_longest_serving,
       salary_of_newest_hire,
       salary_of_newest_hire - salary_of_longest_serving AS newest_minus_longest,
       CASE WHEN salary_of_newest_hire >= salary_of_longest_serving THEN 'compressed' ELSE 'normal' END AS status
FROM w
WHERE job_size >= 3
ORDER BY newest_minus_longest DESC;
