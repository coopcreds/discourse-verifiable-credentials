export default {
  resource: "user",
  path: "users/:username",
  map() {
    this.route("credentials", function () {
      this.route("records");
    });
  },
};
