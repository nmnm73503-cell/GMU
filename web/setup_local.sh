#!/bin/bash
# Glam Me Upp — local setup & quick test (light on RAM)
set -e
cd "$(dirname "$0")"
echo "→ Creating venv..."
python3 -m venv venv
source venv/bin/activate
pip install -q -r requirements.txt
echo "→ Initializing database & seed data..."
python3 -c "from database import init_db; from seed import import_seed; init_db(); print(import_seed(force=True))"
echo "→ Done. Run: source venv/bin/activate && uvicorn app:app --host 127.0.0.1 --port 8081"
echo "→ Open: http://127.0.0.1:8081/gmu/"
