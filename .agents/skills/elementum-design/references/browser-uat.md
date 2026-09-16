# Browser UAT for record experiences

Do not approve a user-visible layout from source, typechecking, or plan output
alone. Open realistic records in an authenticated browser and inspect the
rendered experience.

## Prepare representative records

Use at least:

1. **Happy path:** ordinary valid values.
2. **Risk path:** exceptional content and all important warnings visible.
3. **Sparse path:** optional values empty.
4. **Long-content path:** long title, narrative, and many related items.
5. **Later-stage path:** a materially different stage layout.

Use uniquely prefixed UAT records and delete only fixtures created by the run.

## Required state matrix

Exercise every applicable state:

- Loading and fully settled data.
- Empty, normal, exceptional, long, and heavily populated content.
- Read, edit, dirty, invalid, corrected, saved, and discarded values.
- Collapsed and expanded supporting sections.
- Enabled, disabled, confirmation, cancelled, successful, and rejected
  actions.
- Wide desktop, normal desktop, and reduced content width.
- Keyboard order, Enter/Space behavior, dialog focus, Escape, visible Cancel,
  focus restoration, labels, required state, invalid state, and error
  association.

Wait for picklists, conditional content, and platform-owned blocks to finish
loading before judging the result.

## Browser loop

1. Confirm the profile and target app.
2. Apply the reviewed change.
3. Open a direct URL for each fixture record in an authenticated browser.
4. Verify the organization, app, record, and stage before interacting.
5. Capture the first viewport, then test the applicable state matrix.
6. Inspect clipping, overlap, scroll containers, focus, disabled/required
   state, labels, and error messages.
7. Capture only design-significant states, including one normal desktop width
   and one narrower width.
8. Revise the TypeScript, rebuild, review, apply, reload the same records, and
   rerun affected states.

Do not use synthetic screenshots or source-only reasoning as acceptance
evidence.

## Acceptance criteria

- The first viewport answers what this is, what matters now, and what happens
  next.
- Each stage contains only task-relevant information.
- Sparse, exceptional, and long records preserve hierarchy.
- The primary action is obvious and labels its outcome.
- Supporting evidence and history remain accessible but secondary.
- List views support scanning and prioritization.
- No content clips, overlaps, or becomes unreachable at tested widths.
- Keyboard and visible validation behavior remain usable.
- Screenshots or a short walkthrough demonstrate the final working states.
