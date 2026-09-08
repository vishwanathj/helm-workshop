# Exercise 3 · Factor `_helpers.tpl` into a Library Chart

Work in a fresh scratch directory, e.g. `/tmp/lib-chart`, with **two sibling chart directories** side by side:

```bash
mkdir -p /tmp/lib-chart/webapp-common/templates
mkdir -p /tmp/lib-chart/webapp/templates
```

## Part A — build the library chart

1. `/tmp/lib-chart/webapp-common/Chart.yaml`:
   ```yaml
   apiVersion: v2
   name: webapp-common
   description: Shared naming/labeling helpers for the Helm workshop's charts
   type: library
   version: 0.1.0
   ```

2. `/tmp/lib-chart/webapp-common/templates/_helpers.tpl` — the same three helpers from Module 2 Lesson 1, renamed from the `webapp.*` prefix to a generic `common.*` prefix, since this file no longer belongs to any one chart:
   ```
   {{- define "common.name" -}}
   {{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
   {{- end -}}

   {{- define "common.fullname" -}}
   {{- if .Values.fullnameOverride -}}
   {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
   {{- else -}}
   {{- $name := include "common.name" . -}}
   {{- if contains $name .Release.Name -}}
   {{- .Release.Name | trunc 63 | trimSuffix "-" -}}
   {{- else -}}
   {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
   {{- end -}}
   {{- end -}}
   {{- end -}}

   {{- define "common.labels" -}}
   helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
   app.kubernetes.io/name: {{ include "common.name" . }}
   app.kubernetes.io/instance: {{ .Release.Name }}
   app.kubernetes.io/managed-by: {{ .Release.Service }}
   {{- end -}}
   ```

   Notice this is *only* `define` blocks — a library chart has no `values.yaml` requirement and no rendered manifests of its own.

## Part B — point `webapp` at it

3. `/tmp/lib-chart/webapp/Chart.yaml` — declare the library as a dependency:
   ```yaml
   apiVersion: v2
   name: webapp
   description: A minimal web app chart for the Helm workshop
   version: 0.1.0
   appVersion: "1.25"
   dependencies:
     - name: webapp-common
       version: "0.1.0"
       repository: "file://../webapp-common"
   ```

4. `/tmp/lib-chart/webapp/values.yaml` — same shape as Module 1's `webapp`, with the override hooks from Module 2 Lesson 1:
   ```yaml
   replicaCount: 1

   image:
     repository: nginx
     tag: "1.25"

   service:
     type: ClusterIP
     port: 80

   html:
     message: "Hello from the Helm workshop!"

   nameOverride: ""
   fullnameOverride: ""
   ```

5. `/tmp/lib-chart/webapp/templates/deployment.yaml`, `service.yaml`, `configmap.yaml` — copy them from [Module 2 Lesson 1's solution](../../02-intermediate/01-named-templates-and-helpers/solution/webapp-with-helpers/templates/), but with every `include "webapp.fullname" .` and `include "webapp.labels" .` changed to `include "common.fullname" .` / `include "common.labels" .`.

   **Do not create a `templates/_helpers.tpl` in `webapp` at all** — that's the whole point. The `common.*` templates will come from the dependency once you run `helm dependency update`.

6. Pull in the dependency:
   ```bash
   cd /tmp/lib-chart/webapp
   helm dependency update .
   ls charts/
   ```
   You should see `webapp-common-0.1.0.tgz` show up in `charts/` — Helm packaged the library chart and vendored it in, exactly like any other dependency.

7. Render and confirm the helpers resolved correctly even though they live in a different chart directory:
   ```bash
   helm template webapp .
   ```
   Check: resource names are still `webapp`/`webapp-html`, and `helm.sh/chart: webapp-0.1.0` (not `webapp-common-0.1.0`) appears in the labels — confirming `.Chart.Name`/`.Chart.Version` resolved against the *consuming* chart, not the library.

8. Install it to prove it's a real, working chart:
   ```bash
   helm install webapp-lib . --namespace helm-advanced --create-namespace
   kubectl get deployment,svc,configmap --namespace helm-advanced
   ```

## Part C — confirm a library chart can't stand alone

```bash
cd /tmp/lib-chart/webapp-common
helm install oops .
```
You should get:
```
Error: INSTALLATION FAILED: library charts are not installable
```
This is Helm actively enforcing the concept: a library chart is template logic to be consumed, never a workload to be deployed by itself.

## Part D — clean up

```bash
helm uninstall webapp-lib --namespace helm-advanced
kubectl delete namespace helm-advanced
```

## Questions

<details>
<summary>Q1: Why does <code>webapp-common</code> have no <code>values.yaml</code>, even though its <code>common.fullname</code> helper references <code>.Values.fullnameOverride</code>?</summary>

`.Values` inside an included template always resolves against whichever chart called `include` — here, `webapp`. Since `webapp`'s own `values.yaml` already defines `fullnameOverride`, that's what `common.fullname` sees when `webapp`'s templates call it. The library chart never needs its own `values.yaml` for values it only ever reads through the calling chart's context.
</details>

<details>
<summary>Q2: If a second chart, say <code>greeter</code>, also declared a dependency on <code>webapp-common</code> and called <code>include "common.fullname" .</code>, what would it return?</summary>

`greeter`-flavored names, automatically — e.g. installing `greeter` as release `greeter` would resolve `common.name` to `greeter` (from `greeter`'s own `Chart.Name`) and `common.fullname` to just `greeter` (since the release name contains the chart name). Nothing in `webapp-common` needs to know `greeter` exists; the same helper produces correct, chart-specific output for any chart that depends on it. This is the payoff of factoring the logic out in the first place.
</details>

<details>
<summary>Q3: Could you have gotten the same DRY benefit by just copy-pasting <code>_helpers.tpl</code> into every chart instead of using a library chart?</summary>

You'd get the same *rendered output*, but not the same maintainability: a bug fix or convention change (say, adding a new standard label) would need to be manually applied to every copy, and copies drift over time as different people edit different charts. A library chart is a single source of truth — bump `webapp-common`'s version, run `helm dependency update` in each consuming chart, and every chart picks up the fix identically.
</details>

Next: [Lesson 4 · Custom Helm Plugins](../04-custom-helm-plugins/)
