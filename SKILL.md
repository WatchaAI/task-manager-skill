---
name: task-manager-skill
description: Manage tasks, plans, kanban workflow, and Task Manager Desktop data through task-manager-cli. Use when the user wants to inspect or change tasks, categories, statuses, people, locations, or subtasks in the shared desktop database.
---

# Task Manager Skill

Use this skill whenever the user asks to manage tasks/todos/plans, inspect Task Manager Desktop data, or use `task-manager-cli`.

## Quick Start

1. Ensure the CLI is installed:

```bash
scripts/install_task_manager_cli.sh
```

2. Probe the current command surface before doing non-trivial work:

```bash
tm --help
tm --json db
tm --json types
tm --json people
tm --json stats
```

3. Prefer `--json` for reads and writes that the agent needs to parse.

## Installation Behavior

The installer:

- Requires `node` and `npm`.
- Defaults to the local source at `~/Documents/coding/my/task-manager-cli`.
- If the local source is absent, clones `git@github.com:WatchaAI/task-manager-cli.git`.
- Can be overridden with `TASK_MANAGER_CLI_SOURCE`, which may be a local directory, a `.tgz` file, a git URL, or an npm-installable package/url.
- Builds from source with `npm ci` or `npm install`, runs `npm run build` when available, packs the project, then installs the tarball globally.
- Verifies `tm --help` and prints the active database path.

Useful overrides:

```bash
TASK_MANAGER_CLI_SOURCE=/path/to/task-manager-cli scripts/install_task_manager_cli.sh
TASK_MANAGER_CLI_SOURCE=git@github.com:WatchaAI/task-manager-cli.git scripts/install_task_manager_cli.sh
TASK_MANAGER_DB=/path/to/tasks.sqlite tm --json list
```

## Core Commands

Task types:

```bash
tm --json types
tm --json type add 工作
tm --json type rename 工作 客户项目
tm --json type move 客户项目 --before 日常
tm --json type delete 客户项目
```

Read tasks:

```bash
tm --json list
tm --json list --type 工作
tm --json list --status todo
tm --json list --status canceled
tm --json search 周报
tm --json board
tm --json stats
tm --json show 1
```

Write tasks:

```bash
tm --json add "写周报" --type 工作 --status todo --location "会议室" --person "张三" --subtask "列提纲"
tm --json update 1 --title "写本周周报" --description "整理关键进展" --type 客户项目
tm --json start 1
tm --json done 1
tm --json cancel 1
tm --json move 1 --status in_progress --after 2
tm --json delete 1
```

Subtasks:

```bash
tm --json subtask list 1
tm --json subtask add 1 "检查错别字"
tm --json subtask done 1 1
tm --json subtask todo 1 1
tm --json subtask toggle 1 1
tm --json subtask rename 1 1 "检查格式和错别字"
tm --json subtask delete 1 1
```

## Agent Operating Rules

- Install or update the CLI silently when `tm` is unavailable or fails basic self-check.
- For read-only requests, gather context with `types`, `list`, `board`, `stats`, or `search` and answer from the actual CLI output.
- For write requests, execute the needed CLI command directly when the user's intent is clear.
- Ask before bulk destructive actions, large deletes, or changes that could affect many tasks.
- Use `TASK_MANAGER_DB` or `--db` only when the user names a specific database or the default database is clearly wrong.
- After writes, run a focused read such as `show`, `list --status ...`, or `stats` to verify the result.
- If a command fails, run `tm --help` and adapt to the installed CLI surface instead of assuming this document is perfectly current.
- The shared status set is `todo`, `in_progress`, `done`, and `canceled`; use `cancel` for cancellation rather than deletion when the user wants to retain history.
- Task activity follows the desktop rule that unfinished tasks due two local calendar days ago or earlier are completed automatically. Rescheduling with `update --start ... --end ...` preserves the new dates and status.
- Do not edit the SQLite file directly. Current CLI writes maintain desktop cloud-sync IDs and deletion tombstones; bypassing it can cause deleted data to reappear after iCloud merge.

## Default Database

The CLI shares the Task Manager Desktop SQLite store. On macOS it checks:

- `~/Library/Application Support/Task Manager Desktop/tasks.sqlite`
- `~/Library/Application Support/task-manager-desktop/tasks.sqlite`
- `~/Library/Application Support/Task Manager/tasks.sqlite`
- `~/Library/Application Support/task-manager/tasks.sqlite`

Use `tm --json db` to see the active path.
