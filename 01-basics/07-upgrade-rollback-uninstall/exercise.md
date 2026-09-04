# Exercise 7 · Break It, Then Fix It

Continue in `/tmp/webapp` with the `webapp` release from Lessons 5-6 (currently at revision 2, `replicaCount: 3`, `service.type: NodePort`).

## Part A — check the history so far

```bash
helm history webapp --namespace helm-basics
```
You should see at least 2 revisions: `1` (initial install) and `2` (the NodePort/replicaCount upgrade), both `deployed`/`superseded` as appropriate.

## Part B — ship a bad change on purpose

1. Edit `values.yaml` in `/tmp/webapp` and set the image tag to something that doesn't exist:
   ```yaml
   image:
     repository: nginx
     tag: "this-tag-does-not-exist"
   ```

2. Upgrade:
   ```bash
   helm upgrade webapp . --namespace helm-basics
   ```
   Helm itself will report success (the Deployment object was updated) — but watch the pods:
   ```bash
   kubectl get pods --namespace helm-basics
   ```
   You should see a pod stuck in `ErrImagePull` or `ImagePullBackOff` — Kubernetes can't find that image tag.

3. Check the release history again:
   ```bash
   helm history webapp --namespace helm-basics
   ```
   Revision 3 shows as `deployed` from Helm's point of view (the manifest was applied), even though the app is actually broken. **This is an important, easy-to-miss lesson: `helm upgrade` succeeding does not mean your application is healthy** — you still need to check pod status.

## Part C — roll back

1. Roll back to the last known-good revision (2):
   ```bash
   helm rollback webapp 2 --namespace helm-basics
   ```
2. Confirm recovery:
   ```bash
   kubectl get pods --namespace helm-basics
   ```
   Pods should return to `Running`/`1/1`.
3. Check history again — notice rollback itself creates a *new* revision (4), it doesn't delete revision 3:
   ```bash
   helm history webapp --namespace helm-basics
   ```

## Part D — try `--rollback-on-failure` (optional, recommended)

Repeat the bad upgrade from Part B, but this time with `--rollback-on-failure`, and watch Helm roll back for you automatically on failure. (You may see this flag called `--atomic` in older docs/tutorials — same behavior, `--atomic` is now a deprecated alias that still works but prints a warning.)
```bash
helm upgrade webapp . --namespace helm-basics --set image.tag=this-tag-does-not-exist --rollback-on-failure --timeout 1m
```
This will fail after the timeout (since the pod never becomes ready) and Helm will revert automatically — check `helm history` afterward to see this behavior.

Set `image.tag` back to `"1.25"` in `values.yaml` before continuing, so the chart directory is clean.

## Part E — uninstall and clean up

1. Uninstall the release:
   ```bash
   helm uninstall webapp --namespace helm-basics
   ```
2. Confirm everything's gone:
   ```bash
   kubectl get all --namespace helm-basics
   ```
3. Optional — only if you're completely done with the whole Basics module — delete the cluster:
   ```bash
   kind delete cluster --name helm-workshop
   ```

## Questions

<details>
<summary>Q1: After the bad upgrade in Part B, why did <code>helm upgrade</code> report success even though the app was broken?</summary>

Helm's job is to render templates and apply the resulting manifests to the Kubernetes API — that API call (updating the Deployment object) succeeded. Whether the *resulting pods* actually become healthy is a separate, asynchronous process handled by Kubernetes' scheduler and kubelet. Helm doesn't wait for or verify pod health unless you pass `--wait` (and `--rollback-on-failure` implies `--wait` plus auto-rollback on failure).
</details>

<details>
<summary>Q2: Does <code>helm rollback</code> delete the bad revision from history?</summary>

No. Rollback creates a *new* revision whose content matches the target revision you rolled back to. The full history (including the broken revision) is preserved, so you always have an audit trail of what was deployed and when.
</details>

---

**Basics module complete.** Intermediate topics (dependencies/subcharts, hooks, packaging & chart repos, `helm lint`/`helm test` in depth) land in [02-intermediate](../../02-intermediate/) — coming soon.
