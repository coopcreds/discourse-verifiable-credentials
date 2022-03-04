import Route from "@ember/routing/route";
import UserCredential from "../models/user-credential";

export default Route.extend({
  model() {
    return UserCredential.findAll();
  },

  setupController(controller, model) {
    const hasErrors = model.some((record) => record.error);
    controller.setProperties({
      hasErrors,
      model,
    });
  },
});
