# tsk

> **Opinionated fork of [dots](https://github.com/joelreymont/dots) - Fast, minimal task tracking with plain markdown files**

Minimal task tracker for AI coding agents.

## What is tsk?

A CLI task tracker with **zero dependencies** — tasks are plain markdown files with YAML frontmatter in `.tsk/`. No database, no server, no configuration. Copy the folder between machines, commit to git, edit with any tool. Parent-child relationships map to folders. Each task has an ID, title, status, and optional dependencies.

## Installation

### Homebrew

```bash
brew install mikekelly/acp/tsk
```

### From source (requires Zig 0.15+)

```bash
git clone https://github.com/mikekelly/tsk.git
cd tsk
zig build -Doptimize=ReleaseSmall
cp zig-out/bin/tsk ~/.local/bin/
```

### Verify installation

```bash
tsk --version
# Output: tsk 0.6.3
```

## Quick Start

```bash
# Initialize in current directory
tsk init
# Creates: .tsk/ directory (added to git if in repo)

# Add a task
tsk add "Fix the login bug"
# Output: tsk-a1b2c3d4e5f6a7b8

# List tasks
tsk ls
# Output: [a1b2c3d] o Fix the login bug

# Start working
tsk on a1b2c3d
# Output: (none, task marked active)

# Complete task
tsk off a1b2c3d -r "Fixed in commit abc123"
# Output: (none, task marked done and archived)
```

## Command Reference

### Initialize

```bash
tsk init
```
Creates `.tsk/` directory. Runs `git add .tsk` if in a git repository. Safe to run if already exists.

### Add Task

```bash
tsk add "title" [-d "description"] [-P PARENT_ID] [-a AFTER_ID] [--json]
tsk "title"  # shorthand for: tsk add "title"
```

Options:
- `-d "text"`: Long description (markdown body of the file)
- `-P ID`: Parent task ID (creates folder hierarchy)
- `-a ID`: Blocked by task ID (dependency)
- `--json`: Output created task as JSON

Examples:
```bash
tsk add "Design API"
# Output: tsk-1a2b3c4d

tsk add "Implement API" -a tsk-1a2b3c4d -d "REST endpoints for user management"
# Output: tsk-3c4d5e6f

tsk add "Write tests" --json
# Output: {"id":"tsk-5e6f7a8b","title":"Write tests","status":"open",...}
```

### List Tasks

```bash
tsk ls [--status STATUS] [--json]
```

Options:
- `--status`: Filter by `open`, `active`, or `done` (default: shows open + active)
- `--json`: Output as JSON array

Output format (text):
```
[1a2b3c4] o Design API        # o = open
[3c4d5e6] > Implement API     # > = active
[5e6f7a8] x Write tests       # x = done
```

### Start Working

```bash
tsk on <id> [id2 ...]
```
Marks task(s) as `active`. Use when you begin working on tasks. Supports short ID prefixes.

### Complete Task

```bash
tsk off <id> [id2 ...] [-r "reason"]
```
Marks task(s) as `done` and archives them. Optional reason applies to all. Root tasks are moved to `.tsk/archive/`. Child tasks wait for parent to close before moving.

### Show Task Details

```bash
tsk show <id>
```

Output:
```
ID:       tsk-1a2b3c4d
Title:    Design API
Status:   open
Desc:     REST endpoints for user management
Created:  2024-12-24T10:30:00Z
```

### Remove Task

```bash
tsk rm <id> [id2 ...]
```
Permanently deletes task file(s). If removing a parent, children are also deleted.

### Show Ready Tasks

```bash
tsk ready [--json]
```
Lists tasks that are `open` and have no blocking dependencies (or blocker is `done`).

### Show Hierarchy

```bash
tsk tree [id]
```

Without arguments: shows all open root tasks and their children.
With `id`: shows that specific task's tree (including closed children).

Output:
```
[1a2b3c4] o Build auth system
  +- [2b3c4d5] o Design schema
  +- [3c4d5e6] o Implement endpoints (blocked)
  +- [4d5e6f7] o Write tests (blocked)
```

### Fix Orphans

```bash
tsk fix
```
Promotes orphaned children to root and removes missing parent folders.

### Search Tasks

```bash
tsk find "query"
```
Case-insensitive search across title, description, close-reason, created-at, and closed-at. Shows open tasks first, then archived.

### Purge Archive

```bash
tsk purge
```
Permanently deletes all archived (completed) tasks from `.tsk/archive/`.

## Storage Format

Tasks are stored as markdown files with YAML frontmatter in `.tsk/`:

```
.tsk/
  a1b2c3d4e5f6a7b8.md              # Root task (no children)
  f9e8d7c6b5a49382/                # Parent with children
    f9e8d7c6b5a49382.md            # Parent task file
    1a2b3c4d5e6f7890.md            # Child task
  archive/                          # Closed tasks
    oldtask12345678.md             # Archived root task
    oldparent1234567/              # Archived tree
      oldparent1234567.md
      oldchild23456789.md
  config                            # ID prefix setting
```

### File Format

```markdown
---
title: Fix the bug
status: open
issue-type: task
assignee: joel
created-at: 2024-12-24T10:30:00Z
blocks:
  - a3f2b1c8
---

Description as markdown body here.
```

### ID Format

IDs have the format `{prefix}-{hex}` where:
- `prefix`: Project prefix from `.tsk/config` (default: `tsk`)
- `hex`: 8-character random hex suffix

Example: `tsk-a3f2b1c8`

Commands accept short prefixes:

```bash
tsk on a3f2b1    # Matches tsk-a3f2b1c8
tsk show a3f     # Error if ambiguous (multiple matches)
```

### Status Flow

```
open -> active -> done (archived)
```

- `open`: Task created, not started
- `active`: Currently being worked on
- `done`: Completed, moved to archive

### Dependencies

- `parent (-P)`: Creates folder hierarchy. Parent folder contains child files.
- `blocks (-a)`: Stored in frontmatter. Task blocked until all blockers are `done`.

### Archive Behavior

When a task is marked done:
- **Root tasks**: Immediately moved to `.tsk/archive/`
- **Child tasks**: Stay in parent folder until parent is closed
- **Parent tasks**: Only archive when ALL children are closed (moves entire folder)

## License

MIT
