# Lesson 5 · Helm Hooks

A hook is an ordinary Kubernetes resource (almost always a `Job` or a `Pod`) that Helm creates and waits on at a specific point in a release's lifecycle — before or after install/upgrade/delete/rollback — instead of as part of the release's regular tracked resources.

## Declaring a hook

Any resource becomes a hook purely through an annotation:

```yaml
metadata:
  annotations:
    helm.sh/hook: pre-upgrade
```

Available hook points: `pre-install`, `post-install`, `pre-upgrade`, `post-upgrade`, `pre-rollback`, `post-rollback`, `pre-delete`, `post-delete`, and `test` (Lesson 6). A resource can declare more than one, comma-separated — `helm.sh/hook: post-install,post-upgrade` runs the same Job after either an initial install or a later upgrade.

## Ordering and cleanup

Two more annotations control the details:

- **`helm.sh/hook-weight`** — a string-encoded integer. Hooks for the same hook point run in ascending weight order (ties broken by name), so `"0"` runs before `"5"`. This is how you sequence multiple hooks on the same event.
- **`helm.sh/hook-delete-policy`** — what to do with the hook resource afterward. `before-hook-creation` (delete any leftover hook resource from a previous release action before creating a new one — the safest default, since Job names are fixed and Kubernetes won't let you recreate a Job with the same name while the old one still exists) and `hook-succeeded` (delete it right after it completes successfully, but leave a failed one behind for you to inspect with `kubectl logs`) are the two you'll use most. Without any delete policy, hook resources are left in the cluster indefinitely.

## What actually happens during `helm upgrade`

1. Helm renders the hook's manifest and creates it in the cluster.
2. Helm **waits** for it to reach a ready/completed state (for a `Job`, that means `Complete`) before moving on.
3. Only then does Helm proceed — to the next-weighted hook at the same hook point, or to applying the release's regular resources.

Critically: **if a hook fails, Helm aborts the whole operation.** A `pre-upgrade` hook that fails means the upgrade never touches your Deployment/Service/ConfigMap at all — the release stays exactly as it was. This makes hooks a legitimate (if blunt) way to gate a deployment on a precondition — a migration, a smoke test against a dependency, a permission check.

## Hooks are not part of the tracked release

Unlike your regular templates, hook resources (by default) are **not** recorded as part of the release's revision the way a Deployment or Service is. Run `helm get manifest` on a release and you generally won't see hook resources in the output at all — they're transient by design. If you genuinely need a hook's resource to persist and be tracked, add `helm.sh/resource-policy: keep` — an edge case, not the default pattern.

## Exercise

Go to [exercise.md](exercise.md). A complete working chart is in [solution/webapp-with-hooks/](solution/webapp-with-hooks/).
