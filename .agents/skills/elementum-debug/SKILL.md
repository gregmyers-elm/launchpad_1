---
name: elementum-debug
description: Quickly diagnose Elementum workspace, build, deployment, and live-solution failures. Use for type errors, build or plan failures, profile/workspace mismatches, bad record behavior, failed automations, broken tools, agent misbehavior, conversations, and missing end-to-end outcomes.
edkVersion: 0.9.5
---

# Elementum Debug

This is a coding-agent diagnosis playbook. It is not an Elementum platform
agentic skill or A2A skill; those are runtime components whose behavior may
need diagnosis.

## Diagnose Broadly, Then Drill Down

Keep the first pass short. Capture the exact failing action, expected result,
actual result, target profile, app namespace, and last-known-good behavior.
Do not edit code until evidence identifies the failing layer.

### 1. Confirm target and workspace

Run from the affected EDK org workspace:

```bash
elementum --profile=<profile> auth status
elementum playbooks status elementum-debug
npx tsc --noEmit
```

Check that the selected profile matches the org workspace. Classify failures
as workspace setup, authored TypeScript, generated catalog/reference, or
authentication before investigating live behavior.

### 2. Isolate build and deployment

```bash
elementum build
elementum --profile=<profile> plan
```

- If typecheck fails, fix the first causal error and rerun it.
- If build fails, use the named source file and diagnostic; do not edit
  generated files.
- If plan fails, separate authentication/workspace errors from invalid
  authored configuration.
- If plan succeeds but live behavior is stale, confirm the intended change was
  applied and that automation publication/versioning was included.
- Never apply a speculative fix. Review the plan and obtain approval for
  significant changes.

### 3. Check live data and automation health

```bash
elementum --profile=<profile> records list <app-namespace> --limit 10 --json
elementum --profile=<profile> automations status <app-namespace> \
  "<automation-name>" --latest --timeline
elementum --profile=<profile> interventions list <app-namespace> \
  --status OPEN --json
```

If an automation failed, inspect only the failed action first:

```bash
elementum --profile=<profile> automations status <app-namespace> \
  "<automation-name>" --latest-failure --io "<action-name>" --json
```

Compare trigger data, action input, action output, persisted record state, and
the expected business result. Expand to `--all-io` only when the failing
boundary remains unclear.

### 4. Check agents, platform skills, and tools

Reproduce with one minimal turn, then inspect the conversation:

```bash
elementum --profile=<profile> chat "<agent-name>" -m "<minimal reproduction>"
elementum --profile=<profile> conversation "<agent-name>" \
  <conversation-id> --json
```

Determine whether the failure is routing, instructions, tool selection, tool
inputs, backing automation, returned data, or final-response interpretation.
For platform agentic skills, verify the intended skill loaded. For A2A skills,
verify delegation and the child result independently. If a file is involved,
reproduce with the same file type and size using `-a`.

## Close the Loop

State one evidence-backed root cause and the smallest owning layer. After a
fix, rerun the original reproduction plus one adjacent regression check:

```bash
npx tsc --noEmit
elementum build
elementum --profile=<profile> plan
```

If a deployment is approved and applied, repeat the live record, automation,
or conversation check that originally failed. Report the root cause, evidence,
change, verification, and any remaining uncertainty.
