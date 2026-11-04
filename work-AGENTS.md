# Linear issue before committing

If no Linear issue has been provided in the current task context, ask the user before creating a commit. Use an interactive choice/picker with arrow-key navigation and these options:

- **No issue** — commit without linking a Linear issue; use `ref no-issue` in the work commit template.
- **Linear issue URL** — ask the user for the URL, then use it in the work commit template.

Wait for the user's choice and, when applicable, their URL before committing. Do not infer a choice or invent an issue URL. Reuse the answer for subsequent commits in the same task instead of asking again. If an issue has already been provided, use it without asking.

Use the agent's native interactive choice tool when available. Otherwise, ask the user to choose between the two options in chat; do not launch a terminal picker in an agent-owned pane that the user cannot control.
