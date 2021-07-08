import Controller from "@ember/controller";
import discourseComputed from "discourse-common/utils/decorators";
import { camelize } from "@ember/string";
import { scheduleOnce } from "@ember/runloop";
import { alias } from "@ember/object/computed";

export default Controller.extend({
  hasQRCode: true,
  message: alias('model.custom_fields.verifiable_credentials_message'),

  perform() {
    const provider = this.siteSettings.verifiable_credentials_provider;
    const result = this[camelize(provider)]();

    scheduleOnce('afterRender', () => {
      new QRCode(document.getElementById("qr-code"), result);
    });
  },

  @discourseComputed
  description() {
    const provider = this.siteSettings.verifiable_credentials_provider;
    return I18n.t(`verifiable_credentials.present.provider.${provider}.description`);
  },

  verifiableCredentialsLtd() {
    const group = this.model;
    const user = this.currentUser;
    const discourseUrl =  window.location.protocol + "//" + window.location.hostname;
    const data = {
      "sp": discourseUrl,
      "vcVerifier": "https://verifier.vc.resonate.is",
      "authnCreds": {
        "user_id": user.id,
        "resource_id": group.id,
        "resource_type": "group"
      },
      "policyMatch": {
        "type": group.custom_fields.verifiable_credentials_credential
      },
      "returnResults": [
        {
          "internet": `${discourseUrl}/vc/verify`
        }
      ]
    };

    const encodedRequest = btoa(JSON.stringify(data)).replace(/\+/g, '-').replace(/\//g, '_').replace(/\=+$/, '');
    return `vcwallet://getvp?request=${encodedRequest}`;
  }
});