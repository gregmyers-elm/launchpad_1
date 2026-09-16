---
name: elementum-uat
description: Run whole-solution user acceptance testing for deployed Elementum solutions. Use for records, automations, agents, tools, conversations, file handling, platform agentic skills, A2A delegation, and verified end-to-end business outcomes.
edkVersion: 0.9.5
---

# Elementum UAT

This is a coding-agent playbook for testing a deployed solution. It is not an
Elementum platform agentic skill or A2A skill; those are solution components
this playbook may test.

## Establish the Contract

Before executing:

1. Confirm the target profile, app namespaces, test users, and allowed side
   effects. Do not mutate production data without explicit approval.
2. Turn each requirement into a test with setup, action, expected observable
   result, and cleanup.
3. Cover every applicable layer: records, files, automations, agents,
   agent/skill tools, conversations, integrations, and final business outcome.
4. Use uniquely prefixed test records and fixtures. Never delete data the test
   did not create.

Check the target:

```bash
elementum --profile=<profile> auth status
elementum --profile=<profile> list apps
elementum --profile=<profile> automations list <app-namespace>
```

Stop if the profile or app differs from the agreed target.

## Execute the Smallest Complete Journey

### 1. Records and files

Preview record creation, then create and read back the fixture:

```bash
elementum --profile=<profile> records create <app-namespace> \
  -f "Title=UAT-<run-id>" --dry-run
elementum --profile=<profile> records create <app-namespace> \
  -f "Title=UAT-<run-id>" --json
elementum --profile=<profile> records get <app-namespace> <record-handle> --json
```

When files are in scope, upload a representative fixture and verify the
resulting record:

```bash
elementum --profile=<profile> records create <app-namespace> \
  -f "Title=UAT-<run-id>-file" -a "Attachments=./fixture.pdf" --json
```

Exercise required updates, filters, status changes, relationships, and
validation errors. Assert stored field values and not just command success.

### 2. Automations

Trigger each automation through its real entry point: record creation/update,
an approved on-demand action, or its supported webhook path. Then inspect the
execution:

```bash
elementum --profile=<profile> automations status <app-namespace> \
  "<automation-name>" --latest --timeline
elementum --profile=<profile> automations status <app-namespace> \
  "<automation-name>" --latest --all-io --json
```

Verify trigger selection, task order, inputs, outputs, record changes, and
external side effects. A successful execution is insufficient if the business
outcome is wrong.

### 3. Agents, tools, and conversations

Test direct answers, clarification, refusal/confirmation gates, tool choice,
multi-turn context, and error recovery:

```bash
elementum --profile=<profile> chat "<agent-name>" -m "<initial request>"
elementum --profile=<profile> chat "<agent-name>" \
  --continue <conversation-id> -m "<follow-up>"
elementum --profile=<profile> conversation "<agent-name>" \
  <conversation-id> --json
```

For file-aware behavior:

```bash
elementum --profile=<profile> chat "<agent-name>" \
  -m "<request about the file>" -a ./fixture.pdf
```

For every expected tool call, verify the tool was invoked with correct inputs
and produced the expected record, automation, or external effect. When the
solution uses platform agentic skills, test routing to the intended skill.
When it uses A2A skills, verify delegation, returned result, and parent-agent
use of that result. Do not treat a plausible final message as proof.

### 4. End-to-end outcome

Run at least one realistic journey across all participating components. Read
back the final records and inspect relevant automation and conversation
evidence:

```bash
elementum --profile=<profile> records list <app-namespace> \
  --where "Title=UAT-<run-id>" --json
elementum --profile=<profile> interventions list <app-namespace> \
  --status OPEN --json
```

Pass only when the user-visible result, persisted data, files, executions,
tool calls, and required external effects all agree with the acceptance
criteria.

## Report and Cleanup

Record for each test: ID, requirement, fixture, commands/actions, expected,
actual, evidence identifiers, PASS/FAIL/BLOCKED, and cleanup status. Separate
product failures from environment or fixture blockers.

Use [the report template](assets/report.md) for the run summary and
`assets/test-result.yaml` for machine-readable per-test evidence.

Delete only the uniquely identified fixtures created by this run, and only
when cleanup was approved:

```bash
elementum --profile=<profile> records delete <app-namespace> <record-handle> \
  --dry-run
elementum --profile=<profile> records delete <app-namespace> <record-handle>
```
