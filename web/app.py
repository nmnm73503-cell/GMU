"""Glam Me Upp Studio — mounted at /gmu on munasdream.mooo.com"""
import json
import sqlite3
from datetime import date, datetime, timedelta
from pathlib import Path

from fastapi import APIRouter, FastAPI, File, Form, HTTPException, Request, UploadFile
from fastapi.responses import FileResponse, HTMLResponse, JSONResponse, PlainTextResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from analytics_data import fetch_insights
from config import BASE_PATH, DEDICATED_FOR, PUBLIC_URL
from database import connect, get_setting, init_db, is_seeded, load_settings, set_setting
from helpers import (
    calc_split,
    format_month_short,
    get_split_pcts,
    has_custom_logo,
    logo_url,
    resolve_date_range,
    safe_redirect,
    static_url,
    time_slot_options,
    url,
)
from instagram import fetch_instagram_stats
from packages import (
    CATEGORY_LABELS,
    PAYMENT_METHODS,
    load_packages,
    match_package_for_appt,
    package_by_id,
    packages_grouped,
    packages_with_galleries,
    payment_label,
)
from seed import import_seed

BASE = Path(__file__).parent
router = APIRouter()
templates = Jinja2Templates(directory=str(BASE / "templates"))
(BASE / "static" / "uploads").mkdir(parents=True, exist_ok=True)
(BASE / "static" / "uploads" / "bookings").mkdir(parents=True, exist_ok=True)
(BASE / "static" / "uploads" / "packages").mkdir(parents=True, exist_ok=True)

def _time_now_slot() -> str:
    return datetime.now().strftime("%I:%M %p")


def _session_appt_dict(row) -> dict:
    return {
        "id": row["id"],
        "client_name": row["client_name"],
        "date": row["date"],
        "start_time": row["start_time"] or "",
        "service_style": row["service_style"] or "",
        "headcount_tier": row["headcount_tier"] or "",
        "revenue": float(row["revenue"] or 0),
        "transport_cost": float(row["transport_cost"] or 0),
        "location": row["location"] or "",
        "lat": row["lat"] if row["lat"] is not None else None,
        "lng": row["lng"] if row["lng"] is not None else None,
        "status": row["status"] or "",
    }


def _session_packages_list(conn) -> list[dict]:
    return [
        {
            "id": p["id"],
            "label": p["label"],
            "price": float(p["price"] or 0),
            "style": p["service_style"] or "",
            "tier": p["headcount_tier"] or "",
            "category": p["category"] or "other",
        }
        for p in load_packages(conn, active_only=True)
        if p["id"] != "custom"
    ]


def _aggregate_session_faces(faces: list[dict], conn) -> list[dict]:
    groups: dict[str, dict] = {}
    for face in faces:
        pkg = package_by_id(conn, face.get("package_id", ""))
        if not pkg:
            continue
        pid = pkg["id"]
        if pid not in groups:
            groups[pid] = {
                "package_id": pid,
                "label": pkg["label"],
                "unit_price": float(pkg["price"] or 0),
                "count": 0,
            }
        groups[pid]["count"] += 1
    lines = []
    for line in groups.values():
        line["subtotal"] = line["count"] * line["unit_price"]
        lines.append(line)
    return sorted(lines, key=lambda x: x["label"])


def _session_lines_from_appt(appt, conn) -> list[dict]:
    raw = appt["session_faces"] if appt["session_faces"] else ""
    if not raw:
        return []
    try:
        faces = json.loads(raw)
    except json.JSONDecodeError:
        return []
    if not isinstance(faces, list):
        return []
    return _aggregate_session_faces(faces, conn)


def _booking_form_ctx(appt=None) -> dict:
    with connect() as conn:
        packages = load_packages(conn, active_only=True)
        selected = "tbd"
        if appt:
            if (appt["service_style"] or appt["revenue"]):
                selected = match_package_for_appt(conn, appt)
            else:
                selected = "tbd"
    return {
        "packages": packages,
        "packages_grouped": packages_grouped(packages),
        "category_labels": CATEGORY_LABELS,
        "payment_methods": PAYMENT_METHODS,
        "selected_package": selected,
        "appt": appt,
        "time_slots": time_slot_options(),
    }


def _refresh_client_ltv(conn: sqlite3.Connection, client_id: int) -> None:
    total = conn.execute(
        "SELECT COALESCE(SUM(revenue),0) FROM appointments WHERE client_id=?",
        (client_id,),
    ).fetchone()[0]
    conn.execute(
        "UPDATE clients SET lifetime_value=? WHERE id=?", (total, client_id)
    )


async def _save_booking_photo(appt_id: int, photo: UploadFile | None) -> str | None:
    if not photo or not photo.filename:
        return None
    ext = Path(photo.filename).suffix.lower()
    if ext not in {".jpg", ".jpeg", ".png", ".webp", ".gif"}:
        ext = ".jpg"
    rel = f"uploads/bookings/{appt_id}{ext}"
    dest = BASE / "static" / rel
    dest.write_bytes(await photo.read())
    return static_url(rel)


async def _save_face_photo(appt_id: int, face_id: str, photo: UploadFile) -> str:
    ext = Path(photo.filename or "").suffix.lower()
    if ext not in {".jpg", ".jpeg", ".png", ".webp", ".gif"}:
        ext = ".jpg"
    safe_id = "".join(c for c in face_id if c.isalnum() or c in "-_")[:64] or "face"
    rel = f"uploads/faces/{appt_id}/{safe_id}{ext}"
    dest = BASE / "static" / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(await photo.read())
    return static_url(rel)


def _remove_booking_photo(photo_path: str | None) -> None:
    if not photo_path or "uploads/bookings/" not in photo_path:
        return
    rel = photo_path.split("uploads/bookings/")[-1].split("?")[0]
    path = BASE / "static" / "uploads" / "bookings" / rel
    if path.is_file():
        path.unlink(missing_ok=True)


def _resolve_client(
    conn: sqlite3.Connection,
    client_id: int,
    new_client_name: str,
    new_client_phone: str = "",
) -> tuple[int, str] | None:
    name = (new_client_name or "").strip()
    if name:
        conn.execute(
            "INSERT INTO clients (name, phone) VALUES (?, ?)",
            (name, (new_client_phone or "").strip()),
        )
        cid = conn.execute("SELECT last_insert_rowid()").fetchone()[0]
        return int(cid), name
    if client_id:
        row = conn.execute(
            "SELECT name FROM clients WHERE id = ?", (client_id,)
        ).fetchone()
        if row:
            return client_id, row["name"]
    return None


async def _save_package_images(
    conn: sqlite3.Connection, package_id: str, files: list[UploadFile]
) -> None:
    if not files:
        return
    dest_dir = BASE / "static" / "uploads" / "packages" / package_id
    dest_dir.mkdir(parents=True, exist_ok=True)
    max_order = conn.execute(
        "SELECT COALESCE(MAX(sort_order), -1) FROM package_images WHERE package_id = ?",
        (package_id,),
    ).fetchone()[0]
    for i, upload in enumerate(files):
        if not upload or not upload.filename:
            continue
        ext = Path(upload.filename).suffix.lower()
        if ext not in {".jpg", ".jpeg", ".png", ".webp", ".gif"}:
            ext = ".jpg"
        fname = f"{max_order + i + 1}{ext}"
        rel = f"uploads/packages/{package_id}/{fname}"
        (BASE / "static" / rel).write_bytes(await upload.read())
        conn.execute(
            """INSERT INTO package_images (package_id, path, sort_order)
               VALUES (?, ?, ?)""",
            (package_id, static_url(rel), max_order + i + 1),
        )


def _split_bookings(rows, today: str) -> tuple[list, list]:
    upcoming, past = [], []
    for row in rows:
        if row["date"] >= today and row["status"] not in ("completed", "cancelled", "no_show"):
            upcoming.append(row)
        else:
            past.append(row)
    upcoming.sort(key=lambda r: (r["date"], r["start_time"] or ""))
    past.sort(key=lambda r: (r["date"], r["start_time"] or ""), reverse=True)
    return upcoming, past


def on_startup() -> None:
    init_db()
    if not is_seeded():
        import_seed()


def fmt_money(amount: float) -> str:
    cur = get_setting("currency", "TZS")
    return f"{cur} {amount:,.0f}"


def fmt_pct(amount: float) -> str:
    return f"{amount:.0f}%"


templates.env.globals.update(
    {
        "fmt_money": fmt_money,
        "fmt_pct": fmt_pct,
        "get_setting": get_setting,
        "url": url,
        "static_url": static_url,
        "logo_url": logo_url,
        "has_custom_logo": has_custom_logo,
        "base_path": BASE_PATH,
        "public_url": PUBLIC_URL,
        "dedicated_for": DEDICATED_FOR,
        "payment_label": payment_label,
        "get_split_pcts": get_split_pcts,
        "calc_split": calc_split,
        "fmt_month_short": format_month_short,
    }
)


def _date_ctx(form_path: str, period: str, date_from: str | None, date_to: str | None) -> dict:
    start, end, active_period = resolve_date_range(period, date_from, date_to)
    return {
        "period": active_period,
        "date_from": date_from or "",
        "date_to": date_to or "",
        "range_start": start,
        "range_end": end,
        "form_action": url(form_path),
        "clear_url": url(form_path),
    }


@router.get("/img/{filename}")
async def serve_logo_file(filename: str):
    safe = Path(filename).name
    path = BASE / "static" / "img" / safe
    if not path.is_file():
        raise HTTPException(404)
    return FileResponse(path, media_type="image/svg+xml" if safe.endswith(".svg") else None)


@router.get("/", response_class=HTMLResponse)
async def dashboard(
    request: Request,
    period: str = "month",
    date_from: str | None = None,
    date_to: str | None = None,
):
    ctx = _date_ctx("/", period, date_from, date_to)
    start, end = ctx["range_start"], ctx["range_end"]
    with connect() as conn:
        stats = conn.execute(
            """SELECT COUNT(DISTINCT client_id) as clients,
                      COUNT(*) as bookings,
                      COALESCE(SUM(revenue),0) as revenue,
                      COALESCE(SUM(transport_cost),0) as travel,
                      COALESCE(SUM(revenue - transport_cost),0) as net_profit,
                      COALESCE(SUM(duration_hours),0) as hours
               FROM appointments WHERE date BETWEEN ? AND ?
                 AND status NOT IN ('cancelled', 'no_show')""",
            (start, end),
        ).fetchone()
        upcoming_n = conn.execute(
            """SELECT COUNT(*) FROM appointments
               WHERE date >= ? AND status NOT IN ('completed','cancelled','no_show')""",
            (date.today().isoformat(),),
        ).fetchone()[0]
        cash_total = conn.execute(
            """SELECT COALESCE(SUM(revenue),0) FROM appointments
               WHERE date BETWEEN ? AND ? AND payment_method IN ('cash','')""",
            (start, end),
        ).fetchone()[0]
        recent = conn.execute(
            """SELECT * FROM appointments WHERE date BETWEEN ? AND ?
               ORDER BY date DESC LIMIT 8""",
            (start, end),
        ).fetchall()
        top_clients = conn.execute(
            """SELECT c.id, c.name, COALESCE(SUM(a.revenue),0) as lifetime_value
               FROM clients c
               LEFT JOIN appointments a ON a.client_id = c.id
                  AND a.date BETWEEN ? AND ?
               GROUP BY c.id ORDER BY lifetime_value DESC LIMIT 5""",
            (start, end),
        ).fetchall()
        service_mix = conn.execute(
            """SELECT service_style, headcount_tier, COUNT(*) as cnt,
                      COALESCE(SUM(revenue),0) as total
               FROM appointments WHERE date BETWEEN ? AND ?
               GROUP BY service_style, headcount_tier
               ORDER BY total DESC LIMIT 6""",
            (start, end),
        ).fetchall()
        packages = load_packages(conn, active_only=True)
    return templates.TemplateResponse(
        "dashboard.html",
        {
            "request": request,
            "stats": stats,
            "recent": recent,
            "top_clients": top_clients,
            "service_mix": service_mix,
            "packages": packages,
            "upcoming_n": upcoming_n,
            "cash_total": cash_total,
            "split_pcts": get_split_pcts(),
            "split_target": calc_split(float(stats["revenue"] or 0)),
            **ctx,
        },
    )


@router.get("/clients", response_class=HTMLResponse)
async def clients_list(request: Request, q: str = ""):
    with connect() as conn:
        if q:
            rows = conn.execute(
                "SELECT * FROM clients WHERE name LIKE ? ORDER BY name",
                (f"%{q}%",),
            ).fetchall()
        else:
            rows = conn.execute(
                "SELECT * FROM clients ORDER BY lifetime_value DESC"
            ).fetchall()
    return templates.TemplateResponse(
        "clients.html", {"request": request, "clients": rows, "q": q}
    )


@router.get("/clients/new", response_class=HTMLResponse)
async def client_new_form(request: Request):
    return templates.TemplateResponse("client_form.html", {"request": request, "client": None})


@router.post("/clients/new")
async def client_create(
    name: str = Form(...),
    phone: str = Form(""),
    lead_source: str = Form(""),
    notes: str = Form(""),
):
    with connect() as conn:
        conn.execute(
            "INSERT INTO clients (name, phone, lead_source, notes) VALUES (?,?,?,?)",
            (name.strip(), phone, lead_source, notes),
        )
        cid = conn.execute("SELECT last_insert_rowid()").fetchone()[0]
    return RedirectResponse(url(f"/clients/{cid}"), status_code=303)


@router.get("/clients/{client_id}", response_class=HTMLResponse)
async def client_detail(request: Request, client_id: int):
    with connect() as conn:
        client = conn.execute(
            "SELECT * FROM clients WHERE id = ?", (client_id,)
        ).fetchone()
        if not client:
            return RedirectResponse(url("/clients"), status_code=302)
        history = conn.execute(
            "SELECT * FROM appointments WHERE client_id = ? ORDER BY date DESC",
            (client_id,),
        ).fetchall()
    today = date.today().isoformat()
    upcoming, past = _split_bookings(history, today)
    return templates.TemplateResponse(
        "client_detail.html",
        {
            "request": request,
            "client": client,
            "upcoming": upcoming,
            "past": past,
            "booking_count": len(history),
        },
    )


@router.post("/clients/{client_id}/delete")
async def client_delete(client_id: int):
    with connect() as conn:
        client = conn.execute(
            "SELECT id FROM clients WHERE id = ?", (client_id,)
        ).fetchone()
        if not client:
            return RedirectResponse(url("/clients"), status_code=303)
        appts = conn.execute(
            "SELECT photo_path FROM appointments WHERE client_id = ?",
            (client_id,),
        ).fetchall()
        for row in appts:
            _remove_booking_photo(row["photo_path"])
        conn.execute("DELETE FROM appointments WHERE client_id = ?", (client_id,))
        conn.execute("DELETE FROM clients WHERE id = ?", (client_id,))
    return RedirectResponse(url("/clients"), status_code=303)


@router.get("/calendar")
async def calendar_redirect():
    return RedirectResponse(url("/bookings?tab=upcoming"), status_code=302)


@router.get("/bookings", response_class=HTMLResponse)
async def bookings_hub(
    request: Request,
    tab: str = "upcoming",
    id: int | None = None,
    month: str = "",
    date_from: str | None = None,
    date_to: str | None = None,
):
    ctx = _date_ctx("/bookings", "all", date_from, date_to)
    today = date.today().isoformat()
    if tab in ("new", "calendar"):
        tab = "add" if tab == "new" else "month"
    if tab not in ("add", "upcoming", "past", "month", "edit", "session"):
        tab = "upcoming"
    appt = None
    form_ctx = {}
    cfg = {}
    session_packages = []
    menu_packages = []
    with connect() as conn:
        cfg = load_settings(conn)
        upcoming_rows = conn.execute(
            """SELECT * FROM appointments
               WHERE date >= ? AND status NOT IN ('completed', 'cancelled', 'no_show')
               ORDER BY date, start_time""",
            (today,),
        ).fetchall()
        if not month:
            month = date.today().strftime("%Y-%m")
        past_rows = conn.execute(
            """SELECT * FROM appointments
               WHERE date LIKE ? AND (date < ? OR status IN ('completed', 'cancelled', 'no_show'))
               ORDER BY date DESC, start_time DESC LIMIT 80""",
            (f"{month}%", today),
        ).fetchall()
        cal_stats = conn.execute(
            """SELECT COUNT(*) as total,
                      COALESCE(SUM(revenue),0) as revenue,
                      COALESCE(SUM(transport_cost),0) as travel
               FROM appointments WHERE date LIKE ?""",
            (f"{month}%",),
        ).fetchone()
        clients = conn.execute("SELECT id, name FROM clients ORDER BY name").fetchall()
        if tab == "edit" and id:
            appt = conn.execute(
                "SELECT * FROM appointments WHERE id = ?", (id,)
            ).fetchone()
            if not appt:
                return RedirectResponse(url("/bookings?tab=upcoming"), status_code=302)
            if appt["date"] < today or appt["status"] in (
                "completed", "cancelled", "no_show"
            ):
                return RedirectResponse(url("/bookings?tab=past"), status_code=302)
            form_ctx = _booking_form_ctx(appt)
        elif tab == "add":
            form_ctx = _booking_form_ctx()
        if tab == "session":
            session_packages = _session_packages_list(conn)
        # Menu moved to its own page (/menu). Keep galleries available for forms if needed.
        if tab in ("add", "edit"):
            menu_packages = packages_with_galleries(conn, active_only=True)
    return templates.TemplateResponse(
        "bookings.html",
        {
            "request": request,
            "tab": tab,
            "month": month,
            "upcoming": list(upcoming_rows),
            "session_upcoming": [_session_appt_dict(r) for r in upcoming_rows],
            "session_packages": session_packages if tab == "session" else [],
            "menu_packages": menu_packages,
            "category_labels": CATEGORY_LABELS,
            "past": list(past_rows),
            "cal_stats": cal_stats,
            "clients": clients,
            "appt": appt,
            "cfg": cfg,
            **form_ctx,
            **ctx,
        },
    )


def _iso_to_time_slot(iso_val: str) -> str:
    try:
        dt = datetime.fromisoformat(iso_val.replace("Z", "+00:00"))
        if dt.tzinfo:
            dt = dt.astimezone().replace(tzinfo=None)
        return dt.strftime("%I:%M %p")
    except (TypeError, ValueError):
        return ""


@router.post("/bookings/{appt_id}/session/face-photo")
async def session_face_photo(
    appt_id: int,
    face_id: str = Form(...),
    photo: UploadFile = File(...),
):
    if not photo.filename:
        raise HTTPException(400, "No photo")
    with connect() as conn:
        appt = conn.execute(
            "SELECT id FROM appointments WHERE id = ?", (appt_id,)
        ).fetchone()
        if not appt:
            raise HTTPException(404, "Booking not found")
    path = await _save_face_photo(appt_id, face_id, photo)
    return JSONResponse({"photo_path": path})


@router.post("/bookings/session/complete")
async def session_complete(request: Request):
    try:
        body = await request.json()
    except Exception:
        body = {}
    if not body:
        form = await request.form()
        body = {
            "appointment_id": form.get("appointment_id"),
            "faces": json.loads(form.get("faces", "[]")),
            "started_at": form.get("started_at", ""),
            "finished_at": form.get("finished_at", ""),
            "duration_minutes": int(form.get("duration_minutes", 0) or 0),
        }

    appt_id = body.get("appointment_id")
    faces = body.get("faces") or []
    if not appt_id:
        raise HTTPException(400, "No booking selected")
    if not faces:
        raise HTTPException(400, "Add at least one face before finishing")

    started_at = body.get("started_at", "")
    finished_at = body.get("finished_at", "")
    start_slot = _iso_to_time_slot(started_at) if started_at else ""
    end_slot = _iso_to_time_slot(finished_at) if finished_at else ""
    duration_minutes = int(body.get("duration_minutes", 0) or 0)

    with connect() as conn:
        cfg = load_settings(conn)
        appt = conn.execute(
            "SELECT * FROM appointments WHERE id = ?", (int(appt_id),)
        ).fetchone()
        if not appt:
            raise HTTPException(404, "Booking not found")

        session_lines = _aggregate_session_faces(faces, conn)
        glam_total = sum(line["subtotal"] for line in session_lines)
        transport = float(appt["transport_cost"] or 0)
        duration_hours = round(duration_minutes / 60, 2) if duration_minutes else 0
        summary = ", ".join(
            f"{line['count']}× {line['label'].split('(')[0].strip()}"
            for line in session_lines
        )
        new_start = start_slot or appt["start_time"] or ""
        new_end = end_slot or appt["end_time"] or ""

        conn.execute(
            """UPDATE appointments SET status='completed', start_time=?, end_time=?,
               revenue=?, duration_hours=?, session_faces=?, notes=?
               WHERE id=?""",
            (
                new_start,
                new_end,
                glam_total,
                duration_hours,
                json.dumps(faces),
                summary,
                int(appt_id),
            ),
        )
        if appt["client_id"]:
            _refresh_client_ltv(conn, appt["client_id"])
        updated = conn.execute(
            "SELECT * FROM appointments WHERE id = ?", (int(appt_id),)
        ).fetchone()
        prefix = (cfg.get("business_name") or "GMU")[:3].upper()
        receipt = {
            "appt": dict(updated),
            "receipt_no": f"{prefix}-{int(appt_id):04d}",
            "session_lines": session_lines,
            "glam_total": glam_total,
            "transport_cost": transport,
            "grand_total": glam_total + transport,
        }

    return JSONResponse({
        "receipts": [receipt],
        "cfg": cfg,
        "duration_minutes": duration_minutes,
    })


@router.post("/bookings/{appt_id}/status")
async def booking_set_status(
    appt_id: int,
    status: str = Form(...),
    redirect_to: str = Form("/bookings?tab=upcoming"),
):
    allowed = {"inquiry", "confirmed", "deposit_paid", "completed", "cancelled"}
    if status not in allowed:
        raise HTTPException(400, "Invalid status")
    with connect() as conn:
        appt = conn.execute("SELECT * FROM appointments WHERE id = ?", (appt_id,)).fetchone()
        if not appt:
            return RedirectResponse(safe_redirect(redirect_to, "/bookings?tab=upcoming"), status_code=303)
        conn.execute("UPDATE appointments SET status=? WHERE id=?", (status, appt_id))
        if appt["client_id"]:
            _refresh_client_ltv(conn, appt["client_id"])
    fallback = "/bookings?tab=session" if status == "confirmed" else "/bookings?tab=upcoming"
    return RedirectResponse(safe_redirect(redirect_to, fallback), status_code=303)


@router.post("/bookings/{appt_id}/session/start")
async def booking_session_start(appt_id: int):
    """Mark actual start time when you arrive on site."""
    start_slot = _time_now_slot()
    with connect() as conn:
        appt = conn.execute("SELECT * FROM appointments WHERE id = ?", (appt_id,)).fetchone()
        if not appt:
            raise HTTPException(404, "Booking not found")
        # Ensure it's active and confirmed
        status = appt["status"] or "confirmed"
        if status == "inquiry":
            status = "confirmed"
        conn.execute(
            "UPDATE appointments SET start_time=?, status=? WHERE id=?",
            (start_slot, status, appt_id),
        )
        updated = conn.execute("SELECT * FROM appointments WHERE id = ?", (appt_id,)).fetchone()
    return JSONResponse({"start_time": updated["start_time"], "status": updated["status"]})


@router.get("/bookings/new")
async def booking_new_redirect():
    return RedirectResponse(url("/bookings?tab=add"), status_code=302)


@router.get("/bookings/{appt_id}/edit")
async def booking_edit_redirect(appt_id: int):
    return RedirectResponse(url(f"/bookings?tab=edit&id={appt_id}"), status_code=302)


@router.post("/bookings/new")
async def booking_create(
    client_id: int = Form(0),
    new_client_name: str = Form(""),
    new_client_phone: str = Form(""),
    date_val: str = Form(..., alias="date"),
    start_time: str = Form(""),
    end_time: str = Form(""),
    package_id: str = Form("tbd"),
    service_style: str = Form(""),
    headcount_tier: str = Form(""),
    revenue: float = Form(0),
    transport_cost: float = Form(0),
    payment_method: str = Form("cash"),
    status: str = Form("inquiry"),
    location: str = Form(""),
    lat: str = Form(""),
    lng: str = Form(""),
    photo: UploadFile | None = File(None),
):
    with connect() as conn:
        resolved = _resolve_client(conn, client_id, new_client_name, new_client_phone)
        if not resolved:
            return RedirectResponse(url("/bookings?tab=add"), status_code=303)
        client_id, client_name = resolved

        if package_id == "tbd":
            service_style = ""
            headcount_tier = ""
            revenue = 0
        else:
            pkg = package_by_id(conn, package_id)
            if pkg:
                if pkg["service_style"] and not service_style:
                    service_style = pkg["service_style"]
                if pkg["headcount_tier"] and not headcount_tier:
                    headcount_tier = pkg["headcount_tier"]
                if pkg["price"] and not revenue:
                    revenue = float(pkg["price"])
        if payment_method not in {m[0] for m in PAYMENT_METHODS}:
            payment_method = "cash"

        lat_val = float(lat) if lat else None
        lng_val = float(lng) if lng else None

        conn.execute(
            """INSERT INTO appointments
            (client_id, client_name, date, start_time, end_time, service_style,
             headcount_tier, revenue, transport_cost, payment_method, status,
             location, lat, lng)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)""",
            (client_id, client_name, date_val, start_time, end_time,
             service_style, headcount_tier, revenue, transport_cost, payment_method, status,
             location.strip(), lat_val, lng_val),
        )
        appt_id = conn.execute("SELECT last_insert_rowid()").fetchone()[0]
        photo_path = await _save_booking_photo(appt_id, photo)
        if photo_path:
            conn.execute(
                "UPDATE appointments SET photo_path=? WHERE id=?",
                (photo_path, appt_id),
            )
        _refresh_client_ltv(conn, client_id)
    return RedirectResponse(url("/bookings?tab=upcoming"), status_code=303)


@router.post("/bookings/{appt_id}/edit")
async def booking_update(
    appt_id: int,
    client_id: int = Form(0),
    new_client_name: str = Form(""),
    new_client_phone: str = Form(""),
    date_val: str = Form(..., alias="date"),
    start_time: str = Form(""),
    end_time: str = Form(""),
    package_id: str = Form("custom"),
    service_style: str = Form(""),
    headcount_tier: str = Form(""),
    revenue: float = Form(0),
    transport_cost: float = Form(0),
    payment_method: str = Form("cash"),
    status: str = Form("confirmed"),
    location: str = Form(""),
    lat: str = Form(""),
    lng: str = Form(""),
    photo: UploadFile | None = File(None),
):
    today = date.today().isoformat()
    with connect() as conn:
        pkg = package_by_id(conn, package_id)
        if pkg:
            if pkg["service_style"] and not service_style:
                service_style = pkg["service_style"]
            if pkg["headcount_tier"] and not headcount_tier:
                headcount_tier = pkg["headcount_tier"]
        if payment_method not in {m[0] for m in PAYMENT_METHODS}:
            payment_method = "cash"

        appt = conn.execute(
            "SELECT * FROM appointments WHERE id = ?", (appt_id,)
        ).fetchone()
        if not appt:
            return RedirectResponse(url("/bookings?tab=upcoming"), status_code=302)
        if appt["date"] < today or appt["status"] in ("completed", "cancelled", "no_show"):
            return RedirectResponse(url("/bookings?tab=upcoming"), status_code=302)

        resolved = _resolve_client(conn, client_id, new_client_name, new_client_phone)
        if not resolved:
            return RedirectResponse(url(f"/bookings?tab=edit&id={appt_id}"), status_code=303)
        client_id, client_name = resolved

        if package_id == "tbd":
            if status == "inquiry":
                service_style = ""
                headcount_tier = ""
        else:
            pkg = package_by_id(conn, package_id)
            if pkg:
                if pkg["service_style"] and not service_style:
                    service_style = pkg["service_style"]
                if pkg["headcount_tier"] and not headcount_tier:
                    headcount_tier = pkg["headcount_tier"]

        client = {"name": client_name}

        photo_path = appt["photo_path"] if "photo_path" in appt.keys() else ""
        new_photo = await _save_booking_photo(appt_id, photo)
        if new_photo:
            photo_path = new_photo

        lat_val = float(lat) if lat else None
        lng_val = float(lng) if lng else None

        conn.execute(
            """UPDATE appointments SET
               client_id=?, client_name=?, date=?, start_time=?, end_time=?,
               service_style=?, headcount_tier=?, revenue=?, transport_cost=?, payment_method=?,
               status=?, photo_path=?, location=?, lat=?, lng=?
               WHERE id=?""",
            (client_id, client["name"], date_val, start_time, end_time,
             service_style, headcount_tier, revenue, transport_cost, payment_method, status,
             photo_path or "", location.strip(), lat_val, lng_val, appt_id),
        )
        if appt["client_id"] != client_id:
            _refresh_client_ltv(conn, appt["client_id"])
        _refresh_client_ltv(conn, client_id)
    return RedirectResponse(url("/bookings?tab=upcoming"), status_code=303)


@router.post("/bookings/{appt_id}/delete")
async def booking_delete(
    appt_id: int,
    redirect_to: str = Form("/bookings?tab=upcoming"),
):
    dest = redirect_to if redirect_to.startswith("/") else "/bookings?tab=upcoming"
    with connect() as conn:
        appt = conn.execute(
            "SELECT * FROM appointments WHERE id = ?", (appt_id,)
        ).fetchone()
        if not appt:
            return RedirectResponse(safe_redirect(dest, "/bookings?tab=upcoming"), status_code=303)
        client_id = appt["client_id"]
        _remove_booking_photo(appt["photo_path"])
        conn.execute("DELETE FROM appointments WHERE id = ?", (appt_id,))
        if client_id:
            _refresh_client_ltv(conn, client_id)
    return RedirectResponse(safe_redirect(dest, "/bookings?tab=upcoming"), status_code=303)


@router.get("/analytics", response_class=HTMLResponse)
async def analytics_page(
    request: Request,
    period: str = "month",
    date_from: str | None = None,
    date_to: str | None = None,
):
    ctx = _date_ctx("/analytics", period, date_from, date_to)
    start, end = ctx["range_start"], ctx["range_end"]
    with connect() as conn:
        insights = fetch_insights(conn, start, end)
    return templates.TemplateResponse(
        "analytics.html",
        {
            "request": request,
            "insights": insights,
            "summary": insights["summary"],
            "start": start,
            "end": end,
            **ctx,
        },
    )


@router.get("/expenses", response_class=HTMLResponse)
async def expenses_page(
    request: Request,
    date_from: str | None = None,
    date_to: str | None = None,
):
    ctx = _date_ctx("/expenses", "all", date_from, date_to)
    start, end = ctx["range_start"], ctx["range_end"]
    with connect() as conn:
        rows = conn.execute(
            """SELECT * FROM expenses
               WHERE date IS NULL OR date BETWEEN ? AND ?
               ORDER BY date DESC, id DESC""",
            (start, end),
        ).fetchall()
        total = conn.execute(
            """SELECT COALESCE(SUM(amount),0) FROM expenses
               WHERE date IS NULL OR date BETWEEN ? AND ?""",
            (start, end),
        ).fetchone()[0]
    return templates.TemplateResponse(
        "expenses.html", {"request": request, "expenses": rows, "total": total, **ctx}
    )


@router.get("/income", response_class=HTMLResponse)
async def income_page(
    request: Request,
    period: str = "month",
    date_from: str | None = None,
    date_to: str | None = None,
):
    ctx = _date_ctx("/income", period, date_from, date_to)
    start, end = ctx["range_start"], ctx["range_end"]
    pcts = get_split_pcts()
    with connect() as conn:
        rows = conn.execute(
            """SELECT * FROM income_allocations
               WHERE date IS NULL OR date BETWEEN ? AND ?
               ORDER BY date DESC LIMIT 60""",
            (start, end),
        ).fetchall()
        totals = conn.execute(
            """SELECT COALESCE(SUM(total_earned),0) as earned,
                      COALESCE(SUM(savings),0) as savings,
                      COALESCE(SUM(business),0) as business,
                      COALESCE(SUM(personal),0) as personal,
                      COALESCE(SUM(drawings),0) as drawings
               FROM income_allocations
               WHERE date IS NULL OR date BETWEEN ? AND ?""",
            (start, end),
        ).fetchone()
        notes = conn.execute(
            """SELECT * FROM studio_notes
               WHERE category IN ('income', 'general')
               ORDER BY created_at DESC LIMIT 20"""
        ).fetchall()
    earned = float(totals["earned"] or 0)
    target = calc_split(earned, pcts)
    return templates.TemplateResponse(
        "income.html",
        {
            "request": request,
            "rows": rows,
            "totals": totals,
            "pcts": pcts,
            "target": target,
            "notes": notes,
            **ctx,
        },
    )


@router.post("/income/split")
async def income_split_save(
    split_savings_pct: float = Form(30),
    split_business_pct: float = Form(40),
    split_personal_pct: float = Form(30),
):
    for k, v in {
        "split_savings_pct": str(split_savings_pct),
        "split_business_pct": str(split_business_pct),
        "split_personal_pct": str(split_personal_pct),
    }.items():
        set_setting(k, v)
    return RedirectResponse(url("/income?saved=1"), status_code=303)


@router.post("/notes/add")
async def note_add(
    body: str = Form(...),
    category: str = Form("general"),
    redirect_to: str = Form("/income"),
):
    body = body.strip()
    if body:
        with connect() as conn:
            conn.execute(
                "INSERT INTO studio_notes (category, body) VALUES (?, ?)",
                (category, body),
            )
    dest = redirect_to if redirect_to.startswith("/") else "/income"
    return RedirectResponse(safe_redirect(dest, "/income"), status_code=303)


@router.post("/notes/{note_id}/delete")
async def note_delete(note_id: int, redirect_to: str = Form("/income")):
    with connect() as conn:
        conn.execute("DELETE FROM studio_notes WHERE id = ?", (note_id,))
    dest = redirect_to if redirect_to.startswith("/") else "/income"
    return RedirectResponse(safe_redirect(dest, "/income"), status_code=303)


@router.get("/receipts", response_class=HTMLResponse)
async def receipts_list(
    request: Request,
    date_from: str | None = None,
    date_to: str | None = None,
):
    ctx = _date_ctx("/receipts", "all", date_from, date_to)
    start, end = ctx["range_start"], ctx["range_end"]
    with connect() as conn:
        rows = conn.execute(
            """SELECT id, client_name, date, revenue, transport_cost, service_style
               FROM appointments WHERE date BETWEEN ? AND ?
               ORDER BY date DESC LIMIT 80""",
            (start, end),
        ).fetchall()
    return templates.TemplateResponse(
        "receipts.html", {"request": request, "appointments": rows, **ctx}
    )


@router.get("/receipts/{appt_id}", response_class=HTMLResponse)
async def receipt_detail(request: Request, appt_id: int):
    with connect() as conn:
        appt = conn.execute(
            "SELECT * FROM appointments WHERE id = ?", (appt_id,)
        ).fetchone()
        if not appt:
            return RedirectResponse(url("/receipts"), status_code=302)
        cfg = load_settings(conn)
        session_lines = _session_lines_from_appt(appt, conn)
    prefix = (cfg.get("business_name") or "GMU")[:3].upper()
    receipt_no = f"{prefix}-{appt_id:04d}"
    glam_total = sum(line["subtotal"] for line in session_lines) if session_lines else float(appt["revenue"] or 0)
    transport = float(appt["transport_cost"] or 0)
    return templates.TemplateResponse(
        "receipt_detail.html",
        {
            "request": request,
            "appt": appt,
            "cfg": cfg,
            "receipt_no": receipt_no,
            "session_lines": session_lines,
            "glam_total": glam_total,
            "grand_total": glam_total + transport,
        },
    )


@router.get("/instagram", response_class=HTMLResponse)
async def instagram_page(request: Request):
    stats = fetch_instagram_stats()
    return templates.TemplateResponse(
        "instagram.html", {"request": request, "ig": stats}
    )


@router.get("/touch-up", response_class=HTMLResponse)
async def touchup_page(request: Request):
    with connect() as conn:
        recent = conn.execute(
            """SELECT client_name, date, service_style FROM appointments
               ORDER BY date DESC LIMIT 10"""
        ).fetchall()
    templates_list = [
        {
            "title": "Post-glam care",
            "body": "Hi {name}! 💋 Your lip shade today was {lip}. Blot gently and carry {lip} for touch-ups. Enjoy your event! — Nawal @glam.me.upp",
        },
        {
            "title": "Bridal thank you",
            "body": "Congratulations {name}! ✨ It was an honour doing your bridal glam. Send me photos — I'd love to see! Book touch-ups anytime. — Nawal",
        },
        {
            "title": "Product list",
            "body": "Hi {name}, products used today:\n• Foundation: {foundation}\n• Lip: {lip}\n• Setting: {setting}\n\nDM me for re-booking 💄",
        },
    ]
    return templates.TemplateResponse(
        "touchup.html",
        {"request": request, "recent": recent, "templates_list": templates_list},
    )


@router.get("/more", response_class=HTMLResponse)
async def more_hub(request: Request):
    return templates.TemplateResponse("more.html", {"request": request})


@router.get("/rate-card", response_class=HTMLResponse)
async def rate_card_page(request: Request):
    with connect() as conn:
        packages = load_packages(conn, active_only=True)
    return templates.TemplateResponse(
        "rate_card.html",
        {
            "request": request,
            "packages": packages,
            "packages_grouped": packages_grouped(packages),
            "category_labels": CATEGORY_LABELS,
        },
    )


@router.get("/menu", response_class=HTMLResponse)
async def menu_page(request: Request):
    with connect() as conn:
        packages = packages_with_galleries(conn, active_only=True)
    return templates.TemplateResponse(
        "menu.html",
        {
            "request": request,
            "packages": packages,
            "category_labels": CATEGORY_LABELS,
        },
    )


@router.get("/settings/packages", response_class=HTMLResponse)
async def packages_settings(request: Request):
    with connect() as conn:
        packages = packages_with_galleries(conn, active_only=False)
    return templates.TemplateResponse(
        "packages_settings.html",
        {
            "request": request,
            "packages": packages,
            "packages_grouped": packages_grouped(packages),
            "category_labels": CATEGORY_LABELS,
        },
    )


@router.post("/settings/packages")
async def packages_settings_save(request: Request):
    form = await request.form()
    with connect() as conn:
        for pkg in load_packages(conn, active_only=False):
            pid = pkg["id"]
            label = form.get(f"label_{pid}", pkg["label"])
            try:
                price = float(form.get(f"price_{pid}", pkg["price"]) or 0)
            except ValueError:
                price = pkg["price"]
            active = 1 if form.get(f"active_{pid}") else 0
            conn.execute(
                """UPDATE service_packages SET label=?, price=?, active=?
                   WHERE id=?""",
                (str(label).strip(), price, active, pid),
            )
        for pkg in load_packages(conn, active_only=False):
            pid = pkg["id"]
            files = [
                v for k, v in form.multi_items()
                if k == f"images_{pid}" and hasattr(v, "filename") and v.filename
            ]
            await _save_package_images(conn, pid, files)
    return RedirectResponse(url("/settings/packages?saved=1"), status_code=303)


@router.post("/settings/packages/{package_id}/image/{image_id}/delete")
async def package_image_delete(package_id: str, image_id: int):
    with connect() as conn:
        row = conn.execute(
            "SELECT path FROM package_images WHERE id = ? AND package_id = ?",
            (image_id, package_id),
        ).fetchone()
        if row and row["path"]:
            if "uploads/packages/" in row["path"]:
                rel = row["path"].split("uploads/packages/")[-1].split("?")[0]
                path = BASE / "static" / "uploads" / "packages" / rel
                if path.is_file():
                    path.unlink(missing_ok=True)
        conn.execute(
            "DELETE FROM package_images WHERE id = ? AND package_id = ?",
            (image_id, package_id),
        )
    return RedirectResponse(url("/settings/packages?saved=1"), status_code=303)


@router.get("/settings", response_class=HTMLResponse)
async def settings_page(request: Request):
    with connect() as conn:
        cfg = load_settings(conn)
    return templates.TemplateResponse("settings.html", {"request": request, "cfg": cfg})


@router.post("/settings")
async def settings_save(
    business_name: str = Form(""),
    artist_name: str = Form(""),
    tagline: str = Form(""),
    phone: str = Form(""),
    instagram: str = Form(""),
    currency: str = Form("TZS"),
    receipt_footer: str = Form(""),
    primary_color: str = Form("#000000"),
    accent_color: str = Form("#000000"),
):
    for k, v in {
        "business_name": business_name, "artist_name": artist_name,
        "tagline": tagline, "phone": phone, "instagram": instagram,
        "currency": currency, "receipt_footer": receipt_footer,
        "primary_color": primary_color, "accent_color": accent_color,
    }.items():
        set_setting(k, v)
    set_setting("google_maps_api_key", "")
    return RedirectResponse(url("/settings?saved=1"), status_code=303)


@router.post("/settings/logo/clear")
async def clear_logo():
    set_setting("logo_path", "")
    return RedirectResponse(url("/settings?logo=cleared"), status_code=303)


@router.post("/settings/logo")
async def upload_logo(logo: UploadFile = File(...)):
    ext = Path(logo.filename or "logo.png").suffix or ".png"
    dest = BASE / "static" / "uploads" / f"logo{ext}"
    dest.write_bytes(await logo.read())
    set_setting("logo_path", static_url(f"uploads/logo{ext}"))
    return RedirectResponse(url("/settings?logo=1"), status_code=303)


@router.post("/settings/reimport")
async def reimport_data():
    import_seed(force=True)
    return RedirectResponse(url("/settings?reimported=1"), status_code=303)


@router.get("/robots.txt", response_class=PlainTextResponse)
async def robots():
    return PlainTextResponse("User-agent: *\nDisallow: /\n")


# --- Root app: mount at /gmu, hide OpenAPI ---
gmu_app = FastAPI(title="Glam Me Upp Studio", docs_url=None, redoc_url=None, openapi_url=None)
gmu_app.add_event_handler("startup", on_startup)
gmu_app.include_router(router)

app = FastAPI(docs_url=None, redoc_url=None, openapi_url=None)
app.mount(BASE_PATH + "/static", StaticFiles(directory=str(BASE / "static")), name="static")
app.mount(BASE_PATH, gmu_app)


@app.get("/")
async def root_redirect():
    return RedirectResponse(BASE_PATH + "/", status_code=302)
