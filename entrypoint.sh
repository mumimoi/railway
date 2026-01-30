#!/usr/bin/env bash
set -euo pipefail

# Default root password = 123 (contoh). Override: -e ROOT_PASSWORD=xxxxx
ROOT_PASSWORD="${ROOT_PASSWORD:-123}"
echo "root:${ROOT_PASSWORD}" | chpasswd

# Generate host keys kalau belum ada
ssh-keygen -A >/dev/null 2>&1 || true

# Start SSHD (foreground, biar container "hidup")
/usr/sbin/sshd -D -e &
SSHD_PID=$!

# Start HTTP server di 6080 -> serve /var/www/index.html ("Hello World")
python3 -m http.server 6080 --directory /var/www >/dev/null 2>&1 &
HTTP_PID=$!

# Start cloudflared jika token diset
# Untuk remotely-managed tunnel: cloudflared tunnel run --token <TUNNEL_TOKEN> 2
if [[ -n "${TUNNEL_TOKEN:-}" ]]; then
  cloudflared tunnel run --token "${TUNNEL_TOKEN}" &
  CF_PID=$!
else
  CF_PID=""
  echo "[entrypoint] TUNNEL_TOKEN kosong -> cloudflared tidak dijalankan"
fi

# Shutdown handler
term() {
  kill -TERM "${HTTP_PID}" 2>/dev/null || true
  kill -TERM "${SSHD_PID}" 2>/dev/null || true
  if [[ -n "${CF_PID}" ]]; then kill -TERM "${CF_PID}" 2>/dev/null || true; fi
  wait || true
}
trap term INT TERM

# Tunggu proses utama
wait -n
