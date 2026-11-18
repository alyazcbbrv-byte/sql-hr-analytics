"""
Prepare the CSV files of the HR database.

* employees      : read from the course workbook (107 rows, sheet "Data_1" of "SQL_SELF JOIN_4.xlsx")
* all other tables: the standard Oracle HR sample schema (regions, countries, locations, departments,
                    jobs, job_history), embedded below.

The course copy of the schema has every date moved forward by 10 years (employees.hire_date runs
2011-01-13 .. 2018-04-21 instead of 2001-01-13 .. 2008-04-21). job_history is shifted by the same
10 years so both tables stay consistent with each other.

Usage:
    python src/prepare_data.py --employees "SQL_SELF JOIN_4.xlsx"
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import pandas as pd

OUT = Path(__file__).resolve().parents[1] / "data"
YEARS_SHIFT = 10

REGIONS = [(1, "Europe"), (2, "Americas"), (3, "Asia"), (4, "Middle East and Africa")]

COUNTRIES = [  # id, name, region_id
    ("AR", "Argentina", 2), ("AU", "Australia", 3), ("BE", "Belgium", 1), ("BR", "Brazil", 2), ("CA", "Canada", 2),
    ("CH", "Switzerland", 1), ("CN", "China", 3), ("DE", "Germany", 1), ("DK", "Denmark", 1), ("EG", "Egypt", 4),
    ("FR", "France", 1), ("HK", "HongKong", 3), ("IL", "Israel", 4), ("IN", "India", 3), ("IT", "Italy", 1),
    ("JP", "Japan", 3), ("KW", "Kuwait", 4), ("MX", "Mexico", 2), ("NG", "Nigeria", 4), ("NL", "Netherlands", 1),
    ("SG", "Singapore", 3), ("UK", "United Kingdom", 1), ("US", "United States of America", 2), ("ZM", "Zambia", 4),
    ("ZW", "Zimbabwe", 4),
]

LOCATIONS = [  # id, street_address, postal_code, city, state_province, country_id
    (1000, "1297 Via Cola di Rie", "00989", "Roma", None, "IT"),
    (1100, "93091 Calle della Testa", "10934", "Venice", None, "IT"),
    (1200, "2017 Shinjuku-ku", "1689", "Tokyo", "Tokyo Prefecture", "JP"),
    (1300, "9450 Kamiya-cho", "6823", "Hiroshima", None, "JP"),
    (1400, "2014 Jabberwocky Rd", "26192", "Southlake", "Texas", "US"),
    (1500, "2011 Interiors Blvd", "99236", "South San Francisco", "California", "US"),
    (1600, "2007 Zagora St", "50090", "South Brunswick", "New Jersey", "US"),
    (1700, "2004 Charade Rd", "98199", "Seattle", "Washington", "US"),
    (1800, "147 Spadina Ave", "M5V 2L7", "Toronto", "Ontario", "CA"),
    (1900, "6092 Boxwood St", "YSW 9T2", "Whitehorse", "Yukon", "CA"),
    (2000, "40-5-12 Laogianggen", "190518", "Beijing", None, "CN"),
    (2100, "1298 Vileparle (E)", "490231", "Bombay", "Maharashtra", "IN"),
    (2200, "12-98 Victoria Street", "2901", "Sydney", "New South Wales", "AU"),
    (2300, "198 Clementi North", "540198", "Singapore", None, "SG"),
    (2400, "8204 Arthur St", None, "London", None, "UK"),
    (2500, "Magdalen Centre, The Oxford Science Park", "OX9 9ZB", "Oxford", "Oxford", "UK"),
    (2600, "9702 Chester Road", "09629850293", "Stretford", "Manchester", "UK"),
    (2700, "Schwanthalerstr. 7031", "80925", "Munich", "Bavaria", "DE"),
    (2800, "Rua Frei Caneca 1360", "01307-002", "Sao Paulo", "Sao Paulo", "BR"),
    (2900, "20 Rue des Corps-Saints", "1730", "Geneva", "Geneve", "CH"),
    (3000, "Murtenstrasse 921", "3095", "Bern", "BE", "CH"),
    (3100, "Pieter Breughelstraat 837", "3029SK", "Utrecht", "Utrecht", "NL"),
    (3200, "Mariano Escobedo 9991", "11932", "Mexico City", "Distrito Federal,", "MX"),
]

DEPARTMENTS = [  # id, name, manager_id, location_id
    (10, "Administration", 200, 1700), (20, "Marketing", 201, 1800), (30, "Purchasing", 114, 1700),
    (40, "Human Resources", 203, 2400), (50, "Shipping", 121, 1500), (60, "IT", 103, 1400),
    (70, "Public Relations", 204, 2700), (80, "Sales", 145, 2500), (90, "Executive", 100, 1700),
    (100, "Finance", 108, 1700), (110, "Accounting", 205, 1700), (120, "Treasury", None, 1700),
    (130, "Corporate Tax", None, 1700), (140, "Control And Credit", None, 1700), (150, "Shareholder Services", None, 1700),
    (160, "Benefits", None, 1700), (170, "Manufacturing", None, 1700), (180, "Construction", None, 1700),
    (190, "Contracting", None, 1700), (200, "Operations", None, 1700), (210, "IT Support", None, 1700),
    (220, "NOC", None, 1700), (230, "IT Helpdesk", None, 1700), (240, "Government Sales", None, 1700),
    (250, "Retail Sales", None, 1700), (260, "Recruiting", None, 1700), (270, "Payroll", None, 1700),
]

JOBS = [  # id, title, min_salary, max_salary
    ("AD_PRES", "President", 20080, 40000), ("AD_VP", "Administration Vice President", 15000, 30000),
    ("AD_ASST", "Administration Assistant", 3000, 6000), ("FI_MGR", "Finance Manager", 8200, 16000),
    ("FI_ACCOUNT", "Accountant", 4200, 9000), ("AC_MGR", "Accounting Manager", 8200, 16000),
    ("AC_ACCOUNT", "Public Accountant", 4200, 9000), ("SA_MAN", "Sales Manager", 10000, 20080),
    ("SA_REP", "Sales Representative", 6000, 12008), ("PU_MAN", "Purchasing Manager", 8000, 15000),
    ("PU_CLERK", "Purchasing Clerk", 2500, 5500), ("ST_MAN", "Stock Manager", 5500, 8500),
    ("ST_CLERK", "Stock Clerk", 2008, 5000), ("SH_CLERK", "Shipping Clerk", 2500, 5500),
    ("IT_PROG", "Programmer", 4000, 10000), ("MK_MAN", "Marketing Manager", 9000, 15000),
    ("MK_REP", "Marketing Representative", 4000, 9000), ("HR_REP", "Human Resources Representative", 4000, 9000),
    ("PR_REP", "Public Relations Representative", 4500, 10500),
]

JOB_HISTORY = [  # employee_id, start_date, end_date, job_id, department_id  (standard dates, shifted below)
    (102, "2001-01-13", "2006-07-24", "IT_PROG", 60), (101, "1997-09-21", "2001-10-27", "AC_ACCOUNT", 110),
    (101, "2001-10-28", "2005-03-15", "AC_MGR", 110), (201, "2004-02-17", "2007-12-19", "MK_REP", 20),
    (114, "2006-03-24", "2007-12-31", "ST_CLERK", 50), (122, "2007-01-01", "2007-12-31", "ST_CLERK", 50),
    (200, "1995-09-17", "2001-06-17", "AD_ASST", 90), (176, "2006-03-24", "2006-12-31", "SA_REP", 80),
    (176, "2007-01-01", "2007-12-31", "SA_MAN", 80), (200, "2002-07-01", "2006-12-31", "AC_ACCOUNT", 90),
]


def load_employees(path: Path) -> pd.DataFrame:
    df = pd.read_excel(path, sheet_name="Data_1")
    cols = ["EMPLOYEE_ID", "FIRST_NAME", "LAST_NAME", "EMAIL", "PHONE_NUMBER", "HIRE_DATE", "JOB_ID", "SALARY",
            "COMMISSION_PCT", "MANAGER_ID", "DEPARTMENT_ID"]
    df = df[[c for c in df.columns if str(c).upper() in cols]]
    df.columns = [c.lower() for c in df.columns]
    df["hire_date"] = pd.to_datetime(df["hire_date"]).dt.strftime("%Y-%m-%d")
    for c in ("employee_id", "salary", "manager_id", "department_id"):
        df[c] = df[c].astype("Int64")
    return df.sort_values("employee_id").reset_index(drop=True)


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--employees", required=True, type=Path)
    a = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)

    emp = load_employees(a.employees)
    jh = pd.DataFrame(JOB_HISTORY, columns=["employee_id", "start_date", "end_date", "job_id", "department_id"])
    for c in ("start_date", "end_date"):
        jh[c] = (pd.to_datetime(jh[c]) + pd.DateOffset(years=YEARS_SHIFT)).dt.strftime("%Y-%m-%d")

    tables = {
        "regions": pd.DataFrame(REGIONS, columns=["region_id", "region_name"]),
        "countries": pd.DataFrame(COUNTRIES, columns=["country_id", "country_name", "region_id"]),
        "locations": pd.DataFrame(LOCATIONS, columns=["location_id", "street_address", "postal_code", "city", "state_province", "country_id"]),
        "departments": pd.DataFrame(DEPARTMENTS, columns=["department_id", "department_name", "manager_id", "location_id"]),
        "jobs": pd.DataFrame(JOBS, columns=["job_id", "job_title", "min_salary", "max_salary"]),
        "employees": emp,
        "job_history": jh,
    }
    for name, df in tables.items():
        df.to_csv(OUT / f"{name}.csv", index=False, encoding="utf-8")
        print(f"{name:12s} {len(df):>4} rows -> data/{name}.csv")
    print("employees: salary total", int(emp["salary"].sum()), "| hire_date", emp["hire_date"].min(), "->", emp["hire_date"].max())


if __name__ == "__main__":
    main()
