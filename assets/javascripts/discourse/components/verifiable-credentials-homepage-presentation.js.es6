import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";

export default Component.extend({
  classNames: ["verifiable-credentials-homepage-presentation"],

  @discourseComputed(
    "siteSettings.verifiable_credentials_homepage_groups",
    "site.groups",
    "currentUser.groups"
  )
  groups(homeGroups, siteGroups, userGroups) {
    const groupNames = homeGroups.split("|") || [];
    return siteGroups.filter((g) => {
      return (
        groupNames.includes(g.name) && !userGroups.find((ug) => ug.id === g.id)
      );
    });
  },

  @discourseComputed(
    "site.credential_badges",
    "currentUser.verifiable_credential_badges"
  )
  badges(siteCredBadges, userCredBadges) {
    const userCredBadgeIds = userCredBadges.map((b) => b.id);
    return siteCredBadges.filter((b) => !userCredBadgeIds.includes(b.id));
  },

  mapResource(resources, type) {
    return resources.map((g) => ({ type, id: g.id }));
  },

  @discourseComputed(
    "groups",
    "badges",
    "siteSettings.verifiable_credentials_homepage_include_badges"
  )
  resources(groups, badges, includebadges) {
    let resources = this.mapResource(groups, "group");

    if (includebadges) {
      resources = [...resources, ...this.mapResource(badges, "badge")];
    }

    return resources;
  },

  @discourseComputed("resources.[]", "groups", "badges")
  resourceDescriptions(resources, groups, badges) {
    const resourceIcons = {
      badge: "certificate",
      group: "users",
    };

    return resources.map((r) => {
      let textAttrs = {};
      if (r.type === "group") {
        textAttrs.group_name = groups.find((g) => g.id === r.id).name;
      }
      if (r.type === "badge") {
        textAttrs.badge_name = badges.find((b) => b.id === r.id).name;
      }
      return {
        icon: resourceIcons[r.type],
        text: I18n.t(`verifiable_credentials.homepage.${r.type}`, textAttrs),
      };
    });
  },

  @discourseComputed(
    "siteSettings.verifiable_credentials_homepage",
    "currentPath",
    "resources.[]"
  )
  showModal(enabled, currentPath, resources) {
    return enabled && currentPath.includes("discovery") && resources.length;
  },
});
