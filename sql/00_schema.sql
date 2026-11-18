-- ============================================================================
-- HR database schema (SQLite, ANSI-style DDL)
-- Source model: the Oracle HR sample schema used in the SQL course.
-- ============================================================================
PRAGMA foreign_keys = ON;

CREATE TABLE regions (
    region_id    INTEGER PRIMARY KEY,
    region_name  TEXT NOT NULL
);

CREATE TABLE countries (
    country_id    TEXT PRIMARY KEY,
    country_name  TEXT NOT NULL,
    region_id     INTEGER NOT NULL REFERENCES regions (region_id)
);

CREATE TABLE locations (
    location_id     INTEGER PRIMARY KEY,
    street_address  TEXT,
    postal_code     TEXT,
    city            TEXT NOT NULL,
    state_province  TEXT,
    country_id      TEXT NOT NULL REFERENCES countries (country_id)
);

CREATE TABLE jobs (
    job_id      TEXT PRIMARY KEY,
    job_title   TEXT NOT NULL,
    min_salary  INTEGER,
    max_salary  INTEGER,
    CHECK (max_salary >= min_salary)
);

CREATE TABLE departments (
    department_id    INTEGER PRIMARY KEY,
    department_name  TEXT NOT NULL,
    manager_id       INTEGER,                       -- FK to employees, added after load (circular reference)
    location_id      INTEGER REFERENCES locations (location_id)
);

CREATE TABLE employees (
    employee_id     INTEGER PRIMARY KEY,
    first_name      TEXT,
    last_name       TEXT NOT NULL,
    email           TEXT NOT NULL UNIQUE,
    phone_number    TEXT,
    hire_date       TEXT NOT NULL,                  -- ISO date, YYYY-MM-DD
    job_id          TEXT NOT NULL REFERENCES jobs (job_id),
    salary          INTEGER NOT NULL CHECK (salary > 0),
    commission_pct  REAL,
    manager_id      INTEGER REFERENCES employees (employee_id),
    department_id   INTEGER REFERENCES departments (department_id)
);

CREATE TABLE job_history (
    employee_id    INTEGER NOT NULL REFERENCES employees (employee_id),
    start_date     TEXT NOT NULL,
    end_date       TEXT NOT NULL,
    job_id         TEXT NOT NULL REFERENCES jobs (job_id),
    department_id  INTEGER REFERENCES departments (department_id),
    PRIMARY KEY (employee_id, start_date),
    CHECK (end_date > start_date)
);

CREATE INDEX idx_emp_dept    ON employees (department_id);
CREATE INDEX idx_emp_job     ON employees (job_id);
CREATE INDEX idx_emp_manager ON employees (manager_id);
CREATE INDEX idx_dept_loc    ON departments (location_id);
CREATE INDEX idx_loc_country ON locations (country_id);
