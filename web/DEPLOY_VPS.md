# Glam Me Upp — munasdream.mooo.com/gmu

Passwordless private studio app for **Nawal** (@glam.me.upp).  
Open on iPhone: **https://munasdream.mooo.com/gmu/** → Share → Add to Home Screen.

---

## Quick deploy on VPS

```bash
# 1. Copy project
sudo mkdir -p /opt/glam-me-upp
sudo cp -r web /opt/glam-me-upp/
sudo cp -r GlamMeUppStudio/Resources/SeedData /opt/glam-me-upp/GlamMeUppStudio/Resources/

# 2. Python venv (light ~50MB RAM running)
cd /opt/glam-me-upp/web
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 3. Test locally on VPS
uvicorn app:app --host 127.0.0.1 --port 8081
# curl http://127.0.0.1:8081/gmu/
```

---

## systemd (always on)

```bash
sudo cp deploy/gmu.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now gmu
sudo systemctl status gmu
```

---

## nginx (munasdream.mooo.com)

Add snippet from `deploy/nginx-gmu.conf` to your nginx site config, then:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

---

## iPhone setup

1. Safari → `https://munasdream.mooo.com/gmu/`
2. Share → **Add to Home Screen**
3. Name: **Glam Me Upp**

No password. URL is private (not indexed — robots.txt + noindex).

---

## All pages

| URL | Purpose |
|-----|---------|
| `/gmu/` | Dashboard + animated logo hero |
| `/gmu/clients` | Client list + search |
| `/gmu/clients/new` | Add client |
| `/gmu/clients/{id}` | Client history |
| `/gmu/calendar` | Monthly bookings |
| `/gmu/bookings/new` | New appointment |
| `/gmu/analytics` | Charts & income split |
| `/gmu/expenses` | Business expenses |
| `/gmu/income` | Savings / personal allocations |
| `/gmu/receipts` | Receipt list |
| `/gmu/receipts/{id}` | Printable receipt with logo |
| `/gmu/instagram` | @glam.me.upp stats |
| `/gmu/touch-up` | Client care message templates |
| `/gmu/more` | Hub for all tools |
| `/gmu/settings` | Logo upload, branding |

---

## Logo

Default vector logo: `/gmu/static/img/logo.svg`  
Favicon: `/gmu/static/img/favicon.svg`  
Upload custom logo in Settings — appears on receipts.

---

## Data

Auto-imports `career_seed.json` on first start (12 clients, 49 bookings, income records).

Re-import anytime: **Settings → Re-import My Career data**
