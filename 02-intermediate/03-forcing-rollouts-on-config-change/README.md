# Lesson 3 · Forcing Rollouts on Config Change

Recall the gotcha from Lesson 6 in Module 1: updating a `ConfigMap` through `helm upgrade` does **not** restart pods that mount it. Kubernetes updates the ConfigMap object immediately, but the kubelet only re-syncs a mounted ConfigMap's file contents periodically (roughly every 30-60s) — and even then, a running process inside the container (like nginx) won't automatically notice a file changed under it. If you need config changes to actually take effect promptly, you need a real rollout, not just a quietly-updated mounted file.

## The checksum annotation pattern

The fix is simple and extremely common in real-world charts: put a hash of the ConfigMap's content into a **pod template annotation**. Since `spec.template` is what a `Deployment` diffs to decide whether a rollout is needed, changing anything under it — including an annotation — triggers a new `ReplicaSet` and a real pod rollout:

```
metadata:
  annotations:
    checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
```

Breaking that line down:

- **`$.Template.BasePath`** — the directory containing the current template file (e.g. `webapp/templates`). `$` is used instead of `.` because this line usually sits inside other scoped blocks (`with`, `range`) by the time real charts get this complex — `$` guarantees you're reading the root context's `Template` info, not some inner scope's.
- **`print $.Template.BasePath "/configmap.yaml"`** — concatenates the path to the specific template you want to watch, e.g. `webapp/templates/configmap.yaml`.
- **`include (...) .`** — renders that template file, fully, with the current context — meaning if the ConfigMap's content changes for *any* reason (a `.Values.html.message` override, or a different values file entirely), the rendered text changes.
- **`| sha256sum`** — hashes the rendered text into a short, fixed-length string. The annotation's actual value doesn't matter to Kubernetes; only that it changes when — and only when — the underlying content changes.

The naming convention `checksum/config` isn't special to Helm or Kubernetes — it's just a label people commonly use. You'll also see `checksum/configmap`, `checksum/secret`, or one checksum annotation per file being watched if a chart mounts several ConfigMaps/Secrets.

## Why this belongs in the Deployment, not the ConfigMap

The annotation must live on the **pod template** (`spec.template.metadata.annotations`) inside the `Deployment`, not on the `ConfigMap` object itself. An annotation on the ConfigMap doesn't affect any Deployment's rollout decision — only a change to the *Deployment's own* `spec.template` does that. This is exactly the same rule from Lesson 1: anything under `spec.template` triggers a rollout when it changes; anything on the resource's own top-level `metadata` does not.

## Exercise

Go to [exercise.md](exercise.md). A complete working chart is in [solution/webapp-with-checksum/](solution/webapp-with-checksum/).
