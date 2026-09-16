# Workflow

Use this reference for coding-agent playbooks, workspace setup, importing live
source, cloning, validation, and controlled changes.

## Load or Refresh Coding-Agent Playbooks

Agent Skills are directories whose entry point is `SKILL.md`. The
`elementum` CLI owns the bundled user playbooks:

```bash
elementum playbooks status
elementum playbooks install --yes
elementum playbooks path
elementum playbooks files elementum
elementum playbooks print elementum
elementum playbooks print elementum workflow.md
```

- `status` compares installed copies with the current Elementum compatibility
  train.
- `install` is the install and update operation. Run it when playbooks are
  absent or stale.
- `path` locates the bundled playbook source.
- `files elementum` lists every bundled reference available to the playbook.
- `print elementum [file]` prints `SKILL.md` or one linked reference when an
  agent cannot load the installed tree automatically.

After installation, ask the coding agent to use `/elementum`, or explicitly
point it to the installed `elementum/SKILL.md`. Do not confuse this operation
with authoring a platform agentic skill.

## CLI via MCP

If the session already has Elementum MCP tools named `run` and `help`, prefer
them over a shell for every command in this file. `run` args are the tokens
after `elementum` (for example `["auth", "status"]`, `["pull", "org",
"--data-only"]`, `["plan"]`). Call `help` with a command path before
unfamiliar flags. Pass `profile` on the tool when more than one saved profile
could match.

Those tools come from `elementum mcp`, the local CLI server. They are not the
platform agent MCP Tool. `auth login` over MCP is non-interactive (flags and
process environment). Do not `run` `mcp`, `canvas`, `chat`, `auth env`,
`auth export`, or `auth import`. After the user reviews a plan, `run`
`["apply", "-auto-approve"]` (a bare apply cannot prompt over MCP).

If MCP is not connected, start it from the org workspace (or pass `--cwd`) and
point the coding agent's MCP config at `command: elementum`, `args: ["mcp"]`.
Until then, use the `elementum` CLI in a terminal as shown below.

## Bootstrap a Workspace

Use Node 24 and install the SDK in the package workspace that will contain the
organization folders:

```bash
npm install @elementumai/edk
elementum auth login --profile <profile>
elementum --profile=<profile> auth status
elementum --profile=<profile> pull org --data-only
cd <instance>/<organization>
elementum --profile=<profile> init
```

`pull org --data-only` creates or refreshes the organization workspace,
`org.ts`, and the generated catalog alias. `elementum init` checks and
converges the managed installation and current workspace; it does not log in.
Use plain `pull org` when organization-owned categories, groups, cloud links,
email aliases, or phone providers should also be pulled into editable
`organization.ts`; add `--no-adopt` only when state adoption is intentionally skipped.
Write-only CloudLink and Twilio credentials, plus other input-only values, stay
as explicit pull markers and are excluded from automatic adoption. Supply each
reported value before expecting that resource to build or plan.

Use an explicit profile for bootstrap because the target workspace may not
exist yet. Keep using an explicit profile in automation or whenever more than
one saved profile could match.

## Start From Existing Source

Pull before editing an existing object:

```bash
elementum --profile=<profile> pull org --data-only
elementum --profile=<profile> pull app <namespace>
# or
elementum --profile=<profile> pull element <namespace>
```

The pull writes editable TypeScript and a single JSON summary. Inspect
`diagnostics` and `skipped`; do not claim full coverage when either reports an
unmanaged part of the live solution.

Use `--no-adopt` only when the user explicitly wants source without binding it
to the current workspace. A normal pull is the safe default.

## Create New Source

For a brand-new app or element with no existing platform counterpart to base
it on, scaffold it first instead of hand-authoring the file or copying the
shape of an already-pulled one:

```bash
elementum new app --name "<display name>" --namespace <ns> --category "<category>" [--handle <HANDLE>]
elementum new element --name "<display name>" --namespace <ns> --category "<category>" [--handle <handle>]
```

Each command writes the entity file, regenerates its own per-entity catalog,
and refreshes the org-level catalog barrel, so the new app/element is
immediately reachable as `catalog.<refName>` — including from a sibling
app/element authored in the same workspace before either is deployed. Hand
creating an `apps/<ref>/<ref>.ts` or `elements/<ref>/<ref>.ts` file by copying
another pulled file skips that catalog registration; a sibling file that needs
to reference it then has nothing to import from `@catalog` and falls back to a
repository-relative import, which is not public authoring surface. After
scaffolding, open the generated file, replace the placeholder field, and add
the fields the user actually wants.

`--namespace` is required and immutable once deployed — confirm it with the
user rather than guessing. Use the public clone command instead when the user
wants a distinct app based on an *existing* app:

```bash
elementum clone app <namespace> --as "<new name>"
```

Use its `--namespace`, `--handle`, `--ref`, `--root`, and `--target-root`
options only when the user supplies or approves the corresponding identity or
destination. Review unresolved destination references in a cross-organization
clone before continuing.

For new agents and platform agentic skills under an existing app:

```bash
elementum new agent --app <appRef> --name "<display name>"
elementum new skill --app <appRef> --name "<display name>"
```

Open the generated TypeScript, complete every placeholder, and typecheck it.

## Edit, Validate, Review, Apply

From the organization workspace:

```bash
npx tsc --noEmit
elementum build
elementum --profile=<profile> plan
```

Resolve compiler errors and build diagnostics before planning. Summarize the
plan in user terms:

- what will be created;
- what will change;
- what will be replaced or removed;
- what was skipped or could not be represented.

Stop when the target profile is wrong, the live pull is incomplete in an area
the request depends on, or the plan includes an unexplained replacement or
removal.

After explicit approval:

```bash
elementum --profile=<profile> apply
```

Re-run the relevant pull after platform-side edits so authored source and the
workspace remain aligned.

## Targets and Profiles

`build`, `plan`, and `apply` accept the organization root. `plan` and `apply`
also accept a path nested inside that workspace as a way to locate the root;
they still review the complete workspace.

With no explicit profile, platform commands can select the unique saved profile
matching the workspace path. If selection is ambiguous or the identities do
not match, pass `--profile=<profile>`; never work around the safety check.

## Recovery

If the workspace's deployment identity is missing or stale, restore the
workspace from version control or re-pull each live app and element. Do not
apply a configuration that appears to recreate known live objects. Run a fresh
plan and explain the result before proceeding.
