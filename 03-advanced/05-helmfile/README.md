# Lesson 5 · Helmfile

Every lesson so far has managed **one** release at a time: one `helm install`, one `helm upgrade`. Real environments usually run many charts together — an app plus a database plus an ingress controller plus a couple of shared services — and keeping all of them at the right versions and values, consistently, by running `helm` commands one at a time, doesn't scale. [Helmfile](https://helmfile.io) is a separate, widely-used open-source tool (not part of Helm itself) that lets you describe a whole set of releases declaratively in one file, then bring your cluster in line with that file in one command.

## The core file: `helmfile.yaml`

```yaml
releases:
  - name: webapp
    namespace: helm-advanced
    chart: ./webapp
    values:
      - replicaCount: 3
        html:
          message: "Hello from Helmfile-managed webapp!"

  - name: greeter
    namespace: helm-advanced
    chart: ./greeter
    values:
      - message: "Hello from Helmfile-managed greeter!"
```

Each entry under `releases:` is everything you'd otherwise pass to `helm install`/`helm upgrade` by hand: a release name, a namespace, a chart (a local path here, but also a repo chart or an `oci://` reference), and values — inline, as shown, or (more commonly in real use) `values: [values.yaml]` pointing at actual files, letting one `helmfile.yaml` reuse the values files you already have per environment.

## The commands

| Command | What it does |
|---|---|
| `helmfile sync` | Installs/upgrades every release to match the file, unconditionally — no diff, no skip |
| `helmfile diff` | Shows what *would* change, across every release, without touching the cluster |
| `helmfile apply` | Diffs first, then only touches releases that actually changed — skips anything already in sync |
| `helmfile list` | Shows every release the file manages and its status |
| `helmfile destroy` | Uninstalls every release the file manages, in one command |

`apply` is the one you'll reach for day to day — it's `sync`, but it won't waste time (or risk an unwanted rollout) touching a release that's already correct. It needs the [`helm-diff`](https://github.com/databus23/helm-diff) plugin installed (`helm plugin install https://github.com/databus23/helm-diff`) to compute that diff; without it, `apply` and `diff` fail outright, while `sync` still works since it never needs to compare anything.

## Why not just a shell script looping over `helm upgrade`?

You could — and plenty of teams did, before tools like this existed. What Helmfile buys you over a homemade script: a real diff *before* anything changes (not just "did the command succeed"), one declared desired state instead of a script's implicit one, and the ability to express relationships between releases (dependencies between them, shared values, environment-specific overrides) that a flat script has no clean way to express. It's the same "declarative desired state" idea as a single chart's `values.yaml`, one level up — applied across a whole fleet of releases instead of one.

## Exercise

Go to [exercise.md](exercise.md). You'll manage your `webapp` chart and the `greeter` chart from Module 2 Lesson 4 together, from one `helmfile.yaml`.
