# Lesson 4 · Chart Dependencies & Subcharts

Lesson 4 of Module 1 mentioned `charts/` — the directory where dependency charts (**subcharts**) get vendored — but left it empty. This lesson fills it in: declaring a dependency, fetching it, configuring it from the parent chart, and turning it on or off.

## Declaring a dependency

Dependencies go in `Chart.yaml`, not `values.yaml`:

```yaml
dependencies:
  - name: greeter
    version: "0.1.0"
    repository: "file://../greeter"
    condition: greeter.enabled
```

- **`name`/`version`** — which chart and which version. Version supports the same semver-range syntax as most package managers (`"1.x"`, `">=1.2.0 <2.0.0"`), not just an exact pin.
- **`repository`** — where to fetch it from. A real chart repo would use an `https://` URL (`helm repo add`-style) or an OCI registry (`oci://...`); this lesson uses a `file://` path pointing at a sibling directory on disk, which keeps the exercise fully local and network-free while behaving identically from Helm's point of view.
- **`condition`** — a dotted path into the parent's `values.yaml` (here, `greeter.enabled`) that Helm checks before including the subchart's resources at all. This is the standard way to make a subchart optional.

## Fetching dependencies

```bash
helm dependency update .
```

This resolves everything listed in `dependencies:`, downloads/copies each one into `charts/` as a packaged `.tgz`, and writes (or updates) `Chart.lock` — a record of the exact versions actually resolved, analogous to a lockfile in most other package managers. Commit both `charts/*.tgz` and `Chart.lock` to version control so a chart is fully reproducible without re-resolving dependencies. `helm dependency build` is the companion command that re-fetches into `charts/` from an *existing* `Chart.lock` without re-resolving version ranges — the dependency equivalent of `npm ci` vs `npm install`.

Once dependencies are present, Helm folds their resources into a single release automatically — `helm install`/`helm upgrade` on the parent chart creates/updates the subchart's resources too, all in one release history.

## Configuring a subchart from the parent

A parent chart passes configuration down to a subchart via a values block keyed by the subchart's name:

```yaml
# webapp/values.yaml
greeter:
  enabled: true
  message: "Hello from the greeter subchart, configured by the parent chart!"
```

Inside the `greeter` subchart's own templates, that same data is just `.Values.message` — a subchart never sees its parent's key prefix; Helm strips it off automatically when it evaluates that subchart's templates.

## `global` values

Sometimes multiple charts (parent and one or more subcharts) all need the *same* piece of configuration — an environment name, an image registry, a common label. Anything placed under a top-level `global:` key in the parent's values is visible, unprefixed, to every subchart as `.Values.global.<key>` — no wiring required:

```yaml
# webapp/values.yaml
global:
  environment: "workshop"
```

```
{{/* inside the greeter subchart's own template */}}
environment: {{ .Values.global.environment | default "unspecified" | quote }}
```

Use `global` sparingly — it's the one place where a subchart's configuration silently depends on something declared far away from it, so it's worth a comment wherever it's read. One gotcha: Helm does **not** automatically give every chart an empty `global: {}` to fall back on. A subchart rendered standalone (no parent providing `global` at all) will hit a template error reading `.Values.global.<anything>` unless that subchart's *own* `values.yaml` also declares a `global:` default — worth doing anyway, since it keeps the subchart renderable and testable on its own, dependency or not.

## Exercise

Go to [exercise.md](exercise.md). Complete working charts are in [solution/webapp-with-dependencies/](solution/webapp-with-dependencies/) (the parent) and [solution/greeter/](solution/greeter/) (the subchart's own source, before packaging).
