# marmalade-cloudflared

A minimal [`cloudflared`](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
container for running a **remotely-managed Cloudflare Tunnel** on a
[marmalade.services](https://marmalade.services) tenant, deployed via Coolify.

The tunnel is configured entirely from the Cloudflare Zero Trust dashboard
(Networks → Tunnels). This container just runs the connector and routes traffic
to your apps on the tenant network.

## How it works

- The tunnel **token** is supplied at runtime via the `TUNNEL_TOKEN`
  environment variable (set as a secret in Coolify). It is never committed to
  this repo or baked into the image.
- If `TUNNEL_TOKEN` is unset, the container idles instead of crash-looping, so
  it can be deployed before the token exists.
- Once the token is set, `cloudflared --no-autoupdate tunnel run` connects to
  the Cloudflare edge.

## Routing future apps

In the Cloudflare dashboard, add **Public Hostnames** to this tunnel and point
each one at the internal address of an app on the marmalade tenant network
(e.g. `http://10.152.0.x:PORT` or a tailnet hostname). New apps just need a new
public-hostname entry — no redeploy of this connector required.
