"""Service packages and payment options — loaded from DB, seeded from ODS."""

from __future__ import annotations

import sqlite3

PAYMENT_METHODS = [
    ("cash", "Cash"),
    ("mobile_money", "Mobile Money"),
]

CATEGORY_LABELS = {
    "event": "Event glam",
    "bridal": "Bridal",
    "other": "Other",
}

# Prices matched from My Career.ods Reports / service log
DEFAULT_PACKAGES = [
    {"id": "simple_1_2", "label": "Simple (1–2 people)", "style": "simple", "tier": "1-2", "price": 70_000, "category": "event", "sort_order": 1},
    {"id": "simple_3_plus", "label": "Simple (3+ people)", "style": "simple", "tier": "3+", "price": 50_000, "category": "event", "sort_order": 2},
    {"id": "soft_1_2", "label": "Soft (1–2 people)", "style": "soft", "tier": "1-2", "price": 80_000, "category": "event", "sort_order": 3},
    {"id": "soft_3_plus", "label": "Soft (3+ people)", "style": "soft", "tier": "3+", "price": 60_000, "category": "event", "sort_order": 4},
    {"id": "dramatic_1_2", "label": "Dramatic (1–2 people)", "style": "dramatic", "tier": "1-2", "price": 90_000, "category": "event", "sort_order": 5},
    {"id": "dramatic_3_plus", "label": "Dramatic (3+ people)", "style": "dramatic", "tier": "3+", "price": 70_000, "category": "event", "sort_order": 6},
    {"id": "bridal_trial", "label": "Simple Bridal Trial", "style": "bridal_trial", "tier": "", "price": 70_000, "category": "bridal", "sort_order": 7},
    {"id": "bridal_1_2", "label": "Bridal (1–2 people)", "style": "bridal", "tier": "1-2", "price": 100_000, "category": "bridal", "sort_order": 8},
    {"id": "bridal_3_plus", "label": "Bridal (3+ people)", "style": "bridal", "tier": "3+", "price": 80_000, "category": "bridal", "sort_order": 9},
    {"id": "bridal_oot", "label": "Bridal OOT (Out of City)", "style": "bridal_oot", "tier": "", "price": 150_000, "category": "bridal", "sort_order": 10},
    {"id": "custom", "label": "Custom — enter amount", "style": "", "tier": "", "price": 0, "category": "other", "sort_order": 99},
]


def seed_default_packages(conn: sqlite3.Connection) -> None:
    for pkg in DEFAULT_PACKAGES:
        conn.execute(
            """INSERT OR IGNORE INTO service_packages
               (id, label, service_style, headcount_tier, price, category, sort_order, active)
               VALUES (?, ?, ?, ?, ?, ?, ?, 1)""",
            (
                pkg["id"], pkg["label"], pkg["style"], pkg["tier"],
                pkg["price"], pkg["category"], pkg["sort_order"],
            ),
        )


def load_packages(conn: sqlite3.Connection, active_only: bool = False) -> list[dict]:
    seed_default_packages(conn)
    q = "SELECT * FROM service_packages"
    if active_only:
        q += " WHERE active = 1"
    q += " ORDER BY sort_order, label"
    rows = conn.execute(q).fetchall()
    return [dict(r) for r in rows]


def package_by_id(conn: sqlite3.Connection, package_id: str) -> dict | None:
    seed_default_packages(conn)
    row = conn.execute(
        "SELECT * FROM service_packages WHERE id = ?", (package_id,)
    ).fetchone()
    return dict(row) if row else None


def packages_grouped(packages: list[dict]) -> dict[str, list[dict]]:
    groups: dict[str, list[dict]] = {}
    for pkg in packages:
        cat = pkg.get("category") or "other"
        groups.setdefault(cat, []).append(pkg)
    return groups


def match_package_for_appt(conn: sqlite3.Connection, appt) -> str:
    style = (appt["service_style"] or "").lower()
    tier = appt["headcount_tier"] or ""
    for pkg in load_packages(conn, active_only=False):
        if pkg["id"] == "custom":
            continue
        if (pkg["service_style"] or "").lower() == style and (pkg["headcount_tier"] or "") == tier:
            return pkg["id"]
    if style:
        for pkg in load_packages(conn, active_only=False):
            if (pkg["service_style"] or "").lower() == style and not pkg["headcount_tier"]:
                return pkg["id"]
    return "custom"


def payment_label(method: str) -> str:
    for value, label in PAYMENT_METHODS:
        if value == method:
            return label
    if method == "mpesa":
        return "Mobile Money"
    return method.replace("_", " ").title() if method else "—"


def package_display_label(pkg: dict) -> str:
    return pkg.get("label") or pkg["id"]
