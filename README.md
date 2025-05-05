# git-pull-all

A small, dependency‑free Bash script that **recursively** finds every Git repository under a target folder and executes  
`git pull --ff-only` on **each local branch that tracks a remote**.  

Version 2 introduces **parallel execution**: multiple repositories are updated at the same time, while branches inside each repo are still pulled sequentially to avoid lock‑ups.

## Key Features

| Feature | Notes |
|---------|-------|
| Recursive scan | No need to list projects by hand. |
| Fast‑forward only | Prevents interactive merge prompts in automation. |
| Error‑tolerant | Failures are recorded and reported; the loop never stops early. |
| Parallel jobs | Adjustable – choose how many repositories run at once (default **4**). |
| Portable Bash | Runs on macOS default **Bash 3.2** and any modern Linux Bash 4/5. |
| Zero dependencies | Requires only `bash` and `git` in your `$PATH`. |

## Installation

```bash
git clone https://github.com/<you>/git-pull-all.git
cd git-pull-all
chmod +x git_pull_all.sh    # one‑time
```

## Usage

```bash
# Basic invocation – scans ~/git, 4 parallel jobs
./git_pull_all.sh

# Custom root directory
./git_pull_all.sh /path/to/root

# Custom concurrency: 8 parallel jobs
./git_pull_all.sh /path/to/root 8
```

**Arguments**

| Position | Meaning | Default |
|----------|---------|---------|
| `$1` | Root directory to scan | `$HOME/git` |
| `$2` | Maximum concurrent repositories | `4` |

## Output Example

```
>> Queuing  /Users/me/git/project‑a
>> Queuing  /Users/me/git/project‑b
>> Queuing  /Users/me/git/project‑c
 …⏳ …

==================== PULL REPORT ====================
---- FAILED PULLS ----
/Users/me/git/project‑b:feature/legacy‑hotfix

---- SUCCESSFUL PULLS ----
/Users/me/git/project‑a:main
/Users/me/git/project‑a:develop
=====================================================
```

## Notes & Limitations

* Branches **without** tracking information are skipped.  
* Uncommitted changes that block a checkout are logged as failures.  
* The script does **not** stash, merge, or resolve conflicts for you.  
* Parallelism is controlled with background jobs and two append‑only log files; there is no shared state race condition.

## License

MIT – see `LICENSE`.