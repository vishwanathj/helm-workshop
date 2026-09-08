# Lesson 6 · Chart Testing & CI

`helm lint` (Module 1) and `helm template`/`--dry-run` catch a lot, but they run against exactly one chart, exactly the way you invoke them. **`ct`** ([chart-testing](https://github.com/helm/chart-testing), the CLI the Helm project itself built for this) is the tool that makes chart validation *repeatable across every chart in a repo, automatically, in CI* — the same tool that gates pull requests on most public Helm chart repositories, including Bitnami's and the official `helm/charts` archive.

## What `ct` actually does

| Command | What it does |
|---|---|
| `ct lint` | Runs `helm lint` plus additional repo-hygiene checks (Chart.yaml version bumped, `Chart.yaml`/`values.yaml`/`values.schema.json` well-formed, maintainers present, etc.) across every chart it finds |
| `ct install` | Actually installs every chart into a real cluster, waits for it to become healthy, then uninstalls it — a live smoke test, not just a syntax check |
| `ct list-changed` | Lists which charts changed relative to a target git branch — the mechanism CI uses to only test what a PR actually touched, not your entire chart collection on every push |

`ct` expects a conventional layout — by default, chart directories directly under `charts/` — and a small `ct.yaml` config file telling it where to look and which chart repos to resolve dependencies against:

```yaml
chart-dirs:
  - charts
target-branch: main
```

## Why `ct install` matters beyond `helm lint`

`helm lint` and `helm template` are both static analysis — they check that your templates render into well-formed YAML, but neither one ever asks Kubernetes whether that YAML is actually *deployable*. `ct install` does what Module 1's exercises did by hand — install, wait for pods to go `Ready`, uninstall — except automatically, for every chart, every time, without a human remembering to run through it. This is exactly the gap the Lesson 7 (Basics) gotcha exposed: a `helm upgrade` reporting success tells you nothing about whether the application actually came up healthy. `ct install` closes that gap in an automated pipeline the same way `kubectl get pods` closed it for you manually.

## Where CI fits in

Everything above runs on your own machine in this lesson's exercise — CI (GitHub Actions, in this lesson) just means running the exact same `ct lint`/`ct install` commands automatically, on a fresh disposable Kubernetes cluster, every time someone opens a pull request. [example-workflow.yml](example-workflow.yml) in this lesson's folder is the standard pattern the Helm project itself recommends, built from three official actions (`helm/chart-testing-action`, `helm/kind-action`, `azure/setup-helm`). It's included as reference content, not something this workshop runs for you — GitHub Actions only executes on GitHub's infrastructure when a workflow file under `.github/workflows/` is present in a real repository and a matching event (like a pull request) fires. Copy it there in your own project when you're ready to wire this up for real.

## Exercise

Go to [exercise.md](exercise.md). You'll run `ct lint` and `ct install` locally against your own charts, the same checks a CI pipeline would run automatically.
