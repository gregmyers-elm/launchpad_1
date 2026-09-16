# Process-first record design

Design the work before selecting sections or fields.

## Stage matrix

For each materially different stage, record:

| Question | Required answer |
| --- | --- |
| Persona | Who is responsible now? |
| Primary job | What single outcome must they produce? |
| Decision | What must they understand or decide? |
| Required inputs | What must be edited now? |
| Evidence | What supports the decision? |
| Primary action | What advances or closes the work? |
| Failure path | What blocks, rejects, or returns it? |

If two stages have the same persona, decision, fields, and action, they can
usually share a layout. Reordering the same giant field list is not meaningful
stage design.

## Information hierarchy

Order each record experience around the current job:

1. **Orientation:** the few facts needed to recognize the record and its risk.
2. **Work area:** fields the current persona must review or change.
3. **Decision and action:** the primary outcome and any required confirmation.
4. **Evidence:** attachments, relationships, findings, approvals, or source
   material.
5. **History:** activity and audit detail, available but visually secondary.

Do not repeat information already visible in the native record header.

## Common stage patterns

### Intake

- Show scope, requester, ownership, category, and completeness.
- Hide downstream scores, approvals, and remediation details.
- Primary action: submit or start assessment.

### Assessment

- Show context summary, risk factors, evidence sufficiency, and rationale.
- Surface missing evidence and exceptional risk clearly.
- Primary action: route findings or submit a decision.

### Remediation

- Show open findings, owners, dates, plan, and exceptions.
- Keep original evidence available but secondary.
- Primary action: submit remediation or request an exception.

### Approval

- Show decision summary, material findings, residual risk, and approval notes.
- Keep the full evidence package accessible without front-loading it.
- Primary action: approve, reject, or return with an explicit consequence.

### Monitoring or terminal stages

- Show outcome, ownership, health indicators, and next review.
- Preserve distinct terminal outcomes such as completed, rejected, cancelled,
  or retired instead of collapsing them into a generic closed state.

## Review questions

- Does the first viewport answer what this is, what matters now, and what to do
  next?
- Is every visible field relevant to the current persona and stage?
- Is the primary action singular and outcome-labeled?
- Are exceptional records visibly different without relying on color alone?
- Are evidence and history available without overwhelming the work area?
- Do sparse and long values preserve the hierarchy?
