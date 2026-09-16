# Agents and Skills

This reference covers Elementum agents, their tools, platform agentic skills,
and A2A skill descriptors. For coding-agent playbook installation, return to
the routing table in `SKILL.md` and load the workflow reference.

## Agent

Agents are app-owned. Place one at
`apps/<appRef>/agents/<agentRef>.ts` and use the public agents package:

```ts
import {
  agentCreateRecord,
  agentRunAgent,
  agentSearchRecords,
  agentSearchTable,
  agent,
} from "@elementumai/edk/agents";
import catalog from "@catalog";

export default agent({
  name: "Support Agent",
  app: catalog.support,
  connector: catalog.aiProviders.anthropic.models.claudeHaiku_4_5,
  description: "Finds and creates support tickets.",
  instructions:
    "Ask for missing details. Search before creating a duplicate ticket.",
  skillAccess: {
    mode: "CUSTOM",
    skills: [catalog.support.skills.ticketLookup],
    preloadedSkills: [catalog.support.skills.ticketLookup],
  },
  tools: [
    agentSearchRecords({
      name: "find_tickets",
      description: "Search support tickets.",
      app: catalog.support,
      queryDescription: "Describe the ticket to find.",
      fields: [
        {
          field: catalog.support.fields.status,
          name: "Status",
          description: "Current ticket status.",
        },
      ],
    }),
    agentSearchTable({
      name: "search_articles",
      description: "Search indexed knowledge-base articles.",
      element: catalog.knowledgeBase,
      table: catalog.knowledgeBase.searchTables.articleSearch,
      queryDescription: "Describe the article or answer to find.",
      fields: [
        {
          field: catalog.knowledgeBase.fields.title,
          name: "Title",
          description: "Article title returned by the search.",
        },
      ],
    }),
    agentCreateRecord({
      name: "create_ticket",
      description: "Create a support ticket.",
      app: catalog.support,
      fields: [
        {
          field: catalog.support.fields.summary,
          name: "Summary",
          description: "Short ticket summary.",
          required: true,
        },
      ],
    }),
    agentRunAgent({
      name: "ask_specialist",
      description: "Delegate a focused ticket question to the specialist.",
      agent: catalog.support.agents.specialist,
      workerTaskPrompt: "Resolve the ticket question and return a concise answer.",
    }),
  ],
});
```

Agent rules:

- `app` is the owning app ref.
- `connector` uses
  `catalog.aiProviders.<family>.models.<model>`. Refresh organization
  references if the desired model is absent.
- Give instructions explicit boundaries, confirmation gates, and expected tool
  selection behavior.
- Prefer narrow tools with names and descriptions that tell the model when to
  use them.
- Tool names use 1–64 letters, digits, or underscores, with no spaces,
  hyphens, or doubled underscores.
- Use catalog references for target apps, fields, automations, agents, search
  tables, and skills.
- `agentSearchTable` targets the element that owns the table. Its `fields`
  entries use fields from that same element; legacy pulled tools may use the
  mutually exclusive `returnFields` shape, which is typed the same way.
- Match product tool names. The delegation tool shown in the UI as Run Agent is
  `agentRunAgent`; Run Automation and MCP Tool likewise use their public EDK
  factories. Do not expose or author internal select-bot-route behavior.
- Preserve pulled authentication and execution-identity settings unless the
  user explicitly requests a security change.

Use the current factories exported by `@elementumai/edk/agents`. TypeScript
acceptance alone does not guarantee the workspace can build every factory;
stop on build diagnostics.

## Agent Evaluation

Agent evaluations are app-owned scoring rubrics used by agent scenarios. Place
one at `apps/<appRef>/evaluations/<evaluationRef>.ts`:

```ts
import { agentEvaluation } from "@elementumai/edk/app";
import catalog from "@catalog";

export default agentEvaluation({
  app: catalog.support,
  name: "Helpful response",
  prompt: "Score whether the response is accurate and helpful.",
  connector: catalog.aiProviders.anthropic.models.claudeHaiku_4_5,
  passingThreshold: 3,
});
```

Use an AI-service token from the pulled organization catalog, not a connector
UUID. `passingThreshold` may be any finite score from 0 through 4. The
evaluation must belong to an app; element-owned evaluations are rejected by
the public type system.

## Platform Agentic Skill

A platform agentic skill is an app-owned runtime capability bundle. Place one
at `apps/<appRef>/skills/<skillRef>.ts`:

```ts
import {
  skill,
  serviceAccountRef,
  skillCreateRecord,
  skillRunAgent,
  skillSearchRecords,
} from "@elementumai/edk/agents/skills";
import catalog from "@catalog";

const runner = serviceAccountRef({
  app: catalog.support,
  name: "Support Runner",
});

export default skill({
  name: "ticket-lookup",
  app: catalog.support,
  description: "Find support tickets and log a new ticket when needed.",
  instructions: `Search first. Create only after the user confirms the ticket is new.

## Input Schema

- summary (required): Short ticket summary.
- status: Current ticket status.

## Lookup Notes

- No lookup tools are required.`,
  status: "ACTIVE",
  tools: [
    skillSearchRecords({
      name: "find_tickets",
      description: "Search support tickets.",
      app: catalog.support,
      queryDescription: "Describe the ticket to find.",
      fields: [
        {
          field: catalog.support.fields.status,
          name: "Status",
          description: "Current ticket status.",
        },
      ],
    }),
    skillCreateRecord({
      name: "create_ticket",
      description: "Create a confirmed support ticket.",
      app: catalog.support,
      fields: [
        {
          field: catalog.support.fields.summary,
          name: "Summary",
          description: "Short ticket summary.",
          required: true,
        },
      ],
    }),
    skillRunAgent({
      name: "ask_specialist",
      description: "Delegate a focused ticket question to the specialist.",
      agent: catalog.support.agents.specialist,
      workerTaskPrompt: "Resolve the ticket question and return a concise answer.",
      runAs: { serviceAccount: runner },
    }),
  ],
});
```

Platform agentic skill rules:

- `name` is a lowercase identifier of 1–64 letters, digits, and hyphens.
- `app` is the owning app ref; the filename supplies the skill ref.
- Tool names follow the stricter underscore-only agent-tool rule.
- Write a concise description for discovery and procedural instructions for
  execution.
- Keep the machine-audited `## Input Schema` section in `instructions`, with
  one `- variable_name: description` row per form variable. Under
  `## Lookup Notes`, map lookup-backed fields as
  `- variable_name: tool_name (source)`. `elementum new skill`, pull, and build
  report every variable's matching tool field/input on stderr and in JSON
  `reports`; missing fields, missing or unbound lookup tools, and leftover
  tools are warnings in stderr and JSON `diagnostics`.
- Keep tools cohesive. Split unrelated capabilities into separate skills.
- Use `skillAccess` on an agent to expose or preload skills. A preloaded skill
  must also be available under the selected access mode.
- Service accounts do not have email addresses. Reference one by name within
  its owning app with `serviceAccountRef`, then pass that typed ref in `runAs`.
  Do not use a raw service-account ID or a service account owned by another app.

## A2A Skill

An A2A skill is metadata describing what an agent offers to other agents:

```ts
a2aSkills: [
  {
    name: "support-ticket-triage",
    description: "Finds or creates a support ticket from a concise request.",
    tags: ["support", "triage"],
    examples: ["Find the ticket about a failed invoice upload."],
    inputModes: ["text/plain"],
    outputModes: ["text/plain"],
  },
],
```

Do not put runtime tools or long procedural instructions in an A2A descriptor.
The implementation remains in the agent's tools or platform agentic skills.
Treat a build diagnostic for A2A settings as a blocker and report it.

## Coding-Agent Playbook

A coding-agent playbook such as `/elementum` lives in an Agent Skills
directory and guides a coding assistant. It is not deployed as part of an app,
cannot be placed in `skillAccess`, and must not be authored with `skill`.
