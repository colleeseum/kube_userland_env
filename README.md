# kube_userland_env

Bootstrap scripts that prepare a fully stocked Kubernetes CLI "userland" on a fresh workstation. Running the included `setup.sh` installs the common cluster tooling, wires your shell configuration, and optionally enables a tmux workflow so that you can jump straight into cluster operations.

## What `setup.sh` does

- Detects your OS/architecture (Linux, macOS, or Git Bash/Cygwin) and creates `~/bin` if needed.
- Installs or refreshes the latest released versions of `kubectl`, `kubectx`/`kubens`, `kubetail`, `k9s`, `helm`, `terraform`, and the `mo` templating utility into `~/bin`.
- Installs Oh My Bash when zsh is unavailable, or installs Oh My Zsh + the Powerlevel10k theme when zsh is present. Both paths update your shell rc files to prepend `~/bin` to `PATH`, add `kubectl`/`helm` completion, and source the helper scripts in this repo.
- Creates symlinks so the repo-provided `kubectl.bash`, `start_tmux`, and `tmux.conf` are sourced from your home directory. If `$ACC_CLOUD` is set (Azure Confidential Computing), it also links `bash2zshrc` to auto-switch Bash sessions into zsh.
- Prompts for (and stores in `~/.jfrog`) the Artifactory credentials required by downstream tooling. Secrets stay on your machine.
- Optionally configures tmux by asking whether to link `start_tmux`/`tmux.conf` and source it from your shell rc file.
- Sources `../infra/env.sh` as `~/.env`, so keep the companion `infra` repo checked out next to this one.
- If the `$ACC_CLOUD` environment variable is set, warns when you run against a private AKS cluster (kubectl/helm would fail) and asks if you still want to proceed.

> The script is idempotent: re-running it updates binaries or recreates symlinks when needed, but it never tries to uninstall existing tools.

## Prerequisites

- A POSIX-like shell environment (macOS, Linux, or Windows Git Bash/Cygwin/MSYS2).
- `curl`, `tar`, `gzip`, `git`, and `unzip` available in `PATH`.
- Network access to GitHub, Google Cloud Storage (for `kubectl`), and your organization's Artifactory.
- Optional: `tmux` if you plan to take advantage of the auto-attach behavior from `start_tmux`.
- If you need to bootstrap Azure ACC private clusters, ensure you understand the kubectl/helm limitations noted above.

## Usage

```bash
git clone <this repo> ~/clone/kube_userland_env
cd ~/clone/kube_userland_env
./setup.sh
```

During the run you may be asked to confirm the following:

1. **Private AKS detection** – only when `$ACC_CLOUD` is exported; answer `n` to abort.
2. **Artifactory credentials** – only the first time; credentials are stored under `~/.jfrog`.
3. **tmux integration** – select `y` to have `start_tmux` auto-attach to a `main` session whenever your shell starts.

When the script finishes it restarts your shell (`exec bash` or `exec zsh`) so the new configuration takes effect immediately.

## Repository layout

- `setup.sh` – orchestrator described above.
- `kubectl.bash` – skinny file that adds kubectl aliases plus tab completion for both kubectl and the aliases themselves.
- `start_tmux` and `tmux.conf` – starter tmux session management and default configuration.
- `bash2zshrc` – helper sourced from `.bashrc` inside ACC cloud shells so Bash invokes zsh once it is installed.

Keep this repository checked out; the symlinks created in your home directory reference these files directly.

## Verifying the installation

- Run `which kubectl helm k9s terraform` to confirm each binary resolves to `~/bin/*`.
- Open a new terminal and ensure you see the Oh My Bash/Oh My Zsh prompt with Powerlevel10k (if applicable).
- Execute `k version` or any alias from `kubectl.bash` to verify the completions were sourced.
- If you opted into tmux, open a new shell and confirm you attach to the `main` session automatically.

If any tool is missing, simply rerun `./setup.sh` after fixing the prerequisite (for example installing `tmux` or exporting `ACC_CLOUD`) and it will fill in the gaps.
