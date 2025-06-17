# HAProxy Scripts

This repository contains helper scripts for working with HAProxy.

## haproxy-stats.sh

Retrieve statistics from the HAProxy admin socket and print them in different views.

```
haproxy-stats.sh [view] [backend]
```

- `view` can be one of `basic`, `health`, `performance`, `errors`, `connections`, or `full` (defaults to `basic`).
- `backend` is optional and filters the output for a specific backend name.

The script relies on `socat` and expects the HAProxy admin socket at `/run/haproxy/admin.sock`.
