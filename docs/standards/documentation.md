# Documentation standard

## The two-audience rule

Every consumer repository carries:

- a business **README**: what the product does, for whom, how to run it,
  written for a reader who will never open the source;
- a **TECHNICAL.md**: architecture, key decisions and their reasons,
  operations notes, written for the engineer inheriting the project.

If a sentence serves both audiences, it belongs in both files.

## Currency

- Docs change with the code that changes the behavior, in the same pull
  request. "I'll document it later" is a defect.
- Every borrowed external fact (model name, harness path, vendor behavior)
  carries a `Last verified: YYYY-MM` line. Touch the file, refresh the date
  or flag the drift.
- Diagrams live in `docs/assets/` as source (SVG preferred) and are linked,
  never screenshot-copied.

## Style

- Plain declarative sentences. If a paragraph needs a second read, shorten it.
- One term per concept; link the [glossary](../../GLOSSARY.md) rather than
  redefining.
- Small tables over dense prose for enumerable facts; prose for reasoning.
- No filler adjectives. The docs do not need to sound excited.

## In this hub

- Guidance lives in `docs/`, once. Adapters point; they do not summarize.
- Each shelf README states its own contract in the first ten lines.
- Deleting an obsolete doc is a contribution. Redirect or remove its inbound
  links in the same PR.
