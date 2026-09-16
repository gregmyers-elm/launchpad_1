---
name: elementum-deployments
description: Configure Elementum cross-environment deployments from an admin deployment URL or asyncTaskId. Use for promotion configuration modals, missingEnvironmentConfigurations, table or element connections, CloudLink mappings, unresolved deployment values, and deployment apply verification.
edkVersion: 0.9.5
---

# Elementum Deployments

This is a coding-agent operations playbook. It is not an Elementum platform
agentic skill or A2A skill.

Use it when a service team provides either a full admin deployment URL or its
raw `asyncTaskId`, for example:

```text
https://<org-host>/admin/apps/<app>/deployments/overview?asyncTaskId=<uuid>&deployingEnvId=<uuid>&showConfigModal=true
```

Preserve the full URL exactly. The command extracts `asyncTaskId`; a raw
`asyncTaskId` is also accepted.

## Preflight

1. Select the target-org profile.
2. Change to the EDK org workspace that owns the promoted app and its source
   environment mappings. Do not run from the repository root or another org.
3. Confirm the workspace and profile identify the same Elementum org:

```bash
elementum --profile=<target-profile> auth status
```

Stop on any org, instance, environment, or app mismatch.

## Required Dry Run

Use the URL or raw identifier as one trigger value:

```bash
DEPLOYMENT_TRIGGER='<deployment-url-or-asyncTaskId>'

elementum --profile=<target-profile> deployments configure-url \
  "$DEPLOYMENT_TRIGGER" \
  --dry-run \
  --config-out deployment-config-dry-run.json
```

Review every resolved table/element, connection, data location, field mapping,
field count, and reported issue. The generated JSON is review evidence, not
permission to apply.

If any unresolved value is reported:

- Do not apply.
- Identify each affected dataset and field.
- Obtain the correct target connection or mapping from the user/service team.
- Update the generated configuration only with confirmed values.
- Dry-run the completed configuration before applying it:

```bash
elementum --profile=<target-profile> deployments configure \
  <deployment-id> \
  --config deployment-config-dry-run.json \
  --dry-run
```

## Apply

Only after the dry run is complete and has no unresolved values:

```bash
elementum --profile=<target-profile> deployments configure-url \
  "$DEPLOYMENT_TRIGGER" \
  --yes
```

For a manually completed configuration, use the reviewed file:

```bash
elementum --profile=<target-profile> deployments configure \
  <deployment-id> \
  --config deployment-config-dry-run.json
```

## Verify

The apply result must report success for every reviewed dataset and the
expected field count. Treat partial success as failure and report each failed
dataset without retrying blindly.

When a deployment ID is available, inspect its current status:

```bash
elementum --profile=<target-profile> deployments show <deployment-id> --json
```

The promotion task's `missingEnvironmentConfigurations` can be a snapshot, so
an immediate repeated URL dry run may still list already configured datasets.
Use the apply mutation results as the immediate source of truth, then confirm
the deployment progresses and has no new configuration error.

Report the target profile, app, trigger form (URL or `asyncTaskId`), datasets
reviewed, unresolved-value decision, apply results, verification status, and
any follow-up required. Do not print credentials or connection secrets.
