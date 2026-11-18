"""
Build the SQLite database (hr.db) from sql/00_schema.sql and the CSV files in data/,
then run data-quality and referential-integrity checks written in SQL.

    python src/build_db.py
"""
from __future__ import annotations

import csv
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DB = ROOT / "hr.db"
LOAD_ORDER = ["regions", "countries", "locations", "jobs", "departments", "employees", "job_history"]

# Each check is a SQL query that must return 0 rows (violations).
CHECKS = {
    "employees.department_id exists in departments": "SELECT e.employee_id FROM employees e LEFT JOIN departments d ON d.department_id = e.department_id WHERE e.department_id IS NOT NULL AND d.department_id IS NULL",
    "employees.job_id exists in jobs": "SELECT e.employee_id FROM employees e LEFT JOIN jobs j ON j.job_id = e.job_id WHERE j.job_id IS NULL",
    "employees.manager_id exists in employees": "SELECT e.employee_id FROM employees e LEFT JOIN employees m ON m.employee_id = e.manager_id WHERE e.manager_id IS NOT NULL AND m.employee_id IS NULL",
    "departments.manager_id exists in employees": "SELECT d.department_id FROM departments d LEFT JOIN employees e ON e.employee_id = d.manager_id WHERE d.manager_id IS NOT NULL AND e.employee_id IS NULL",
    "departments.location_id exists in locations": "SELECT d.department_id FROM departments d LEFT JOIN locations l ON l.location_id = d.location_id WHERE l.location_id IS NULL",
    "locations.country_id exists in countries": "SELECT l.location_id FROM locations l LEFT JOIN countries c ON c.country_id = l.country_id WHERE c.country_id IS NULL",
    "countries.region_id exists in regions": "SELECT c.country_id FROM countries c LEFT JOIN regions r ON r.region_id = c.region_id WHERE r.region_id IS NULL",
    "job_history references valid employee, job, department": "SELECT h.employee_id FROM job_history h LEFT JOIN employees e ON e.employee_id = h.employee_id LEFT JOIN jobs j ON j.job_id = h.job_id LEFT JOIN departments d ON d.department_id = h.department_id WHERE e.employee_id IS NULL OR j.job_id IS NULL OR d.department_id IS NULL",
    "exactly one employee without a manager (the CEO)": "SELECT 1 WHERE (SELECT COUNT(*) FROM employees WHERE manager_id IS NULL) <> 1",
    "no employee manages himself": "SELECT employee_id FROM employees WHERE manager_id = employee_id",
    "hire_date is a valid ISO date": "SELECT employee_id FROM employees WHERE date(hire_date) IS NULL OR date(hire_date) <> hire_date",
}
# Observations about the data itself (not integrity errors): reported as warnings.
WARNINGS = {
    "employee gets commission but has no Sales department": "SELECT employee_id FROM employees WHERE commission_pct IS NOT NULL AND COALESCE(department_id, -1) <> 80",
    "employee without a department": "SELECT employee_id FROM employees WHERE department_id IS NULL",
    "job_history period overlaps the current employment": "SELECT h.employee_id FROM job_history h JOIN employees e ON e.employee_id = h.employee_id WHERE h.end_date > e.hire_date",
}
EXPECTED_ROWS = {"regions": 4, "countries": 25, "locations": 23, "jobs": 19, "departments": 27, "employees": 107, "job_history": 10}


def value(v: str):
    return None if v == "" else v


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    if DB.exists():
        DB.unlink()
    con = sqlite3.connect(DB)
    con.executescript((ROOT / "sql" / "00_schema.sql").read_text(encoding="utf-8"))
    for t in LOAD_ORDER:
        with open(ROOT / "data" / f"{t}.csv", encoding="utf-8", newline="") as f:
            rows = list(csv.reader(f))
        head, body = rows[0], rows[1:]
        con.executemany(f"INSERT INTO {t} ({','.join(head)}) VALUES ({','.join('?' * len(head))})", [[value(x) for x in r] for r in body])
        n = con.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
        flag = "OK " if n == EXPECTED_ROWS[t] else "DIFF"
        print(f"{flag} {t:12s} {n:>4} rows")
    con.commit()

    bad = 0
    print("\nIntegrity and data-quality checks (each must return 0 rows):")
    for name, sql in CHECKS.items():
        n = len(con.execute(sql).fetchall())
        bad += n > 0
        print(("OK   " if n == 0 else f"FAIL ({n}) ") + name)
    fk = con.execute("PRAGMA foreign_key_check").fetchall()
    print(("OK   " if not fk else f"FAIL ({len(fk)}) ") + "PRAGMA foreign_key_check")
    print("\nData observations (warnings, not errors):")
    for name, sql in WARNINGS.items():
        n = len(con.execute(sql).fetchall())
        print(f"WARN ({n}) {name}")
    print(f"\nDatabase written to {DB.name}: {DB.stat().st_size/1024:.0f} KB")
    return 1 if bad or fk else 0


if __name__ == "__main__":
    raise SystemExit(main())
