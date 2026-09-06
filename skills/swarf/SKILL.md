---
name: swarf
description: Score Ruby methods by complexity against test coverage with swarf, and turn the worst rows into the next test to write. Use after writing or changing Ruby code and before calling a change done.
---

# swarf

swarf scores every Ruby method with `CRAP = CC² · (1 − coverage)³ + CC` and lists them worst first. Complexity is parsed from source. Coverage is recorded by a probe loaded into the test run and stored in `.swarf/coverage.json`, so scoring works without setup but coverage needs a test run.

## The loop

1. Run the suite with the probe loaded (see Setup if unsure):

   ```
   bundle exec rspec          # or: bundle exec rake test
   ```

2. Score the files you touched, not the whole project:

   ```
   git diff --name-only --diff-filter=d main -- '*.rb' | xargs bundle exec swarf
   ```

   Named paths are always scored, even under `test/`, `db/` or a `.swarfignore` pattern.

3. Take the top rows and act on the Evidence column (next section). Write or extend the test, re-run the suite, score again.

4. Stop when the touched methods sit at `CRAP = CC` with `Cov% 100.0`. Nothing you test pulls a score under its CC. If a score is too high at full coverage, that is complexity, which is a refactor question, not a testing one. Do not split methods to chase the number.

Before saying a change is done, run step 2 and report the top rows.

## Reading a row

```
Method          CC    Cov%   CRAP      Evidence  Location
Cart#checkout    6    0.0%  42.00  never called  lib/cart.rb:31
Cart#discount    4   50.0%   6.00        3/6 br  lib/cart.rb:24
```

| Evidence       | Meaning                                      | Do                                                            |
| -------------- | -------------------------------------------- | ------------------------------------------------------------- |
| `never called` | A VM call count of zero. No test reaches it. | Write a test that calls it.                                   |
| `3/6 br`       | 3 of 6 branch outcomes ran.                  | Extend a test to the untaken outcomes.                        |
| `1/1 ln`       | No branches, so lines are the whole truth.   | Nothing, at 100%.                                             |
| `no data`      | No run has been recorded for this file.      | The probe is not loaded, or the suite has not run. Fix Setup. |
| `stale`        | The file changed after it was measured.      | Re-run the suite, then score again.                           |

`no data` and `stale` both score at the `CC² + CC` floor rather than guess. They are also counted per file under the table, because the fix is per file.

A `never called` on a method a test clearly exercises means the test ran without the probe, or the probe loaded after the file. Check Setup before writing a duplicate test.

## Setup

The probe must load before the code under test, because `Coverage` only sees files loaded after it starts. One line, placed first:

- **RSpec**: first line of `.rspec`: `--require swarf/probe`
- **Minitest**: first line of `test/test_helper.rb`: `require "swarf/probe"`
- **Rails**: in `test/test_helper.rb`, after `require "bundler/setup"` and before `require_relative "../config/environment"`. Below the environment require, the whole app is invisible to it.
- **Anything**: `RUBYOPT="-rswarf/probe" bundle exec rake test`

Add `.swarf/` to `.gitignore`. Runs merge, so a single spec file adds to what earlier runs proved; nothing is erased until the file's bytes change.

Do not run swarf's probe alongside SimpleCov. Ruby allows one `Coverage.start` per process; if SimpleCov started first, swarf warns and records nothing.

## Commands

```
bundle exec swarf                       # whole project, worst 20
bundle exec swarf lib/ app/             # directories
bundle exec swarf app/models/cart.rb    # one file
bundle exec swarf --limit 0             # every row
bundle exec swarf --ignore "app/legacy/**"
bundle exec swarf --all                 # ignore nothing, including db/ and .swarfignore
SWARF_DIR=/tmp/swarf bundle exec swarf  # store elsewhere; set for the test run too
```

swarf's CC counts `if`, `unless`, `while`, `until`, `for`, `when`, `in`, `rescue`, `&&`, `||` and `&.`, not blocks, so it will not match RuboCop's. Methods made by `define_method` are not seen.
