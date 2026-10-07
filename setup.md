Do all of the following work inside an `orkes-conductor` folder in the current directory. If that folder or anything in it already exists, reuse it — do not delete, move, or recreate it. Only overwrite the specific files this setup downloads (`scripts/*.sh`) or creates (`.env`, `.gitignore`) below.

Never print, `cat`, echo, or otherwise read back the contents of `.env`, and never put a key or secret value on a command line. Do not `source .env` yourself — the scripts read it internally instead.

**Preflight.** Confirm `curl` and `jq` are available (`curl --version`, `jq --version`). If either is missing, tell me how to install it for my OS and stop — nothing below works without them.

**Check for an existing setup first.** If the `orkes-conductor` folder already exists and contains a `.env` file, load those credentials and run `whoami` to verify the connection. If the connection succeeds, skip everything below and go straight to fetching the workflow, setting up integrations, deploying, and running it.

If the folder does not exist, or the connection check fails, do the full setup below.

---

Create the `orkes-conductor` folder. If a Conductor skill/plugin is installable for this agent, install it: in Claude Code run `claude plugin marketplace add conductor-oss/conductor-skills` then `claude plugin install conductor@conductor-skills`; in other agents run `npx @conductor-oss/conductor-skills --agent <agent>`. One method only. This is optional polish, not a dependency — if it fails or isn't supported for this agent, continue anyway. Everything below works without it.

Immediately open `https://developer.orkescloud.com` in my browser so I can sign in or sign up. Do not ask whether I have an account or existing credentials first — just open it and let me log in or create one. To open a URL: macOS `open <url>`, Linux `xdg-open <url>`, Windows `start <url>`. If you have no way to open a browser on my machine (for example a remote or cloud session), print the URL clearly and ask me to open it myself — do not just silently skip this step.

While I am doing that, fetch the workflow definition from `{WORKFLOW_URL}` and scan it for every `LLM_CHAT_COMPLETE`, `LLM_GENERATE_EMBEDDINGS`, `LLM_GENERATE_IMAGE`, `LLM_GENERATE_TTS`, and `LLM_GENERATE_VIDEO` task. Collect the distinct `(llmProvider, model)` pairs used across the workflow — there may be more than one, and they may use different providers.

Create an empty `.env` file inside the `orkes-conductor` folder and a `.gitignore` that includes `.env`. Do not use any `.env` file from a parent directory.

Open `https://developer.orkescloud.com/applicationManagement/applications/default-orkes-application` in my browser the same way as above. Ask me to click **Create Access Key**. Ask me to paste my credentials, plus one API key for each distinct `llmProvider` found above, into `.env` using this format (no `export` prefix):

```
CONDUCTOR_SERVER_URL=https://developer.orkescloud.com/api
CONDUCTOR_AUTH_KEY=<key id>
CONDUCTOR_AUTH_SECRET=<key secret>
OPENAI_API_KEY=<only if the workflow uses openai>
ANTHROPIC_API_KEY=<only if the workflow uses anthropic>
GEMINI_API_KEY=<only if the workflow uses google_gemini>
```

Only ask for the key(s) matching the provider(s) actually used by this workflow — don't request keys for providers it doesn't need.

Once I confirm the credentials are pasted, load them and verify the connection using `whoami`.

Download the setup scripts into a `scripts/` folder inside `orkes-conductor/`:

```bash
mkdir -p scripts
curl -s -o scripts/lib.sh https://raw.githubusercontent.com/maria-shimkovska/orkes-developer-edition-prompt-setup/main/scripts/lib.sh
curl -s -o scripts/setup_integration.sh https://raw.githubusercontent.com/maria-shimkovska/orkes-developer-edition-prompt-setup/main/scripts/setup_integration.sh
curl -s -o scripts/deploy_workflow.sh https://raw.githubusercontent.com/maria-shimkovska/orkes-developer-edition-prompt-setup/main/scripts/deploy_workflow.sh
curl -s -o scripts/run_workflow.sh https://raw.githubusercontent.com/maria-shimkovska/orkes-developer-edition-prompt-setup/main/scripts/run_workflow.sh
```

For **each distinct `(llmProvider, model)` pair** found above, set up the integration (skip this step entirely if none were found):

```bash
bash scripts/setup_integration.sh {llmProvider} {model}
```

Deploy the workflow:

```bash
bash scripts/deploy_workflow.sh {workflowFile}
```

If the Conductor skill is installed and you're able to reason about the workflow definition, do a quick sanity check before running it: flag any `SIMPLE` task with no registered task definition (it will hang forever — tell me and stop so we can fix it), and flag any obviously missing timeout or retry config on HTTP or LLM tasks. This is a bonus check only — if the skill isn't available or you can't do this, skip it and continue.

Immediately after deploying, open the workflow definition page in my browser — `https://developer.orkescloud.com/workflowDef/{workflowName}` — so I can see the visual graph. Open it the same way as above, with the same browser-unavailable fallback.

Run the workflow and capture the output:

```bash
bash scripts/run_workflow.sh {workflowName} '{workflowInput}'
```

The script will print the execution URL. Open it in my browser the same way. Once the script finishes, check whether it succeeded or failed.

If it succeeded: print the result clearly in the terminal, then print a short explanation — describe what the workflow did, name the tasks that ran and what each one did, and remind me the full execution is open in my browser.

If it failed: do not just show the raw error. Identify which task failed and explain in plain English what went wrong. For common failures, offer a specific fix:
- LLM task failure with an auth or invalid key error → the matching provider's API key in `.env` is likely wrong or expired; ask me to update it and offer to re-run
- LLM task failure mentioning the model or integration → the integration may not be set up correctly; offer to re-run `setup_integration.sh` for that provider and model
- HTTP task failure → print the status code and explain what it means (e.g. 401 = auth issue, 404 = resource not found, 429 = rate limited)
- Timeout → the workflow took too long; suggest re-running or checking the Orkes UI for details
