import { withPluginApi } from 'discourse/lib/plugin-api';
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import { alias, or } from '@ember/object/computed';
import { inject as service } from "@ember/service";
import discourseComputed, { on, observes } from "discourse-common/utils/decorators";

export default {
  name: 'verifiable-credentials',
  initialize() {
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
              this.set('loading', true);
              
              let protocol = window.location.protocol + "//";
              let holderUrl = protocol + "127.0.0.1:1880";
              let discourseUrl =  protocol + window.location.hostname + ":3000";
              let data = {
                "sp": discourseUrl,
                "vcVerifier": discourseUrl + "/vc-policy",
                "authnCreds": {},
                "policyMatch": {}
              };
                            
              ajax(`${holderUrl}/v1/RequestVP`, {
                type: 'POST',
                dataType: "json",
                contentType: "application/json",
                data: JSON.stringify(data)
              }).then(result => {                
                if (result.vpjwt) {
                  ajax('/vc/verify', {
                    type: 'POST',
                    data: {
                      presentation: result.vpjwt,
                      resource: 'group',
                      resource_id: this.model.id
                    }
                  }).then(result => {
                    if (result.success) {
                      let redirectUrl = this.model.custom_fields.verifiable_credentials_redirect;
                      
                      if (redirectUrl) {
                        window.location.href = redirectUrl;
                      } else {
                        this.router.transitionTo("group.index", this.model);
                      }
                    }
                  }).catch(popupAjaxError)
                    .finally(() => {
                      this.set('loading', false);
                    });
                }
              }).catch(error => {
                this.set('loading', false);
              });
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
      })
    });
  }
}