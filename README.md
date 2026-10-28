# Proxmint proxy for GitHub Actions

Run end-to-end and geo tests in GitHub Actions through [Proxmint](https://proxmint.com) residential, datacenter
or mobile proxies, with no proxy password in your repository secrets. The job trades the OIDC token GitHub
signs for it for one proxy line of the Proxmint account linked to the repository.

## Setup

1. Install the [Proxmint GitHub App](https://github.com/apps/proxmint) on the repositories that need proxies. It
   asks for no permissions beyond reading their names.
2. GitHub sends you back to Proxmint to link the installation to your account (or link it later under
   **Settings, GitHub Actions** in the dashboard).
3. Use the action in a job that has `id-token: write`:

```yaml
jobs:
  geo-test:
    runs-on: ubuntu-latest
    permissions:
      id-token: write   # lets the job ask GitHub for its OIDC token
      contents: read
    steps:
      - uses: actions/checkout@v5
      - id: proxy
        uses: proxmint/setup-proxy@v1
        with:
          product: residential
          country: de
      - run: npm test
        env:
          HTTPS_PROXY: ${{ steps.proxy.outputs.url }}
          HTTP_PROXY: ${{ steps.proxy.outputs.url }}
```

Pass the line only to the steps that need it. Set for the whole job (`export-env: true`), it also sends
checkouts, caches and artifact uploads through the proxy.

## Inputs

| Input | Default | |
|---|---|---|
| `product` | the oldest product on the account | `residential`, `premium-residential`, `datacenter` or `mobile` |
| `country` | the targeting saved in the dashboard | two-letter exit country, such as `us` |
| `session` | `rotating` | `rotating` (a new IP on every request) or `sticky` |
| `sticky-minutes` | `30` | how long a sticky session keeps its IP, 1 to 120 |
| `export-env` | `false` | `true` sets `HTTP_PROXY` and `HTTPS_PROXY` for every later step |

## Outputs

`url` (`http://user:pass@host:port`), `host`, `port`, `username` and `password`. The password and the URL are
masked in logs.

## Who can get your proxies

Only jobs in repositories the app is installed on, and only while that installation is linked to your account.
Pull requests from forks get no OIDC token, so they cannot ask. Workflows triggered by `pull_request_target` can,
so never run code from a fork in one with `id-token: write`. Unlink in the dashboard, or uninstall the app, and
the next request is refused.

Runs on GitHub-hosted and self-hosted runners with `bash`, `curl` and `jq`. Full reference, errors and the raw
API: [proxmint.com/docs/github-actions](https://proxmint.com/docs/github-actions).

## License

MIT
