-- ============================================================================
-- 04  SUBQUERIES AND CTEs: correlated subqueries, EXISTS, CTE, recursive CTE
-- ============================================================================

-- name: q18_above_department_average
-- title: Employees paid above their own department's average (correlated subquery)
-- question: Who earns noticeably more than colleagues in the same department?
SELECT e.employee_id,
       e.first_name || ' ' || e.last_name AS employee,
       d.department_name,
       e.salary,
       ROUND((SELECT AVG(x.salary) FROM employees x WHERE x.department_id = e.department_id), 0) AS dept_avg,
       ROUND(100.0 * (e.salary / (SELECT AVG(x.salary) FROM employees x WHERE x.department_id = e.department_id) - 1), 0) AS pct_above_avg
FROM employees e
JOIN departments d ON d.department_id = e.department_id
WHERE e.salary > (SELECT AVG(x.salary) FROM employees x WHERE x.department_id = e.department_id)
ORDER BY pct_above_avg DESC
LIMIT 10;

-- name: q19_span_of_control
-- title: Span of control: managers with the most direct reports (CTE)
-- question: Which managers carry the biggest teams and payroll responsibility?
WITH reports AS (
    SELECT manager_id,
           COUNT(*)      AS direct_reports,
           SUM(salary)   AS reports_payroll
    FROM employees
    WHERE manager_id IS NOT NULL
    GROUP BY manager_id
)
SELECT m.employee_id,
       m.first_name || ' ' || m.last_name AS manager,
       j.job_title,
       r.direct_reports,
       r.reports_payroll
FROM reports r
JOIN employees m ON m.employee_id = r.manager_id
JOIN jobs j      ON j.job_id = m.job_id
ORDER BY r.direct_reports DESC, r.reports_payroll DESC
LIMIT 10;

-- name: q20_org_hierarchy_levels
-- title: Organisation depth (recursive CTE)
-- question: How many management layers are there and how many people sit on each layer?
WITH RECURSIVE org (employee_id, manager_id, level) AS (
    SELECT employee_id, manager_id, 0
    FROM employees
    WHERE manager_id IS NULL
    UNION ALL
    SELECT e.employee_id, e.manager_id, org.level + 1
    FROM employees e
    JOIN org ON e.manager_id = org.employee_id
)
SELECT org.level,
       COUNT(*)                   AS employees,
       ROUND(AVG(e.salary), 0)    AS avg_salary
FROM org
JOIN employees e ON e.employee_id = org.employee_id
GROUP BY org.level
ORDER BY org.level;

-- name: q21_departments_with_high_earners
-- title: Departments that employ at least one person above 12,000 (EXISTS)
-- question: Which departments have high earners on the payroll?
SELECT d.department_name,
       (SELECT COUNT(*) FROM employees e WHERE e.department_id = d.department_id AND e.salary > 12000) AS high_earners
FROM departments d
WHERE EXISTS (SELECT 1 FROM employees e
              WHERE e.department_id = d.department_id AND e.salary > 12000)
ORDER BY high_earners DESC, d.department_name;

-- name: q22_hired_before_manager
-- title: Employees who joined before their own manager
-- question: Where do juniors-by-title have longer tenure than their boss? (a retention / promotion signal)
SELECT COUNT(*) AS employees_hired_before_manager,
       (SELECT COUNT(*) FROM employees WHERE manager_id IS NOT NULL) AS employees_with_manager,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM employees WHERE manager_id IS NOT NULL), 1) AS pct
FROM employees e
JOIN employees m ON m.employee_id = e.manager_id
WHERE e.hire_date < m.hire_date;
