# Prerequisites

Set these up before starting [Lesson 1](../01-basics/01-what-is-helm/). All commands assume macOS with [Homebrew](https://brew.sh).

## 1. A container runtime: Docker or Podman

`kind` (Kubernetes IN Docker) runs a real Kubernetes cluster inside containers, so a container runtime must be installed and running first. Pick one:

### Option A — Docker Desktop (simplest, most common)

- Download and install: https://www.docker.com/products/docker-desktop/
- Start Docker Desktop and wait until it says it's running.
- Verify:
  ```bash
  docker info
  ```
  If this prints cluster/system info without errors, you're good. Skip to [2. kubectl](#2-kubectl).

### Option B — Podman (open-source alternative, no Docker account needed)

- **Apple Silicon Macs**: `brew install podman` works directly.
- **Intel Macs**: Homebrew's `podman` formula (v6+) dropped Intel support. Instead, download the last Intel-compatible installer from the [containers/podman v5.8.6 release](https://github.com/containers/podman/releases/tag/v5.8.6) — the `podman-installer-macos-universal.pkg` asset — and run it (it opens the standard macOS Installer app).
- After installing, initialize and start the VM, then verify:
  ```bash
  podman machine init
  podman machine start
  podman run --rm hello-world
  ```
- `kind` doesn't use Podman by default — tell it to with an environment variable, every time you run a `kind` command in a new shell (or add it to your shell profile):
  ```bash
  export KIND_EXPERIMENTAL_PROVIDER=podman
  ```

## 2. kubectl

```bash
brew install kubectl
kubectl version --client
```

## 3. kind

```bash
brew install kind
kind version
```

## 4. Helm

```bash
brew install helm
helm version
```

## 5. Create your workshop cluster

You'll use one `kind` cluster throughout the Basics module.

If you're using Podman (Option B above), make sure `export KIND_EXPERIMENTAL_PROVIDER=podman` is set in this shell first.

```bash
kind create cluster --name helm-workshop
kubectl cluster-info --context kind-helm-workshop
kubectl get nodes
```

You should see a single node in `Ready` status. Keep this cluster running for the whole workshop — Lesson 7 (upgrade/rollback) tells you when it's safe to delete it:

```bash
# only when you're done with the whole Basics module
kind delete cluster --name helm-workshop
```

## Checklist

- [ ] `docker info` (Docker) or `podman run --rm hello-world` (Podman) works
- [ ] `kubectl version --client` works
- [ ] `kind version` works
- [ ] `helm version` works
- [ ] `kubectl get nodes` shows a `Ready` node named something like `helm-workshop-control-plane`

Once all boxes are checked, head to [01-basics](../01-basics/).
