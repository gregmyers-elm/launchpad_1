import clmOwn from "../clm.js";
import { appCatalog } from "@elementumai/edk/catalog";

const __own = clmOwn.ref("clm");

export const clm = appCatalog(
  { refName: __own.refName, name: __own.name, ...(__own.namespace !== undefined ? { namespace: __own.namespace } : {}) },
  {
    fields: __own.fields,
  },
);
