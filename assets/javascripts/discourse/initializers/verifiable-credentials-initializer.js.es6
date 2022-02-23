import { withPluginApi } from 'discourse/lib/plugin-api';
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import { alias, or } from '@ember/object/computed';
import { inject as service } from "@ember/service";
import discourseComputed, { on, observes } from "discourse-common/utils/decorators";
import showModal from "discourse/lib/show-modal";
import bootbox from "bootbox";

export default {
  name: 'verifiable-credentials',
  initialize(container) {
    const messageBus = container.lookup("message-bus:main");
    const encodeParams = p => Object.entries(p).map(kv => kv.map(encodeURIComponent).join("=")).join("&");

    messageBus.subscribe("/vc/verified", function (redirectUrl) {
      window.location.href = redirectUrl;
    });

    messageBus.subscribe("/vc/failed-to-verify", function (params) {
      if (params.resource_type === 'group') {
        window.location.href = `/g/${params.resource_name}?failed_to_verify=true`;
      }
    });

    withPluginApi('0.8.30', api => {
      api.modifyClass('component:group-membership-button', {
        router: service(),
        canJoin: or('canAccessByVerifiedCredentials', 'canRequestMembership'),

        @discourseComputed('model.custom_fields.allow_membership_by_verifiable_credentials', 'userIsGroupUser')
        canAccessByVerifiedCredentials(membershipByVC, userIsGroupUser) {
          return membershipByVC && !userIsGroupUser;
        },

        actions: {
          verifyCredentials() {
            if (this.currentUser) {
              const provider = this.siteSettings.verifiable_credentials_provider;
              const oidc = this.siteSettings[`verifiable_credentials_${provider}_oidc`];

              if (oidc) {
                let params = {
                  resource_type: 'group',
                  resource_id: this.model.id,
                  provider
                }
                let url =  window.location.protocol + "//" + window.location.hostname + ":" + window.location.port;
                let path = `/vc/presentation/${provider}/initiate?` + encodeParams(params);
                window.location.href = url + path;
              } else {
                const controller = showModal("vc-present", {
                  model: this.model
                });
                controller.perform();
              }
            } else {
              this._showLoginModal();
            }
          }
        }
      });

      api.modifyClass('component:groups-form-membership-fields', {
        disableMembershipByVerifiableCredentials: alias('disableMembershipRequestSetting')
      });

      api.modifyClass('model:group', {
        custom_fields: {},

        asJSON() {
          return Object.assign(this._super(...arguments), {
            custom_fields: this.custom_fields
          });
        }
      });

      api.modifyClass('route:group', {
        activate() {
          const params = new Proxy(new URLSearchParams(window.location.search), {
            get: (searchParams, prop) => searchParams.get(prop),
          });

          if (params.failed_to_verify === 'true') {
            bootbox.alert(I18n.t("verifiable_credentials.present.failed"));
            window.history.replaceState(null, null, window.location.pathname);
          }
        }
      })
    });
  }
}
