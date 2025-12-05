# Conventional Commit

Create a commit for the currently staged files using conventional commit format.

## Instructions

1. Run `git diff --cached` to see the staged changes
2. Run `git diff --cached --stat` to get an overview of files changed
3. Run `git log --oneline -10` to see recent commit style for context

4. Analyze the changes and determine:
   - The commit type: feat, fix, refactor, docs, style, test, chore, ci, perf, build
   - The scope (optional): the area/module affected
   - A concise subject line (max 50 chars, imperative mood, no period)

5. Write a detailed body that explains:
   - **Why** this change was made (the motivation/context)
   - **What** behavior or functionality changes (from user/system perspective)
   - **Impact** on the project (if any breaking changes, dependencies, etc.)

   Do NOT simply describe the code changes line by line. Focus on the intent and impact.

6. Format the commit message as:
   ```
   <type>(<scope>): <subject>

   <body>

   Signed-off-by: Otavio Salvador <otavio@ossystems.com.br>
   ```

7. Create the commit using a HEREDOC:
   ```bash
   git commit -m "$(cat <<'EOF'
   <full commit message here>
   EOF
   )"
   ```

8. Run `git status` to verify the commit was successful

If there are no staged changes, inform the user and do not create an empty commit.
