#!/bin/sh
set -e

# cloudflared reads the tunnel token from the TUNNEL_TOKEN environment variable.
# If it isn't set yet, idle gracefully instead of crash-looping so the container
# can be deployed ahead of time and started the moment the token is provided.
if [ -z "$TUNNEL_TOKEN" ]; then
  echo "[entrypoint] TUNNEL_TOKEN is not set yet — idling."
  echo "[entrypoint] Set TUNNEL_TOKEN as a secret env var and redeploy/restart to bring the tunnel up."
  while [ -z "$TUNNEL_TOKEN" ]; do
    sleep 30
  done
fi

echo "[entrypoint] TUNNEL_TOKEN detected — starting cloudflared tunnel."
exec cloudflared --no-autoupdate tunnel run
