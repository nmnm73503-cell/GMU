"""SQLite database — lightweight, no ORM."""
import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).parent / "data" / "glam.db"


def _normalize_google_maps_key(key: str) -> str:
    key = (key or "").strip()
    if key.startswith("AlzaSy"):
        key = "AIzaSy" + key[6:]
    return key


def connect() -> sqlite3.Connection:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def init_db() -> None:
    with connect() as conn:
        conn.executescript(
            """
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS clients (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                phone TEXT DEFAULT '',
                email TEXT DEFAULT '',
                instagram TEXT DEFAULT '',
                lead_source TEXT DEFAULT '',
                notes TEXT DEFAULT '',
                lifetime_value REAL DEFAULT 0,
                created_at TEXT DEFAULT (datetime('now'))
            );

            CREATE TABLE IF NOT EXISTS appointments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                client_id INTEGER,
                client_name TEXT NOT NULL,
                date TEXT NOT NULL,
                start_time TEXT DEFAULT '',
                end_time TEXT DEFAULT '',
                duration_hours REAL DEFAULT 0,
                service_style TEXT DEFAULT '',
                headcount_tier TEXT DEFAULT '',
                revenue REAL DEFAULT 0,
                transport_cost REAL DEFAULT 0,
                payment_method TEXT DEFAULT '',
                lead_source TEXT DEFAULT '',
                status TEXT DEFAULT 'completed',
                location TEXT DEFAULT '',
                notes TEXT DEFAULT '',
                FOREIGN KEY (client_id) REFERENCES clients(id)
            );

            CREATE TABLE IF NOT EXISTS expenses (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT,
                month TEXT DEFAULT '',
                category TEXT DEFAULT '',
                amount REAL DEFAULT 0,
                description TEXT DEFAULT ''
            );

            CREATE TABLE IF NOT EXISTS income_allocations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT,
                total_earned REAL DEFAULT 0,
                savings REAL DEFAULT 0,
                business REAL DEFAULT 0,
                personal REAL DEFAULT 0,
                drawings REAL DEFAULT 0,
                expenses REAL DEFAULT 0
            );

            CREATE TABLE IF NOT EXISTS daily_summaries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date TEXT UNIQUE,
                total_revenue REAL DEFAULT 0,
                total_expenses REAL DEFAULT 0,
                net_profit REAL DEFAULT 0
            );

            CREATE TABLE IF NOT EXISTS monthly_summaries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                month TEXT UNIQUE,
                total_revenue REAL DEFAULT 0,
                total_expenses REAL DEFAULT 0,
                net_profit REAL DEFAULT 0
            );

            CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(date);
            CREATE INDEX IF NOT EXISTS idx_clients_name ON clients(name);

            CREATE TABLE IF NOT EXISTS service_packages (
                id TEXT PRIMARY KEY,
                label TEXT NOT NULL,
                service_style TEXT DEFAULT '',
                headcount_tier TEXT DEFAULT '',
                price REAL DEFAULT 0,
                category TEXT DEFAULT 'event',
                sort_order INTEGER DEFAULT 0,
                active INTEGER DEFAULT 1
            );

            CREATE TABLE IF NOT EXISTS studio_notes (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                category TEXT DEFAULT 'general',
                body TEXT NOT NULL,
                created_at TEXT DEFAULT (datetime('now'))
            );
            """
        )
        from packages import seed_default_packages
        seed_default_packages(conn)
        try:
            conn.execute(
                "ALTER TABLE appointments ADD COLUMN photo_path TEXT DEFAULT ''"
            )
        except sqlite3.OperationalError:
            pass
        try:
            conn.execute(
                "ALTER TABLE appointments ADD COLUMN session_faces TEXT DEFAULT ''"
            )
        except sqlite3.OperationalError:
            pass
        try:
            conn.execute("ALTER TABLE appointments ADD COLUMN lat REAL")
        except sqlite3.OperationalError:
            pass
        try:
            conn.execute("ALTER TABLE appointments ADD COLUMN lng REAL")
        except sqlite3.OperationalError:
            pass
        conn.executescript(
            """
            CREATE TABLE IF NOT EXISTS package_images (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                package_id TEXT NOT NULL,
                path TEXT NOT NULL,
                sort_order INTEGER DEFAULT 0
            );
            CREATE INDEX IF NOT EXISTS idx_package_images_pkg ON package_images(package_id);
            """
        )
        defaults = {
            "business_name": "Glam Me Upp",
            "artist_name": "Nawal",
            "tagline": "Dar es Salaam | Bridal • Event • Photoshoots",
            "currency": "TZS",
            "instagram": "glam.me.upp",
            "phone": "",
            "logo_path": "",
            "primary_color": "#000000",
            "accent_color": "#000000",
            "google_maps_api_key": "",
            "receipt_footer": "Thank you for trusting me with your glam.",
            "seed_imported": "0",
            "split_savings_pct": "30",
            "split_business_pct": "40",
            "split_personal_pct": "30",
        }
        for k, v in defaults.items():
            conn.execute(
                "INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)", (k, v)
            )
        for k, v in {"primary_color": "#000000", "accent_color": "#000000"}.items():
            conn.execute("UPDATE settings SET value = ? WHERE key = ?", (v, k))


def get_setting(key: str, default: str = "") -> str:
    with connect() as conn:
        row = conn.execute(
            "SELECT value FROM settings WHERE key = ?", (key,)
        ).fetchone()
        value = row["value"] if row else default
        if key == "google_maps_api_key" and value:
            value = _normalize_google_maps_key(value)
        return value


def set_setting(key: str, value: str) -> None:
    with connect() as conn:
        conn.execute(
            "INSERT INTO settings (key, value) VALUES (?, ?) "
            "ON CONFLICT(key) DO UPDATE SET value = excluded.value",
            (key, value),
        )


def load_settings(conn: sqlite3.Connection | None = None) -> dict[str, str]:
    """All settings as a dict, with known normalizations applied."""
    if conn is None:
        with connect() as c:
            return load_settings(c)
    cfg = {r["key"]: r["value"] for r in conn.execute("SELECT key, value FROM settings").fetchall()}
    if cfg.get("google_maps_api_key"):
        cfg["google_maps_api_key"] = _normalize_google_maps_key(cfg["google_maps_api_key"])
    return cfg


def is_seeded() -> bool:
    return get_setting("seed_imported") == "1"
