-- ============================================================================
-- 01  BASICS: SELECT, WHERE, ORDER BY, LIKE, NULL handling, simple joins
-- ============================================================================

-- name: q01_top_earners
-- title: Top 10 highest-paid employees
-- question: Who earns the most, in which job and department?
SELECT e.employee_id,
       e.first_name || ' ' || e.last_name AS employee,
       j.job_title,
       COALESCE(d.department_name, '(none)') AS department,
       e.salary
FROM employees e
JOIN jobs j             ON j.job_id = e.job_id
LEFT JOIN departments d ON d.department_id = e.department_id
ORDER BY e.salary DESC, e.employee_id
LIMIT 10;

-- name: q02_recent_it_hires
-- title: Programmers hired since 2015
-- question: Which IT programmers joined from 2015 on, newest first?
SELECT employee_id,
       first_name || ' ' || last_name AS employee,
       hire_date,
       salary
FROM employees
WHERE job_id = 'IT_PROG'
  AND hire_date >= '2015-01-01'
ORDER BY hire_date DESC;

-- name: q03_management_jobs
-- title: Management job titles and their pay ranges
-- question: Which job titles are management roles and what are their salary bands?
SELECT job_id, job_title, min_salary, max_salary,
       max_salary - min_salary AS range_width
FROM jobs
WHERE job_title LIKE '%Manager%' OR job_title LIKE '%President%'
ORDER BY max_salary DESC;

-- name: q04_commission_coverage
-- title: Who gets a commission?
-- question: How many employees have a commission, and how many have NULL?
SELECT COUNT(*)                                        AS employees,
       COUNT(commission_pct)                           AS with_commission,
       COUNT(*) - COUNT(commission_pct)                AS without_commission,
       ROUND(100.0 * COUNT(commission_pct) / COUNT(*), 1) AS pct_with_commission
FROM employees;

-- name: q05_employee_without_department
-- title: Employees that are not assigned to a department
-- question: Is anybody missing a department? (NULL handling with LEFT JOIN)
SELECT e.employee_id, e.first_name || ' ' || e.last_name AS employee,
       e.job_id, e.salary, e.commission_pct
FROM employees e
LEFT JOIN departments d ON d.department_id = e.department_id
WHERE d.department_id IS NULL;
