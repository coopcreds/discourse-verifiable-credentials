import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";

const UserCredential = EmberObject.extend();

UserCredential.reopenClass({
  findAll() {
    return ajax("/vc/user/records.json");
  },
});

export default UserCredential;
