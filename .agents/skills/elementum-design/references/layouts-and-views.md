# TypeScript layouts and views

Pull an existing app before changing its record experience. Preserve unrelated
`layouts`, `listViews`, and `viewOrder` entries.

## Per-stage record layouts

`layouts` is keyed by the stage key used by the app's stage options. Each
layout contains ordered sections:

```ts
import { app, textField } from "@elementumai/edk/app";

export default app({
  handle: "REQ",
  namespace: "requests",
  name: "Requests",
  category: { name: "Operations" },
  fields: {
    summary: textField({ name: "Summary", required: true }),
  },
  systemFields: {
    stage: { name: "Stage", options: ["Intake", "Assessment"] },
  },
}).withRefs((self) => ({
  layouts: {
    intake: {
      sections: [
        {
          type: "group",
          name: "Request details",
          displayLocation: "CENTER",
          displayOrder: 0,
          sideNavItem: false,
          maxColumns: 1,
          fields: [self.fields.summary, "createdAt", "createdBy"],
        },
        {
          type: "attachments",
          displayLocation: "CENTER",
          displayOrder: 1,
          sideNavItem: true,
        },
      ],
    },
  },
}));
```

Supported section types are:

- `group`
- `activityLog`
- `approvals`
- `attachments`
- `status`
- `surveys`
- `relatedTasks`
- `relationships`
- `update`

Only `group` sections carry `fields`, `icon`, `color`, and `maxColumns`. Use
`maxColumns: 1` for a single-column field stack or a larger value for denser
groups. Use custom field tokens or stable audit-field keys in a group. Preserve
pulled system sections that the app already owns.

Changing an existing stage layout may replace that layout. Review the plan and
state this consequence before apply.

Stage-owned display blocks are the record-details experience. App- or
element-owned display blocks belong to the record create form. Preserve that
ownership distinction when pulling or editing; do not move record-details
blocks to the root merely because both surfaces display fields.

## List views

Use `listViews` for saved record-finding experiences and `viewOrder` for their
navigation order:

```ts
listViews: {
  activeRequests: {
    name: "Active requests",
    columns: ["title", "status", summaryRef, "updatedAt"],
    allowRecordCreation: true,
    density: "STANDARD",
    rows: 25,
    sort: {
      orders: [{ field: "updatedAt", direction: "DESC" }],
    },
  },
},
viewOrder: ["activeRequests"],
```

Choose columns that support scanning and prioritization. A useful list view
normally includes identity, current state, ownership or urgency, and one or two
decision-relevant fields.

Managed-view sorts contain an ordered `orders` list. Each order takes a typed
custom-field token or stable system-field key, an `"ASC"` or `"DESC"`
direction, and optionally one of `"AVERAGE"`, `"COUNT"`, `"MAX"`, `"MIN"`, or
`"SUM"` as `aggregation`. List-view density is `"COMFORTABLE"`, `"COMPACT"`,
or `"STANDARD"`. Filters remain typed through the shared `filter` helpers.

## Edit loop

```bash
elementum --profile=<profile> pull app <namespace>
npx tsc --noEmit
elementum build
elementum --profile=<profile> plan
```

Review layout replacement, list-view changes, ordering, and any unrelated
removal before apply.
