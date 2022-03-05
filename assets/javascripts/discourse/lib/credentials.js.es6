import { joinResources } from "../lib/resources";
import showModal from "discourse/lib/show-modal";

const encodeParams = (p) =>
  Object.entries(p)
    .map((kv) => kv.map(encodeURIComponent).join("="))
    .join("&");

function verify(user, resources, siteSettings) {
  const provider = siteSettings.verifiable_credentials_provider;
  if (!provider || !resources) {
    return;
  }

  const oidc = siteSettings.verifiable_credentials_oidc;
  const resourcesString = joinResources(resources);

  if (oidc) {
    let params = {
      resources: resourcesString,
      provider,
    };
    let url =
      window.location.protocol +
      "//" +
      window.location.hostname +
      ":" +
      window.location.port;
    let path =
      `/vc/presentation/${provider}/initiate?` + encodeParams(params);
    window.location.href = url + path;
  } else {
    const controller = showModal("verifiable-credentials-presentation", {
      model: {
        resources: resourcesString,
      },
    });
    controller.perform();
  }
}

export {
  verify
};
