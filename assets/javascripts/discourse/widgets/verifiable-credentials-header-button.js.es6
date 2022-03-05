import { createWidget } from "discourse/widgets/widget";
import { iconNode } from "discourse-common/lib/icon-library";
import { userPath } from "discourse/lib/url";
import { h } from "virtual-dom";
import { wantsNewWindow } from "discourse/lib/intercept-click";
import I18n from "I18n";

export default createWidget("verifiable-credentials-header-button", {
  tagName: "li.header-dropdown-toggle.verifiable-credentials-header-button",

  html(attrs) {
    const headerWidget = this.headerWidget();
    return h(
      "a.icon",
      {
        attributes: {
          "aria-haspopup": true,
          "aria-expanded": headerWidget.state.vcPanelVisible,
          href: userPath(this.currentUser.username + "/credentials/records"),
          title: I18n.t("verifiable_credentials.header.button.title"),
          "data-auto-route": true,
        },
      }, [
        iconNode('passport')
      ]
    );
  },

  buildClasses(attrs) {
    const headerWidget = this.headerWidget();
    let classes = [];
    if (headerWidget.state.vcPanelVisible) {
      classes.push("active");
    }
    return classes;
  },

  click(e) {
    if (wantsNewWindow(e)) {
      return;
    }
    e.preventDefault();
    if (!this.attrs.active) {
      this.sendWidgetAction("toggleVcPanelVisible");
    }
  },

  headerWidget() {
    return this.parentWidget.parentWidget;
  }
});
