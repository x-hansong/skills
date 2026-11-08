---
name: paseo-routed-guide
description: "Guide to the paseo-routed skill set: which of paseo-routed, implement-routed, implement-spec-routed or paseo-watch fits a situation, how worker/reviewer rosters work and how to switch them, and a guided first run. Use when the user asks how to use routed or Paseo delegation, which routed skill to pick, how to switch rosters or compare models, or is getting started."
license: MIT
compatibility: "Claude Code or Codex. Uses setup-paseo-routed for its readiness check."
metadata:
  author: x-hansong
---

# Paseo Routed guide

Help the user pick and use the right routed skill. Reply in the user's language. For a Chinese-speaking user, use the `.zh-CN.md` versions of the references.

Before telling the user what a skill does, read that skill's `SKILL.md`. The summaries here are for orientation only.

## 1. Check readiness first

Load the `setup-paseo-routed` skill in **check-only** mode (its `check` argument) and show its table. If any row the user's goal needs is not ✅, explain what's missing in one or two sentences and offer `/setup-paseo-routed` to fix it. Don't walk through a first run on a machine that isn't ready.

## 2. Answer the question

Use [scenarios](references/scenarios.md) ([中文](references/scenarios.zh-CN.md)) to:

- pick the skill for the user's situation;
- explain rosters and how to switch them;
- answer common questions.

Keep the answer to what the user asked; offer the rest.

## 3. Offer a guided first run

When the user is new, offer a small, safe first run in the current repo: a read-only research task through `paseo-routed`, for example "explain how <some module> works and where its tests are". Walk through what happens as it happens: roster resolution, the shared notes directory, the worker dispatch, acceptance. Afterwards show the same task with `--roster <another roster>` if they have one, and where the notes ended up.

Only run it when the user agrees; it starts real agents that cost tokens.
