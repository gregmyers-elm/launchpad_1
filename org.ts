// Org reference identities from `elementum pull org --data-only` — refresh by re-running it.
// Each key IS the identity's terraform label in camelCase: tfLabel = tsLabelToTfLabel(key)
// (the lossless bijection in src/tf/labels.ts — the stable naming contract).
import { aiProvider, categoryRef, cloudLinkRef, connectorRef, groupRef, orgCatalog } from "@elementumai/edk/catalog";

export const org = orgCatalog({
  aiProviders: {
    demoDoNotUseElementumGemini: aiProvider({ name: "DEMO: DO NOT USE - Elementum Gemini", type: "gemini", models: {
      gemini_1_5Pro: connectorRef({ name: "Gemini 1.5 Pro" }),
      gemini_2_5Flash: connectorRef({ name: "Gemini 2.5 Flash" }),
      gemini_2_5Pro: connectorRef({ name: "Gemini 2.5 Pro" }),
    } }),
    demoDoNotUseElementumOpenai: aiProvider({ name: "DEMO: DO NOT USE - Elementum OpenAI", type: "openai", models: {
      chatGpt_4OmniMini: connectorRef({ name: "ChatGPT 4 Omni Mini" }),
      chatGpt_5: connectorRef({ name: "ChatGPT 5" }),
      chatGpt_5_1: connectorRef({ name: "ChatGPT 5.1" }),
      chatGpt_5Mini: connectorRef({ name: "ChatGPT 5 Mini" }),
      openaiO1Mini: connectorRef({ name: "OpenAI o1-mini" }),
    } }),
    snowflake: aiProvider({ name: "Snowflake", type: "snowflake", models: {
      claudeOpus_4_6: connectorRef({ name: "Claude Opus 4.6" }),
      claudeOpus_4_7: connectorRef({ name: "Claude Opus 4.7" }),
      claudeOpus_4_8: connectorRef({ name: "Claude Opus 4.8" }),
      claudeSonnet_4_5: connectorRef({ name: "Claude Sonnet 4.5" }),
      claudeSonnet_4_6: connectorRef({ name: "Claude Sonnet 4.6" }),
      gpt_5: connectorRef({ name: "GPT 5" }),
      gpt_5Mini: connectorRef({ name: "GPT 5 Mini" }),
      snowflakeArcticLV2_0: connectorRef({ name: "Snowflake Arctic L V2.0" }),
    } }),
  },
  cloudLinks: {
    apacPartial: cloudLinkRef({ name: "APAC Partial" }),
    elementumSnowflake: cloudLinkRef({ name: "Elementum Snowflake" }),
    flightsApi: cloudLinkRef({ name: " Flights API" }),
  },
  categories: {
    common: categoryRef({ name: "Common" }),
    customerSupport: categoryRef({ name: " Customer Support " }),
    edkPlayground: categoryRef({ name: "EDK Playground" }),
    humanResources: categoryRef({ name: "Human Resources" }),
    itsm: categoryRef({ name: "ITSM" }),
    medical: categoryRef({ name: "Medical" }),
    operations: categoryRef({ name: "Operations" }),
    retail: categoryRef({ name: "Retail" }),
    technology: categoryRef({ name: "Technology" }),
  },
  groups: {
    allUsers: groupRef({ name: "All Users" }),
    billing: groupRef({ name: "Billing" }),
    dpBillingTeam: groupRef({ name: "DP Billing Team" }),
    dpBillingTeam_1: groupRef({ name: "DP Billing Team" }),
    elementumAdmins: groupRef({ name: "Elementum Admins" }),
    externalUsers: groupRef({ name: "External Users" }),
    hardware: groupRef({ name: "Hardware" }),
    internalUsers: groupRef({ name: "Internal Users" }),
    it: groupRef({ name: "IT" }),
    rbTestGroup_2: groupRef({ name: "RB Test Group 2" }),
    robertTest: groupRef({ name: "Robert Test" }),
    rtbTest: groupRef({ name: "RTB Test" }),
    rtbTestGroup_4: groupRef({ name: "RTB Test Group 4" }),
    sarahTest: groupRef({ name: "Sarah Test" }),
    software: groupRef({ name: "Software" }),
    tcsGroup: groupRef({ name: "TCS_GROUP" }),
    tcsItSupport: groupRef({ name: "TCS_IT_SUPPORT" }),
    tcsSupportGroup: groupRef({ name: "TCS Support Group" }),
    test: groupRef({ name: "test" }),
    test_1: groupRef({ name: "test" }),
    testGroup: groupRef({ name: "test group" }),
    testGroup_2: groupRef({ name: "test group 2" }),
    testGroup_3: groupRef({ name: "Test Group 3" }),
    training: groupRef({ name: "Training" }),
  },
});
