FROM debian:bookworm-slim

# Install cloudflared (latest stable) + tailscale.
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl gnupg iptables \
 && curl -fsSL -o /usr/local/bin/cloudflared \
      https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
 && chmod +x /usr/local/bin/cloudflared \
 && curl -fsSL https://tailscale.com/install.sh | sh \
 && apt-get purge -y curl gnupg \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /var/lib/tailscale

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Secrets are supplied at runtime via env vars (set in Coolify), never baked in:
#   TUNNEL_TOKEN  - Cloudflare tunnel token (required for the tunnel)
#   TS_AUTHKEY    - optional Tailscale auth key; if unset, the container prints
#                   an interactive login URL to its logs instead.
ENTRYPOINT ["/entrypoint.sh"]
