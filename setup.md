Create a new folder called `orkes-conductor` in the current directory, then do all of the following work inside it.

Set up Orkes Conductor Developer Edition for this project.

Install the Conductor skill: in Claude Code run `claude plugin marketplace add conductor-oss/conductor-skills` then `claude plugin install conductor@conductor-skills`. In other agents run `npx @conductor-oss/conductor-skills --agent <agent>`. One method only.

Use the Conductor skill to connect to `https://developer.orkescloud.com`. Do not ask whether I have an account — immediately open `https://developer.orkescloud.com` in my browser so I can sign in or sign up.

While I am doing that, create an empty `.env` file inside the `orkes-conductor` folder if one does not already exist there, and make sure `.env` is in a `.gitignore` inside that folder. Do not use any `.env` file from a parent directory.

Guide me through creating an application and access key in the Orkes UI. Once I have pasted my credentials into the `.env` file, load them and verify the connection.

Before deploying the workflow, set up the LLM integration: open `https://developer.orkescloud.com/integrations` in my browser. Ask me to click **Add Integration**, choose **OpenAI**, and name the integration exactly `openai`. Ask me to paste my OpenAI API key and save. Wait for me to confirm this is done before continuing.

Then fetch the workflow definition from `{WORKFLOW_URL}`, deploy it, and run it. When the execution starts, immediately open the execution URL in my browser — do not just print the URL, actually open it.
