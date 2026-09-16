# Other Entities

Use this reference after identifying ownership and lifecycle. Pull the owning
app or element first when editing an existing solution.

## Ownership and Locations

| Entity | Public import | Owner and authored location |
| --- | --- | --- |
| Chart | `@elementumai/edk/charts` | App: `apps/<app>/charts/<ref>.ts` |
| Search table | `@elementumai/edk/searchTables` | Element or table (never an app): `<owner>/search-tables/<ref>.ts` |
| Visual Flow | `@elementumai/edk/visualFlows` | App: `apps/<app>/visual-flows/<ref>.ts` |
| Approval process | `@elementumai/edk/approvalProcesses` | App: `apps/<app>/approval-chains/<ref>.ts` |
| File reader | `@elementumai/edk/fileReaders` | Owning app or element: `<owner>/fileReaders/<ref>.ts` |
| Table | `@elementumai/edk/tables` | Organization: `tables/<ref>/<ref>.ts` |
| Standalone task | `@elementumai/edk/tasks` | Organization: `tasks/<ref>/<ref>.ts` |

Apps and elements may also own automations. Agents, platform agentic skills,
and approval chains are app-owned.

## Charts and Dashboard Widgets

Charts are app-owned analytics resources. Define each chart in
`apps/<app>/charts/<ref>.ts` with `defineChart`, then place it on an app
dashboard with a typed chart ref. Use the exported constants for chart types,
aggregations, static-value types, and join types; do not author platform IDs.

```ts
import {
  chartAggregation,
  chartSubscription,
  chartType,
  defineChart,
} from "@elementumai/edk/charts";
import catalog from "@catalog";

export default defineChart({
  app: catalog.sales,
  name: "Pipeline by Stage",
  type: chartType.bar,
  properties: { beginAtZero: true, legend: true },
  subscriptions: [
    chartSubscription({
      datasource: catalog.sales,
      columns: [{
        field: catalog.sales.fields.amount,
        aggregation: chartAggregation.sum,
      }],
      groupBy: [{ field: catalog.sales.fields.stage }],
    }),
  ],
});
```

The subscription builder ties each column and grouping field to its data
source. Use `chartJoin` for a typed second data source; its left and right
fields are checked against their respective owners. The closed chart domains
are branded: select `chartType`, `chartAggregation`, `chartColumnValueType`,
and `chartJoinType` members rather than spelling their wire strings.

A dashboard may embed only a chart owned by that same app. Build widgets with
`dashboardChartWidget({ owner, chart, name, size })` or
`dashboardRecordsWidget({ target, name, size })`, and select sizes through
`dashboardWidgetSize`. The factories hide wire discriminator strings, require
object refs, and reject raw size literals. Inside `app(...).withRefs`, use
`self.chart(...)`, `self.dashboard(...)`, and the `self` app token rather than
child keys or platform IDs. Pulled source emits these same factories and refs.

## Visual Flows

Use `visualFlow` only for the product's immutable visual Flows diagram.
Pass the typed `app` owner, key `stages` by
their stable stage keys, and use `visualFlowSymbol` / `visualFlowPosition`
constants. Build actions and object targets with the `flow*Action` and
`flowObjectTarget` factories so pulled and authored source contains catalog
references rather than platform IDs. This is not the experimental executable
app-flow API; `defineFlow` and app-flow activities are not public EDK APIs.
Elements cannot own visual flows because they do not expose stages.

## Search Tables

Search tables index fields for record and agent search. A managed or linked
search table is owned by an **element**; only a table's search table is owned by
a table. An app can never own one — an app's backing Snowflake table is hybrid,
and Cortex cannot index one (`AI Search Tables cannot be created on hybrid
tables`). `searchTable` therefore takes `element`, and passing `app` is a
type error.

```ts
import { searchTable, searchTableDuration } from "@elementumai/edk/searchTables";
import catalog, { org } from "@catalog";

export default searchTable({
  name: "Article Search",
  element: catalog.knowledgeBase,
  attributeFields: [
    catalog.knowledgeBase.fields.title,
    catalog.knowledgeBase.fields.section,
  ],
  duration: searchTableDuration.hours,
  targetLag: 1,
  vectorIndex: {
    field: catalog.knowledgeBase.fields.body,
    service: org.aiProviders.snowflake.models.snowflakeArcticM_V1_5,
  },
});
```

The vector-index `service` must be an **embedding** connector; an LLM connector
cannot back a search table.

An agent or skill that searches this table targets the owning ELEMENT, which is
usually not the agent's own app:

```ts
skillSearchTable({
  name: "search_kb",
  description: "Search the knowledge base.",
  element: catalog.knowledgeBase,
  table: catalog.knowledgeBase.searchTables.articleSearch,
  queryDescription: "what to search for",
  fields: [{ field: catalog.knowledgeBase.fields.body, name: "Body", description: "..." }],
});
```

Use `linkedSearchTable` only when the user has supplied the existing
search service and cloud-link details. A managed search table requires an
attribute field and a vector index.

For semantic search over an organization table, place the file at
`tables/<table>/search-tables/<ref>.ts` and use `tableSearchTable`.
Pass `org.tables.<table>` as `table` and its typed `.columns.*` tokens for
`field` and `attributeFields`; do not pass a raw table kind, parent, or ID.

Only lag settings on a managed table have limited update support. Treat other
changes, and changes to linked tables, as potentially replacement-requiring
until the plan proves otherwise.

## Approval Processes

Use `approvalProcess` for app-owned approval processes. Pass the typed
owning `app`, then set a portable app
stage key, `numberOfDynamicApprovers`, and whether automation exclusively
manages the process. The automation task that starts the approval supplies the
actual dynamic approvers; static user/group steps are not part of the provider
resource.

Reference the process from an automation with
`catalog.<app>.approvalChains.<process>`. The `approvalChain` action also
requires the record being approved and the requester as typed runtime refs;
its optional `approvers` entries fill the process's dynamic approver slots.
Never copy the approval-process platform ID into automation source.

Use catalog field tokens for `lockedFields`. Approval processes update in
place, but changing the approver count, automation ownership, or locked fields
is a business-control change; call it out separately in the plan summary.

## File Readers

Use `aiFileReader`, `excelFileReader`, `jsonFileReader`, `textFileReader`, or
`xmlFileReader` for the five provider-backed document readers. The factory
selects the variant, so authored code never passes a wire `type` string.

Keep document parsing instructions narrow and fields explicit. For recursive
JSON or XML structures, use `fileReaderStructure` helpers. Preserve source
document references from pulled source rather than inventing them.

## Tables

Tables are organization-owned analytics entities authored with `table`.
They can declare cloud, calculation, source, and reference fields plus typed
joins and filters.

Place each table at `tables/<ref>/<ref>.ts`. Use app/element, cloud-link, field, and
table tokens from pulled catalogs. Use `snowflakeColumn` or `bigQueryColumn`
instead of selecting a provider with a discriminator, `snowflakeTableMapping`,
`bigQueryTableMapping`, or `databricksTableMapping` for cloud mappings, and the
`tableColumnType`, `tableColumnTag`, `tableAggregation`, `tableExpansion`, and
`tableJoinType` constants for every closed value. A table category is an
`org.categories.<key>` token; source and join columns are typed field/table
column refs, never provider IDs.

Keep column bag keys stable across edits because they carry identity. A simple
current-time calculation is `calculationColumn({ name: "Captured At",
expression: "NOW()" })`; do not wrap it in an aggregate.

## Standalone Tasks

Standalone tasks are organization-owned work-item containers authored with
`task`. Use an organization category token, not a category-name object,
and use `taskStatusTag.closed` for terminal status options:

```ts
task({
  name: "Action Items",
  category: org.categories.operations,
  statusField: {
    options: [
      { label: "Open" },
      { label: "Done", tags: [taskStatusTag.closed] },
    ],
  },
});
```

Standalone task aspects use `task` at `tasks/<ref>/<ref>.ts`. Prefer
file-derived handle/namespace defaults, category names from the org catalog,
and explicit status options with `CLOSED` tags on terminal states.

## Decision Rules

- Need reusable record storage: app or element.
- Need an event-driven task graph: automation.
- Need a conversational model with tools: agent.
- Need a progressively loaded runtime tool bundle: platform agentic skill.
- Need semantic or indexed record lookup: search table.
- Need staged human approval: approval process.
- Need structured extraction from documents: file reader.
- Need organization-level analytical data: table.

When the requested behavior does not fit a public builder, report the gap and
ask for a supported design choice. Do not approximate it with hidden APIs or a
second configuration format.
