import Component from "@ember/component";

export default Component.extend({
  inputDelimiter: "|",

  actions: {
    onChange(claims) {
      this.set("claims", claims.join(this.inputDelimiter));
    },
  },
});
