import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";

export default Component.extend({
  @discourseComputed(
    "group.custom_fields.verifiable_credentials_allow_membership",
    "group.is_group_user"
  )
  canAccess(membershipByVC, userIsGroupUser) {
    return membershipByVC && !userIsGroupUser;
  },

  @discourseComputed(
    "canAccess",
    "group.custom_fields.verifiable_credentials_show_button"
  )
  showButton(canAccess, showButton) {
    return canAccess && showButton;
  },

  @discourseComputed("group.custom_fields.verifiable_credentials_include_tags")
  resources(includeTags) {
    let resources = [
      {
        type: "group",
        id: this.group.id,
      },
    ];

    const badgeIds = this.site.credential_badges.map((b) => b.id);
    if (includeTags && badgeIds) {
      resources = resources.concat(
        badgeIds.map((id) => ({ type: "badge", id }))
      );
    }

    return resources;
  },
});
