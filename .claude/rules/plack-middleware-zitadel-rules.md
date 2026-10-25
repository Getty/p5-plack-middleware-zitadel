# Plack-Middleware-Zitadel House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They load
as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish nothing
until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Plack middleware that verifies Bearer tokens via ZITADEL OIDC. Read first: the contract table
in skill `plack-middleware-zitadel-core`.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `plack-middleware-zitadel-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `plack-middleware-zitadel-release-manager` |
| Read-only research, audit, gap analysis | `plack-middleware-zitadel-worker` ("read-only, change nothing") |

Behavior-relevant = anything in `lib/`, the tests, the Bearer extraction, the scope check, the
env injection, the challenge and the error responses. Docs wording is not.

## The binding contract is the product — don't regress it silently

Three things reach into every app behind this middleware: the **challenge** (the
`WWW-Authenticate` header with its realm and error codes), the **env contract**
(`zitadel.claims` and `zitadel.token`, under the configurable key) and the **scope check**.
The token verification itself belongs to the sibling WWW-Zitadel — this distribution calls
`verify_token` and hands the claims on; it does not decode JWTs itself. A change that alters
one of the three wants a `Changes` entry naming the user-visible effect, and its POD updated
in the same edit. Tests verify exactly these three: they are the product.

## Hazards

- **A new dependency needs a real justification** — keep the existing layout.

## Perl specifics — reference, don't restate

Perl conventions live in `getty-perl-core`/`getty-perl-pod`, the ZITADEL side in
`www-zitadel-perl`/`zitadel-general`, the contract in `plack-middleware-zitadel-core`
(force-loaded for `plack-middleware-zitadel-*` agents).
