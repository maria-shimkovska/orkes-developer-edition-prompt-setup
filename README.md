# orkes-developer-edition-prompt-setup

**A one-line, AI-agent-ready setup for [Orkes Conductor](https://orkes.io/) Developer Edition.**

Drop a single line into any article or tutorial. Readers paste it into their AI coding agent (Claude Code, Cursor, Copilot, etc.), and the agent handles the rest: installing the Conductor skill, configuring the project, deploying your workflow, and running it.

---

## Why this exists

When you're reading one of our [Orkes articles](https://orkes.io/blog), we want you to be able to try the workflow yourself right away, without stopping to work through a long list of install and configuration steps first.

That's what this repo is for. Instead of following setup instructions by hand, you copy one line from the article, paste it into your AI agent, and it gets Orkes Conductor running and the workflow deployed for you. You get to spend your time exploring how the workflow actually works, which is the fun part.

We also keep these setup instructions in one place and update them as tools change, so the one-liner in every article keeps working.

## How it works

1. You copy the one-liner from the Orkes article you're reading.
2. You paste it into your AI agent.
3. The agent fetches [`setup.md`](./setup.md) from this repo.
4. The agent reads the workflow link from the article and follows the instructions in `setup.md`:
   - creates an `orkes-conductor` folder to contain everything
   - installs the Conductor skill
   - sets up Orkes Conductor Developer Edition in your project
   - fetches and deploys the workflow definition
   - runs the workflow and reports the result

### Example

```text
Fetch https://raw.githubusercontent.com/maria-shimkovska/orkes-developer-edition-prompt-setup/main/setup.md, set WORKFLOW_URL to https://raw.githubusercontent.com/maria-shimkovska/orkes-developer-edition-prompt-setup/main/workflows/github_repo_health_check.json, and follow the instructions.
```

## Repo structure

```text
orkes-setup/
├── README.md       # this file
├── setup.md        # the hosted prompt that agents fetch
└── workflows/      # workflow JSON files referenced by articles
```

## Updating the prompt

Edit `setup.md` and push to `main`. Every article that links to `main` picks up the change automatically, with no need to edit the articles themselves.

### Pinning a version (recommended for published articles)

Because `main` changes over time, an edit to `setup.md` could break an older article whose workflow expects the previous behavior. To lock an article to a known-good version, tag a release and reference the tag instead of `main`:

```bash
git tag v1.0.0
git push origin v1.0.0
```

```text
Fetch https://raw.githubusercontent.com/YOUR_USERNAME/orkes-setup/v1.0.0/setup.md, set WORKFLOW_URL to ..., and follow the instructions.
```

Use `main` for articles you actively maintain, and tags for anything you want frozen.

## Troubleshooting

**The agent says it can't fetch the URL.**
Check that the repo is public and the URL uses `raw.githubusercontent.com`, not `github.com/.../blob/...`. Some agents also need web access enabled.

**The agent sets up Conductor but skips the workflow.**
Make sure the one-liner includes `set WORKFLOW_URL to ...` and that the workflow URL opens as plain JSON in a browser.

**Recent changes to `setup.md` aren't showing up.**
GitHub caches raw files for a few minutes. Wait briefly and try again, or pin to a tag or commit SHA.

## A note for readers

This prompt tells your AI agent to install software and run commands in your project. As with any script from the internet, it's worth opening [`setup.md`](./setup.md) and skimming it before you run it.

## Contributing

Issues and pull requests are welcome. If you change `setup.md`, please test it end-to-end with at least one agent and one workflow before opening a PR.
