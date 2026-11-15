---
paths:
  - "skills/**"
---

# Skill README and requirements

Users must know what a skill needs, and what it sends, runs or changes,
before they install it.

## README.md

Every `skills/<name>/README.md` is for users, not agents: a one-paragraph
summary, then `## Install`, `## Requirements` and `## Security & Privacy`,
in that order. Don't repeat `SKILL.md` instructions. Write both sections
even when there is nothing to declare ("None.").

- **Requirements:** tools (required or optional, with install hints),
  accounts, environment variables (and where to get their values), and
  network access.
- **Security & Privacy:** cover three topics, saying "none" when that's the
  case:
  - data that leaves the machine: each destination, what is sent, and when;
  - credentials: which environment variables hold secrets; tell users to
    keep them out of chat and commits;
  - local side effects: commands the skill runs and files it may change.

## SKILL.md frontmatter

Don't add a requirements section to the body; declare requirements in
frontmatter:

- `compatibility` (spec, max 500 characters): the tools and network access
  the skill needs.
- `metadata.requires-env`: only when the skill needs environment variables.
  List their `UPPER_SNAKE` names separated by spaces (spec `metadata`
  values are strings), e.g. `requires-env: SERVICE_API_KEY OTHER_TOKEN`.

Keep the README, `compatibility` and `requires-env` consistent.

## Skeleton

````markdown
# <name>

An agent skill to <what it does, for whom; what stays out of scope>.

## Install

```sh
npx skills add gilbertotcc/agent-skills --skill <name>
```

## Requirements

<None. | - **<tool>** (required|optional, <why>): <install hint>
- **<account>**: <where to sign up; costs>
- **`<ENV_VAR>`**: <what it holds; where to get it>
- Network access: <what for; behavior without it>>

## Security & Privacy

- Data leaving the machine: <None. | <destination>: <what is sent>, <when>>
- Credentials: <None. | `<ENV_VAR>` holds <secret>; keep it out of chat and
  commits.>
- Local side effects: <commands run; files it may change; what it never
  does>
````
