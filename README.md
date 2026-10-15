# dotclaude-sync

A Claude Code plugin. It keeps a backup of your `~/.claude` folder in a private GitHub repository.

> **Language:** This document uses ASD-STE100 Simplified Technical English.

---

## 1. Purpose

Your `~/.claude` folder has your Claude Code configuration: settings, instructions, skills, hooks and memory notes.
These files change frequently. Claude and its helpers change some of them automatically.

This plugin keeps each change in git and sends it to a private GitHub repository. Thus:

- You can see each change and undo it.
- You can use the same configuration on a different computer.
- Your teammates can use the same plugin for their own backups.

---

## 2. Prerequisites

1. Make sure that Claude Code is installed. Type `claude --version`.
2. Make sure that `git` and `jq` are installed.
3. Make sure that the GitHub CLI is logged in. Type `gh auth status`.

**NOTE:** The plugin does not ask for GitHub credentials. It uses your current `gh` login.

---

## 3. Installation

1. In a terminal, start `claude`.
2. Type this command:

```text
/plugin install dotclaude-sync --marketplace oiegorov-embrace/dotclaude-sync
```

3. Answer `y` to add the marketplace.
4. Select the **user** scope.
5. In the settings form, leave **Backup repository** empty, or type `owner/name`.

**NOTE:** The Code tab of the Claude desktop app cannot install plugins. Install the plugin in a terminal. The desktop app then uses it in local sessions.

---

## 4. Setup

**CAUTION:** Use a private repository only. The setup stops if the repository is public.

1. In a Claude Code session, type `/dotclaude-sync:setup`.
2. To use a specific repository, type `/dotclaude-sync:setup owner/name`.

The setup does these steps:

1. It makes sure that `gh` is logged in.
2. It examines the repository. The repository must be private and empty, or it must not exist.
3. It makes `~/.claude` a git repository and adds the whitelist [`.gitignore`](templates/gitignore).
4. It examines the files for secrets. If it finds a possible secret, it stops and makes no commit.
5. It makes the first commit.
6. If the repository does not exist, it makes a new private repository.
7. It pushes the commit and shows the list of files in the backup.

**NOTE:** If `~/.claude/.gitignore` exists, the setup keeps it. Compare it with [`templates/gitignore`](templates/gitignore).

**NOTE:** The setup does not restore files from a repository that has content. It stops with a message.

---

## 5. What the backup contains

The [`.gitignore`](templates/gitignore) is a whitelist. Git ignores all files in `~/.claude`, except these:

| Included | Not included |
| --- | --- |
| `CLAUDE.md`, `settings.json`, `keybindings.json` | Session transcripts (`projects/*/*.jsonl`) |
| `hooks/`, `agents/`, `commands/`, `rules/`, `output-styles/` | Prompt history (`history.jsonl`) |
| `skills/` (not `skills/synced/`) | Shell and environment snapshots |
| `scheduled-tasks/` | Caches, logs, telemetry, backups |
| Memory notes (`projects/*/memory/`) | Plugin downloads |
| `plugins/known_marketplaces.json` | All new files, until you add them to the whitelist |

To add a file or folder, add a line `!/<name>` to `~/.claude/.gitignore`.
To keep memory notes local, remove the three lines under "Memory notes".

---

## 6. How it works

| Event | Hook | Script | Result |
| --- | --- | --- | --- |
| Session start | `SessionStart` | [`session-start.sh`](scripts/session-start.sh) | If the setup is not done, Claude tells you to do it. |
| Each Claude reply | `Stop` | [`autosave.sh`](scripts/autosave.sh) | Commits the changes and pushes them in the background. |
| Each user message | `UserPromptSubmit` | [`notices.sh`](scripts/notices.sh) | Gives Claude the notes from autosave, if there are notes. |
| `/dotclaude-sync:setup` | Skill | [`setup.sh`](scripts/setup.sh) | Connects `~/.claude` to the repository. |
| `/dotclaude-sync:status` | Skill | [`status.sh`](scripts/status.sh) | Shows the backup state. |

The autosave sequence:

1. Claude finishes a reply. The `Stop` hook starts `autosave.sh`. The hook stops immediately.
2. The script adds the changes in the whitelist.
3. The script examines the new lines for secrets. If it finds a possible secret, it makes no commit. It writes a note.
4. The script makes a commit. The commit message has the names of the changed files.
5. If the local branch has commits that GitHub does not have, the script pushes them.
6. If the push fails, the script writes a note one time. The next autosave tries the push again.
7. On your next message, `notices.sh` gives the notes to Claude. Claude tells you about each note.

---

## 7. Settings

| Setting | Where | Default | Effect |
| --- | --- | --- | --- |
| `repo` | Plugin settings (`/config`) | `<gh login>/claude-config` | Repository for the setup |
| `DOTCLAUDE_SYNC_DISABLE=1` | Environment variable | Not set | Stops the autosave |

---

## 8. Troubleshooting

| Symptom | Possible cause | Action |
| --- | --- | --- |
| `SETUP FAILED: gh is not logged in` | No `gh` login | Type `gh auth login` in a terminal. Then do the setup again. |
| `SETUP FAILED: ... is not private` | The repository is public | Use a different repository name. |
| `SETUP FAILED: ... already has content` | The repository is not empty | Use a different repository name. Restore is not available. |
| Note: "autosave stopped" | A change looks like a secret | Remove the secret from the file. The next autosave continues. |
| Note: "push ... failed" | No access to the repository | Type `gh auth status`. Read the log in the plugin data folder. |
| No commits after a change | The file is not in the whitelist | Add the file to `~/.claude/.gitignore`. |

To see the backup state, type `/dotclaude-sync:status`.

---

## 9. Files

```text
dotclaude-sync/
├── .claude-plugin/
│   ├── plugin.json          Plugin manifest and the "repo" setting
│   └── marketplace.json     Lets you install the plugin from this repository
├── hooks/hooks.json         Registers the three hooks
├── scripts/                 Hook and skill scripts (section 6)
├── skills/
│   ├── setup/SKILL.md       /dotclaude-sync:setup
│   └── status/SKILL.md      /dotclaude-sync:status
└── templates/gitignore      Whitelist for ~/.claude
```

## License

MIT. See [LICENSE](LICENSE).
