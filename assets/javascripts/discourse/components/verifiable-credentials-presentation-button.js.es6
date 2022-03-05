import Component from "@ember/component";
import { verify } from "../lib/credentials";

export default Component.extend({
  classNames: ["verifiable-credentials-presentation-button"],

  actions: {
    verifyCredentials() {
      verify(this.currentUser, this.resources, this.siteSettings);
    }
  }
});
