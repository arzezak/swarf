# Domain language

Terms used in swarf's code, tests and commit messages. The README splits swarf into a **probe** and a **runner**. The terms below name the parts of the runner.

## Scan

One pass over a set of paths, joining parsed complexity to recorded coverage to produce scores.

A scan owns no I/O policy — it is given its paths, its ignore patterns, its store and its root — and no formatting beyond naming each method's `file:line`. Scan is the part of the runner that produces scores; `CLI` and `Report` are the rest of it.

## Measurement

What test runs recorded about one file: line hits, branch outcomes, method call counts, and the SHA-256 of the bytes those numbers were measured against.

A measurement knows whether it still describes the file on disk. It answers that question the first time it is asked and remembers the answer — asked before the source is read, it would report bytes the scan never saw, which is the confidently-wrong staleness the SHA-256 check exists to prevent.
