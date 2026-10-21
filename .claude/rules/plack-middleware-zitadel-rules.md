# Plack-Middleware-Zitadel House Rules

Apply to every task in this repository unless explicitly overridden. Bias: caution over
speed on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch
(same priority as `CLAUDE.md`). Subagents get their conventions from the skills
force-loaded via `briefing.skills` — this file is for the orchestrating agent. Perl
conventions live in `getty-perl-core`/`getty-perl-pod`, the ZITADEL side in
`www-zitadel-perl`/`zitadel-general`, the contract in `plack-middleware-zitadel-core`;
don't repeat them.

## Engineering discipline

1. **Think before coding** — State assumptions. When uncertain, ask rather than guess.
   Push back when a simpler approach exists. Stop when confused; name what's unclear.
2. **Simplicity first** — Minimum code that solves the problem, nothing speculative;
   a new dependency needs a real justification. Touch only what you must; match the
   existing layout.
3. **Tests verify intent, not just behavior** — Reproduce a bug before fixing it; leave a
   regression test behind. The challenge, the env contract and the scope decision are the product.
4. **Match the codebase's conventions, even if you disagree** — Conformance > taste;
   surface a harmful convention instead of forking silently. Fail loud: "Done" is wrong
   if anything was skipped silently, "Tests pass" is wrong if any were skipped.
5. **A red test is a claim before it is a failure** — Before changing code to turn a test
   green, say what it asserts and whether your fix keeps that claim or replaces it.

## Delegation

- **You can spawn subagents** (orchestrating main agent): Do NOT touch behavior-relevant
  code yourself — delegate. Your lane: coordinate, inspect, plan, review diffs, run tests,
  edit non-behavioral docs. Why: only the `plack-middleware-zitadel-*` agents get their
  skills force-loaded; you get no briefing and would touch the challenge and the env
  contract with too little context.

  | Task | Agent |
  |---|---|
  | Implement / refactor / debug behavior-relevant code | `plack-middleware-zitadel-worker` (default) |
  | Commits, `Changes`, card → done, pre-release audit | `plack-middleware-zitadel-release-manager` |

- **You cannot spawn subagents** (you ARE a `plack-middleware-zitadel-*` agent): The
  delegation lock does not apply — implement, refactor, debug and test per these rules.

Behavior-relevant = anything in `lib/`, the tests, the Bearer extraction, the scope
check, the env injection, the challenge and the error responses. Docs wording is not.

**Only `plack-middleware-zitadel-release-manager` commits.** A worker leaves a
commit-ready tree and hands its card to `review`; you then dispatch
`plack-middleware-zitadel-release-manager` to cut the commit and close the card.

## The binding contract is the product — don't regress it silently

Three things reach into every app behind this middleware: the **challenge** (the
`WWW-Authenticate` header with its realm and error codes), the **env contract**
(`zitadel.claims` and `zitadel.token`, under the configurable key) and the **scope
check**. The token verification itself belongs to the sibling WWW-Zitadel — this
distribution calls `verify_token` and hands the claims on; it does not decode JWTs
itself. A change that alters one of the three wants a `Changes` entry naming the
user-visible effect, and its POD updated in the same edit. Contract table: skill
`plack-middleware-zitadel-core`.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope —
don't invoke the skill first, just use it. Board state lives in `refs/karr/*`.
`karr list --compact` / `karr board` / `karr show ID` read · `karr create "Title"
--priority high --tags a,b --body '…'` files · `karr edit ID -a "note" --claim NAME
--block "why"` updates · `karr move ID in-progress --claim NAME` starts ·
`karr handoff ID --claim NAME --note "…"` hands to review · mutating commands auto-sync.

Card life cycle: you claim and hand out → the worker notes and ends at `review` → the
release-manager commits and moves it to `done`. **Serialize board mutations when fanning
out** — keep implementation work parallel if you like, but collect the results and then
loop the `karr move`/`handoff`/`sync` calls sequentially; N of them landing at once is a
resource event. Command surface: skill `kanban-issues-karr-coordination`.

## Release — never without permission

`dzil build` / `dzil test` / `prove -lr t/` are fine anytime. `dzil release` and any
CPAN upload are STRICTLY forbidden without the maintainer's explicit go-ahead — even if
a plan lists "release" as the next step. Stop and ask.

The last release in this repo's history is 0.010 (2026-04-16); the module stands at 0.011, the
next unreleased number — derived at release time, never copied back from CPAN. The CPAN
status is never a blocker and never a ticket.

## Public issues — never act without instruction

`karr` is the internal agent board, churned freely. The GitHub issue tracker carries real
people's reports, written under the maintainer's account. Never act on a public issue on
your own initiative — not even to read it: no listing, viewing, commenting or closing.

