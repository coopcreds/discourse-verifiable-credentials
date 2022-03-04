import Component from "@ember/component";
import showModal from "discourse/lib/show-modal";
import { joinResources } from "../lib/resources";

const encodeParams = (p) =>
  Object.entries(p)
    .map((kv) => kv.map(encodeURIComponent).join("="))
    .join("&");

export default Component.extend({
  classNames: ["credential-presentation-button"],

  actions: {
    verifyCredentials() {
      if (this.currentUser) {
        const provider = this.siteSettings.verifiable_credentials_provider;
        const resources = this.resources;

        if (!provider || !resources) {
          return;
        }

        const oidc = this.siteSettings.verifiable_credentials_oidc;
        const resourcesString = joinResources(resources);

        if (oidc) {
          let params = {
            resources: resourcesString,
            provider,
          };
          let url =
            window.location.protocol +
            "//" +
            window.location.hostname +
            ":" +
            window.location.port;
          let path =
            `/vc/presentation/${provider}/initiate?` + encodeParams(params);
          window.location.href = url + path;
        } else {
          const controller = showModal("verifiable-credentials-presentation", {
            model: {
              resources: resourcesString,
            },
          });
          controller.perform();
        }
      } else {
        this._showLoginModal();
      }
    },
  },
});
