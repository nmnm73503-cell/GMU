"""Service packages and payment options — loaded from DB, seeded from ODS."""

from __future__ import annotations

import re
import sqlite3
import time

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


def load_package_images(conn: sqlite3.Connection, package_id: str) -> list[dict]:
    rows = conn.execute(
        """SELECT * FROM package_images WHERE package_id = ?
           ORDER BY sort_order, id""",
        (package_id,),
    ).fetchall()
    return [dict(r) for r in rows]


def load_all_package_images(conn: sqlite3.Connection) -> dict[str, list[str]]:
    rows = conn.execute(
        "SELECT package_id, path FROM package_images ORDER BY package_id, sort_order, id"
    ).fetchall()
    out: dict[str, list[str]] = {}
    for row in rows:
        out.setdefault(row["package_id"], []).append(row["path"])
    return out


def packages_with_galleries(conn: sqlite3.Connection, active_only: bool = True) -> list[dict]:
    packages = load_packages(conn, active_only=active_only)
    for pkg in packages:
        gallery = load_package_images(conn, pkg["id"])
        pkg["gallery"] = gallery
        pkg["images"] = [g["path"] for g in gallery]
    return packages


def _slug_id(label: str) -> str:
    s = re.sub(r"[^a-z0-9]+", "_", label.lower().strip())[:48].strip("_")
    return s or f"pkg_{int(time.time())}"


def unique_package_id(conn: sqlite3.Connection, label: str) -> str:
    base = _slug_id(label)
    pid = base
    n = 2
    while conn.execute(
        "SELECT 1 FROM service_packages WHERE id = ?", (pid,)
    ).fetchone():
        pid = f"{base}_{n}"
        n += 1
    return pid


def create_package(
    conn: sqlite3.Connection,
    *,
    label: str,
    price: float,
    category: str = "event",
    service_style: str = "",
    headcount_tier: str = "",
    active: bool = True,
) -> str:
    seed_default_packages(conn)
    label = label.strip()
    if not label:
        raise ValueError("Package name required")
    if category not in CATEGORY_LABELS:
        category = "other"
    pid = unique_package_id(conn, label)
    sort_order = conn.execute(
        "SELECT COALESCE(MAX(sort_order), 0) + 1 FROM service_packages"
    ).fetchone()[0]
    conn.execute(
        """INSERT INTO service_packages
           (id, label, service_style, headcount_tier, price, category, sort_order, active)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
        (
            pid,
            label,
            service_style.strip(),
            headcount_tier.strip(),
            price,
            category,
            sort_order,
            1 if active else 0,
        ),
    )
    return pid


def delete_package(conn: sqlite3.Connection, package_id: str) -> bool:
    if package_id in ("custom", "tbd"):
        return False
    row = conn.execute(
        "SELECT id FROM service_packages WHERE id = ?", (package_id,)
    ).fetchone()
    if not row:
        return False
    conn.execute("DELETE FROM package_images WHERE package_id = ?", (package_id,))
    conn.execute("DELETE FROM service_packages WHERE id = ?", (package_id,))
    return True


def face_unit_price(face: dict, pkg: dict | None) -> float:
    """Price for one face — prefer snapshot stored on the face."""
    if face.get("price") is not None and face.get("price") != "":
        try:
            return float(face["price"])
        except (TypeError, ValueError):
            pass
    if pkg:
        return float(pkg.get("price") or 0)
    return 0.0


def face_label(face: dict, pkg: dict | None) -> str:
    if face.get("label"):
        return str(face["label"])
    if pkg:
        return pkg.get("label") or pkg["id"]
    return face.get("package_id") or "Service"


def snapshot_session_faces(faces: list[dict], conn: sqlite3.Connection) -> list[dict]:
    """Freeze label + price on each face at session/booking time."""
    out = []
    for face in faces:
        pkg = package_by_id(conn, face.get("package_id", ""))
        row = dict(face)
        row["label"] = face_label(face, pkg)
        row["price"] = face_unit_price(face, pkg)
        if pkg:
            row.setdefault("style", pkg.get("service_style") or "")
            row.setdefault("tier", pkg.get("headcount_tier") or "")
        out.append(row)
    return out


def aggregate_session_faces(faces: list[dict], conn: sqlite3.Connection) -> list[dict]:
    """Receipt lines from faces — uses stored prices, not current catalog."""
    groups: dict[str, dict] = {}
    for face in faces:
        pkg = package_by_id(conn, face.get("package_id", ""))
        pid = face.get("package_id") or (pkg["id"] if pkg else "unknown")
        label = face_label(face, pkg)
        unit = face_unit_price(face, pkg)
        if pid not in groups:
            groups[pid] = {
                "package_id": pid,
                "label": label,
                "unit_price": unit,
                "count": 0,
            }
        groups[pid]["count"] += 1
    lines = []
    for line in groups.values():
        line["subtotal"] = line["count"] * line["unit_price"]
        lines.append(line)
    return sorted(lines, key=lambda x: x["label"])
