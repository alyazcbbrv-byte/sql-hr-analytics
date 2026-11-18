"""
Draw charts from the query results (results/*.csv) into images/.

    python src/make_charts.py
"""
from __future__ import annotations

import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as mtick
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RES, IMG = ROOT / "results", ROOT / "images"

NAVY, TEAL, AMBER, RED, GREY, TEXT, SUB = "#14213D", "#2A9D8F", "#F4A259", "#D1495B", "#B8C0CC", "#1F2933", "#6B7785"
plt.rcParams.update({
    "font.family": ["Segoe UI", "DejaVu Sans", "Arial"], "font.size": 10, "text.color": TEXT, "axes.labelcolor": SUB,
    "axes.edgecolor": GREY, "axes.spines.top": False, "axes.spines.right": False, "axes.grid": True, "axes.grid.axis": "x",
    "grid.color": "#E9EDF2", "axes.axisbelow": True, "xtick.color": SUB, "ytick.color": TEXT, "figure.facecolor": "white",
    "savefig.facecolor": "white", "savefig.dpi": 150, "legend.frameon": False,
})


def title(ax, head: str, sub: str) -> None:
    ax.text(0, 1.14, head, transform=ax.transAxes, fontsize=13, fontweight="bold", va="bottom")
    ax.text(0, 1.05, sub, transform=ax.transAxes, fontsize=9, color=SUB, va="bottom")


def payroll_by_department(ax) -> None:
    d = pd.read_csv(RES / "q06_department_summary.csv")
    d = d[d["department"] != "(no department)"].sort_values("payroll")
    colors = [AMBER if p == d["payroll"].max() else NAVY for p in d["payroll"]]
    ax.barh(d["department"], d["payroll"], color=colors, height=0.68)
    total = d["payroll"].sum()
    for y, (p, h) in enumerate(zip(d["payroll"], d["headcount"])):
        ax.text(p, y, f"  {p:,.0f}  ·  {h} people  ·  {p/total:.0%}", va="center", fontsize=8, color=TEXT)
    ax.set_xlim(0, d["payroll"].max() * 1.62)
    ax.xaxis.set_major_formatter(mtick.FuncFormatter(lambda x, _: f"{x/1000:,.0f}k"))
    title(ax, "Sales and Shipping take two thirds of the payroll", "Monthly payroll by department · people · share of total")


def hiring_trend(ax) -> None:
    d = pd.read_csv(RES / "q25_hiring_trend.csv")
    ax.bar(d["hire_year"].astype(str), d["hires"], color=TEAL, width=0.62)
    for x, h in zip(d["hire_year"].astype(str), d["hires"]):
        ax.text(x, h + 0.6, str(h), ha="center", fontsize=9, fontweight="bold")
    ax.set_ylabel("Hires per year")
    ax.grid(axis="y", color="#E9EDF2"); ax.grid(axis="x", visible=False)
    ax2 = ax.twinx(); ax2.spines["right"].set_visible(True); ax2.spines["right"].set_color(GREY)
    ax2.plot(d["hire_year"].astype(str), d["cumulative_headcount"], color=NAVY, marker="o", lw=2)
    ax2.set_ylabel("Cumulative headcount"); ax2.set_ylim(0, 120); ax2.grid(False)
    title(ax, "Hiring peaked in 2015 and has slowed every year since", "Hires per year (bars) and cumulative headcount (line)")


def compa_ratio(ax) -> None:
    d = pd.read_csv(RES / "q28_compa_ratio_by_job.csv").sort_values("avg_compa_ratio")
    colors = [RED if v < 0.8 else (AMBER if v > 1.1 else NAVY) for v in d["avg_compa_ratio"]]
    ax.barh(d["job_title"], d["avg_compa_ratio"], color=colors, height=0.66)
    ax.axvline(1.0, color=SUB, lw=1.2, ls="--"); ax.text(1.0, len(d) - 0.35, " band midpoint", color=SUB, fontsize=8, va="bottom")
    for y, v in enumerate(d["avg_compa_ratio"]):
        ax.text(v, y, f" {v:.2f}", va="center", fontsize=9)
    ax.set_xlim(0, 1.4)
    title(ax, "Clerks are paid below the middle of their pay band", "Average compa-ratio = salary / band midpoint (red = below 0.80)")


def concentration(ax) -> None:
    d = pd.read_csv(RES / "q26_payroll_concentration.csv")
    x = [0] + (d["decile"] * 10).tolist(); y = [0] + d["cumulative_pct"].tolist()
    ax.fill_between(x, y, [0] + (d["decile"] * 10).tolist(), color=TEAL, alpha=0.25, label="gap to an equal split")
    ax.plot(x, y, color=NAVY, marker="o", lw=2, label="actual payroll share")
    ax.plot([0, 100], [0, 100], color=GREY, ls="--", label="equal split")
    ax.annotate("top 10% of people\nget 22.7% of payroll", (10, 22.7), (28, 10), fontsize=9, arrowprops=dict(arrowstyle="->", color=SUB))
    ax.set_xlabel("Employees, highest paid first (%)"); ax.set_ylabel("Cumulative share of payroll (%)")
    ax.set_xlim(0, 100); ax.set_ylim(0, 105); ax.legend(loc="lower right", fontsize=8)
    ax.grid(True, axis="both", color="#E9EDF2")
    title(ax, "Pay is moderately concentrated at the top", "Cumulative payroll share by pay decile")


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    IMG.mkdir(exist_ok=True)
    charts = {"01_payroll_by_department": payroll_by_department, "02_hiring_trend": hiring_trend,
              "03_compa_ratio": compa_ratio, "04_payroll_concentration": concentration}
    for name, fn in charts.items():
        fig, ax = plt.subplots(figsize=(8, 4.6))
        fn(ax); fig.tight_layout(rect=(0, 0, 1, 0.93)); fig.savefig(IMG / f"{name}.png"); plt.close(fig)
        print("saved", f"images/{name}.png")
    fig, axes = plt.subplots(2, 2, figsize=(16, 9.4))
    for ax, fn in zip(axes.flat, charts.values()):
        fn(ax)
    fig.suptitle("HR analytics with SQL: 107 employees · 11 departments · 7 cities", x=0.02, ha="left", fontsize=16, fontweight="bold", y=0.995)
    fig.tight_layout(rect=(0, 0, 1, 0.95), h_pad=3.2, w_pad=3)
    fig.savefig(IMG / "00_overview.png"); plt.close(fig); print("saved images/00_overview.png")


if __name__ == "__main__":
    main()
