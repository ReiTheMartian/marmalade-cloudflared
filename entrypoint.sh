#!/bin/sh
set -e

# ---------------------------------------------------------------------------
# Tailscale (userspace-networking; the container has no NET_ADMIN/TUN).
# Joins the tenant's tailnet so the connector is reachable/can reach peers.
# State lives in /var/lib/tailscale — it survives container *restarts* but is
# lost on a full *redeploy* (no persistent volume), after which you re-auth.
# ---------------------------------------------------------------------------
if command -v tailscaled >/dev/null 2>&1; then
  echo "[entrypoint] starting tailscaled (userspace-networking)"
  tailscaled \
    --tun=userspace-networking \
    --statedir=/var/lib/tailscale \
    --socks5-server=localhost:1055 \
    >/var/log/tailscaled.log 2>&1 &

  # Wait for the daemon socket to come up.
  i=0
  while [ ! -S /var/run/tailscale/tailscaled.sock ] && [ "$i" -lt 10 ]; do
    sleep 1
    i=$((i + 1))
  done

  TS_ARGS="--hostname=marmalade-cloudflared --accept-routes"
  if [ -n "$TS_AUTHKEY" ]; then
    echo "[entrypoint] bringing up tailscale with TS_AUTHKEY"
    tailscale up --authkey="$TS_AUTHKEY" $TS_ARGS \
      || echo "[entrypoint] 'tailscale up --authkey' failed"
  else
    # Interactive auth: prints a login URL to the logs. Backgrounded so it
    # never blocks cloudflared. Re-run to get a fresh URL: tailscale up
    echo "[entrypoint] no TS_AUTHKEY set — requesting an interactive login URL"
    ( tailscale up $TS_ARGS 2>&1 | sed 's/^/[tailscale] /' ) &
  fi
fi

# ---------------------------------------------------------------------------
# Cloudflared (the main/foreground process).
# ---------------------------------------------------------------------------
if [ -z "$TUNNEL_TOKEN" ]; then
  echo "[entrypoint] TUNNEL_TOKEN is not set yet — idling."
  echo "[entrypoint] Set TUNNEL_TOKEN as a secret env var and redeploy to bring the tunnel up."
  while [ -z "$TUNNEL_TOKEN" ]; do
    sleep 30
  done
fi

echo "[entrypoint] TUNNEL_TOKEN detected — starting cloudflared tunnel."
exec cloudflared --no-autoupdate tunnel run
