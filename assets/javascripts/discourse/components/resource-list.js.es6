import Component from "@ember/component";
import { equal } from "@ember/object/computed";
import { createPopper } from "@popperjs/core";
import { scheduleOnce } from "@ember/runloop";
import discourseComputed from "discourse-common/utils/decorators";

export default Component.extend({
  classNames: ["resource-list"],
  attributeBindings: ["record.resource.did:data-did"],
  showResources: false,
  single: equal("record.resources.length", 1),

  @discourseComputed("record.resources")
  resource(resources) {
    return resources.length ? resources[0] : null;
  },

  didInsertElement() {
    $(document).on("click", (event) => this.documentClick(event));
  },

  willDestroyElement() {
    $(document).off("click", (event) => this.documentClick(event));
  },

  documentClick(event) {
    if (this._state === "destroying") {
      return;
    }

    if (
      !event.target.closest(
        `tr[data-created-at="${this.record.created_at}"] .resource-list button`
      )
    ) {
      this.set("showResources", false);
      this._popper = null;
    }
  },

  createModal() {
    let container = this.element.querySelector(".list-container");
    let modal = this.element.querySelector(".list");

    this._popper = createPopper(container, modal, {
      strategy: "absolute",
      placement: "bottom-start",
      modifiers: [
        {
          name: "preventOverflow",
        },
        {
          name: "offset",
          options: {
            offset: [0, 5],
          },
        },
      ],
    });
  },

  actions: {
    showResources() {
      this.toggleProperty("showResources");

      if (this.showResources) {
        scheduleOnce("afterRender", this, this.createModal);
      }
    },
  },
});
