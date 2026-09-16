---
name: elementum-design
description: Design and verify high-quality Elementum record experiences with the TypeScript EDK. Use when asked to design or improve layouts, list views, stage-specific record pages, information hierarchy, record UX, field composition, responsive behavior, accessibility, or browser UAT for an Elementum solution.
edkVersion: 0.9.5
---

# Elementum Design

Use this coding-agent playbook for the user experience of an Elementum
solution. Use `/elementum` for general data-model and automation authoring, and
`/elementum-uat` for acceptance testing beyond layout and interaction quality.

## Route the request

- Process stages, personas, decision points, and information hierarchy:
  [process design](references/process-design.md)
- Current TypeScript EDK `layouts`, `listViews`, and `viewOrder` authoring:
  [layouts and views](references/layouts-and-views.md)
- Real-browser states, responsive checks, accessibility, and evidence:
  [browser UAT](references/browser-uat.md)

Read only the references needed for the request. For a new or materially
changed record experience, read all three.

## Design workflow

1. Pull the existing app before editing it.
2. Identify the personas, stages, decisions, handoffs, failure paths, and one
   primary job at each stage.
3. Put decision-critical facts and the primary action first. Keep evidence and
   history available without letting them dominate the first viewport.
4. Use a distinct layout when a stage changes the user's job materially.
5. Preserve unrelated pulled layouts, list views, and ordering.
6. Typecheck, build, and review the plan. Layout changes can replace an
   existing stage layout; call that out explicitly.
7. Apply only after approval.
8. Open realistic records in an authenticated browser and test the applicable
   state matrix. Revise from visual and interaction evidence.

## Hard rules

- A compiling component tree is not proof of good design.
- Do not duplicate title, status, stage, owner, or actions already supplied by
  the native record chrome.
- Prefer one primary action per stage.
- Use explicit labels; never communicate state by color alone.
- Do not invent components, conditions, or behavior outside the public
  TypeScript types.
- Do not hand-author opaque list-view filters or sorts. Preserve pulled values
  when they already exist.
- Use realistic sparse, populated, risk, and long-content records.
- Browser verification is required for user-visible layout changes.
- Separate design defects from unsupported authoring or platform behavior;
  report the owning boundary instead of hiding it.
