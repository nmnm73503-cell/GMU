"""Fetch public Instagram stats for @glam.me.upp — cached, lightweight."""
import json
import urllib.request
from datetime import datetime, timezone

from database import get_setting, set_setting

HANDLE = "glam.me.upp"
CACHE_KEY = "instagram_cache"
CACHE_TTL_SECONDS = 3600


def fetch_instagram_stats() -> dict:
    cached = get_setting(CACHE_KEY, "")
    if cached:
        try:
            data = json.loads(cached)
            ts = datetime.fromisoformat(data.get("fetched_at", "2000-01-01"))
            age = (datetime.now(timezone.utc) - ts.replace(tzinfo=timezone.utc)).total_seconds()
            if age < CACHE_TTL_SECONDS:
                return data
        except (json.JSONDecodeError, ValueError):
            pass

    result = {
        "handle": HANDLE,
        "full_name": "Nawal | Makeup Artist",
        "followers": 0,
        "following": 0,
        "posts": 0,
        "biography": "",
        "fetched_at": datetime.now(timezone.utc).isoformat(),
        "error": None,
    }

    try:
        req = urllib.request.Request(
            f"https://www.instagram.com/api/v1/users/web_profile_info/?username={HANDLE}",
            headers={
                "X-IG-App-ID": "936619743392459",
                "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)",
            },
        )
        with urllib.request.urlopen(req, timeout=12) as resp:
            payload = json.loads(resp.read().decode())
        user = payload.get("data", {}).get("user", {})
        result.update(
            {
                "full_name": user.get("full_name", result["full_name"]),
                "followers": user.get("edge_followed_by", {}).get("count", 0),
                "following": user.get("edge_follow", {}).get("count", 0),
                "posts": user.get("edge_owner_to_timeline_media", {}).get("count", 0),
                "biography": user.get("biography", ""),
                "profile_url": f"https://www.instagram.com/{HANDLE}/",
            }
        )
    except Exception as exc:
        result["error"] = str(exc)
        result["followers"] = 1961
        result["following"] = 765
        result["posts"] = 160
        result["biography"] = (
            "Dar es Salaam | Available for travel\n"
            "Bridal • Event • Photoshoots\nBookings via Call"
        )

    set_setting(CACHE_KEY, json.dumps(result))
    return result
