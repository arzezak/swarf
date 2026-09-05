# Domain language

Terms used in swarf's code, tests and commit messages. The README splits swarf
into two halves that never talk to each other: the **probe**, which records
coverage from inside your test process, and the **runner**, which scores. The
terms below name the parts of the runner.

## Scan

One pass over a set of paths, joining parsed complexity to recorded coverage to
produce scores.

A scan owns no I/O policy — it is given its paths, its ignore patterns, its
store and its root — and no formatting beyond naming each method's `file:line`.
Scan is the part of the runner that produces scores; `CLI` and `Report` are the
rest of it.
