const listDelimiter = "|";
const claimDelimiter = ":";

function joinResources(resources) {
  return resources
    .map((resource) => {
      return `${resource.type}${claimDelimiter}${resource.id}`;
    })
    .join(listDelimiter);
}

function headerGroups(siteSettings, site, currentUser) {
  const headerGroups = siteSettings.verifiable_credentials_header_groups;
  const siteGroups = site.groups;
  const userGroups = currentUser.groups;
  const groupNames = headerGroups.split("|") || [];

  return siteGroups.filter((group) => {
    return (
      groupNames.includes(group.name) &&
        !userGroups.find((userGroup) => userGroup.id === group.id)
    );
  });
}

function credentialBadges(siteSettings, site, currentUser) {
  const siteCredBadges = site.credential_badges;
  const userCredBadges = currentUser.verifiable_credential_badges;
  const userCredBadgeIds = userCredBadges.map((badge) => badge.id);

  return siteCredBadges.filter((badge) => !userCredBadgeIds.includes(badge.id));
}

function mapResource(resources, type) {
  return resources.map((group) => ({ type, id: group.id }));
}

export {
  joinResources,
  headerGroups,
  credentialBadges,
  mapResource
};
