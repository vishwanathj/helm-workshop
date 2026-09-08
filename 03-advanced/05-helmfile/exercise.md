# Exercise 5 · Manage Two Releases with One `helmfile.yaml`

Install Helmfile first if you haven't: `brew install helmfile`.

## Part A — set up

```bash
mkdir -p /tmp/helmfile-test
cp -R /path/to/01-basics/06-values-and-templates/solution/webapp-with-configmap /tmp/helmfile-test/webapp
cp -R /path/to/02-intermediate/04-chart-dependencies-and-subcharts/solution/greeter /tmp/helmfile-test/greeter
```

Create `/tmp/helmfile-test/helmfile.yaml`:
```yaml
releases:
  - name: webapp
    namespace: helm-advanced
    chart: ./webapp
    values:
      - replicaCount: 2
        html:
          message: "Hello from Helmfile-managed webapp!"

  - name: greeter
    namespace: helm-advanced
    chart: ./greeter
    values:
      - message: "Hello from Helmfile-managed greeter!"
```

## Part B — bring both releases up with one command

```bash
cd /tmp/helmfile-test
helmfile sync
```
Watch the output — Helmfile installs both `webapp` and `greeter` in one run. Confirm:
```bash
kubectl get deploy,svc,cm --namespace helm-advanced
helmfile list
```

## Part C — the diff-then-apply workflow

1. Install the `helm-diff` plugin (`apply`/`diff` need it; `sync` doesn't):
   ```bash
   helm plugin install https://github.com/databus23/helm-diff
   ```
   (If your Helm install complains about signature verification, add `--verify=false` — this workshop's local registry/plugin exercises have already been using unsigned, unverified sources for learning purposes.)

2. Change `replicaCount: 2` to `replicaCount: 3` in `helmfile.yaml`.

3. Preview the change across **both** releases without touching the cluster:
   ```bash
   helmfile diff
   ```
   You should see a unified diff showing `- replicas: 2` / `+ replicas: 3` under `webapp`'s Deployment — and nothing at all under `greeter`, since nothing about it changed.

4. Apply — and watch that only the changed release actually gets touched:
   ```bash
   helmfile apply
   ```
   The output should upgrade `webapp` but skip `greeter` entirely. Confirm:
   ```bash
   kubectl get deploy webapp --namespace helm-advanced
   ```
   `READY`/`UP-TO-DATE` should reflect 3 replicas.

5. Run `helmfile apply` again immediately, with no changes to the file:
   ```bash
   helmfile apply
   ```
   Nothing should be upgraded this time — both releases already match the file.

## Part D — tear both down together

```bash
helmfile destroy
kubectl get all --namespace helm-advanced
kubectl delete namespace helm-advanced
```

## Questions

<details>
<summary>Q1: Why did <code>helmfile sync</code> work without the <code>helm-diff</code> plugin installed, but <code>helmfile apply</code>/<code>helmfile diff</code> didn't?</summary>

`sync` unconditionally runs `helm upgrade --install` for every release — it never needs to know what would change, so it has nothing to compute a diff for. `apply` and `diff` both work by shelling out to `helm diff upgrade` under the hood (from the `helm-diff` plugin) to figure out what's actually different before deciding what to touch; without that plugin installed, that shell-out fails immediately.
</details>

<details>
<summary>Q2: In Part C step 4, why did <code>greeter</code> get skipped by <code>helmfile apply</code> even though it was included in the same <code>helmfile.yaml</code> run?</summary>

`apply` diffs every release independently before deciding what to touch. `greeter`'s values and chart hadn't changed since the last sync, so its diff came back empty, and `apply`'s whole point is to leave anything already in the desired state alone. `webapp` had an actual values change (`replicaCount`), so only it got upgraded. This is exactly the behavior that makes `apply` safe to run repeatedly (in a CI pipeline, say) without worrying about unnecessary rollouts.
</details>

<details>
<summary>Q3: What would you change in <code>helmfile.yaml</code> to reuse actual values files per environment (dev vs. prod) instead of the inline values shown here?</summary>

Replace the inline `values:` blocks with paths to real files, e.g. `values: [values-dev.yaml]` or `values: [values-prod.yaml]`, exactly the `custom-values.yaml` files you've already written throughout this workshop. Helmfile also supports an `environments:` block for switching which values files get loaded based on a named environment (`helmfile -e production apply`), which is the natural next step once you have more than one or two environments to juggle — out of scope for this lesson, but worth knowing the mechanism exists.
</details>

Next: [Lesson 6 · Chart Testing & CI](../06-chart-testing-and-ci/)
