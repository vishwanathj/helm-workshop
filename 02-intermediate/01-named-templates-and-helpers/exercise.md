# Exercise 1 · Add `_helpers.tpl` to `webapp`

Continue in `/tmp/webapp`. If you tore down the cluster or release at the end of Module 1, recreate the cluster (see [Prerequisites](../../docs/prerequisites.md)) and reinstall first:

```bash
cd /tmp/webapp
helm upgrade --install webapp . --namespace helm-basics --create-namespace -f custom-values.yaml
```

## Part A — write the helpers

1. Create `templates/_helpers.tpl`:
   ```
   {{- define "webapp.name" -}}
   {{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
   {{- end -}}

   {{- define "webapp.fullname" -}}
   {{- if .Values.fullnameOverride -}}
   {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
   {{- else -}}
   {{- $name := include "webapp.name" . -}}
   {{- if contains $name .Release.Name -}}
   {{- .Release.Name | trunc 63 | trimSuffix "-" -}}
   {{- else -}}
   {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
   {{- end -}}
   {{- end -}}
   {{- end -}}

   {{- define "webapp.labels" -}}
   helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
   app.kubernetes.io/name: {{ include "webapp.name" . }}
   app.kubernetes.io/instance: {{ .Release.Name }}
   app.kubernetes.io/managed-by: {{ .Release.Service }}
   {{- end -}}
   ```

2. Add override hooks to `values.yaml` (empty defaults — `fullname.tpl` only uses them if set):
   ```yaml
   nameOverride: ""
   fullnameOverride: ""
   ```

## Part B — use the helpers in your templates

3. In `templates/deployment.yaml`, `templates/service.yaml`, and `templates/configmap.yaml`:
   - Replace every hardcoded `name: webapp` (the resource's own `metadata.name`) with `name: {{ include "webapp.fullname" . }}`.
   - Replace the hardcoded ConfigMap name `webapp-html` (both where it's defined in `configmap.yaml` and where it's referenced in `deployment.yaml`'s `volumes:`) with `{{ include "webapp.fullname" . }}-html`.
   - Add a `labels:` block under each resource's `metadata:` (the resource-level one, not `selector`) using:
     ```yaml
     labels:
       {{- include "webapp.labels" . | nindent 4 }}
     ```
   - In `deployment.yaml`, also add the same labels under `spec.template.metadata.labels`, **alongside** (not replacing) the existing `app: webapp`:
     ```yaml
     template:
       metadata:
         labels:
           app: webapp
           {{- include "webapp.labels" . | nindent 8 }}
     ```
   - **Leave `spec.selector.matchLabels: { app: webapp }` in `deployment.yaml` and `spec.selector: { app: webapp }` in `service.yaml` exactly as they are.** Don't template or rename these.

4. Validate:
   ```bash
   helm lint .
   helm template webapp .
   ```
   In the rendered output, confirm: resource names are unchanged (still `webapp` and `webapp-html` — because your release is also named `webapp`, `fullname` collapses to just the release name), and each resource now carries `helm.sh/chart`, `app.kubernetes.io/name`, `app.kubernetes.io/instance`, and `app.kubernetes.io/managed-by` labels.

5. Apply it:
   ```bash
   helm upgrade webapp . --namespace helm-basics -f custom-values.yaml
   kubectl get deployment webapp --namespace helm-basics -o jsonpath='{.metadata.labels}'
   ```
   You should see the new labels on the Deployment object.

6. Check the pods:
   ```bash
   kubectl get pods --namespace helm-basics
   ```
   Notice a *new* set of pods got created (a real rollout happened), even though nothing about the app's behavior changed. That's because you added labels to `spec.template.metadata.labels`, and **any** change under `spec.template` — even just a label — makes Kubernetes create a new `ReplicaSet` and roll pods over. Compare that with step 5: labels added directly on the *Deployment's own* `metadata.labels` (not under `spec.template`) never trigger a rollout by themselves.

## Part C — bonus: break the selector on purpose

This part is destructive to your current release but instructive — you'll recover it immediately after.

1. Temporarily edit `templates/deployment.yaml` and add a templated label into `spec.selector.matchLabels`, e.g.:
   ```yaml
   selector:
     matchLabels:
       app: webapp
       app.kubernetes.io/instance: {{ .Release.Name }}
   ```
2. Try to upgrade:
   ```bash
   helm upgrade webapp . --namespace helm-basics -f custom-values.yaml
   ```
   This fails with an error like:
   ```
   UPGRADE FAILED: ... Deployment.apps "webapp" is invalid: spec.selector: Invalid value: ...: field is immutable
   ```
   Kubernetes rejects the update because `spec.selector` is immutable on an existing `Deployment`. Helm surfaces the Kubernetes API server's rejection as the upgrade error.
3. Revert the file back to just `app: webapp` in `matchLabels` and confirm a normal upgrade succeeds again:
   ```bash
   helm upgrade webapp . --namespace helm-basics -f custom-values.yaml
   ```

This is why the lesson's `webapp.labels` helper is kept deliberately separate from the selector — it's the only label set on a `Deployment` you can never safely regenerate from scratch after the first `helm install`.

## Questions

<details>
<summary>Q1: Why is <code>include</code> used instead of <code>template</code> in this chart?</summary>

`include` is a function, so its output can be piped into other functions — here, `| nindent 4` / `| nindent 8` to get the indentation right for a YAML map nested under `labels:`. `template` is an action, not a function, and can't be piped, so it can't easily be re-indented. Because of this, `include` is used almost universally in modern charts even though `template` still works for simple cases.
</details>

<details>
<summary>Q2: What does <code>webapp.fullname</code> return if you install this chart with <code>helm install my-webapp .</code> instead of <code>webapp</code>? What about <code>helm install demo .</code>?</summary>

`my-webapp` — unchanged. The release name `my-webapp` already contains the chart name `webapp` as a substring, so `contains $name .Release.Name` is true and the helper just returns `.Release.Name` as-is, avoiding a redundant `my-webapp-webapp`.

`demo`, on the other hand, does **not** contain `webapp`, so the helper falls into the `else` branch and concatenates them: `demo-webapp`. Try `helm template demo .` to see it for yourself.
</details>

<details>
<summary>Q3: Why keep <code>nameOverride</code>/<code>fullnameOverride</code> in <code>values.yaml</code> at all if this exercise never sets them?</summary>

They're an escape hatch for chart consumers, not something the chart author needs day-to-day. If someone installing your chart wants full control over generated resource names (e.g. to fit an existing naming scheme, or to avoid a collision), `--set fullnameOverride=my-custom-name` lets them do it without editing your templates. It costs nothing to support and is expected by convention in any chart that copies this helper pattern.
</details>

Next: [Lesson 2 · Conditionals, Loops & Structuring `values.yaml`](../02-conditionals-loops-and-values-structure/)
