# claude-plugins-marketplace

The catalogue of the family's plugins. This repository holds one manifest,
`.claude-plugin/marketplace.json`, named `lounisbou`. Each entry points at the
GitHub repository where its plugin lives.

## Install

```
/plugin marketplace add LounisBou/claude-plugins-marketplace
/plugin install <plugin>@lounisbou
```

Already added the previous source of this catalogue? Remove the `lounisbou`
marketplace and add this one. The marketplace name is unchanged, so every
installed `<plugin>@lounisbou` stays valid.

## Plugins

| Plugin | Description | Source |
| --- | --- | --- |
| `claude-statusbar` | Two-line status bar: directory, enriched git, PR, model, session name, context and 5h/7d quotas read natively from the stdin payload. | [LounisBou/claude-statusbar](https://github.com/LounisBou/claude-statusbar) |
| `pr-review` | Interactive PR review workflow: a pending-review walkthrough item by item, GitHub comment processing, and an autonomous review-fix loop. | [LounisBou/claude-review](https://github.com/LounisBou/claude-review) |
| `github` | GitHub API from the standard library: pull requests, review threads, comments, reviews, labels, issues, search and image attachments, without the gh CLI. | [LounisBou/claude-github](https://github.com/LounisBou/claude-github) |
| `norms` | Evidence-based code norms: eight review agents, a parallel conformity check, and a learner that turns resolved PR review threads into project rules. Depends on the github plugin. | [LounisBou/claude-norms](https://github.com/LounisBou/claude-norms) |
| `implement` | The feature lifecycle as five commands: brainstorm and plan a feature, run its phases, check a delivery, close the branch, prepare the next one. | [LounisBou/claude-implement](https://github.com/LounisBou/claude-implement) |
| `orchestrator` | Orchestrate implementer sessions: briefs, evidence-based reviews, rotation, succession, tab tooling, context gauge. | [LounisBou/claude-orchestrator](https://github.com/LounisBou/claude-orchestrator) |
| `bugs-bot` | A Telegram or Slack bug-report relay for the host: one bot, one group or channel and one agent per project. | [LounisBou/claude-bugs-bot](https://github.com/LounisBou/claude-bugs-bot) |

## Releasing a plugin

A plugin's release updates its entry here: bump that entry's `version` in
`.claude-plugin/marketplace.json` to the released version, in one pull request.
Keep the table above in step if the description changes.

## Tests

```
./tests/run-tests.sh            # offline: manifest shape, README table
ONLINE=1 ./tests/run-tests.sh   # also checks each source repository and its plugin.json version
```

## License

MIT, see [LICENSE](LICENSE).
