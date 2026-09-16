# TypeScript Authoring

Use public EDK package subpaths and the generated catalog. Treat pulled source
and the TypeScript compiler as the contract for the installed EDK version.

## Workspace Shape

Editable source normally lives at:

```text
<orgRoot>/org.ts
<orgRoot>/organization.ts
<orgRoot>/generated/catalog.ts
<orgRoot>/apps/<appRef>/<appRef>.ts
<orgRoot>/apps/<appRef>/automations/<refName>.ts
<orgRoot>/apps/<appRef>/agents/<refName>.ts
<orgRoot>/apps/<appRef>/skills/<refName>.ts
<orgRoot>/apps/<appRef>/approval-chains/<refName>.ts
<orgRoot>/elements/<ref>/<ref>.ts
<orgRoot>/elements/<ref>/search-tables/<refName>.ts
<orgRoot>/tables/<ref>/<ref>.ts
<orgRoot>/tables/<ref>/search-tables/<refName>.ts
<orgRoot>/tasks/<ref>/<ref>.ts
```

Edit `organization.ts` and files under `apps/`, `elements/`, and `tables/`.
Do not edit `org.ts` or `generated/`; refresh those lookup catalogs with
`elementum pull org --data-only`. Plain `elementum pull org` refreshes editable
organization resources and adopts them with the same zero-write gates as app pulls.

Organization credentials must be environment-backed. Use `secret("name")` in
`organization.ts` and supply the value as `TF_VAR_name`; never place a token,
password, service-account JSON, Twilio SID, or auth token in source. A pulled
`redactedSecret(...)` or `unavailableValue(...)` marks an input the platform
does not return. Replace the marker before managing that resource; do not
remove it merely to silence a build diagnostic.

Choose organization connection variants with their dedicated factories, such
as `elementumCloudLink`, `apiCloudLink`, `bigQueryCloudLink`, and
`twilioPhoneProvider`. Use `cloudLinkUsageType`, `cloudLinkScheduleUnit`, and
`cloudLinkWarehouseSize` constants for closed provider values. Do not author a
raw CloudLink `type`, schedule unit, warehouse size, or usage-type string.

## Imports

Import builders from public package subpaths:

```ts
import { app, textField } from "@elementumai/edk/app";
import { element } from "@elementumai/edk/elements";
import { automation, onDemand } from "@elementumai/edk/automations";
import { agent } from "@elementumai/edk/agents";
import { skill } from "@elementumai/edk/agents/skills";
import { linkedSearchTable, searchTable, tableSearchTable, searchTableDuration } from "@elementumai/edk/searchTables";
import { visualFlow, visualFlowSymbol } from "@elementumai/edk/visualFlows";
import { approvalProcess } from "@elementumai/edk/approvalProcesses";
import { table } from "@elementumai/edk/tables";
import { task } from "@elementumai/edk/tasks";
import { organization, secret } from "@elementumai/edk/organization";
import catalog from "@catalog";
```

Do not use repository-relative source imports or hand-built object shapes when
a public builder exists.

Organization-owned categories and groups live in `organization.ts`. Group
members require typed user references; the EDK resolves their provider IDs:

```ts
import { organization, userRef } from "@elementumai/edk/organization";

export default organization({
  categories: { operations: { name: "Operations" } },
  groups: {
    operators: {
      name: "Operators",
      members: [userRef("operator@example.com")],
    },
  },
});
```

## Type-Safe Public API

Use the product concept directly and let each builder constrain the valid
owner. Public workspace source should contain `app`, `element`, `agent`, and
other catalog refs—not generic implementation wrappers, private resource
names, transport objects, or platform IDs.

```ts
agentSearchRecords({
  app: catalog.support,
  name: "find_tickets",
  description: "Find support tickets.",
  queryDescription: "Describe the ticket to find.",
});

agentSearchRecords({
  element: catalog.locations,
  name: "find_locations",
  description: "Find locations.",
  queryDescription: "Describe the location to find.",
});
```

Pass exactly one supported owner. Do not create a generic owner ref, pass both
app and element, cast one token to another kind, or reach into an internal
representation.

Prefer exported constant namespaces for closed values:

```ts
duration: searchTableDuration.hours
```

This keeps autocomplete, compile-time validation, and the installed EDK
version aligned. Use a string literal only when the public type intentionally
accepts an open string.

References that the platform resolves to IDs still remain typed in authored
source. Use a public ref helper scoped by stable human identity and owner; do
not paste the resolved UUID. If the EDK cannot reconstruct a safe ref during
pull, treat its diagnostic as a support boundary.

## References

Use typed catalog tokens:

```ts
catalog.support
catalog.support.fields.status
catalog.support.automations.notifyOwner
catalog.support.agents.triage
catalog.support.skills.ticketLookup
catalog.aiProviders.anthropic.models.claudeHaiku_4_5
```

The model connector path is nested by connector family and model. Do not use
an inline connector object or flatten the generated token path.

Pulled app files may import `org` from a relative `org.js` path for cloud links
or other organization references. Preserve the generated import style in
pulled files. For agent connectors and AI action connectors, prefer the current
catalog token shape shown above.

If a reference is absent, refresh organization references or pull the owning
app. Do not guess names or paste an identifier to make the compiler quiet.

## Identity and Names

- A file stem is the `refName` for app-owned files. For example,
  `agents/supportAgent.ts` gives the agent ref `supportAgent`.
- An app or element directory and root filename use the same ref.
- A field's key in `fields` is stable authored identity; its `name` is the
  display label.
- A generated catalog key is a reference, not a place to store configuration.
- Default-export the result returned by the relevant builder.

Configured builders such as `app`, `automation`, `agent`, and
`skill` do not have a `.deploy()` method. Workspace discovery supplies
their file-based ref.

When renaming:

1. Change a display `name` when only the user-facing label should change.
2. Treat a file stem, app namespace, handle, or field bag key change as an
   identity change.
3. Pull first and review the plan for replacement or removal before apply.

## Typed Data Flow

Within an automation, use the typed action context:

```ts
actions: actions()
  .trigger(onDemand({ REQUEST: { type: "text", required: true } }))
  .executeScript("NORMALIZE", {
    code: (input) => ({ normalized: String(input.parameters.request).trim() }),
    inputs: (ctx) => ({ request: ctx.trigger.REQUEST }),
    outputs: { normalized: "text" },
  })
  .outputs((ctx) => ({
    RESULT: ctx.actions.NORMALIZE.result.normalized,
  })),
```

Script outputs are always read as `result.<name>`. A pulled script whose stored
schema names its root object prints the longer form `outputs: { name: "result",
properties: { normalized: "text" } }` — leave that name alone, since rewriting
it to the short form makes the next plan update the task for no behavior change.

Across entities, use catalog tokens. Do not construct cross-entity reference
strings by hand.

For calculated fields, use the exported `calc` helpers and field tokens. Do
not write an opaque expression string. If a pulled calculated field contains a
TODO placeholder, replace it with a typed expression only when the user wants
to manage that expression.

Prefer the smallest expression that demonstrates the desired behavior. For a
current-time field, use `calc.now()` directly; do not hide it in an aggregate.

## Validation Loop

After every coherent edit:

```bash
npx tsc --noEmit
elementum build
```

Read compiler errors literally. Build diagnostics indicate an authored option
that cannot be represented safely; remove it only if that matches user intent.
Otherwise report the gap and stop.

Do not silence errors with broad casts, hand-authored tokens, or generated-file
edits.
