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
the principle and the lane boundaries are in
`.claude/rules/plack-middleware-zitadel-rules.md`.

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

The middleware works and the suite is green (`prove -lr t/`, two files, 10 tests) — but
`WWW::Zitadel` has to be installed, and the tests currently pull the sibling checkout
into `@INC` when it sits next to this repo. The distribution predates the current house
structures: there is no `LICENSE` file, so `dzil build` aborts, there is no CI, the POD
is malformed and the README names a middleware class that does not exist. The known gaps
are tracked on the internal board.
