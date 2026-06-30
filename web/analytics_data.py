"""Insights / Reports metrics — mirrors ODS Reports tab for any date range."""
from __future__ import annotations

import calendar
import sqlite3
from datetime import date

from helpers import DATA_START

_APPT_FILTER = (
    "date BETWEEN ? AND ? AND status NOT IN ('cancelled', 'no_show')"
)

REPORT_START = DATA_START.isoformat()[:7]  # 2026-01


def _days_in_range(start: str, end: str) -> int:
    d0 = date.fromisoformat(start)
    d1 = date.fromisoformat(end)
    return max(1, (d1 - d0).days + 1)


def _months_in_range(start: str, end: str) -> list[str]:
    d0 = date.fromisoformat(start)
    d1 = date.fromisoformat(end)
    floor = date.fromisoformat(REPORT_START + "-01")
    if d0 < floor:
        d0 = floor
    months: list[str] = []
    y, m = d0.year, d0.month
    while (y, m) <= (d1.year, d1.month):
        months.append(f"{y:04d}-{m:02d}")
        m += 1
        if m > 12:
            m = 1
            y += 1
    return months


def _service_label(style: str | None, tier: str | None) -> str:
    s = (style or "other").replace("_", " ").title()
    t = (tier or "").strip()
    return f"{s} ({t})" if t else s


def _month_metrics(
    conn: sqlite3.Connection, month: str, start: str, end: str
) -> dict:
    """Compute one row of the ODS Reports monthly table."""
    m_start = max(start, f"{month}-01")
    y, mo = int(month[:4]), int(month[5:7])
    last_day = calendar.monthrange(y, mo)[1]
    m_end = min(end, f"{month}-{last_day:02d}")

    p = (m_start, m_end)
    base = conn.execute(
        f"""SELECT COALESCE(SUM(revenue),0) as revenue,
                   COALESCE(SUM(transport_cost),0) as transport,
                   COALESCE(SUM(duration_hours),0) as hours,
                   COUNT(*) as bookings
            FROM appointments WHERE {_APPT_FILTER}""",
        p,
    ).fetchone()

    houses = conn.execute(
        f"""SELECT COUNT(*) FROM (
                SELECT DISTINCT date, client_name FROM appointments
                WHERE {_APPT_FILTER}
            )""",
        p,
    ).fetchone()[0]

    unique_clients = conn.execute(
        f"SELECT COUNT(DISTINCT client_name) FROM appointments WHERE {_APPT_FILTER}",
        p,
    ).fetchone()[0]

    repeat_clients = conn.execute(
        f"""SELECT COUNT(*) FROM (
                SELECT client_name FROM appointments WHERE {_APPT_FILTER}
                GROUP BY client_name HAVING COUNT(*) > 1
            )""",
        p,
    ).fetchone()[0]

    alloc = conn.execute(
        """SELECT COALESCE(SUM(savings),0) as savings,
                  COALESCE(SUM(business),0) as business,
                  COALESCE(SUM(personal),0) as personal,
                  COALESCE(SUM(expenses),0) as alloc_expenses
           FROM income_allocations
           WHERE date BETWEEN ? AND ?""",
        p,
    ).fetchone()

    revenue = float(base["revenue"])
    transport = float(base["transport"])
    bookings = int(base["bookings"])
    hours = float(base["hours"])
    alloc_exp = float(alloc["alloc_expenses"])

    top = conn.execute(
        f"""SELECT client_name, SUM(revenue) as total
            FROM appointments WHERE {_APPT_FILTER}
            GROUP BY client_name ORDER BY total DESC LIMIT 1""",
        p,
    ).fetchone()

    best = conn.execute(
        f"""SELECT service_style, headcount_tier, SUM(revenue) as total
            FROM appointments WHERE {_APPT_FILTER}
            GROUP BY service_style, headcount_tier ORDER BY total DESC LIMIT 1""",
        p,
    ).fetchone()

    days = _days_in_range(m_start, m_end)
    net = revenue - transport

    return {
        "month": month,
        "label": date(y, mo, 1).strftime("%B %Y"),
        "revenue": revenue,
        "total_expenses": transport,
        "net_profit": net,
        "hours": hours,
        "hourly_rate": revenue / hours if hours else 0,
        "bookings": bookings,
        "houses": houses,
        "avg_people_per_house": bookings / houses if houses else 0,
        "avg_daily_expense": alloc_exp / days,
        "avg_profit_per_service": net / bookings if bookings else 0,
        "avg_revenue_per_house": revenue / houses if houses else 0,
        "top_client": top["client_name"] if top else "—",
        "best_seller": _service_label(
            best["service_style"] if best else None,
            best["headcount_tier"] if best else None,
        ),
        "business_account": float(alloc["business"]),
        "savings_account": float(alloc["savings"]),
        "personal_account": float(alloc["personal"]),
        "transport": transport,
        "avg_booking_per_client": bookings / unique_clients if unique_clients else 0,
        "retention_rate": (repeat_clients / unique_clients * 100)
        if unique_clients
        else 0,
        "revenue_concentration": (float(top["total"]) / revenue * 100)
        if revenue and top
        else 0,
    }


def fetch_insights(conn: sqlite3.Connection, start: str, end: str) -> dict:
    """Return all Insights page data for the selected date range."""
    p = (start, end)
    days = _days_in_range(start, end)

    base = conn.execute(
        f"""SELECT COALESCE(SUM(revenue),0) as revenue,
                   COALESCE(SUM(transport_cost),0) as transport,
                   COALESCE(SUM(duration_hours),0) as hours,
                   COUNT(*) as bookings
            FROM appointments WHERE {_APPT_FILTER}""",
        p,
    ).fetchone()

    houses = conn.execute(
        f"""SELECT COUNT(*) FROM (
                SELECT DISTINCT date, client_name FROM appointments
                WHERE {_APPT_FILTER}
            )""",
        p,
    ).fetchone()[0]

    unique_clients = conn.execute(
        f"SELECT COUNT(DISTINCT client_name) FROM appointments WHERE {_APPT_FILTER}",
        p,
    ).fetchone()[0]

    repeat_clients = conn.execute(
        f"""SELECT COUNT(*) FROM (
                SELECT client_name FROM appointments WHERE {_APPT_FILTER}
                GROUP BY client_name HAVING COUNT(*) > 1
            )""",
        p,
    ).fetchone()[0]

    business_expenses = conn.execute(
        """SELECT COALESCE(SUM(amount),0) FROM expenses
           WHERE date IS NULL OR date BETWEEN ? AND ?""",
        p,
    ).fetchone()[0]

    alloc = conn.execute(
        """SELECT COALESCE(SUM(total_earned),0) as earned,
                  COALESCE(SUM(savings),0) as savings,
                  COALESCE(SUM(business),0) as business,
                  COALESCE(SUM(personal),0) as personal,
                  COALESCE(SUM(drawings),0) as drawings,
                  COALESCE(SUM(expenses),0) as alloc_expenses
           FROM income_allocations
           WHERE date IS NULL OR date BETWEEN ? AND ?""",
        p,
    ).fetchone()

    revenue = float(base["revenue"])
    transport = float(base["transport"])
    bookings = int(base["bookings"])
    hours = float(base["hours"])
    alloc_exp = float(alloc["alloc_expenses"])

    top = conn.execute(
        f"""SELECT client_name, SUM(revenue) as total, COUNT(*) as cnt
            FROM appointments WHERE {_APPT_FILTER}
            GROUP BY client_name ORDER BY total DESC LIMIT 1""",
        p,
    ).fetchone()

    best = conn.execute(
        f"""SELECT service_style, headcount_tier, SUM(revenue) as total, COUNT(*) as cnt
            FROM appointments WHERE {_APPT_FILTER}
            GROUP BY service_style, headcount_tier ORDER BY total DESC LIMIT 1""",
        p,
    ).fetchone()

    net_profit = revenue - transport

    summary = {
        "revenue": revenue,
        "total_expenses": transport,
        "business_expenses": float(business_expenses),
        "alloc_expenses": alloc_exp,
        "net_profit": net_profit,
        "hours": hours,
        "hourly_rate": revenue / hours if hours else 0,
        "bookings": bookings,
        "houses": houses,
        "unique_clients": unique_clients,
        "avg_people_per_house": bookings / houses if houses else 0,
        "avg_daily_expense": alloc_exp / days,
        "avg_profit_per_service": net_profit / bookings if bookings else 0,
        "avg_revenue_per_house": revenue / houses if houses else 0,
        "transport": transport,
        "avg_booking_per_client": bookings / unique_clients if unique_clients else 0,
        "retention_rate": (repeat_clients / unique_clients * 100)
        if unique_clients
        else 0,
        "top_client": top["client_name"] if top else "—",
        "top_client_revenue": float(top["total"]) if top else 0,
        "revenue_concentration": (float(top["total"]) / revenue * 100)
        if revenue and top
        else 0,
        "best_seller": _service_label(
            best["service_style"] if best else None,
            best["headcount_tier"] if best else None,
        ),
        "earned": float(alloc["earned"]),
        "savings": float(alloc["savings"]),
        "business": float(alloc["business"]),
        "personal": float(alloc["personal"]),
        "drawings": float(alloc["drawings"]),
    }

    revenue_by_month = [
        r for r in conn.execute(
            f"""SELECT substr(date,1,7) as m, SUM(revenue) as total,
                       SUM(transport_cost) as transport,
                       COUNT(*) as bookings
                FROM appointments WHERE {_APPT_FILTER}
                GROUP BY m ORDER BY m""",
            p,
        ).fetchall()
        if r["m"] >= REPORT_START
    ]

    profit_by_month = [
        r for r in conn.execute(
            f"""SELECT substr(date,1,7) as m,
                       SUM(revenue) - SUM(transport_cost) as net
                FROM appointments WHERE {_APPT_FILTER}
                GROUP BY m ORDER BY m""",
            p,
        ).fetchall()
        if r["m"] >= REPORT_START
    ]

    by_style = conn.execute(
        f"""SELECT service_style, headcount_tier,
                   COUNT(*) as cnt, SUM(revenue) as total
            FROM appointments WHERE {_APPT_FILTER}
            GROUP BY service_style, headcount_tier ORDER BY total DESC""",
        p,
    ).fetchall()

    top_clients = conn.execute(
        f"""SELECT client_name, SUM(revenue) as total, COUNT(*) as cnt
            FROM appointments WHERE {_APPT_FILTER}
            GROUP BY client_name ORDER BY total DESC LIMIT 8""",
        p,
    ).fetchall()

    by_payment = conn.execute(
        f"""SELECT payment_method, COUNT(*) as cnt, SUM(revenue) as total
            FROM appointments WHERE {_APPT_FILTER}
            GROUP BY payment_method ORDER BY total DESC""",
        p,
    ).fetchall()

    expense_categories = conn.execute(
        """SELECT category, SUM(amount) as total, COUNT(*) as cnt
           FROM expenses
           WHERE date IS NULL OR date BETWEEN ? AND ?
           GROUP BY category ORDER BY total DESC""",
        p,
    ).fetchall()

    monthly_rows = [
        _month_metrics(conn, m, start, end) for m in _months_in_range(start, end)
    ]

    return {
        "summary": summary,
        "revenue_by_month": revenue_by_month,
        "profit_by_month": profit_by_month,
        "by_style": by_style,
        "top_clients": top_clients,
        "by_payment": by_payment,
        "expense_categories": expense_categories,
        "monthly_rows": monthly_rows,
    }
