# Local PC — Glam Me Upp Web

## Already done on this machine
- Python venv created (`web/venv/`)
- Dependencies installed
- Database seeded (12 clients, 49 bookings)
- Local server tested OK
- Deploy package: `/home/mohamad443/projects/glam-me-upp-deploy.tar.gz`

## Run locally (test on PC)
```bash
cd /home/mohamad443/projects/GlamMeUppStudio/web
source venv/bin/activate
uvicorn app:app --host 127.0.0.1 --port 8081
```
Open: http://127.0.0.1:8081/gmu/

## Upload to VPS (one file)
```bash
scp /home/mohamad443/projects/glam-me-upp-deploy.tar.gz \
  midwayboot11200@munasdream.mooo.com:/tmp/
```

Then on VPS extract — see DEPLOY_VPS.md

## Re-pack after changes
```bash
bash /home/mohamad443/projects/GlamMeUppStudio/web/pack_for_vps.sh
```
