# Lesson 3 · Library Charts

Since Module 2 Lesson 1, every chart you've built has carried its own copy of `templates/_helpers.tpl` — `name`, `fullname`, and `labels` helpers, copy-pasted chart to chart. Fine for one chart, but Module 2 Lesson 4 had you write a *second* chart (`greeter`) with its own near-identical helpers. In a real organization with a dozen charts, that copy-paste becomes a dozen slightly-diverging copies of the same logic. A **library chart** is Helm's answer: a chart that contributes reusable template logic to other charts, and produces no Kubernetes resources of its own.

## What makes a chart a library chart

One line in `Chart.yaml`:
```yaml
type: library
```
(as opposed to the default `type: application`, which every other chart in this workshop has used, usually implicitly since `helm create` writes it out). A library chart:

- Contains `templates/_helpers.tpl`-style `define` blocks — and nothing else. No `deployment.yaml`, no `service.yaml`. Templates that aren't `define` blocks are simply not rendered.
- **Cannot be installed on its own.** `helm install` on a library chart fails outright — it has nothing to deploy.
- Is added as a **dependency** of an application chart, exactly like the `greeter` subchart from Module 2 Lesson 4 — except a library chart contributes template *functions*, not a running workload.

## How an application chart uses it

Declare it in `Chart.yaml` and run `helm dependency update`, same as any dependency:
```yaml
dependencies:
  - name: webapp-common
    version: "0.1.0"
    repository: "file://../webapp-common"
```

Then call its named templates via `include`, exactly as if they were defined locally — because for the purposes of `include`, they are: once `helm dependency update` vendors the library into `charts/`, its `define` blocks join the same template namespace as the rest of your chart.

## The context-passing detail that makes this actually reusable

A library chart's helper doesn't hardcode which chart it's naming — the same `{{ .Chart.Name }}`/`{{ .Release.Name }}`/`{{ .Values }}` inside a library's `define` block resolve against **whichever chart calls `include`**, not the library chart itself. That's the entire mechanism that makes one library chart reusable across many unrelated application charts: `webapp-common`'s `common.fullname` helper produces `webapp`-flavored names when `webapp`'s templates call it, and would produce `greeter`-flavored names if `greeter`'s templates called the exact same helper — no changes to the library needed.

## Exercise

Go to [exercise.md](exercise.md). You'll factor the `_helpers.tpl` logic out of `webapp` into a standalone `webapp-common` library chart, then wire `webapp` to depend on it instead of carrying its own copy.
