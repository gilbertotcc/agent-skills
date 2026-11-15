# cli-designer

An agent skill to design, validate and extend command-line interfaces with
the [Command Line Interface Guidelines](https://clig.dev/) (clig.dev). It
defines new commands and subcommands, reviews a CLI or a diff against the
guidelines, and suggests missing commands and flags. A project's own CLI
guidelines take precedence over clig.dev. The skill also lists recommended
CLI libraries for common languages.

## Install

```sh
npx skills add gilbertotcc/agent-skills --skill cli-designer
```

## Requirements

None. The agent reads the live guidelines from `https://clig.dev/llms.txt`
with the skill's script, which needs `bash`, `curl`, `awk` and network
access. Without them, the agent uses the skill's bundled checklist.

## Security & Privacy

- Data leaving the machine: the skill's script fetches
  `https://clig.dev/llms.txt` when network access is available, and sends
  nothing else. Your CLI may still send data by itself, even for `--help`
  or `--version`.
- Credentials: none.
- Local side effects: the agent runs your CLI only with harmless calls
  (`--help`, `--version`, no arguments, a typo), never commands that change
  state. It changes files only when you ask it to implement a design.
