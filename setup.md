Do all of the following work inside an `orkes-conductor` folder in the current directory. If that folder or anything in it already exists, reuse it — do not delete, move, or recreate it. Only overwrite the specific files this setup downloads (`scripts/*.sh`, `workflow.json`) or creates (`.env`, `.gitignore`) below.

Never print, `cat`, echo, or otherwise read back the contents of `.env`, and never put a key or secret value on a command line. Do not `source .env` yourself — the scripts (and your own shell loading of it) must treat it as data, not executable code.

**Always target Developer Edition, never local.** Every step below uses `https://developer.orkescloud.com` and the credentials in `.env` — never `http://localhost:8080`. Do not run `conductor server start`, do not create or switch to a `localhost` CLI profile, and do not offer "start a local server instead" as an option at any point, even if the installed Conductor skill's own default setup flow would otherwise suggest or ask about one. This flow has exactly one destination: the reader's Developer Edition account.

**Preflight.** Confirm `curl` and `jq` are available (`curl --version`, `jq --version`) — these are required regardless of which agent you are, because the LLM integration step below always uses them. If either is missing, tell me how to install it for my OS and stop.

**Check for an existing setup first.** If the `orkes-conductor` folder already exists and contains a `.env` file, load those credentials as data (never execute the file) and confirm they still work: on the Claude Code path, export them into the process environment and run `conductor whoami`; on the portable path, source the existing `scripts/lib.sh` and call its `get_token` function — if it returns a token, the connection is good. If it succeeds, skip straight to fetching the workflow, setting up integrations, deploying, and running it.

If the folder does not exist, or the connection check fails, do the full setup below.

**State the plan, then go.** Before anything else — before the preflight check — tell me the plan in 3-4 short sentences: what you're about to do and roughly how long it'll take. Then start immediately; don't wait for confirmation, the plan is a heads-up, not a gate. Adapt it to what you find (existing setup vs. fresh, which provider the workflow needs) rather than reciting a fixed script. Something in this shape:

> Here's what I'm about to do: get you signed into Orkes Developer Edition (free), set up the AI provider this workflow needs, then deploy and run it and show you the result. Should take about 2 minutes, mostly while you sign in. Starting now.

Keep narrating briefly as you move between phases — sign-in, credentials, integration setup, deploy, run — so I'm never watching silence wondering if something's stuck. A line or two per phase is enough ("Opening Developer Edition — sign in or create an account, I'll fetch the workflow while you do that." / "Registering the OpenAI integration..." / "Deployed — running it now, typically ~10-15s..."). Keep the visible chat output terse throughout; don't dump raw `curl` commands or JSON output unless something fails, in which case show the real detail. If this is a resume (existing `.env`, still valid), say so plainly and skip straight to the real work rather than re-narrating steps that already happened.

---

## Are you Claude Code with the Conductor plugin?

Create the `orkes-conductor` folder, then try to install the Conductor skill: in Claude Code run `claude plugin marketplace add conductor-oss/conductor-skills` then `claude plugin install conductor@conductor-skills`; in any other agent run `npx @conductor-oss/conductor-skills --agent <agent>`. One method only, and only the one matching what you are.

Note the result — you'll use it below:
- **Claude Code path**: you are Claude Code *and* the plugin install above succeeded. You'll use the `conductor` CLI directly for deploy/run and the skill's own rules for review.
- **Portable path**: anything else — a different agent, or the install failed/isn't supported. You'll use the downloaded shell scripts for every step, exactly as a reader with no AI-agent skill support would.

This choice only changes *how* deploy/run/review happen below — the credential and integration steps are identical either way.

## Sign in and fetch the workflow

Immediately open `https://developer.orkescloud.com` in my browser so I can sign in or sign up. Do not ask whether I have an account first — just open it and let me log in or create one. To open a URL: macOS `open <url>`, Linux `xdg-open <url>`, Windows `start <url>`. If you have no way to open a browser on my machine (for example a remote or cloud session), print the URL clearly and ask me to open it myself — do not just silently skip this.

While I am doing that, fetch the workflow definition from `{WORKFLOW_URL}` and save it as `workflow.json` inside `orkes-conductor/` (every deploy/run step below reads from this local file, not the URL, so it works offline after this point). Scan it for every `LLM_CHAT_COMPLETE`, `LLM_GENERATE_EMBEDDINGS`, `LLM_GENERATE_IMAGE`, `LLM_GENERATE_TTS`, and `LLM_GENERATE_VIDEO` task, and collect the distinct `(llmProvider, model)` pairs used — there may be more than one, and they may use different providers. Also note the workflow's `name` — you'll need it below.

## Credentials

Create an empty `.env` file inside the `orkes-conductor` folder and a `.gitignore` that includes `.env`. Do not use any `.env` file from a parent directory.

Open `https://developer.orkescloud.com/applicationManagement/applications/default-orkes-application` in my browser the same way as above. Ask me to click **Create Access Key**. Ask me to paste my credentials, plus one API key for each distinct `llmProvider` found above, into `.env` using this format (no `export` prefix). If a provider key is needed, mention up front that Developer Edition itself is free and this demo's AI provider calls typically cost a fraction of a cent, so it's not a surprise:

```
CONDUCTOR_SERVER_URL=https://developer.orkescloud.com/api
CONDUCTOR_AUTH_KEY=<key id>
CONDUCTOR_AUTH_SECRET=<key secret>
OPENAI_API_KEY=<only if the workflow uses openai>
ANTHROPIC_API_KEY=<only if the workflow uses anthropic>
GEMINI_API_KEY=<only if the workflow uses google_gemini>
```

Only ask for the key(s) matching providers the workflow actually uses.

**Verify the connection.** Load `.env` as data (never execute it) and confirm the values work, the same way as the existing-setup check above: Claude Code path → export the three `CONDUCTOR_*` variables into the process environment (the `conductor` CLI reads these directly — no profile needed) and run `conductor whoami`; portable path → this gets verified for free the moment `setup_integration.sh` or `deploy_workflow.sh` runs below, since both call `lib.sh`'s `get_token` first and fail loudly if the credentials are wrong. Never print the values themselves, only whether the check passed.

## Download the scripts

```bash
mkdir -p scripts
curl -s -o scripts/lib.sh https://raw.githubusercontent.com/maria-shimkovska/orkes-developer-edition-prompt-setup/main/scripts/lib.sh
curl -s -o scripts/setup_integration.sh https://raw.githubusercontent.com/maria-shimkovska/orkes-developer-edition-prompt-setup/main/scripts/setup_integration.sh
```

`lib.sh` and `setup_integration.sh` are needed on **both** paths — there is no CLI or skill equivalent for registering an LLM provider integration on Developer Edition. On the portable path, also download the deploy/run scripts:

```bash
curl -s -o scripts/deploy_workflow.sh https://raw.githubusercontent.com/maria-shimkovska/orkes-developer-edition-prompt-setup/main/scripts/deploy_workflow.sh
curl -s -o scripts/run_workflow.sh https://raw.githubusercontent.com/maria-shimkovska/orkes-developer-edition-prompt-setup/main/scripts/run_workflow.sh
```

## Set up the LLM integration(s)

For **each distinct `(llmProvider, model)` pair** found above, run (skip entirely if none were found):

```bash
bash scripts/setup_integration.sh {llmProvider} {model}
```

## Review, deploy, and run

**Claude Code path:** if the skill's optimization rules are available to you, check `workflow.json` against them first: flag any `SIMPLE` task with no registered task definition (`conductor task list --json`) — it will hang forever, so tell me and stop rather than deploying it — and flag any missing timeout/retry config on HTTP or LLM tasks. Then deploy and run with the CLI:

```bash
conductor workflow create workflow.json
conductor workflow start -w {workflowName} -i '{workflowInput}' --sync
```

If `--sync` doesn't return a clear result, follow up with `conductor workflow get-execution {executionId} -c` for the full detail, including which task failed and why.

**Portable path:**

```bash
bash scripts/deploy_workflow.sh workflow.json
bash scripts/run_workflow.sh {workflowName} '{workflowInput}'
```

On either path, immediately after deploying, open the workflow definition page in my browser — `https://developer.orkescloud.com/workflowDef/{workflowName}` — so I can see the visual graph. Open it the same way as above, with the same browser-unavailable fallback. Once run/start returns, it will give you an execution URL — open that too.

## Report the result

If it succeeded: print the result clearly in the terminal, then a short explanation — describe what the workflow did and name the tasks that ran and what each one did. Close by reminding me the execution is open in my browser, and that the workflow is now live in my own account — I can change the input and run it again, or open it in the UI and tweak a task, any time, since everything's already set up in `orkes-conductor/`.

If it failed: do not just show the raw error. Identify which task failed and explain in plain English what went wrong, then give me something concrete to do next, not just an explanation:
- LLM task failure with an auth or invalid key error → the matching provider's API key in `.env` is likely wrong or expired; tell me to update it and that I can just say "retry" to pick back up from the integration step, not redo the whole setup
- LLM task failure mentioning the model or integration → the integration may not be set up correctly; offer to re-run `setup_integration.sh` for that provider and model
- HTTP task failure → print the status code and explain what it means (e.g. 401 = auth issue, 404 = resource not found, 429 = rate limited)
- Timeout → the workflow took too long; suggest re-running or checking the Orkes UI for details
