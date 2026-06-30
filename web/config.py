"""App configuration — served at munasdream.mooo.com/gmu"""
import os

# Subpath on VPS (no password; private dedicated URL)
BASE_PATH = os.environ.get("GMU_BASE_PATH", "/gmu")

# Public site URL for meta tags / receipts
PUBLIC_URL = os.environ.get(
    "GMU_PUBLIC_URL", "https://munasdream.mooo.com/gmu"
)

APP_TITLE = "Glam Me Upp Studio"
DEDICATED_FOR = "Nawal — @glam.me.upp"
