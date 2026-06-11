# Task Manager Skill

Agent skill for operating the Task Manager system from Codex, Claude, or other skill-aware agents.

This repository is one part of the Task Manager toolchain:

- [Task Manager Desktop](https://github.com/WatchaAI/task-manager-desktop): Electron desktop app for the visual kanban/task board.
- [Task Manager CLI](https://github.com/WatchaAI/task-manager-cli): command line interface that reads and writes the same SQLite database as the desktop app.
- [Task Manager Skill](https://github.com/WatchaAI/task-manager-skill): agent-facing skill that installs the CLI, discovers its command surface, and uses it to manage tasks automatically.

## What This Skill Does

After installation, an agent can:

- Install or update `task-manager-cli` automatically.
- Locate the active Task Manager SQLite database.
- Read task types, lists, boards, details, and statistics.
- Add, update, move, start, complete, and delete tasks.
- Manage task types and subtasks.
- Prefer JSON output so task state can be parsed reliably.

## Repository Layout

```text
.
├── SKILL.md
├── agents/
│   └── openai.yaml
└── scripts/
    └── install_task_manager_cli.sh
```

## Install the Skill

Clone this repository into your local skills directory:

```bash
git clone git@github.com:WatchaAI/task-manager-skill.git ~/.agents/skills/task-manager-skill
```

If you also use Claude skills, create a symlink:

```bash
mkdir -p ~/.claude/skills
ln -s ~/.agents/skills/task-manager-skill ~/.claude/skills/task-manager-skill
```

## Install or Update the CLI

The skill includes an installer that builds and installs the CLI:

```bash
~/.agents/skills/task-manager-skill/scripts/install_task_manager_cli.sh
```

By default, the installer can use the official CLI repository:

```bash
TASK_MANAGER_CLI_SOURCE=git@github.com:WatchaAI/task-manager-cli.git \
  ~/.agents/skills/task-manager-skill/scripts/install_task_manager_cli.sh
```

It also accepts a local directory, a `.tgz` file, a git URL, or any npm-installable package reference:

```bash
TASK_MANAGER_CLI_SOURCE=/path/to/task-manager-cli \
  ~/.agents/skills/task-manager-skill/scripts/install_task_manager_cli.sh
```

## Agent Usage

Ask the agent to use the skill:

```text
Use $task-manager-skill to show my current task board.
Use $task-manager-skill to add a work task for writing the weekly report.
Use $task-manager-skill to move task 12 to in progress and add a subtask.
```

The skill instructs the agent to run command probes before non-trivial work:

```bash
tm --help
tm --json db
tm --json types
tm --json stats
```

Common CLI operations:

```bash
tm --json list
tm --json board
tm --json stats
tm --json add "Write weekly report" --type Work --status todo
tm --json start 1
tm --json done 1
tm --json subtask add 1 "Check numbers"
```

## Shared Data Model

The desktop app and CLI share the same local SQLite database. The skill does not define its own task store; it delegates all task operations to [task-manager-cli](https://github.com/WatchaAI/task-manager-cli), which is compatible with [task-manager-desktop](https://github.com/WatchaAI/task-manager-desktop).

Use a custom database when needed:

```bash
TASK_MANAGER_DB=/path/to/tasks.sqlite tm --json list
tm --db /path/to/tasks.sqlite --json stats
```
