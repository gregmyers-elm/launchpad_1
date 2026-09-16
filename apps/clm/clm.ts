import { app } from "@elementumai/edk/app";
import { org } from "../../org.js";

const clm = app({
  name: "CLM",
  namespace: "clm",
  category: { name: "Common" },
  cloudLink: org.cloudLinks.elementumSnowflake,
  handle: "CLM",
  fields: {},
  systemFields: {
    status: {
      name: "Status",
      options: [
        { label: "Open", color: "#3B82F6" },
        { label: "In Progress", color: "#F59E0B" },
        { label: "Closed", color: "#10B981", tags: ["CLOSED"] },
      ],
    },
  },
});

export default clm;
