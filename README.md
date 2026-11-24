# Homebrew Tap

[![Test](https://github.com/dblock/homebrew-tap/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/dblock/homebrew-tap/actions/workflows/test.yml) [![Lint](https://github.com/dblock/homebrew-tap/actions/workflows/lint.yml/badge.svg?branch=master)](https://github.com/dblock/homebrew-tap/actions/workflows/lint.yml) [![Coverage Status](https://coveralls.io/repos/github/dblock/homebrew-tap/badge.svg?branch=master)](https://coveralls.io/github/dblock/homebrew-tap?branch=master) [![Update Formulae](https://github.com/dblock/homebrew-tap/actions/workflows/update.yml/badge.svg?branch=master)](https://github.com/dblock/homebrew-tap/actions/workflows/update.yml)

Homebrew formulae for command-line tools by [@dblock](https://github.com/dblock). Formulae install the prebuilt binaries attached to each tool's GitHub Releases, so installing does not need a compiler.

## Installation

Install [Homebrew](https://brew.sh/) on macOS or Linux. Installing a formula by its full name taps this repository automatically.

## Usage

```sh
brew install dblock/tap/fue
```

| Formula | Tool |
| --- | --- |
| `fue` | [fue](https://github.com/dblock/fue-rs), find e-mail addresses of GitHub users and repository contributors. |

A formula appears once its tool has its first release. The [Update Formulae](.github/workflows/update.yml) workflow checks for new releases every six hours, audits, installs, and tests the updated formulae on macOS, and commits them. Run it immediately after a release with `gh workflow run update.yml --repo dblock/homebrew-tap`.

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md). Automated contributors start with [AGENTS](AGENTS.md).

## License

[MIT](LICENSE).
