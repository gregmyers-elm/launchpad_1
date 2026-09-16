# Apps, Elements, and Automations

Pull an existing app or element before changing it. For a brand-new app or
element, run `elementum new app` / `elementum new element` (see
[workflow.md](workflow.md)) rather than hand-copying the shape of a pulled
file — the scaffold command also registers the new entity's catalog entry, so
other authored files can reference it as `catalog.<refName>` immediately. Then
edit the generated file with public TypeScript builders.

## Apps

Apps define a business process and its record fields. Use `app` from
`@elementumai/edk/app`:

```ts
import {
  app,
  dropdownField,
  multiSelectField,
  numberField,
  textField,
} from "@elementumai/edk/app";
import { org } from "../../org.js";

export default app({
  handle: "SUPPORT",
  name: "Support Tickets",
  category: { name: "Operations" },
  namespace: "support",
  cloudLink: org.cloudLinks.operations,
  fields: {
    summary: textField({ name: "Summary", required: true }),
    priority: dropdownField({
      name: "Priority",
      config: { static: { values: ["Low", "Medium", "High"] } },
    }),
    labels: multiSelectField({
      name: "Labels",
      config: { static: { values: ["Customer", "Internal"] } },
    }),
    effort: numberField({ name: "Effort" }),
  },
  systemFields: {
    status: {
      name: "Status",
      required: false,
      requiredOnClose: false,
      showOnCreate: false,
      options: ["Open", { label: "Closed", tags: ["CLOSED"] }],
    },
  },
});
```

Rules:

- Keep each field's bag key stable. Change `name` for a display rename.
- Use the field factory that matches the intended stored value.
- Append status options rather than inserting or reordering them.
- Preserve the pulled `required`, `requiredOnClose`, and `showOnCreate` values
  on system-field overrides. These flags control record validation and phone
  agent behavior; an explicit `false` is significant.
- Preserve pulled `systemFields`, `layouts`, `dynamicLayouts`, and list views
  unless the request explicitly changes them.
- A cloud link is optional when the organization has a usable default. When a
  specific store is required, use a pulled `org.cloudLinks.<key>` token.

`dropdownField` stores one value; `multiSelectField` stores multiple values.
Both use the same exact-one configuration: `config.static` for authored values
or `config.dynamic` for records sourced from another app or element. Dynamic
Dropdowns support typed filters, multi-column sorts, Dropdown/Table rendering,
auto-relation, and an optional parent Dropdown with source-field mappings:

```ts
import {
  asc,
  dropdownDisplay,
  dropdownField,
  filter,
  sortBy,
} from "@elementumai/edk/app";
import catalog from "@catalog";

destination: dropdownField({
  name: "Destination",
  config: {
    dynamic: {
      source: catalog.hallPasses,
      label: catalog.hallPasses.fields.title,
      filter: filter.isNotNull(catalog.hallPasses.fields.destination),
      sort: sortBy(asc(catalog.hallPasses.fields.title)),
      displayAs: dropdownDisplay.table,
      autoRelate: true,
    },
  },
}),
```

For static dependent values, use `dropdownOption` and `dropdownValue` so the
EDK resolves the parent option IDs rather than embedding platform UUIDs.
Dynamic parents are single-value Dropdown fields; Multi-Select is a separate
field type, not a setting on Dropdown.

Custom roles are inline on their owning app or element. Use
`roleAutoShare`, `rolePermissionGroup`, and `rolePermissionLevel`; do not type
provider enum strings. Assign users with `userRef(email)` and groups with
`org.groups.<key>` so membership stays typed and portable. Platform-managed
Admin, Edit, and View roles are lookups, not authored custom roles.

Service accounts are also inline and app-owned. They have no email address.
Use constants and name refs so the EDK resolves provider IDs internally:

```ts
import {
  serviceAccountRoleRef,
  serviceAccountStatus,
} from "@elementumai/edk/app";

serviceAccounts: {
  supportRunner: {
    firstName: "Support",
    lastName: "Runner",
    purpose: "Runs approved support tools.",
    status: serviceAccountStatus.active,
    roles: [serviceAccountRoleRef("Support Reviewers")],
    accessPolicies: [{ groups: [org.groups.supportOperators] }],
  },
},
```

Use `serviceAccountRef({ app: catalog.support, name: "Support Runner" })`
when a tool runs as that account. Never expose or persist a raw service-account
ID in authored or pulled EDK source.

Use `calculatedField` with typed `calc` helpers. The expression determines the
stored result type, so authors cannot declare a contradictory field type:

```ts
import { calc, calculatedField } from "@elementumai/edk/app";
import catalog from "@catalog";

const calculated = calculatedField({
  name: "Extended Price",
  expression: calc.times(
    catalog.orders.fields.quantity,
    catalog.orders.fields.unitPrice,
  ),
});
```

Use projections such as `calc.label`, `calc.email`, `calc.name`, or `calc.id`
when comparing a reference field's projected value rather than the reference
itself.

For a simple current-time field, keep the calculation explicit:

```ts
currentTime: calculatedField({
  name: "Current Time",
  expression: calc.now(),
}),
```

Do not wrap a simple `NOW()` contract in an aggregate.

## Elements

Elements are reusable record shapes that are lighter than standalone apps. Use
`element`, not `app`:

```ts
import {
  booleanField,
  element,
  textField,
} from "@elementumai/edk/elements";
import { org } from "../../org.js";

export default element({
  handle: "LOCATION",
  name: "Locations",
  category: { name: "Operations" },
  namespace: "locations",
  cloudLink: org.cloudLinks.operations,
  fields: {
    address: textField({ name: "Address", required: true }),
    active: booleanField({ name: "Active" }),
  },
});
```

Place the file at `elements/<ref>/<ref>.ts`. Pull an existing element with:

```bash
elementum --profile=<profile> pull element <namespace>
```

Elements can be targets anywhere an element token is accepted. They do not own
agents, platform agentic skills, or approval chains.

## Phone Services

Phone services are app-owned resources, not agent properties. An app may own
multiple phone services and each service points to its handling agent:

```ts
import { callerAccessMode, phoneService } from "@elementumai/edk/app";
import catalog from "@catalog";

export default phoneService({
  app: catalog.support,
  agent: catalog.support.agents.triage,
  provider: catalog.phoneProviders.primary,
  callerAccessMode: callerAccessMode.knownCallersOnly,
  twilioExistingNumber: { phoneNumber: "+14155550123" },
});
```

Keep only properties represented by the current public configuration contract.
Do not invent future phone-service options or flatten the service onto the
agent.

## Automations

An automation is a trigger plus a typed action chain. Place it under
`apps/<appRef>/automations/<refName>.ts` and use
`@elementumai/edk/automations`.

```ts
import {
  automationStatus,
  automation,
  actions,
  filter,
  onDemand,
} from "@elementumai/edk/automations";
import catalog from "@catalog";

export default automation({
  name: "Find Escalated Tickets",
  app: catalog.support,
  revision: "1.0.0",
  status: automationStatus.draft,
  actions: actions()
    .trigger(onDemand({
      QUERY: { type: "text", required: true },
    }))
    .recordSearch("FIND_TICKETS", {
      app: catalog.support,
      filter: filter.eq(
        catalog.support.fields.priority,
        "High",
      ),
      limit: 10,
    })
    .outputs((ctx) => ({
      MATCH_COUNT: ctx.actions.FIND_TICKETS.totalCount,
    })),
});
```

Automation rules:

- `parent` is the owning app ref.
- `revision` is required SemVer and is the publication gate. Keep it
  unchanged for draft edits; ask before bumping it to publish a new revision.
- Use `automationStatus.draft`, `.inactive`, or `.active` for the authorable
  automation lifecycle. `UNPUBLISHED` and `DISABLED` are derived automation
  summaries in Mobius, not authoring inputs.
- Use `ctx.trigger`, `ctx.actions`, and `ctx.variables` for data flow.
- Author `forEach`, `switch`, and `forkJoin` branches by continuing the fluent
  builder passed to each branch. Nested action outputs accumulate on that
  branch, and a `forEach` branch reads its current value from `ctx.item`.
- Use the namespaced `filter` export for automation filters.
- Prefer one clear trigger, explicit action names, and declared automation outputs
  for values callers need.
- When an action needs a model connector, pass
  `catalog.aiProviders.<family>.models.<model>`.
- Search an organization table with `tableRecordsSearch` and a portable
  `catalog.tables.<ref>` token (or `tableRef({ name, refName })` before the
  table is pulled). Do not pass a raw platform table UUID.
- Start an approval with `approvalChain`. Pass the app-owned
  `catalog.<app>.approvalChains.<process>` token plus record and requester
  value references; add `approvers` only for dynamic approver slots. Do not
  pass an approval-process UUID or static user IDs.

```ts
.approvalChain("REQUEST_APPROVAL", (ctx) => ({
  approvalProcess: catalog.expenses.approvalChains.expenseApproval,
  record: ctx.trigger.record,
  requester: ctx.trigger.record.createdBy.id,
  approvers: [ctx.trigger.record.manager.id],
}))
```

```ts
.forEach("NOTIFY_MATCHES", {
  collection: (ctx) => ctx.actions.FIND_TICKETS.records,
  actions: (branch) => branch
    .executeScript("PREPARE_MESSAGE", {
      code: (input) => ({ message: `Ticket ${input.parameters.id}` }),
      inputs: (ctx) => ({ id: ctx.item.id }),
      outputs: { message: "string" },
    })
    .sendEmail("SEND_MESSAGE", (ctx) => ({
      body: ctx.actions.PREPARE_MESSAGE.result.message,
      subject: "Escalated ticket",
      toAddresses: ["support@example.com"],
    })),
})
```

```ts
import {
  automation,
  actions,
  onDemand,
} from "@elementumai/edk/automations";
import catalog from "@catalog";

export default automation({
  name: "Find Matching Orders",
  app: catalog.support,
  revision: "1.0.0",
  actions: actions()
    .trigger(onDemand({}))
    .tableRecordsSearch("FIND_ORDERS", {
      table: catalog.tables.orders,
    })
    .outputs((ctx) => ({
      MATCH_COUNT: ctx.actions.FIND_ORDERS.totalCount,
    })),
});
```

Author calculations with the typed `calc` grammar. Wrap referenced values with
`calc.param`; the expression type becomes the named action-output type, while
Mobius and Ultron validate and store the authoritative platform type:

```ts
import { calc } from "@elementumai/edk/automations";

.calculation("CALCULATE_TOTAL", (ctx) => ({
    values: {
      TOTAL: calc.times(
        calc.param(ctx.trigger.record.quantity),
        calc.param(ctx.trigger.record.unitPrice),
      ),
    },
  }))
.outputs((ctx) => ({ TOTAL: ctx.actions.CALCULATE_TOTAL.TOTAL }))
```

Do not pass `outputType`: it is not a calculation write field. Avoid opaque
formula strings for new work; raw strings remain a pull-fidelity fallback.

`calc` is a closed, statically typed view of Knowhere's calculated-expression
grammar. The supported function families and EDK spellings are:

| Family | Typed builders |
| --- | --- |
| Logic and null | `and`, `or`, `if`, `ifs`, `bool`, `blank`, `isBlank` |
| Aggregate | `average`, `count`, `countIf`, `countUnique`, `max`, `min`, `stdev`, `stringAgg`, `stringAggUnique`, `sum`, `sumIf` |
| Date and time | `makeDate`, `dateTime`, `dateDif`, `dateTimeTrunc`, `dateValue`, `now`, `weekday`, `year`, `month`, `day`, `hour`, `minute`, `second` |
| Text | `concat`, `left`, `right`, `splitText`, `len`, `find`, `search`, `mid`, `lower`, `upper`, `substitute`, `repeat`, `toText`, `trim` |
| Regex and JSON | `regexExtract`, `regexMatch`, `regexReplace`, `jsonEscape`, `jsonUnescape` |
| Numeric and identity | `round`, `power`, `sqrt`, `toNumber`, `uuid` |
| Operators and projections | `plus`, `minus`, `times`, `dividedBy`, `gt`, `lt`, `gte`, `lte`, `eq`, `ne`, `label`, `id`, `email`, `name` |

Constrained backend options have exported constant objects and derived literal
unions, so authors get autocomplete and unsupported values fail at compile
time:

- `dateDif` units: `"S" | "MIN" | "H" | "Y" | "M" | "D"`
- `dateTimeTrunc` precision: `"MICROSECONDS" | "MILLISECONDS" | "SECOND" | "MINUTE" | "HOUR" | "DAY" | "WEEK" | "MONTH" | "QUARTER" | "YEAR" | "DECADE" | "CENTURY" | "MILLENNIUM"`
- `weekday` modes: `1 | 2 | 3`
- `stringAgg` ordering: `{ orderBy: [{ field, direction: "ASC" | "DESC" }] }`
- `countIf` / `sumIf` predicates: `{ op: "=" | "!=" | "<>" | ">" | ">=" | "<" | "<=", value }`

Import `dateDifUnit`, `dateTimeTruncPrecision`, `weekdayMode`,
`orderByDirection`, `predicateOp`, and `calculationParameterType` from
`@elementumai/edk/automations` instead of repeating those literals. The app
entry point exports the field-calculation constants as well.

Action refs with a unique TypeScript primitive infer automatically. DATE,
DATETIME, and TEXT are all string-shaped, so state that calculation type where
it matters:

```ts
const opened = calc.param(ctx.trigger.record.openedOn, { type: calculationParameterType.date });
const checked = calc.param(ctx.trigger.record.checkedAt, { type: calculationParameterType.datetime });

const ageMinutes = calc.dateDif(opened, checked, dateDifUnit.minutes);
```

The type option is authoring metadata only. Mobius still derives the actual
calculation parameter type from the reference and validates it before execution.

Author calculations with the typed `calc` grammar. Action refs are accepted
directly, and each `values` object key becomes a precisely typed action output:

```ts
import { calc } from "@elementumai/edk/automations";

.calculation("CALCULATE_TOTAL", (ctx) => ({
    values: {
      total: calc.times(
        ctx.trigger.record.quantity,
        ctx.trigger.record.unitPrice,
      ),
      checkedAt: calc.now(),
    },
  }))
.outputs((ctx) => ({
  total: ctx.actions.CALCULATE_TOTAL.total,
  checkedAt: ctx.actions.CALCULATE_TOTAL.checkedAt,
}))
```

Do not pass `outputType`: it is not a calculation write field. Avoid opaque
formula strings for new work; `calc.raw(text, resultType)` is only for pulled
formulas and legacy escape hatches. `calc.field`, `calc.param`, and the old
`calculations: [{ name, expression }]` shape remain compatibility helpers.

Aggregates and stored functions need a record context. AUTO relationship
inclusion is the default; use `include: "manual"`, `include: "both"`, or
`include: { picklist: catalog.orders.fields.lineCategory }` when required.

`calc` is a closed, statically typed view of Knowhere's calculated-expression
grammar. The supported function families and EDK spellings are:

| Family | Typed builders |
| --- | --- |
| Logic and null | `and`, `or`, `if`, `ifs`, `bool`, `blank`, `isBlank` |
| Aggregate | `average`, `count`, `countIf`, `countUnique`, `max`, `min`, `stdev`, `stringAgg`, `stringAggUnique`, `sum`, `sumIf` |
| Date and time | `makeDate`, `dateTime`, `dateDiff`, `truncateDateTime`, `dateValue`, `now`, `weekday`, `year`, `month`, `day`, `hour`, `minute`, `second` |
| Text | `concat`, `left`, `right`, `split`, `len`, `find`, `search`, `mid`, `lower`, `upper`, `substitute`, `repeat`, `toText`, `trim` |
| Regex and JSON | `regexExtract`, `regexMatch`, `regexReplace`, `jsonEscape`, `jsonUnescape` |
| Numeric and identity | `round`, `power`, `sqrt`, `toNumber`, `uuid` |
| Operators and projections | `plus`, `minus`, `times`, `dividedBy`, `gt`, `lt`, `gte`, `lte`, `eq`, `ne`, `label`, `id`, `email`, `name`, `call`, `raw` |

Constrained backend options have exported constant objects and derived literal
unions, so authors get autocomplete and unsupported values fail at compile
time:

- `dateDiff` units include `"seconds"`, `"minutes"`, `"hours"`, `"days"`,
  `"months"`, and `"years"`.
- `truncateDateTime` accepts readable precisions such as `"month"`.
- `weekday` accepts `"sundayOne"`, `"mondayOne"`, or `"mondayZero"`.
- `stringAgg` ordering uses `{ orderBy: [{ value, direction: "asc" | "desc" }] }`.
- Predicates use readable keys such as `{ greaterThan: 10 }` and
  `{ greaterThanOrEqual: 10 }`.

Import `dateDifUnit`, `dateTimeTruncPrecision`, `weekdayMode`,
`orderByDirection`, `predicateOp`, and `calculationParameterType` from
`@elementumai/edk/automations` instead of repeating those literals. The app
entry point exports the field-calculation constants as well.

Catalog and action refs carry their calculation type even when their runtime
TypeScript values share a primitive representation. DATE, DATETIME, TEXT,
PICKLIST, and MULTI_PICKLIST therefore infer without annotations:

```ts
const ageMinutes = calc.dateDiff(
  ctx.trigger.record.openedOn,
  ctx.trigger.record.checkedAt,
  "minutes",
);
```

Factories exported by the TypeScript package are broader than the set every
workspace can safely build. Treat any `elementum build` diagnostic as a hard
boundary; do not replace an unsupported trigger or action with a different one
without user approval.

## Editing Existing Data Models

1. Pull the app or element.
2. Preserve unrelated fields and pulled configuration.
3. Make the smallest coherent TypeScript change.
4. Typecheck and build.
5. Review the complete plan, especially field removals, option changes,
   namespace changes, and automation revision changes.
