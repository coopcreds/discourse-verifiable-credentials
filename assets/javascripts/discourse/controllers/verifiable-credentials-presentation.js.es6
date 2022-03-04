import Controller from "@ember/controller";
import discourseComputed from "discourse-common/utils/decorators";
import { camelize } from "@ember/string";
import { ajax } from "discourse/lib/ajax";
import I18n from "I18n";

export default Controller.extend({
  loadingQRCode: false,
  hasQRCode: true,

  perform() {
    const provider = this.siteSettings.verifiable_credentials_provider;
    this[camelize(provider)]();
  },

  @discourseComputed("siteSettings.verifiable_credentials_provider")
  description(provider) {
    return I18n.t(
      `verifiable_credentials.present.provider.${provider}.description`
    );
  },

  mattr() {
    this.set("loadingQRCode", true);

    ajax("/vc/presentation/mattr/create", {
      type: "POST",
      data: {
        resources: this.model.resources,
        provider: "mattr",
      },
    }).then((result) => {
      this.set("loadingQRCode", false);

      if (result.success) {
        const domain = this.siteSettings.verifiable_credentials_verifier_domain;
        this.set("QRData", `didcomm://${domain}/?request=${result.jws}`);
      }
    });
  },

  verifiableCredentialsLtd() {
    const user = this.currentUser;
    const discourseUrl =
      window.location.protocol + "//" + window.location.hostname;
    const domain = this.siteSettings.verifiable_credentials_verifier_domain;
    const data = {
      sp: discourseUrl,
      vcVerifier: domain,
      authnCreds: {
        user_id: user.id,
        resources: this.model.resources,
      },
      policyMatch: {
        type: this.credentialId,
      },
      returnResults: [
        {
          internet: `${discourseUrl}/vc/verify/verifiable_credentials_ltd`,
        },
      ],
    };

    const encodedRequest = btoa(JSON.stringify(data))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/\=+$/, "");
    this.set("QRData", encodedRequest);
  },
});
