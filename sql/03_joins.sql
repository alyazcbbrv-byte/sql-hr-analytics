-- ============================================================================
-- 03  JOINS: multi-table INNER / LEFT joins, anti-join, self join
-- ============================================================================

-- name: q12_employee_roster_geo
-- title: Employee roster with job, department, city, country and region
-- question: Give me one denormalised roster (a 6-table join).
SELECT e.employee_id,
       e.first_name || ' ' || e.last_name AS employee,
       j.job_title,
       d.department_name,
       l.city,
       c.country_name,
       r.region_name,
       e.salary
FROM employees e
JOIN jobs j        ON j.job_id = e.job_id
JOIN departments d ON d.department_id = e.department_id
JOIN locations l   ON l.location_id = d.location_id
JOIN countries c   ON c.country_id = l.country_id
JOIN regions r     ON r.region_id = c.region_id
ORDER BY r.region_name, c.country_name, l.city, e.employee_id;

-- name: q13_headcount_by_country
-- title: Headcount and payroll by country (LEFT JOINs keep empty countries)
-- question: Where do our people sit, and which countries have a location but nobody working there?
SELECT r.region_name,
       c.country_name,
       COUNT(DISTINCT l.location_id)         AS locations,
       COUNT(e.employee_id)                  AS headcount,
       COALESCE(SUM(e.salary), 0)            AS payroll
FROM countries c
JOIN regions r         ON r.region_id = c.region_id
JOIN locations l       ON l.country_id = c.country_id
LEFT JOIN departments d ON d.location_id = l.location_id
LEFT JOIN employees e   ON e.department_id = d.department_id
GROUP BY r.region_name, c.country_name
ORDER BY headcount DESC, c.country_name;

-- name: q14_departments_without_staff
-- title: Departments with no employees (anti-join)
-- question: Which departments exist on paper but have nobody assigned?
SELECT d.department_id, d.department_name,
       COALESCE(d.manager_id, 0) AS manager_id
FROM departments d
LEFT JOIN employees e ON e.department_id = d.department_id
WHERE e.employee_id IS NULL
ORDER BY d.department_id;

-- name: q15_employee_and_manager
-- title: Employees and their managers (self join)
-- question: Who reports to whom? Show each employee with the manager's name.
SELECT e.employee_id,
       e.first_name || ' ' || e.last_name                         AS employee,
       COALESCE(m.first_name || ' ' || m.last_name, '(top of the organisation)') AS manager,
       e.salary,
       m.salary                                                   AS manager_salary
FROM employees e
LEFT JOIN employees m ON m.employee_id = e.manager_id
ORDER BY (m.employee_id IS NULL) DESC, m.last_name, e.last_name
LIMIT 15;

-- name: q16_salary_outside_job_range
-- title: Check: employees paid outside their job band
-- question: Who is paid below the minimum or above the maximum defined for the job?
SELECT e.employee_id,
       e.first_name || ' ' || e.last_name AS employee,
       j.job_title,
       e.salary, j.min_salary, j.max_salary,
       CASE WHEN e.salary < j.min_salary THEN 'below band' ELSE 'above band' END AS position,
       CASE WHEN e.salary < j.min_salary THEN j.min_salary - e.salary
            ELSE e.salary - j.max_salary END AS distance_from_band
FROM employees e
JOIN jobs j ON j.job_id = e.job_id
WHERE e.salary < j.min_salary OR e.salary > j.max_salary
ORDER BY distance_from_band DESC;

-- name: q17_headcount_by_city
-- title: Headcount by city
-- question: Which office cities host the most employees?
SELECT l.city, c.country_name,
       COUNT(e.employee_id) AS headcount,
       SUM(e.salary)        AS payroll
FROM employees e
JOIN departments d ON d.department_id = e.department_id
JOIN locations l   ON l.location_id = d.location_id
JOIN countries c   ON c.country_id = l.country_id
GROUP BY l.location_id, l.city, c.country_name
ORDER BY headcount DESC;
