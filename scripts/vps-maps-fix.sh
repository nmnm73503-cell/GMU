#!/bin/bash
# Glam Me Upp — Maps diagnostic + fix (run on VPS as any user with sudo)
# Usage:
#   bash vps-maps-fix.sh           # diagnose only
#   bash vps-maps-fix.sh osm       # switch to OpenStreetMap (no Google key)
#   bash vps-maps-fix.sh google    # re-enable Google (uses key in DB)

set -euo pipefail
APP=/opt/glam-me-upp/web
MODE="${1:-diag}"

echo "=============================================="
echo " GMU MAPS — mode: $MODE"
echo "=============================================="

if [[ ! -d "$APP" ]]; then
  echo "ERROR: $APP not found"
  exit 1
fi

cd "$APP"

run_py() {
  sudo -u www-data ./venv/bin/python3 "$@"
}

echo ""
echo "--- 1) Key in database ---"
run_py - <<'PY'
from database import connect, get_setting, set_setting, _normalize_google_maps_key

with connect() as c:
    raw = c.execute(
        "SELECT value FROM settings WHERE key='google_maps_api_key'"
    ).fetchone()
raw_val = raw[0] if raw else ""
norm = _normalize_google_maps_key(raw_val)
print("raw length:", len(raw_val or ""))
print("raw prefix:", repr((raw_val or "")[:8]))
print("normalized prefix:", repr(norm[:8]) if norm else "(empty)")
if raw_val and raw_val.startswith("AlzaSy"):
    print("WARNING: typo AlzaSy → should be AIzaSy (capital i)")
print("normalized valid format:", bool(norm.startswith("AIza") and len(norm) >= 35))
PY

KEY=$(run_py -c "from database import get_setting; print(get_setting('google_maps_api_key',''))")

echo ""
echo "--- 2) Google API tests (if key set) ---"
if [[ -z "$KEY" ]]; then
  echo "No key → app uses OpenStreetMap (Leaflet). Good."
else
  GEO=$(curl -sS "https://maps.googleapis.com/maps/api/geocode/json?address=Dar+es+Salaam&key=${KEY}")
  echo "Geocoding API: $(echo "$GEO" | run_py -c "import sys,json; d=json.load(sys.stdin); print(d.get('status'), '-', d.get('error_message','OK')[:120])")"
  SM=$(curl -sS "https://maps.googleapis.com/maps/api/staticmap?center=-6.79,39.21&zoom=12&size=200x200&key=${KEY}" | head -c 200)
  if echo "$SM" | grep -q "PNG"; then
    echo "Static Maps API: OK"
  else
    echo "Static Maps API: FAIL"
    echo "$SM" | tr '\n' ' ' | head -c 200
    echo ""
  fi
  JS=$(curl -sS "https://maps.googleapis.com/maps/api/js?key=${KEY}&libraries=places" | head -c 80)
  if echo "$JS" | grep -qi "error\|invalid"; then
    echo "Maps JS loader: possible error in response"
  else
    echo "Maps JS loader: returns JavaScript (library may load but tiles can still fail)"
  fi
fi

echo ""
echo "--- 3) Live page check ---"
curl -sS "http://127.0.0.1:8081/gmu/bookings?tab=add" | grep -oE 'googleKey|leaflet|location-picker|maps.googleapis' | sort -u || true

echo ""
echo "--- 4) Apply fix: $MODE ---"
case "$MODE" in
  osm)
    run_py - <<'PY'
from database import set_setting
set_setting("google_maps_api_key", "")
print("DONE: Google key cleared. App will use OpenStreetMap on Bookings → Add.")
PY
    ;;
  google)
    run_py - <<'PY'
from database import get_setting, set_setting, _normalize_google_maps_key
k = _normalize_google_maps_key(get_setting("google_maps_api_key", ""))
if not k:
    print("No key in DB. Add one in More → Settings, or:")
    print('  sudo -u www-data ./venv/bin/python3 -c "from database import set_setting; set_setting(\\"google_maps_api_key\\", \\"AIzaSy...\\")"')
else:
    set_setting("google_maps_api_key", k)
    print("Key normalized and saved. Enable in Google Cloud:")
    print("  - Maps JavaScript API")
    print("  - Places API")
    print("  - Billing on the project")
    print("  - HTTP referrer: https://munasdream.mooo.com/*")
PY
    ;;
  diag|*)
    echo "Diagnose only. To fix now, run ONE of:"
    echo "  bash $0 osm      # use free OSM map (works immediately)"
    echo "  bash $0 google   # keep Google, print checklist"
    ;;
esac

echo ""
echo "--- 5) Restart app ---"
sudo systemctl restart gmu
sleep 1
sudo systemctl is-active gmu && echo "gmu service: active" || echo "gmu service: FAILED"

echo ""
echo "=============================================="
echo " Open on phone: https://munasdream.mooo.com/gmu/bookings?tab=add"
echo " Hard-refresh after any change."
echo "=============================================="
