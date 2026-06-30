"""URL and date helpers for /gmu subpath."""
from datetime import date, timedelta

from config import BASE_PATH
from database import get_setting

# Business data starts here (ODS / career tracking)
DATA_START = date(2026, 1, 1)


def url(path: str = "") -> str:
    if not path.startswith("/"):
        path = "/" + path
    if path == "/":
        return BASE_PATH + "/"
    return BASE_PATH + path


def static_url(path: str) -> str:
    path = path.lstrip("/")
    return f"{BASE_PATH}/static/{path}"


def logo_url() -> str:
    custom = get_setting("logo_path", "")
    if custom:
        if custom.startswith("/static/"):
            return BASE_PATH + custom
        if custom.startswith("static/"):
            return BASE_PATH + "/" + custom
        return custom
    return static_url("img/logo.svg") + "?v=11"


def has_custom_logo() -> bool:
    return bool(get_setting("logo_path", ""))


def period_filter(period: str) -> tuple[str, str]:
    today = date.today()
    if period == "week":
        start = max(today - timedelta(days=today.weekday()), DATA_START)
    elif period == "month":
        start = max(today.replace(day=1), DATA_START)
    elif period == "half":
        start = max(today - timedelta(days=182), DATA_START)
    elif period == "year":
        start = max(today.replace(month=1, day=1), DATA_START)
    else:
        start = DATA_START
    return start.isoformat(), today.isoformat()


def resolve_date_range(
    period: str = "month",
    date_from: str | None = None,
    date_to: str | None = None,
) -> tuple[str, str, str]:
    """Return (start, end, active_period). active_period is 'custom' when dates set."""
    if date_from and date_to:
        start, end = sorted([date_from, date_to])
        if start < DATA_START.isoformat():
            start = DATA_START.isoformat()
        return start, end, "custom"
    start, end = period_filter(period)
    return start, end, period


def get_split_pcts() -> dict[str, float]:
    return {
        "savings": float(get_setting("split_savings_pct", "30") or 30),
        "business": float(get_setting("split_business_pct", "40") or 40),
        "personal": float(get_setting("split_personal_pct", "30") or 30),
    }


def time_slot_options(start_hour: int = 6, end_hour: int = 22, step_minutes: int = 30) -> list[str]:
    from datetime import datetime, timedelta

    slots: list[str] = []
    t = datetime(2000, 1, 1, start_hour, 0)
    end = datetime(2000, 1, 1, end_hour, 0)
    while t <= end:
        slots.append(t.strftime("%I:%M %p"))
        t += timedelta(minutes=step_minutes)
    return slots


def calc_split(amount: float, pcts: dict[str, float] | None = None) -> dict[str, float]:
    p = pcts or get_split_pcts()
    total = p["savings"] + p["business"] + p["personal"]
    if total <= 0:
        total = 100
    return {
        "savings": amount * p["savings"] / total,
        "business": amount * p["business"] / total,
        "personal": amount * p["personal"] / total,
    }
