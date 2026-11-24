# Contributing

## Setup and Validation

Install Ruby 4.0 and [Homebrew](https://brew.sh/). Install the test gems, run the updater tests and the formula checks, and lint Markdown with [rumdl](https://github.com/rvben/rumdl):

```sh
bundle install
bundle exec ruby -Ilib test/formula_updater_test.rb
bin/update-formula
bin/test-formulae
rumdl check .
```

`bin/update-formula` writes `Formula/NAME.rb` from the latest release of each tool listed in `lib/formula_updater.rb`, using the `.sha256` file attached to each archive. `bin/test-formulae` taps this checkout as `dblock/tap`, which clones it, so it tests committed formulae only, then runs `brew audit --strict`, `brew install`, and `brew test` for every formula. Its install and uninstall may let Homebrew remove dependencies nothing else uses.

## Tests

`test/formula_updater_test.rb` checks the generated formulae and the updater's errors with a fake fetcher, and the HTTP fetcher with a stubbed `Net::HTTP`, without network access. Tests measure line and branch coverage with SimpleCov, written to `coverage/` and reported to [Coveralls](https://coveralls.io/github/dblock/homebrew-tap) by CI; keep it complete and add a test for each change to the updater.

## Pull Requests

Formulae are generated: change `lib/formula_updater.rb` rather than editing `Formula/*.rb`, and add a tool by adding an entry to `FORMULAE` with its repository, description, license, binary, and archive targets. Work on a topic branch named `<github-login>/<topic>` with one commit per pull request; pull requests are merged with rebase merges only. The Update Formulae workflow commits formula updates directly to `master`, so `master` does not require pull requests, but changes to anything else still go through them. Use Title Case for Markdown headings and workflow, job, and step names, and keep each Markdown paragraph on one line.
