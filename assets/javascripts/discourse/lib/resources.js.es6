const listDelimiter = "|";
const claimDelimiter = ":";

function joinResources(resources) {
  return resources
    .map((resource) => {
      return `${resource.type}${claimDelimiter}${resource.id}`;
    })
    .join(listDelimiter);
}

export { joinResources };
