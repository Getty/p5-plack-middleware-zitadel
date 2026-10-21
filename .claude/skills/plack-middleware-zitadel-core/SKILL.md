---
name: plack-middleware-zitadel-core
description: Architecture, contracts and traps of the Plack-Middleware-Zitadel distribution — the request path through Plack::Middleware::Zitadel, the error/challenge table, the attributes, the env contract, the scope check and the seams the tests use. Read before changing the middleware, the challenge or the PSGI env contract.
---

# Plack-Middleware-Zitadel — core

## What this repository is

One distribution, one module: `Plack::Middleware::Zitadel`, a `Plack::Middleware`
subclass that verifies a ZITADEL Bearer token in front of a PSGI application and
hands the decoded claims to that application.

The token verification is **not** part of this distribution — it belongs to the
sibling **WWW-Zitadel** (`WWW::Zitadel::OIDC`). This module calls
`verify_token` and passes the claims on. Anything about JWT decoding, JWKS
caching, key rotation or the issuer discovery belongs over there.

| Path | What it is |
|---|---|
| `lib/Plack/Middleware/Zitadel.pm` | the whole library — one class, one file |
| `examples/proxy.psgi` | transparent proxy: verify, then forward to `UPSTREAM_BASE` |
| `examples/Dockerfile` | container image for that proxy |
| `examples/k8s/*.yaml` | Gateway API deployment (configmap, deployment, service, httproute) |
| `examples/deploy-k8s-proxy.sh` | applies the manifests |
| `t/00-load.t` | load test |
| `t/01-auth.t` | the behaviour tests, one `Local::OIDC` fake |

## The request path

`call` does five things, in this order. The order is the contract.

1. **`_extract_bearer`** — reads `$env->{HTTP_AUTHORIZATION}` and matches
   `/^Bearer\s+(.+)\z/i`. The scheme is case-insensitive (`Bearer`, `bearer`,
   `BeArEr` all pass); the token is everything after the whitespace run.
2. **verify** — `verify_token($token, %args)`, wrapped in `eval`. `audience` is
   passed **only** when it is defined and non-empty.
3. **scope check** — only when `required_scopes` is set; a missing scope ends the
   request with 403 before the app is reached.
4. **env injection** — the claims and the raw token.
5. **`$self->app->($env)`** — the wrapped application.

### The error table

| Situation | Status | `error` | `error_description` |
|---|---|---|---|
| no `Authorization` header, or empty | 401 | `invalid_request` | `missing Authorization header` |
| scheme is not Bearer | 401 | `invalid_request` | `Authorization must use Bearer token` |
| `verify_token` dies | 401 | `invalid_token` | the die message, trailing whitespace stripped |
| `verify_token` dies with an empty message | 401 | `invalid_token` | `token verification failed` |
| a required scope is missing | 403 | `insufficient_scope` | `required scopes are missing` |

Every failure answers with a JSON body `{error, error_description}` and
`Content-Type: application/json`. The 401 additionally carries the challenge
header; the 403 does not (that is pinned by a test — see Traps).

## The challenge

The 401 header is built by one `sprintf`:

```
Bearer realm="<realm>", error="<error>", error_description="<description>"
```

`realm` defaults to `api`. The description is the verbatim text of the
verification error — for the real sibling that is the stringified
`WWW::Zitadel::Error`, which overloads `""` to its message. The middleware only
strips **trailing** whitespace (`s/\s+\z//`); leading whitespace survives.

## The attributes

| Attribute | Default | Meaning |
|---|---|---|
| `issuer` | — | OIDC issuer URL; required unless `oidc` is given |
| `audience` | — | passed to `verify_token` when set and non-empty |
| `required_scopes` | — | arrayref **or** space-separated string |
| `claims_env_key` | `zitadel.claims` | PSGI key for the decoded claims |
| `realm` | `api` | realm in the challenge |
| `oidc` | — | a pre-built object; must implement `verify_token` |

`prepare_app` fills in the defaults, dies with `issuer required` when neither
`issuer` nor `oidc` is given, dies with `oidc object must implement
verify_token` when the object cannot do it, and keeps the object in
`$self->{_oidc}`.

## The env contract

Two keys reach the application:

- the claims hashref under `claims_env_key` (default `zitadel.claims`) — the
  value is whatever `verify_token` returned, unfiltered;
- the raw token under the **fixed** key `zitadel.token` — not configurable.

Nothing is injected when the request fails: a 401/403 leaves the env untouched,
so the wrapped application never sees claims it did not earn.

## The scope check

`required_scopes` is normalized to a list: an arrayref is filtered for defined
and non-empty entries, a string is split on whitespace. **All** listed scopes
must be present; one missing scope is enough for the 403.

The check reads the token's `scope` claim and only that claim, as a
whitespace-separated string. Consequences worth knowing:

- a token without a `scope` claim has no scopes and fails every requirement;
- array-shaped scope claims (the Azure-style `scp`) are not understood;
- the sibling verifies JWTs only — there is no introspection, so opaque tokens
  are not supported here at all.

## The seam for tests

`oidc` accepts any object that can `verify_token`. `t/01-auth.t` uses a
`Local::OIDC` fake that dies for known tokens and returns a claims hash
otherwise — the pattern to copy. The fake also records its arguments, which is
how the audience handling is pinned.

## Traps

- **The POD is broken.** Its headings are lower case (`=synopsis`,
  `=description`, `=attr`); `podchecker` reports 8 errors, and the author test
  the `[@Author::GETTY]` bundle adds (`xt/author/pod-syntax.t`) is red over it.
  The release path fails until that is fixed.
- **The README enables a class that does not exist**:
  `enable 'Plack::Middleware::Zitadel::Auth'`. The class is
  `Plack::Middleware::Zitadel`; the example as written dies at startup.
- **`error_description` is not escaped** in the challenge header. A die message
  with a double quote or a newline breaks the quoted string — a remote library
  controls that text.
- **The 403 has no `WWW-Authenticate` header**, although RFC 6750 expects the
  challenge to carry the `scope` attribute. `t/01-auth.t` pins the current
  behaviour (`ok !$missing_res->header('WWW-Authenticate')`) — changing it means
  changing the test on purpose.
- **The `empty bearer token` branch is unreachable** through the header path:
  the regex needs at least one character, so `"Bearer  "` yields the single
  space as token.
- **The tests pull in an out-of-repo checkout**: both test files prepend
  `$FindBin::Bin/../../p5-www-zitadel/lib` to `@INC` when that directory
  exists. Locally the sibling checkout wins over the installed module; on a
  machine without the checkout the path silently disappears and a different
  version is tested.
- **No `LICENSE`** — `[@Author::GETTY/LicenseFile]` aborts `dzil build`; the
  bundle gathers files through Git, so the file has to be committed.
- **No CI workflow** — the tests only run locally.
- **The cpanfile pins no minimum versions**, and `WWW::Zitadel` — a hard
  runtime dependency — is declared without one.
- **The deploy script is tied to one machine**: the default kubeconfig path is
  a personal absolute path, and the script prints an internal hostname.
- `WWW::Zitadel` has to be installed for the suite to load; without it the
  middleware cannot even be loaded.

## Tests

`t/00-load.t` — one load test. `t/01-auth.t` — nine subtests: `prepare_app`
validates config, Bearer extraction, verification failure, audience handling,
`required_scopes` as arrayref, `required_scopes` as string, env injection,
custom `claims_env_key` and `realm`, and the challenge format.

Not covered today: a die message that contains a quote or a newline, a Bearer
value of only whitespace, the env staying clean on the 403 path, and the
`realm` in any path other than the default one.

## Vocabulary

**claims** — the decoded token content, as returned by `verify_token`.
**challenge** — the `WWW-Authenticate` header of a 401. **realm** — the
namespace inside the challenge. **scope** — a permission name in the token's
`scope` claim. **env key** — the PSGI key under which the claims are stored.
**upstream** — in `examples/proxy.psgi`, the service behind the proxy.
