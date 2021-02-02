import { withPluginApi } from 'discourse/lib/plugin-api';
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';

export default {
  name: 'verifiable-credentials',
  initialize() {
    withPluginApi('0.8.30', api => {
      api.modifyClass('component:group-membership-button', {
        canVerifyCredentials: true,
        
        actions: {
          verifyCredentials() {
            if (this.currentUser) {
              this.set('loading', true);
              // Request VP from VC Holder (i.e. user's wallet)
              let protocol = window.location.protocol + "//";
              let holderUrl = protocol + "127.0.0.1:1880";
              let discourseUrl =  protocol + window.location.hostname + ":3000";
              let data = {
                "sp": discourseUrl,
                "vcVerifier": discourseUrl + "/vc-policy",
                "authnCreds": {},
                "policyMatch": {}
              };
              
              console.log(data)
              
              ajax(`${holderUrl}/v1/RequestVP`, {
                type: 'POST',
                dataType: "json",
                contentType: "application/json",
                data: JSON.stringify(data)
              }).then(result => {
                
                console.log("RequestVP result: ", result);
                
                if (result.vpjwt) {
                  ajax('/vc/verify', {
                    type: 'POST',
                    data: {
                      presentation: result.vpjwt,
                      resource: 'group',
                      resource_id: this.model.id
                    }
                  }).then(result => {
                    console.log('verify result: ', result);
                    this.set('loading', false);
                  }).catch(popupAjaxError);
                }
              }).catch(error => {
                console.log(error);
              });
            } else {
              this._showLoginModal();
            }
          }
        }
      })
    });
  }
}