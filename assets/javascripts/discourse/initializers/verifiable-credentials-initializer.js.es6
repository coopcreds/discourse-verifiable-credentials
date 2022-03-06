import { withPluginApi } from "discourse/lib/plugin-api";
import { credentialBadges, headerGroups, mapResource } from "../lib/resources";
import { userPath } from "discourse/lib/url";
import bootbox from "bootbox";
import I18n from "I18n";

export default {
  name: "verifiable-credentials",
  initialize(container) {
    const messageBus = container.lookup("message-bus:main");
    const siteSettings = container.lookup("site-settings:main");
    const site = container.lookup("site:main");
    const currentUser = container.lookup("current-user:main");

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

      api.attachWidgetAction("header", "toggleVcPanelVisible", function () {
        this.state.vcPanelVisible = !this.state.vcPanelVisible;
        this.scheduleRerender();
      });

      const groups = headerGroups(siteSettings, site, currentUser);
      const badges = credentialBadges(siteSettings, site, currentUser);
      let resources = [
        ...mapResource(groups, "group"),
        ...mapResource(badges, "badge"),
      ];

      api.addHeaderPanel(
        "verifiable-credentials-header-panel",
        "vcPanelVisible",
        function () {
          return {
            resources,
            groups,
            badges,
          };
        }
      );

      if (siteSettings.verifiable_credentials_header && resources.length) {
        api.addToHeaderIcons("verifiable-credentials-header-button");
      }

      if (currentUser) {
        api.addQuickAccessProfileItem({
          icon: "passport",
          href: userPath(currentUser.username + "/credentials/records"),
          content: I18n.t("verifiable_credentials.user.label"),
        });
      }
    });
  },
};
