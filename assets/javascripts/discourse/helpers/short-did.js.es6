import { registerUnbound } from "discourse-common/lib/helpers";

export default registerUnbound("short-did", function (did) {
  if (!did || did.length < 3) {
    return null;
  }
  return did.substring(0, 25) + "...";
});
