import { withPluginApi } from "discourse/lib/plugin-api";
import bootbox from "bootbox";
import I18n from "I18n";

export default {
  name: "verifiable-credentials",
  initialize(container) {
    const messageBus = container.lookup("message-bus:main");

    messageBus.subscribe("/vc/verification-complete", function (redirectUrl) {
      const href = redirectUrl ? redirectUrl : "/";
      window.location.href = href;
    });

    withPluginApi("0.8.30", (api) => {
      api.modifyClass("model:group", {
        pluginId: ["verifialbe-credentials"],
        custom_fields: {},

        asJSON() {
          return Object.assign(this._super(...arguments), {
            custom_fields: this.custom_fields,
          });
        },
      });

      api.modifyClass("route:group", {
        pluginId: ["verifialbe-credentials"],

        activate() {
          const params = new Proxy(
            new URLSearchParams(window.location.search),
            {
              get: (searchParams, prop) => searchParams.get(prop),
            }
          );

          if (params.failed_to_verify === "true") {
            bootbox.alert(I18n.t("verifiable_credentials.present.failed"));
            window.history.replaceState(null, null, window.location.pathname);
          }
        },
      });
    });
  },
};
