import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import DiscourseURL from "discourse/lib/url";
import I18n from "I18n";

export default Component.extend({
  classNameBindings: [
    ":resource-label",
    "resource.type",
    "resource.verified:verified",
  ],
  attributeBindings: ["title"],

  @discourseComputed("resource.type", "model.name", "resource.verified")
  title(type, name, verified) {
    const key = verified ? "verified" : "not_verified";
    return I18n.t(
      `verifiable_credentials.user.records.resources.${type}.${key}`,
      { name }
    );
  },

  @discourseComputed("resource.type")
  resourceIcon(type) {
    return {
      group: "users",
      badge: "certificate",
    }[type];
  },

  @discourseComputed("resource.verified")
  verifiedIcon(verified) {
    return verified ? "check" : "times";
  },

  @discourseComputed("resource.type", "resource.id")
  model(type, id) {
    if (type === "group") {
      const groups = this.site.groups;
      return groups.find((g) => g.id === id);
    }
    if (type === "badge") {
      const badges = this.currentUser.verifiable_credential_badges;
      return badges.find((b) => b.id === id);
    }
  },

  click() {
    const resource = this.resource;
    const model = this.model;
    let url = "#";
    if (resource.type === "group") {
      url = `/g/${model.name}`;
    }
    if (resource.type === "badge") {
      url = `/badges/${model.id}/${model.name}`;
    }
    DiscourseURL.routeTo(url);
  },
});
