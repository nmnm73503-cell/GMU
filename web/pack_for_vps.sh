#!/bin/bash
# Create tarball ready to upload to VPS
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="/home/mohamad443/projects/glam-me-upp-deploy.tar.gz"
cd "$ROOT"
tar czf "$OUT" \
  web/*.py web/requirements.txt web/setup_local.sh \
  web/static web/templates web/deploy \
  GlamMeUppStudio/Resources/SeedData/career_seed.json
echo "Created: $OUT"
ls -lh "$OUT"
echo ""
echo "Deploy to VPS:"
echo "  scp $OUT user@host:/tmp/"
echo "  ssh user@host 'cd /tmp && mkdir -p gmu-deploy && tar xzf glam-me-upp-deploy.tar.gz -C gmu-deploy && sudo cp -a gmu-deploy/web/. /opt/glam-me-upp/web/ && sudo chown -R www-data:www-data /opt/glam-me-upp/web/static /opt/glam-me-upp/web/templates && sudo systemctl restart gmu'"
