import Controller from "@ember/controller";
import discourseComputed from "discourse-common/utils/decorators";
import { camelize } from "@ember/string";
import { scheduleOnce } from "@ember/runloop";
import { alias } from "@ember/object/computed";
import { ajax } from "discourse/lib/ajax";
import I18n from "I18n";

export default Controller.extend({
  loadingQRCode: false,
  hasQRCode: true,
  message: alias('model.custom_fields.verifiable_credentials_message'),

  perform() {
    const provider = this.siteSettings.verifiable_credentials_provider;
    this[camelize(provider)]();
  },

  @discourseComputed
  description() {
    const provider = this.siteSettings.verifiable_credentials_provider;
    return I18n.t(`verifiable_credentials.present.provider.${provider}.description`);
  },

  mattr() {
    const group = this.model;
    const domain = this.siteSettings.verifiable_credentials_verifier_domain;

    this.set('loadingQRCode', true);

    ajax('/vc/presentation/mattr/create', {
      type: 'POST',
      data: {
        resource_type: 'group',
        resource_id: group.id,
        provider: 'mattr'
      }
    }).then(result => {
      this.set('loadingQRCode', false);

      if (result.success) {
        this.set('QRData', `didcomm://${domain}/?request=${result.jws}`);
      }
    });
  },

  verifiableCredentialsLtd() {
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
        "type": group.custom_fields.verifiable_credentials_credential_identifier
      },
      "returnResults": [
        {
          "internet": `${discourseUrl}/vc/verify/verifiable_credentials_ltd`
        }
      ]
    };

    const encodedRequest = btoa(JSON.stringify(data)).replace(/\+/g, '-').replace(/\//g, '_').replace(/\=+$/, '');
    this.set('QRData', encodedRequest);
  }
});
