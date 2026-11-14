# CLI libraries

Prefer the library the project already uses; otherwise pick the default (listed
first) for the language. Helpers must honor [NO_COLOR](https://no-color.org)
and disable color and prompts when output is not a TTY.

## Python

- [Typer](https://github.com/fastapi/typer/tree/0.29.1): default; typed
  options from type hints, subcommands, generated help and completion.
- [Click](https://github.com/pallets/click/tree/8.5.1): mature, explicit
  decorators; choose for fine control or plugin-style command groups.
- [argparse](https://docs.python.org/3.14/library/argparse.html): stdlib; choose
  when no dependencies are allowed and the CLI is small.

Helpers: `sys.stdout.isatty()`; [Rich](https://github.com/Textualize/rich/tree/v15.0.0)
for color, tables and progress.

## Go

- [Cobra](https://github.com/spf13/cobra/tree/v1.10.2): default; nested
  subcommands, generated help, shell completion.
- [urfave/cli](https://github.com/urfave/cli/tree/v3.14.0): lighter; flags and
  subcommands with less ceremony.
- [Kong](https://github.com/alecthomas/kong/tree/v1.17.0): struct-tag
  declarations; typed options and nested commands.

Helpers: [golang.org/x/term](https://github.com/golang/term/tree/v0.48.0)
(`term.IsTerminal`); [fatih/color](https://github.com/fatih/color/tree/v1.19.0)
or [lipgloss](https://github.com/charmbracelet/lipgloss/tree/v2.1.0).

## Rust

- [clap](https://github.com/clap-rs/clap/tree/v4.6.7) (derive API): default;
  typed options, subcommands, generated help, completion via `clap_complete`.
- [argh](https://github.com/google/argh/tree/0.1.10): small and fast to
  compile; choose for simple CLIs with few features.

Helpers: [`std::io::IsTerminal`](https://doc.rust-lang.org/1.95.0/std/io/trait.IsTerminal.html);
[anstream](https://github.com/rust-cli/anstyle/tree/anstream-v1.0.0) (strips
color when piped) or [owo-colors](https://github.com/owo-colors/owo-colors/tree/v4.4.0).

## JavaScript/TypeScript (Node.js)

- [Commander](https://github.com/tj/commander.js/tree/v15.1.0): default;
  subcommands, generated help, typed options with TypeScript.
- [yargs](https://github.com/yargs/yargs/tree/v18.2.0): rich option parsing and
  completion generation.
- [oclif](https://github.com/oclif/oclif/tree/6.0.15): framework for large,
  plugin-based multi-command CLIs.

Helpers: [`process.stdout.isTTY`](https://nodejs.org/docs/latest-v24.x/api/tty.html);
[picocolors](https://github.com/alexeyraspopov/picocolors/tree/v1.1.1) (tiny)
or [chalk](https://github.com/chalk/chalk/tree/v6.0.1).

## Java/Kotlin

- [picocli](https://github.com/remkop/picocli/tree/v4.7.7): default; annotated
  options, subcommands, generated help and completion; Java and Kotlin.
- [Clikt](https://github.com/ajalt/clikt/tree/5.1.0): idiomatic Kotlin DSL;
  typed options, subcommands, completion.

Helpers: `System.console()`; [JLine](https://github.com/jline/jline3/tree/4.7.0)
or [Jansi](https://github.com/fusesource/jansi/tree/jansi-2.4.3) for ANSI.

## C#/.NET

- [System.CommandLine](https://github.com/dotnet/command-line-api/tree/v2.0.2):
  default; first-party, typed options, subcommands, help, completion.
- [Spectre.Console.Cli](https://github.com/spectreconsole/spectre.console.cli/tree/0.57.2):
  command classes with rich help output; pairs with Spectre.Console.

Helpers: `Console.IsOutputRedirected`;
[Spectre.Console](https://github.com/spectreconsole/spectre.console/tree/0.57.2)
for color, tables and progress.

## Ruby

- [Thor](https://github.com/rails/thor/tree/v1.5.0): default; subcommands,
  generated help, widely used (Rails generators).
- [dry-cli](https://github.com/dry-rb/dry-cli/tree/v1.4.1): command objects;
  choose for a modular, testable command registry.

Helpers: `$stdout.tty?`; [pastel](https://github.com/piotrmurach/pastel/tree/v0.8.0)
for color and [tty-prompt](https://github.com/piotrmurach/tty-prompt/tree/v0.23.1)
for prompts.

## Shell (POSIX sh/Bash)

- [`getopts`](https://pubs.opengroup.org/onlinepubs/9799919799/utilities/getopts.html):
  default; built-in, portable short options only; handle `--help` and
  `--version` by hand. Move to another language when subcommands, typed
  options or completion are needed.

Helpers: `[ -t 1 ]` (stdout is a TTY); `tput` for portable color codes, unset
when `NO_COLOR` is set or `TERM=dumb`.
