import { withPluginApi } from 'discourse/lib/plugin-api';
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import { alias, or } from '@ember/object/computed';
import { inject as service } from "@ember/service";
import discourseComputed, { on, observes } from "discourse-common/utils/decorators";
import showModal from "discourse/lib/show-modal";

export default {
  name: 'verifiable-credentials',
  initialize(container) {
    const messageBus = container.lookup("message-bus:main");

    messageBus.subscribe("/vc/verified", function (redirectUrl) {
      window.location.href = redirectUrl;
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
              const controller = showModal("vc-present", {
                model: this.model 
              });
              controller.perform();
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
    });
  }
}