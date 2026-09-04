# Lesson 2 · Install & Setup

If you completed [Prerequisites](../../docs/prerequisites.md), your tools and cluster are already in place. This lesson is a short exercise to prove the whole chain works end to end before you install anything real.

## Exercise

1. Confirm your cluster is up and Helm can talk to it:
   ```bash
   kubectl config current-context
   ```
   This should print `kind-helm-workshop`. If it doesn't, switch to it:
   ```bash
   kubectl config use-context kind-helm-workshop
   ```

2. Helm has no separate server component (unlike old Helm 2 with Tiller) — it talks directly to the cluster via your kubeconfig. Confirm it's installed and check the version:
   ```bash
   helm version
   ```
   You should see a `version.BuildInfo{Version:"v...` string with no errors (Homebrew installs whatever the current major version is — this workshop's commands work the same on Helm 3 or Helm 4).

3. List releases (should be empty — you haven't installed anything yet):
   ```bash
   helm list
   ```
   Expected output: just column headers, no rows.

4. List what's currently running in the cluster with plain kubectl, to compare against later once you start installing charts:
   ```bash
   kubectl get pods -A
   ```
   You'll see only system pods (`kube-system` namespace, `local-path-storage`, etc.) — nothing of yours yet.

<details>
<summary>Solution / expected results</summary>

- `kubectl config current-context` → `kind-helm-workshop`
- `helm version` → a version string like `v4.x.x` (or `v3.x.x`), no errors
- `helm list` → empty table with headers `NAME NAMESPACE REVISION UPDATED STATUS CHART APP VERSION`
- `kubectl get pods -A` → only system namespace pods, no errors connecting to the cluster

If any command fails, revisit [Prerequisites](../../docs/prerequisites.md) — most issues at this stage are a Docker Desktop that isn't running, or `kind create cluster` not having been run.
</details>

Next: [Lesson 3 · Helm Basic Commands](../03-helm-basic-commands/)
