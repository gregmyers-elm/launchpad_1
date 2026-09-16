---
name: elementum
description: Use the public Elementum CLI and TypeScript EDK to build or change Elementum apps, elements, fields, dashboards, charts, automations, agents, platform agentic skills, search tables, approval chains, and tables. Also use when asked to "load Agent Skills", "install Elementum playbooks", "update coding-agent skills", "find the Elementum SKILL.md", "use the /elementum playbook", or manage coding-agent playbooks with the Elementum CLI. Use when an Elementum CLI MCP server is connected so you can run those same commands through its run and help tools.
edkVersion: 0.9.7
---

# Elementum

This is the core coding-agent playbook for TypeScript EDK authoring. Use only
the public `elementum` CLI and public `@elementumai/edk` package subpaths.

## Drive the CLI with MCP

If this session has Elementum MCP tools named `run` and `help`, use them for
every public `elementum` command instead of a shell. They come from
`elementum mcp` (local CLI server on this machine). They are not the platform
agent MCP Tool.

`run` args are the tokens after `elementum`. Call `help` with a command path
before unfamiliar flags. Pass `profile` on the tool when more than one saved
profile could match.

Typical `run` args:

- `["auth", "login"]` then `["auth", "status", "--json"]`
- `["pull", "org", "--data-only"]` then `["pull", "app", "<namespace>"]`
- `["build"]`, `["plan"]`, then `["apply", "-auto-approve"]` only after the user reviews the plan

`auth login` over MCP is non-interactive: it uses flags and the process
environment, then persists a profile. Do not `run` `mcp`, `canvas`, `chat`,
`auth env`, `auth export`, or `auth import`. If those MCP tools are not
connected, use the `elementum` CLI in a terminal as shown below.

## Route the Request

Read only the directly relevant reference:

- Playbook loading, installation, workspace setup, pull, clone, build, plan, or
  apply: [workflow.md](workflow.md)
- TypeScript files, imports, generated catalogs, names, and references:
  [authoring.md](authoring.md)
- Apps, elements, fields, calculated fields, or automations:
  [apps-and-automations.md](apps-and-automations.md)
- Agents, tools, platform agentic skills, or A2A skills:
  [agents-and-skills.md](agents-and-skills.md)
- Typed DASHBOARD `dynamicLayouts`, classic layouts, list views, information
  hierarchy, responsive UX, or browser verification: load `/elementum-design`
- Charts, search tables, approval chains, tables, or ownership:
  [entities.md](entities.md)

For a cross-cutting change, read the workflow and each affected entity
reference before editing.

## Keep the Three Meanings Separate

- A **coding-agent playbook** is an Agent Skills directory containing
  `SKILL.md`, such as this `/elementum` playbook. It guides a coding assistant
  and is installed or refreshed with `elementum playbooks`.
- A **platform agentic skill** is an app-owned Elementum solution component
  authored with `skill`. It packages runtime instructions and tools that
  an Elementum agent can discover or preload.
- An **A2A skill** is a capability descriptor on an agent's A2A card. It helps
  other agents discover capabilities; it is neither a coding-agent playbook
  nor a platform tool bundle.

If the user says only "skill", determine which meaning applies before changing
files or running commands.

## Core Workflow

Prefer MCP `run` for the commands below when those tools are connected.

1. Confirm the intended profile, organization, app or element namespace, and
   whether the target already exists.
2. For an existing solution, pull it before editing. Refresh organization
   references whenever model connectors, cloud links, categories, users, or
   groups may have changed.
3. Edit only authored TypeScript. Use public package imports and generated
   typed references.
4. Run `npx tsc --noEmit`, then `elementum build`.
5. Run `elementum plan`. Explain every create, update, replacement, and
   removal. Treat diagnostics as blockers rather than bypassing them.
6. Run `elementum apply` only after the user approves the reviewed plan.

Typical existing-app sequence:

```bash
elementum --profile=<profile> auth status
elementum --profile=<profile> pull org --data-only
elementum --profile=<profile> pull app <namespace>
npx tsc --noEmit
elementum build
elementum --profile=<profile> plan
elementum --profile=<profile> apply
```

Use `pull element <namespace>` for an existing element. Run initial pulls from
the parent workspace; after bootstrap, work from the organization workspace.

## Non-Negotiable Authoring Rules

- Author TypeScript with EDK builders. Do not invent a parallel configuration
  format or call private executables.
- Import builders from `@elementumai/edk/<subpath>` and solution references
  from `@catalog`.
- Use the nested model connector shape
  `catalog.aiProviders.<family>.models.<model>`, never a flat connector bag.
- Preserve pulled file locations and stable bag keys. Change display `name`
  when renaming a field; changing its key changes its authored identity.
- Do not hand-edit `org.ts` or `generated/`. Refresh them with their owning
  public commands.
- Do not paste guessed platform identifiers into source. Prefer pulled typed
  references and preserve exceptional values already present in pulled source.
- Scaffold a brand-new app or element with `elementum new app` / `elementum
  new element`, not by hand-copying a pulled file's shape. Only the scaffold
  command registers the new entity's catalog entry immediately, so a sibling
  app/element authored in the same workspace can reference it via `@catalog`
  instead of a repository-relative import.
- Use public product nouns and factories. Pass `app`, `element`, `agent`,
  `automation`, field, and other catalog refs directly; do not author generic
  implementation refs, private resource names, transport shapes, or internal
  discriminants.
- Let TypeScript enforce ownership. Do not widen typed refs, combine mutually
  exclusive app/element inputs, or silence an ownership error with a cast.
- Use exported constants for supported kinds, durations, modes, statuses, and
  units instead of memorized string literals when the package provides them.
- Pulled source is the canonical public API too. Preserve its public factories
  and typed refs; do not replace them with raw IDs or private shapes.
- Do not add template APIs. Treat any capability absent from the installed
  public EDK and live product as unsupported, even if an internal
  schema or resource type exists.
- Pull output and build diagnostics may report unsupported pieces. Report the
  gap and pause instead of silently dropping or approximating user intent.
- Never print credentials or authentication material.

## Fast Command Router

If MCP `run` is connected, pass the same tokens without `elementum` itself.
Otherwise:

```bash
# Local MCP server (stdio; the coding agent then uses run/help)
elementum mcp

# Coding-agent playbooks
elementum playbooks status
elementum playbooks install --yes
elementum playbooks path
elementum playbooks print elementum

# Workspace and source
elementum init
elementum --profile=<profile> pull org --data-only
elementum --profile=<profile> pull app <namespace>
elementum --profile=<profile> pull element <namespace>
elementum clone app <namespace> --as "<new name>"

# Offline authoring helpers
elementum new app --name "<display name>" --namespace <ns> --category "<category>" [--handle <HANDLE>]
elementum new element --name "<display name>" --namespace <ns> --category "<category>" [--handle <handle>]
elementum new agent --app <appRef> --name "<display name>"
elementum new skill --app <appRef> --name "<display name>"
elementum canvas <orgRoot-or-file>
elementum build [orgRoot]

# Review and apply
elementum --profile=<profile> plan [orgRoot-or-nested-target]
elementum --profile=<profile> apply [orgRoot-or-nested-target]
```

For a command not shown here, inspect `elementum --help` or the relevant
subcommand help. Do not substitute an internal command.
