# Contributing

## Setup and Validation

Install Ruby 4.0 and [Homebrew](https://brew.sh/). Run the updater tests and the formula checks, and lint Markdown with [rumdl](https://github.com/rvben/rumdl):

```sh
ruby -Ilib test/formula_updater_test.rb
bin/update-formula
bin/test-formulae
rumdl check .
```

`bin/update-formula` writes `Formula/NAME.rb` from the latest release of each tool listed in `lib/formula_updater.rb`, using the `.sha256` file attached to each archive. `bin/test-formulae` taps this checkout as `dblock/tap`, then runs `brew audit --strict`, `brew install`, and `brew test` for every formula. Its install and uninstall may let Homebrew remove dependencies nothing else uses.

## Tests

`test/formula_updater_test.rb` checks the generated formulae and the updater's errors with a fake fetcher, without network access. Add a test for each change to the updater.

## Pull Requests

Formulae are generated: change `lib/formula_updater.rb` rather than editing `Formula/*.rb`, and add a tool by adding an entry to `FORMULAE` with its repository, description, license, binary, and archive targets. Work on a topic branch named `<github-login>/<topic>` with one commit per pull request; pull requests are merged with rebase merges only. The Update Formulae workflow commits formula updates directly to `master`, so `master` does not require pull requests, but changes to anything else still go through them. Use Title Case for Markdown headings and workflow, job, and step names, and keep each Markdown paragraph on one line.
