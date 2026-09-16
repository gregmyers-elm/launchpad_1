import { org } from "../org.js";
import { usersCatalog } from "@elementumai/edk/catalog";

declare const require: (id: string) => unknown;

const catalog = {
  get clm() { return (require("../apps/clm/generated/catalog.js") as typeof import("../apps/clm/generated/catalog.js")).clm; },
  get contractTypes() { return (require("../elements/contractTypes/generated/catalog.js") as typeof import("../elements/contractTypes/generated/catalog.js")).contractTypes; },
  users: usersCatalog,
  aiProviders: org.aiProviders,
  cloudLinks: org.cloudLinks,
  categories: org.categories,
  groups: org.groups,
  phoneProviders: org.phoneProviders,
};

export { org };
export type Ref = typeof catalog;
export default catalog;
