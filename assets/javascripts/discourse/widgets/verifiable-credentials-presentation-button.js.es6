import { createWidget } from "discourse/widgets/widget";
import { verify } from "../lib/credentials";

export default createWidget("verifiable-credentials-presentation-button", {
  tagName: "div.verifiable-credentials-presentation-button",

  html() {
    return this.attach("button", {
      action: "verifyCredentials",
      className: "verify-request btn-primary",
      icon: "passport",
      label: "verifiable_credentials.button.label",
    });
  },

  verifyCredentials() {
    verify(this.currentUser, this.attrs.resources, this.siteSettings);
  },
});
