export default function configureTestFilter(config, queryParams) {
  const mode = queryParams.get("discourseTestFilterMode");
  if (!["literal", "regex"].includes(mode)) {
    return;
  }

  const filter = queryParams.get("filter");
  if (filter === null) {
    return;
  }

  config.filter = undefined;

  if (mode === "literal") {
    const normalizedLiteral = filter.toLowerCase();
    config.testFilter = ({ module, testName }) =>
      `${module}: ${testName}`.toLowerCase().includes(normalizedLiteral);
  } else if (mode === "regex") {
    const regex = new RegExp(filter, "i");
    config.testFilter = ({ module, testName }) =>
      regex.test(`${module}: ${testName}`);
  }
}
