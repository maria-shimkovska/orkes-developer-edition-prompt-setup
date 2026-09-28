# orkes-setup

A hosted prompt for setting up Orkes Conductor Developer Edition in any project — designed to be dropped as a one-liner into articles and tutorials.

## How it works

Readers copy one line from your article and paste it into their AI agent. The agent fetches `setup.md` from this repo and follows the instructions, handling everything from installing the Conductor skill to deploying and running the workflow.

## Usage in articles

```
Fetch https://raw.githubusercontent.com/YOUR_USERNAME/orkes-setup/main/setup.md, set WORKFLOW_URL to https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/workflows/YOUR_WORKFLOW.json, and follow the instructions.
```

Replace `WORKFLOW_URL` with the raw GitHub URL of the workflow definition for that specific article.

## Repo structure

```
orkes-setup/
├── README.md         # this file
├── setup.md          # the hosted prompt — fetched by agents
└── workflows/        # optional: store workflow JSONs here
```

## Updating the prompt

Edit `setup.md` and all articles that reference this repo automatically pick up the changes — no need to update the articles themselves.
