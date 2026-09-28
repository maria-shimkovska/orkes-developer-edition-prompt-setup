Create a new folder called `orkes-conductor` in the current directory, then do all of the following work inside it.

Set up Orkes Conductor Developer Edition for this project.

Install the Conductor skill: in Claude Code run `claude plugin marketplace add conductor-oss/conductor-skills` then `claude plugin install conductor@conductor-skills`. In other agents run `npx @conductor-oss/conductor-skills --agent <agent>`. One method only.

Immediately open `https://developer.orkescloud.com` in my browser so I can sign in or sign up. Do not ask whether I have an account first.

While I am doing that, create an empty `.env` file inside the `orkes-conductor` folder if one does not already exist there, and make sure `.env` is in a `.gitignore` inside that folder. Do not use any `.env` file from a parent directory.

Guide me through creating an application and access key: open `https://developer.orkescloud.com/access-control/applications` in my browser. Ask me to click **Create Application**, give it a name, then click **Create Access Key** inside the app. Ask me to paste the Key ID and Key Secret into the `.env` file using this exact format (no `export` prefix):

```
CONDUCTOR_SERVER_URL=https://developer.orkescloud.com/api
CONDUCTOR_AUTH_KEY=<key id>
CONDUCTOR_AUTH_SECRET=<key secret>
```

Once I confirm the credentials are pasted, load them and verify the connection using `whoami`. Then ask me to grant the application EXECUTE permission on workflows: go back to the application in the Orkes UI, click **Add Permission**, select **Workflow**, search for the workflow by name, and grant **Execute** access.

Before setting up the LLM integration, fetch the workflow definition from `{WORKFLOW_URL}` so you know which LLM provider and model it uses.

Then set up the LLM integration: open `https://developer.orkescloud.com/integrations` in my browser. Ask me to click **Add Integration**, choose the provider used by the workflow, and name the integration exactly as it appears in the workflow's `llmProvider` field. Ask me to paste my API key and save. Then ask me to click **Add Model** inside the integration and add the model name exactly as it appears in the workflow definition. Wait for me to confirm both are saved before continuing.

Deploy the workflow and run it. When the execution starts, immediately open the execution URL in my browser — do not just print the URL, actually open it.
