FROM debian:bookworm-slim

# Install cloudflared (latest stable) from Cloudflare's official release.
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && curl -fsSL -o /usr/local/bin/cloudflared \
      https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
 && chmod +x /usr/local/bin/cloudflared \
 && apt-get purge -y curl \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# The tunnel token is supplied at runtime via the TUNNEL_TOKEN env var
# (set as a secret in Coolify). It is never baked into the image.
ENTRYPOINT ["/entrypoint.sh"]
