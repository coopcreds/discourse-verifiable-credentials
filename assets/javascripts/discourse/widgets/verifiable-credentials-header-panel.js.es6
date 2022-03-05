import { createWidget } from "discourse/widgets/widget";
import { h } from "virtual-dom";
import { iconNode } from "discourse-common/lib/icon-library";
import DiscourseURL, { userPath } from "discourse/lib/url";
import I18n from "I18n";

export default createWidget("verifiable-credentials-header-panel", {
  tagName: "div.verifiable-credentials-header-panel",

  html() {
    return this.attach("menu-panel", {
      maxWidth: 300,
      contents: () => this.panelContents(),
    });
  },

  panelContents() {
    const resourceDescriptions = this.resourceDescriptions();
    const resources = this.attrs.resources;

    return h(
      'div.verifiable-credentials-header-panel-contents', [
        this.attach('verifiable-credentials-presentation-button', { resources }),
        h('ul',
          resourceDescriptions.map(description => {
            return h('li', [
              iconNode(description.icon),
              h('span', description.text)
            ]);
          })
        ),
        h('hr'),
        h('div.footer-links', this.footerLinks())
      ]
    );
  },

  footerLinks() {
    let links = [
      this.attach('link', {
        icon: 'user',
        label: 'verifiable_credentials.header.yours',
        actionParam: userPath(this.currentUser.username + "/credentials/records"),
        action: "goToLink",
      })
    ];

    const infoUrl = this.siteSettings.verifiable_credentials_header_info_url;
    if (infoUrl) {
      links.push(
        this.attach('link', {
          icon: 'info-circle',
          label: 'verifiable_credentials.header.info',
          actionParam: infoUrl,
          action: "goToLink"
        })
      );
    }

    return links;
  },

  resourceDescriptions() {
    const resources = this.attrs.resources;
    const groups = this.attrs.groups;
    const badges = this.attrs.badges;
    const resourceIcons = {
      badge: "certificate",
      group: "users",
    };

    return resources.map((resource) => {
      let textAttrs = {};
      if (resource.type === "group") {
        textAttrs.group_name = groups.find((group) => group.id === resource.id).name;
      }
      if (resource.type === "badge") {
        textAttrs.badge_name = badges.find((badge) => badge.id === resource.id).name;
      }
      return {
        icon: resourceIcons[resource.type],
        text: I18n.t(`verifiable_credentials.header.resource.${resource.type}.description`, textAttrs),
      };
    });
  },

  mouseDownOutside() {
    this.sendWidgetAction("toggleVcPanelVisible");
  },

  goToLink(url) {
    DiscourseURL.routeTo(url);
    this.sendWidgetAction("toggleVcPanelVisible");
  }
});
