# Explore subagent model (Claude Code)

Reply in the user's language. This reference covers one Claude Code check: whether the built-in `Explore` subagent runs on the model the user set for subagents.

## Why it matters

Claude Code picks a subagent's model in this order: the `model` passed to the Agent tool; else the agent definition's `model`; else `CLAUDE_CODE_SUBAGENT_MODEL`; else the session model. The built-in `Explore` and `Plan` definitions say `model: inherit`, which ends the lookup at step two. So with `CLAUDE_CODE_SUBAGENT_MODEL` set, a `general-purpose` subagent uses it, but `Explore` and `Plan` still run on the session model (`Explore` capped at opus). `Explore` is the subagent agents start most often, so this is where an expensive session model leaks into cheap searches.

A custom agent named `Explore` in `~/.claude/agents/` (user level) or `.claude/agents/` (project level) replaces the built-in one, model, prompt and tool limits included. Its `model` is then used as written. Verified on Claude Code 2.1.316; the resolution order is internal and may change, so on another version offer the proof run below.

## Check (read-only)

1. `command -v claude`. Not found: ✅ "not applicable".
2. Read `CLAUDE_CODE_SUBAGENT_MODEL` from the environment and from `env` in `~/.claude/settings.json`. Unset: ✅ "Explore follows the session model, like every other subagent".
3. Look for `Explore.md` with `name: Explore` in `~/.claude/agents/` and `.claude/agents/`.
   - Missing: ⚠️ "Explore and Plan ignore CLAUDE_CODE_SUBAGENT_MODEL=<value> and run on the session model".
   - Present: report where it is and its `model`. ⚠️ when it has no `model`, has `model: inherit`, or allows `Edit`, `Write` or `NotebookEdit`. Compare its `# checked-against:` version with `claude --version`; a different version is ⚠️ "offer the proof run".
4. `Plan.md` the same way, but only as information: a plan-mode subagent on the session model is usually what users want.

## Plan

Propose writing the template below to `~/.claude/agents/Explore.md`, or to `.claude/agents/Explore.md` when the user wants it for one project only. Ask which. Put the value of `CLAUDE_CODE_SUBAGENT_MODEL` in `model`. The user can change it to any value the Agent tool accepts, and fill in `checked-against` from `claude --version`. In the plan, say plainly:

- the file replaces the whole built-in definition, so its prompt is this template's and won't follow Claude Code updates;
- a single run can still pick another model by passing `model` to the Agent tool;
- sessions already running may keep the old definition until restarted.

Offer `Plan.md` only when the user asks for it.

## Write

1. If the target exists, copy it to `Explore.md.bak-<timestamp>` in the same directory.
2. Write the file, then read it back: the frontmatter parses, `name` is `Explore` and `model` is the planned value.

## Proof run (optional, costs a few tokens)

Run it only when the user agrees. In a new empty temp directory, run `claude -p` and ask it to start one `Explore` subagent through the Agent tool, without `model`, to list the directory. Then read that run's newest `~/.claude/projects/<temp-dir-slug>/<session>/subagents/*.meta.json`. ✅ when `isBuiltIn` is `false` and the `message.model` in the subagent's transcript is the model the alias resolves to. Otherwise ❌, with the values you saw. Delete the temp directory and its `projects` entry afterwards.

## Template

```markdown
---
name: Explore
description: Read-only search agent for broad fan-out searches, when answering means sweeping many files, directories or naming conventions and you only need the conclusion, not the file dumps. It locates code; it doesn't review or audit it. Give the breadth: "medium" for moderate exploration, "very thorough" for several locations and naming conventions.
disallowedTools: Agent, Edit, Write, NotebookEdit, ExitPlanMode
model: <model>
# Replaces the built-in Explore, whose model: inherit skips CLAUDE_CODE_SUBAGENT_MODEL.
# checked-against: Claude Code <version>
---
You are a read-only code search agent. Find what the caller asks for, quickly, and report it.

Never change anything: no creating, editing, moving or deleting files (temp files included), no shell redirects or heredocs into files, no installs, no git commands that write. Use Bash only for read-only commands such as ls, find, grep, cat, head, tail, git status, git log and git diff.

Use Glob and Grep, or find and grep, for broad searches, and Read when you know the path. Run independent searches in parallel. Match your depth to the breadth the caller gave.

Report the answer as your final message: paths with line numbers, short excerpts where they help, and what you could not find.
```
