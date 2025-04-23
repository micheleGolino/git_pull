# git-pull-all

A tiny Bash utility that walks a directory tree, finds every Git repository, and runs  
`git pull --ff-only` on **each local branch that tracks a remote**.  
All errors are logged; the script never stops on a problem.

---

## Features

* **Recursive scan** – no need to list projects manually.  
* **Fast-forward only** – avoids interactive merge prompts during automation.  
* **Error-tolerant** – failures are recorded and shown later, never halt the loop.  
* **macOS-ready** – works on the default Bash 3.2 that ships with macOS.  
* **Zero dependencies** – requires only `bash` and `git` in your `PATH`.

---

## Usage

```bash
# 1) Make the script executable
chmod +x git_pull_all.sh

# 2) Run it

#   a) Default root folder ($HOME/git)
./git_pull_all.sh

#   b) Custom root folder
./git_pull_all.sh /path/to/root/folder
