# Plugin source types reference

Detailed reference for all plugin source types in marketplace.json.

## Source type comparison

| Source type | Format | Use case | Works with URL-based marketplace? |
|---|---|---|---|
| Relative path | string | Plugins in the same repository | No (git-based only) |
| GitHub | object | Plugins hosted on GitHub | Yes |
| Git URL | object | Plugins on GitLab, Bitbucket, or self-hosted git | Yes |

## Relative paths

Simplest option for monorepo marketplaces where plugins live alongside the marketplace file.

```json
{
  "name": "my-plugin",
  "source": "./plugins/my-plugin"
}
```

**Rules**:
- Must be relative to the marketplace repository root
- Cannot use `../` (path traversal is blocked)
- Only works when users add the marketplace via Git (not URL-based)

**With `metadata.pluginRoot`**:
```json
{
  "metadata": { "pluginRoot": "./plugins" },
  "plugins": [
    { "name": "a", "source": "a" },
    { "name": "b", "source": "b" }
  ]
}
```

## GitHub repositories

For plugins hosted as separate GitHub repositories.

### Basic

```json
{
  "name": "github-plugin",
  "source": {
    "source": "github",
    "repo": "owner/plugin-repo"
  }
}
```

### With version pinning

```json
{
  "name": "github-plugin",
  "source": {
    "source": "github",
    "repo": "owner/plugin-repo",
    "ref": "v2.0.0",
    "sha": "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0"
  }
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `source` | string | Yes | Must be `"github"` |
| `repo` | string | Yes | GitHub repository in `owner/repo` format |
| `ref` | string | No | Git branch or tag (defaults to repository default branch) |
| `sha` | string | No | Full 40-character git commit SHA for exact version pinning |

**Best practices**:
- Use `ref` with semantic version tags (e.g., `"v2.0.0"`) for reproducible installs
- Use `sha` when you need absolute certainty about the exact code version
- Omit both for "latest from default branch" behavior

## Git URL repositories

For plugins on GitLab, Bitbucket, self-hosted Gitea, or any git server.

### Basic

```json
{
  "name": "git-plugin",
  "source": {
    "source": "url",
    "url": "https://gitlab.com/team/plugin.git"
  }
}
```

### With version pinning

```json
{
  "name": "git-plugin",
  "source": {
    "source": "url",
    "url": "https://gitlab.com/team/plugin.git",
    "ref": "main",
    "sha": "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0"
  }
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `source` | string | Yes | Must be `"url"` |
| `url` | string | Yes | Full git repository URL (must end with `.git`) |
| `ref` | string | No | Git branch or tag (defaults to repository default branch) |
| `sha` | string | No | Full 40-character git commit SHA for exact version pinning |

## Hosting and distribution

### GitHub (recommended)

Easiest distribution: push marketplace repo to GitHub, users add with:

```
/plugin marketplace add owner/repo
```

### Other git services

```
/plugin marketplace add https://gitlab.com/company/plugins.git
```

### Local testing

```
/plugin marketplace add ./my-local-marketplace
/plugin install test-plugin@my-local-marketplace
```

## Private repository authentication

### Manual install/update

Uses existing git credential helpers. If `git clone` works in your terminal, it works in Claude Code. Common helpers:
- `gh auth login` for GitHub
- macOS Keychain
- `git-credential-store`

### Background auto-updates

Set authentication tokens in your shell environment:

| Provider | Environment variables | Notes |
|---|---|---|
| GitHub | `GITHUB_TOKEN` or `GH_TOKEN` | Personal access token or GitHub App token |
| GitLab | `GITLAB_TOKEN` or `GL_TOKEN` | Personal access token or project token |
| Bitbucket | `BITBUCKET_TOKEN` | App password or repository access token |

```bash
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
```

**Scopes required**:
- GitHub: `repo` scope for private repositories
- GitLab: `read_repository` scope at minimum
