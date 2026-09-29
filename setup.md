Create a new folder called `orkes-conductor` in the current directory, then do all of the following work inside it.

Install the Conductor skill: in Claude Code run `claude plugin marketplace add conductor-oss/conductor-skills` then `claude plugin install conductor@conductor-skills`. In other agents run `npx @conductor-oss/conductor-skills --agent <agent>`. One method only.

Immediately open `https://developer.orkescloud.com` in my browser so I can sign in or sign up. Do not ask whether I have an account first.

While I am doing that, fetch the workflow definition from `{WORKFLOW_URL}` so you know which LLM provider and model it uses.

Create an empty `.env` file inside the `orkes-conductor` folder and a `.gitignore` that includes `.env`. Do not use any `.env` file from a parent directory.

Open `https://developer.orkescloud.com/applicationManagement/applications` in my browser. Ask me to click into the default application that's already there, then click **Create Access Key**. Ask me to paste my credentials and the API key for the LLM provider into `.env` using this format (no `export` prefix):

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

Deploy the workflow and run it. When the execution starts, immediately open the execution URL in my browser — do not just print the URL, actually open it.
