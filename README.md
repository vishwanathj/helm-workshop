# Helm Workshop for Beginners

A hands-on, self-paced workshop for learning [Helm](https://helm.sh), the package manager for Kubernetes. Every lesson pairs a short explanation with a real exercise you run on your own machine against a local Kubernetes cluster.

No prior Helm experience assumed. Basic familiarity with `kubectl` and the idea of a Kubernetes Pod/Deployment/Service is helpful but not required — the basics module explains what you need as you go.

## Roadmap

| Module | Status | Covers |
|---|---|---|
| [01 · Basics](01-basics/) | ✅ Available | What Helm is, installing it, core commands, chart anatomy, building your first chart, templating, upgrade/rollback |
| [02 · Intermediate](02-intermediate/) | ✅ Available | Named templates, conditionals/loops, checksum rollouts, dependencies/subcharts, hooks, `helm lint`/`helm test`, packaging & repos |
| [03 · Advanced](03-advanced/) | 🚧 Coming soon | GitOps, CI/CD, OCI registries, provenance/signing, Helmfile |

Start with **[01 · Basics](01-basics/)**.

## How this workshop works

- Each lesson lives in its own numbered folder with a `README.md` (concepts) and, where hands-on, an `exercise.md` (tasks).
- Work through exercises yourself before checking the `<details>` solution blocks or `solution/` folders — that's where the learning happens.
- Lessons build on each other in order within a module. Go in sequence the first time through.

## Prerequisites

See [docs/prerequisites.md](docs/prerequisites.md) before starting Lesson 1. It covers installing Helm, `kubectl`, and a local cluster (this workshop uses [`kind`](https://kind.sigs.k8s.io/)).

## License

[MIT](LICENSE)
