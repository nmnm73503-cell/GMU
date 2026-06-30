"""Import career_seed.json into SQLite."""
import json
from pathlib import Path

from database import connect, set_setting

SEED_PATH = (
    Path(__file__).parent.parent
    / "GlamMeUppStudio"
    / "Resources"
    / "SeedData"
    / "career_seed.json"
)


def import_seed(force: bool = False) -> dict:
    if not SEED_PATH.exists():
        return {"error": f"Seed file not found: {SEED_PATH}"}

    with open(SEED_PATH, encoding="utf-8") as f:
        data = json.load(f)

    with connect() as conn:
        if force:
            conn.executescript(
                "DELETE FROM appointments; DELETE FROM clients; "
                "DELETE FROM expenses; DELETE FROM income_allocations; "
                "DELETE FROM daily_summaries; DELETE FROM monthly_summaries;"
            )

        client_map: dict[str, int] = {}
        for c in data.get("clients", []):
            cur = conn.execute(
                "INSERT INTO clients (name, lead_source) VALUES (?, ?)",
                (c["name"], c.get("leadSource", "")),
            )
            client_map[c["name"]] = cur.lastrowid

        appt_count = 0
        for a in data.get("appointments", []):
            cid = client_map.get(a.get("clientName", ""))
            conn.execute(
                """INSERT INTO appointments
                (client_id, client_name, date, start_time, end_time, duration_hours,
                 service_style, headcount_tier, revenue, transport_cost,
                 payment_method, lead_source, status)
                VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)""",
                (
                    cid,
                    a.get("clientName", ""),
                    a.get("date", ""),
                    a.get("startTime", ""),
                    a.get("endTime", ""),
                    a.get("durationHours", 0),
                    a.get("serviceStyle", ""),
                    a.get("headcountTier", ""),
                    a.get("revenue", 0),
                    a.get("transportCost", 0),
                    a.get("paymentMethod", ""),
                    a.get("leadSource", ""),
                    a.get("status", "completed"),
                ),
            )
            appt_count += 1

        for e in data.get("expenses", []):
            conn.execute(
                "INSERT INTO expenses (date, month, category, amount, description) VALUES (?,?,?,?,?)",
                (
                    e.get("date"),
                    e.get("month", ""),
                    e.get("category", ""),
                    e.get("amount", 0),
                    e.get("description", ""),
                ),
            )

        for row in data.get("incomeAllocations", []):
            conn.execute(
                """INSERT INTO income_allocations
                (date, total_earned, savings, business, personal, drawings, expenses)
                VALUES (?,?,?,?,?,?,?)""",
                (
                    row.get("date"),
                    row.get("totalEarned", 0),
                    row.get("savings", row.get("savingsAmount", 0)),
                    row.get("business", row.get("businessAmount", 0)),
                    row.get("personal", row.get("personalAmount", 0)),
                    row.get("drawings", 0),
                    row.get("expenses", 0),
                ),
            )

        for row in data.get("dailySummaries", []):
            conn.execute(
                """INSERT OR REPLACE INTO daily_summaries
                (date, total_revenue, total_expenses, net_profit) VALUES (?,?,?,?)""",
                (
                    row.get("date"),
                    row.get("totalRevenue", 0),
                    row.get("totalExpenses", 0),
                    row.get("netProfit", 0),
                ),
            )

        for row in data.get("monthlySummaries", []):
            conn.execute(
                """INSERT OR REPLACE INTO monthly_summaries
                (month, total_revenue, total_expenses, net_profit) VALUES (?,?,?,?)""",
                (
                    row.get("month"),
                    row.get("totalRevenue", 0),
                    row.get("totalExpenses", 0),
                    row.get("netProfit", 0),
                ),
            )

        for name, cid in client_map.items():
            total = conn.execute(
                "SELECT COALESCE(SUM(revenue),0) FROM appointments WHERE client_id = ?",
                (cid,),
            ).fetchone()[0]
            count = conn.execute(
                "SELECT COUNT(*) FROM appointments WHERE client_id = ?", (cid,)
            ).fetchone()[0]
            conn.execute(
                "UPDATE clients SET lifetime_value = ? WHERE id = ?",
                (total, cid),
            )

    set_setting("seed_imported", "1")
    return {
        "clients": len(data.get("clients", [])),
        "appointments": appt_count,
        "expenses": len(data.get("expenses", [])),
        "income_allocations": len(data.get("incomeAllocations", [])),
        "daily_summaries": len(data.get("dailySummaries", [])),
        "monthly_summaries": len(data.get("monthlySummaries", [])),
    }
