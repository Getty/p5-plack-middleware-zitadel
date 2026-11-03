# Plack-Middleware-Zitadel

Plack middleware that verifies a ZITADEL OIDC Bearer token in front of a PSGI
application: it takes the token out of the `Authorization` header, has it verified by
the sibling `WWW-Zitadel`, checks the required scopes, injects the claims into the PSGI
environment and answers 401/403 with a JSON body and an RFC 6750 challenge.

Released to CPAN as `Plack-Middleware-Zitadel`, built with `Dist::Zilla` via
`[@Author::GETTY]`. One module — `Plack::Middleware::Zitadel`, a `Plack::Middleware`
subclass — plus the deployment examples under `examples/` (transparent proxy,
Dockerfile, Gateway API manifests).

The token verification belongs to `WWW-Zitadel`: this distribution calls
`verify_token` and hands the claims on. The request path, the error and challenge
table, the attributes, the env contract and the scope check live in skill
`plack-middleware-zitadel-core` — they are not repeated here.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself —
the delegation lock is a shared house rule (skilletor bundle `getty-cpan-dist@getty`); the
lane boundaries are in `.claude/rules/plack-middleware-zitadel-rules.md`.

| Task | Agent |
|---|---|
| Implement / refactor / debug behavior-relevant code | `plack-middleware-zitadel-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `plack-middleware-zitadel-release-manager` |

The agents carry their skills via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. Skill sources live under `.claude/skills/` —
`getty-perl-core`, `getty-perl-pod`, `www-zitadel-perl`, `zitadel-general` and the
karr skills are installed from the shared sources; `plack-middleware-zitadel-core` is
owned by this repo.

Work is coordinated on the repo's `karr` board (`karr board`).

## State of the code

The middleware works and the suite is green (`prove -lr t/`; `dzil test` is the
release-path run). `WWW::Zitadel` has to be installed for the suite to load. The tests
run against the installed `WWW::Zitadel`; a sibling checkout joins `@INC` only when
`PLACK_MIDDLEWARE_ZITADEL_WWW_ZITADEL_LIB` points at its `lib/`. The distribution
carries a committed `LICENSE`, a `Changes` file, a README whose usage example a test
runs, valid POD (`t/02-pod.t`) and a GitHub Actions workflow (`.github/workflows/ci.yml`)
that runs `dzil test` on Perl 5.36, 5.38 and 5.40.
