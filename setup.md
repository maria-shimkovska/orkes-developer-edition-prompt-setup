Do all of the following work inside an `orkes-conductor` folder in the current directory.

**Check for an existing setup first.** If the `orkes-conductor` folder already exists and contains a `.env` file, load those credentials and run `whoami` to verify the connection. If the connection succeeds, skip everything below and go straight to fetching the workflow, setting up the integration if needed, deploying, and running it.

If the folder does not exist, or the connection check fails, do the full setup below.

---

Create the `orkes-conductor` folder. Install the Conductor skill: in Claude Code run `claude plugin marketplace add conductor-oss/conductor-skills` then `claude plugin install conductor@conductor-skills`. In other agents run `npx @conductor-oss/conductor-skills --agent <agent>`. One method only.

Immediately open `https://developer.orkescloud.com` in my browser so I can sign in or sign up. Do not ask whether I have an account first.

While I am doing that, fetch the workflow definition from `{WORKFLOW_URL}` so you know which LLM provider and model it uses.

Create an empty `.env` file inside the `orkes-conductor` folder and a `.gitignore` that includes `.env`. Do not use any `.env` file from a parent directory.

Open `https://developer.orkescloud.com/applicationManagement/applications/default-orkes-application` in my browser. Ask me to click **Create Access Key**. Ask me to paste my credentials and the API key for the LLM provider into `.env` using this format (no `export` prefix):

```
CONDUCTOR_SERVER_URL=https://developer.orkescloud.com/api
CONDUCTOR_AUTH_KEY=<key id>
CONDUCTOR_AUTH_SECRET=<key secret>
OPENAI_API_KEY=<your openai key>
```

Once I confirm the credentials are pasted, load them and verify the connection using `whoami`.

Using the credentials from `.env`, automatically set up the LLM integration via the Orkes API — no UI steps needed:
- Check if the provider already exists: `GET /api/integrations/provider/{llmProvider}`
- If not, create it: `POST /api/integrations/provider/{llmProvider}` with `"category": "AI_MODEL"`, `"type": "{llmProvider}"`, `"enabled": true`, `"configuration": {"api_key": "<key from .env>", "endpoint": "https://api.openai.com/v1/", "organizationId": ""}`
- Check if the model already exists: `GET /api/integrations/provider/{llmProvider}/integration/{model}`
- If not, add it: `POST /api/integrations/provider/{llmProvider}/integration/{model}` with `"description": "{model}"`, `"enabled": true`, `"configuration": {}`

Deploy the workflow and run it synchronously using the `--sync` flag so you can capture the output. While it runs, open the execution URL in my browser — do not just print the URL, actually open it. Once the workflow completes, check whether it succeeded or failed.

If it succeeded: print the result clearly in the terminal, then print a short explanation — describe what the workflow did, name the tasks that ran and what each one did, and remind me the full execution is open in my browser.

If it failed: do not just show the raw error. Identify which task failed and explain in plain English what went wrong. For common failures, offer a specific fix:
- LLM task failure with an auth or invalid key error → the OpenAI API key in `.env` is likely wrong or expired; ask me to update `OPENAI_API_KEY` and offer to re-run
- LLM task failure mentioning the model or integration → the model may not be set up correctly; offer to re-run the integration setup
- HTTP task failure → print the status code and explain what it means (e.g. 401 = auth issue, 404 = resource not found, 429 = rate limited)
- Timeout → the workflow took too long; suggest re-running or checking the Orkes UI for details
