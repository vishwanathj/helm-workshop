# Exercise 6 · Override Values

Continue in `/tmp/webapp` from Lesson 5, with the `webapp` release still installed.

## Part A — quick override with `--set`

1. Bump the replica count with `--set`:
   ```bash
   helm upgrade webapp . --namespace helm-basics --set replicaCount=3
   ```
2. Confirm:
   ```bash
   kubectl get pods --namespace helm-basics
   ```
   You should now see 3 `webapp` pods.

## Part B — a values file for a "NodePort" environment

Imagine you want to expose this app differently for local testing — via `NodePort` instead of `ClusterIP` — while keeping replicaCount at 3.

1. Create `custom-values.yaml` in `/tmp/webapp` (a working copy is also at [solution/custom-values.yaml](solution/custom-values.yaml)):
   ```yaml
   replicaCount: 3

   service:
     type: NodePort
   ```
   Notice this file only needs the keys you're changing — everything else keeps its default from the chart's `values.yaml` (image repository/tag stay as-is).

2. Preview the change first, without applying it:
   ```bash
   helm upgrade webapp . --namespace helm-basics -f custom-values.yaml --dry-run --debug
   ```
   Look at the printed `COMPUTED VALUES` section — confirm `service.type: NodePort` and `replicaCount: 3` show up, and check the rendered `Service` manifest in the output.

3. Apply it for real:
   ```bash
   helm upgrade webapp . --namespace helm-basics -f custom-values.yaml
   ```

4. Confirm the Service type changed:
   ```bash
   kubectl get svc webapp --namespace helm-basics
   ```
   `TYPE` should now show `NodePort`, with a port in the 30000-32767 range listed under `PORT(S)`.

5. Confirm what values Helm now considers "set" for this release:
   ```bash
   helm get values webapp --namespace helm-basics
   ```

## Questions

<details>
<summary>Q1: Why didn't <code>custom-values.yaml</code> need to repeat <code>image.repository</code> and <code>image.tag</code>?</summary>

Values files are merged on top of the chart's default `values.yaml`, not used as a full replacement. Any key you don't mention keeps its default. This is why you only put the fields you actually want to change in an override file.
</details>

<details>
<summary>Q2: What's the risk of skipping <code>--dry-run</code> before an upgrade on a real (non-workshop) release?</summary>

Without previewing, a typo or wrong value (e.g., accidentally setting `replicaCount: 0`, or the wrong `image.tag`) gets applied directly to a live release, potentially causing an outage. `--dry-run --debug` lets you catch mistakes by reading the rendered manifests and computed values before anything changes in the cluster.
</details>

Next: [Lesson 7 · Upgrade, Rollback & Uninstall](../07-upgrade-rollback-uninstall/)
