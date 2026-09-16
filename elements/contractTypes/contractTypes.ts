import { element, picklistField, textField } from "@elementumai/edk/elements";
import { org } from "../../org.js";

const contractTypes = element({
  name: "Contract Types",
  namespace: "contracttypes",
  category: { name: "Common" },
  cloudLink: org.cloudLinks.elementumSnowflake,
  handle: "CONTYP",
  fields: {
    contractTypeCode: textField({ name: "Contract Type Code" }),
    contractSideFamily: picklistField({
      name: "Contract Side / Family",
      options: ["Buy-side", "Sell-side", "Confidentiality", "Partnership", "Others"],
    }),
    definition: textField({ name: "Definition" }),
  },
});

export default contractTypes;
