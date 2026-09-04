# Lesson 4 · Chart Anatomy

Every Helm chart follows the same directory layout, whether it's a tiny demo or a production-grade chart with hundreds of options. Let's look at one.

## The standard layout

```
mychart/
├── Chart.yaml           # Metadata: name, version, description
├── values.yaml           # Default configuration values
├── .helmignore            # Files to exclude when packaging
├── charts/                # Bundled dependency charts (subcharts) — empty for now
└── templates/             # Kubernetes manifest templates
    ├── deployment.yaml
    ├── service.yaml
    ├── _helpers.tpl        # Reusable template snippets (helper functions)
    ├── NOTES.txt           # Printed to the user after install/upgrade
    └── tests/
        └── test-connection.yaml
```

## What each piece does

- **`Chart.yaml`** — required metadata: `name`, `version` (the chart's own version, semver), `appVersion` (the version of the app it deploys), `description`.
- **`values.yaml`** — the default values for everything the templates reference. This is the "public API" of the chart — what a user is expected to configure.
- **`templates/*.yaml`** — Kubernetes manifests written with Go template syntax (`{{ .Values.xyz }}`) instead of hardcoded values. Helm renders these into real YAML at install time by substituting values.
- **`templates/_helpers.tpl`** — a place for reusable named template snippets (e.g., a standard way to compute a resource name or common labels), referenced from other templates via `{{ include "mychart.fullname" . }}`. Filenames starting with `_` are not rendered as standalone manifests.
- **`templates/NOTES.txt`** — plain text (with templating available) shown to the user right after `helm install`/`helm upgrade` — typically "how to access your app" instructions.
- **`charts/`** — where dependency charts (subcharts) get vendored, e.g. if your app chart depends on a `redis` chart. Empty until you declare dependencies (that's an Intermediate-module topic).
- **`.helmignore`** — like `.gitignore`, controls what's excluded when packaging the chart with `helm package`.

## Exercise

Go to [exercise.md](exercise.md).
