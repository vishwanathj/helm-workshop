# Exercise 5 · Add Pre-Upgrade and Post-Install Hooks

Continue in `/tmp/webapp` with the chart from Lesson 4 (including the `greeter` dependency).

## Part A — a `pre-upgrade` hook

1. Create `templates/hooks/pre-upgrade-check.yaml`:
   ```yaml
   apiVersion: batch/v1
   kind: Job
   metadata:
     name: {{ include "webapp.fullname" . }}-pre-upgrade-check
     labels:
       {{- include "webapp.labels" . | nindent 4 }}
     annotations:
       helm.sh/hook: pre-upgrade
       helm.sh/hook-weight: "0"
       helm.sh/hook-delete-policy: before-hook-creation
   spec:
     backoffLimit: 0
     template:
       metadata:
         labels:
           app: webapp
       spec:
         restartPolicy: Never
         containers:
           - name: pre-upgrade-check
             image: busybox:1.36
             command:
               - sh
               - -c
               - "echo 'pre-upgrade check passed'"
   ```
   (`backoffLimit: 0` means Kubernetes won't retry the Job on failure — good for a fast fail/success signal during a hook, where you want Helm to know the result quickly rather than sit through retries.)

## Part B — a `post-install`/`post-upgrade` hook

2. Create `templates/hooks/post-install-greeting.yaml`:
   ```yaml
   apiVersion: batch/v1
   kind: Job
   metadata:
     name: {{ include "webapp.fullname" . }}-post-install-greeting
     labels:
       {{- include "webapp.labels" . | nindent 4 }}
     annotations:
       helm.sh/hook: post-install,post-upgrade
       helm.sh/hook-weight: "5"
       helm.sh/hook-delete-policy: hook-succeeded
   spec:
     backoffLimit: 0
     template:
       metadata:
         labels:
           app: webapp
       spec:
         restartPolicy: Never
         containers:
           - name: post-install-greeting
             image: busybox:1.36
             command:
               - sh
               - -c
               - "echo '{{ .Values.html.message }}'"
   ```

3. Validate:
   ```bash
   helm lint .
   helm template webapp . --show-only templates/hooks/pre-upgrade-check.yaml
   helm template webapp . --show-only templates/hooks/post-install-greeting.yaml
   ```

## Part C — watch the hooks actually run

4. Upgrade, and immediately check Jobs in the namespace:
   ```bash
   helm upgrade webapp . --namespace helm-basics -f custom-values.yaml
   kubectl get jobs --namespace helm-basics
   ```
5. Notice the difference between the two delete policies: `webapp-pre-upgrade-check` is still there (its `before-hook-creation` policy only cleans up right before the *next* hook run, not after this one succeeds), while `webapp-post-install-greeting` is already gone (`hook-succeeded` deletes it immediately). Check the surviving one's logs:
   ```bash
   kubectl logs job/webapp-pre-upgrade-check --namespace helm-basics
   ```
6. Confirm hook resources aren't part of the tracked release manifest:
   ```bash
   helm get manifest webapp --namespace helm-basics | grep "kind: Job"
   ```
   This should print nothing — hooks render and run, but by default they're not stored as part of the release the way your Deployment/Service/ConfigMap are.

## Part D — bonus: a failing hook blocks the upgrade

7. Temporarily break the pre-upgrade hook's command:
   ```yaml
             command:
               - sh
               - -c
               - "echo 'about to fail' && exit 1"
   ```
8. Try to upgrade:
   ```bash
   helm upgrade webapp . --namespace helm-basics --set html.message="this should never land" -f custom-values.yaml
   ```
   This fails. Confirm the release was **not** actually changed:
   ```bash
   helm history webapp --namespace helm-basics
   kubectl get configmap webapp-html --namespace helm-basics -o jsonpath='{.data.index\.html}'
   ```
   The message should still be whatever it was before this attempt — the failed pre-upgrade hook stopped everything downstream of it, including the ConfigMap and Deployment updates.
9. Inspect the failed Job (it's left behind — there's no `hook-failed` delete policy set, only `before-hook-creation`):
   ```bash
   kubectl get jobs --namespace helm-basics
   kubectl logs job/webapp-pre-upgrade-check --namespace helm-basics
   ```
10. Revert the command back to the working version from Part A, then upgrade again — notice `before-hook-creation` now deletes the old failed Job before creating a fresh (successful) one:
    ```bash
    helm upgrade webapp . --namespace helm-basics -f custom-values.yaml
    kubectl get jobs --namespace helm-basics
    ```

## Questions

<details>
<summary>Q1: If both hooks had the same <code>helm.sh/hook-weight</code>, what would decide their run order?</summary>

Resource name, alphabetically. This lesson gives them different weights (`"0"` and `"5"`) specifically so the order is explicit and doesn't depend on incidental naming — a good habit once a chart has more than one or two hooks at the same hook point.
</details>

<details>
<summary>Q2: Why does <code>post-install-greeting.yaml</code> declare <em>both</em> <code>post-install</code> and <code>post-upgrade</code> instead of just one?</summary>

`post-install` only fires on the very first `helm install`; a later `helm upgrade` on the same release does not re-trigger it. If you want the same behavior (here, printing a greeting) to happen after every deploy action — not just the first one — you need to list both hook points on the same resource, which is exactly what the comma-separated annotation does.
</details>

<details>
<summary>Q3: Why use a <code>Job</code> for these hooks instead of a bare <code>Pod</code>?</summary>

Helm can hook either kind, but a `Job` gives you `backoffLimit` (control over retries) and Kubernetes' own notion of `Complete`/`Failed` status for free, which is exactly the success/failure signal Helm needs to decide whether to proceed or abort. A bare `Pod` can work for very simple hooks, but you'd be reimplementing retry/completion semantics Kubernetes already gives you with `Job`.
</details>

Next: [Lesson 6 · `helm lint` and `helm test`](../06-linting-and-testing/)
