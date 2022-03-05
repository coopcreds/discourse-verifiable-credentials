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

  @discourseComputed
  resources() {
    let resources = [
      {
        type: "group",
        id: this.group.id,
      },
    ];
    return resources;
  },
});
