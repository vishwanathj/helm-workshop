# Exercise 6 · `ct lint` and `ct install` Against Your Own Charts

Install the tools first: `brew install chart-testing yamllint`. (`ct` shells out to `yamllint` and `helm lint` internally, so both need to be on your `PATH`.)

`ct` diffs against a git branch to decide which charts changed — it needs a real git repo with an `origin` remote, exactly like a CI checkout. This exercise sets that up locally so you can see it work without needing an actual GitHub repo.

## Part A — set up a conventional chart-testing layout

```bash
mkdir -p /tmp/ct-test/charts
cp -R /path/to/01-basics/06-values-and-templates/solution/webapp-with-configmap /tmp/ct-test/charts/webapp
cp -R /path/to/02-intermediate/04-chart-dependencies-and-subcharts/solution/greeter /tmp/ct-test/charts/greeter
```

`/tmp/ct-test/ct.yaml`:
```yaml
chart-dirs:
  - charts
target-branch: main
validate-maintainers: false
```

(`validate-maintainers: false` turns off one of `ct`'s stricter checks — see Q1.)

## Part B — build the git history `ct` needs

```bash
cd /tmp/ct-test
git init -q
git add -A
git commit -q -m "initial charts"
git branch -M main

# a real origin remote, since ct diffs against origin/<target-branch>
git init -q --bare /tmp/ct-origin.git
git remote add origin /tmp/ct-origin.git
git push -q origin main
```

Now simulate a pull request that only touches `webapp`:
```bash
git checkout -q -b bump-version
sed -i '' 's/version: 0.1.0/version: 0.2.0/' charts/webapp/Chart.yaml
git add -A
git commit -q -m "bump webapp chart version"
git push -q origin bump-version
git fetch -q origin
```

## Part C — see what `ct` thinks changed

```bash
ct list-changed --config ct.yaml
```
Should print only `charts/webapp` — `greeter` never changed on this branch, so `ct` correctly leaves it alone.

## Part D — lint

```bash
ct lint --config ct.yaml
```
Watch it: confirm the chart's version was actually bumped since the last commit on `main` (a real check — try skipping the `sed` step above and see this fail), validate `Chart.yaml`, then run the equivalent of `helm lint`. You should end with `All charts linted successfully`.

## Part E — install (a real smoke test)

```bash
ct install --config ct.yaml
```
This is the big one: `ct` installs `webapp` into a **throwaway namespace** in your real cluster, waits for it to become ready, prints the pod's description and container logs for you to eyeball, then uninstalls it and deletes the namespace — automatically. This is the exact sequence Module 1 Lesson 7 had you do by hand (install, check pods, look at what's actually running) — except scripted, repeatable, and safe to run on every single pull request.

## Questions

<details>
<summary>Q1: Why did this exercise set <code>validate-maintainers: false</code>?</summary>

By default `ct lint` requires a `maintainers:` field in every chart's `Chart.yaml` — a real hygiene rule public chart repositories often enforce, but one this workshop's charts never bothered with, since it's not central to what any given lesson is teaching. Turning it off is a legitimate, documented `ct.yaml` option, not a workaround — real projects tune which of `ct`'s checks matter for their own repo the same way.
</details>

<details>
<summary>Q2: What would have happened in Part D if you'd skipped bumping <code>charts/webapp/Chart.yaml</code>'s <code>version:</code> field?</summary>

`ct lint` would fail at the "checking for a version bump" step. This check exists because a chart repository (classic or OCI) is versioned content — if two different commits produce a chart still labeled `0.1.0`, there's no way to tell them apart once published, and no way to know a change even happened. Requiring a version bump on every change is `ct` enforcing the same discipline you'd expect from any package registry.
</details>

<details>
<summary>Q3: <code>ct install</code> only tested <code>webapp</code>, not <code>greeter</code> — is that a bug?</summary>

No — same reasoning as `list-changed` in Part C. `ct install` (like `ct lint`) only processes charts that changed relative to the target branch by default, which is exactly the behavior you want in CI: a pull request that only touches one chart out of a hundred shouldn't have to wait for all hundred to reinstall. You can force it to test everything regardless of git history with `ct install --all`, useful for a scheduled full-repo health check rather than a per-PR gate.
</details>

Next: [Lesson 7 · GitOps with Argo CD](../07-gitops-with-argocd/)
