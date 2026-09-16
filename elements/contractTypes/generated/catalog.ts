import contractTypesOwn from "../contractTypes.js";
import { elementCatalog } from "@elementumai/edk/catalog";

const __own = contractTypesOwn.ref("contractTypes");

export const contractTypes = elementCatalog(
  { refName: __own.refName, name: __own.name, ...(__own.namespace !== undefined ? { namespace: __own.namespace } : {}) },
  {
    fields: __own.fields,
  },
);
