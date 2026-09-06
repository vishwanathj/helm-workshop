# Exercise 7 · Package, Host, and Install From Your Own Repo

## Part A — package your charts

1. Set up a scratch repo directory:
   ```bash
   mkdir -p /tmp/chart-repo
   ```
2. Package both charts from Lesson 6 (`webapp`, with `greeter` already vendored in `charts/`, plus `greeter` itself so it's independently installable too):
   ```bash
   helm package /tmp/webapp -d /tmp/chart-repo
   helm package /tmp/greeter -d /tmp/chart-repo
   ls /tmp/chart-repo
   ```
   You should see `webapp-0.1.0.tgz` and `greeter-0.1.0.tgz`.

## Part B — build and serve the index

3. Generate the index. The exact port doesn't matter — pick anything free — but it must match what you serve on in the next step:
   ```bash
   helm repo index /tmp/chart-repo --url http://localhost:8756
   cat /tmp/chart-repo/index.yaml
   ```
4. Serve it locally, in its own terminal (leave this running for the rest of the exercise):
   ```bash
   cd /tmp/chart-repo
   python3 -m http.server 8756
   ```
5. In your original terminal, confirm it's reachable:
   ```bash
   curl -s http://localhost:8756/index.yaml | head -5
   ```

## Part C — add, search, install

6. Add it as a Helm repo, same as you did with `bitnami` back in Module 1:
   ```bash
   helm repo add local-workshop http://localhost:8756
   helm repo update
   helm search repo local-workshop
   ```
7. Install `webapp` **from the repo** into a fresh namespace (deliberately separate from `helm-basics` — both releases would otherwise render a `Deployment` selector of plain `app: webapp`, and two Deployments claiming the same pod label in the same namespace will fight over the same pods):
   ```bash
   helm install my-webapp local-workshop/webapp --version 0.1.0 --namespace helm-repo-test --create-namespace
   kubectl get pods,svc,configmap --namespace helm-repo-test
   ```
   Notice the resource names are prefixed `my-webapp-` (not `webapp-`) — this is the `webapp.fullname` helper from Lesson 1 at work, now driven by a different release name.
8. Confirm it really came from the packaged `.tgz`, not your working directory, by checking Helm's own record of the chart source:
   ```bash
   helm get metadata my-webapp --namespace helm-repo-test
   ```

## Part D — publish a new version

9. Bump the chart version in `/tmp/webapp/Chart.yaml`:
   ```yaml
   version: 0.1.1
   ```
10. Repackage and re-index, **merging** with the existing index so the old version stays listed too:
    ```bash
    helm package /tmp/webapp -d /tmp/chart-repo
    helm repo index /tmp/chart-repo --url http://localhost:8756 --merge /tmp/chart-repo/index.yaml
    helm repo update
    helm search repo local-workshop -l
    ```
    You should see both `0.1.0` and `0.1.1` of `webapp` listed.

## Part E — clean up

11. Uninstall the test release and remove the temporary repo:
    ```bash
    helm uninstall my-webapp --namespace helm-repo-test
    kubectl delete namespace helm-repo-test
    helm repo remove local-workshop
    ```
12. Stop the `python3 -m http.server` process (Ctrl+C in its terminal).
13. Revert `/tmp/webapp/Chart.yaml` back to `version: 0.1.0` so it matches [solution/webapp-with-tests](../06-linting-and-testing/solution/webapp-with-tests/) if you want to keep comparing against it.

## Questions

<details>
<summary>Q1: Why does <code>helm repo index</code> need <code>--url</code>, and why does it matter that the URL matches where you actually serve the files?</summary>

Each entry in `index.yaml` embeds a full download URL for its `.tgz`, built by combining `--url` with the package filename. `helm install`/`helm pull` follow that exact URL — if it doesn't match where the files are actually being served, every install from that repo fails with a fetch error, even though `helm search repo` (which only reads `index.yaml` itself) looks perfectly fine.
</details>

<details>
<summary>Q2: What would you have seen in Part C step 7 if you'd installed into <code>helm-basics</code> instead of a fresh namespace?</summary>

Both Deployments' `ReplicaSet` controllers would try to manage any pod labeled `app: webapp` in that namespace — Kubernetes doesn't stop you from creating two selectors that overlap, so both Deployments start believing they own the *same* pods, and you'd see chaotic, competing scale-up/scale-down behavior instead of two independent, healthy releases. This exact hazard is why Lesson 1 pointed out that selector labels are the one thing this chart deliberately doesn't derive from the release name — it's simple, but it means "one release of this chart per namespace" is an implicit rule you're now responsible for respecting.
</details>

<details>
<summary>Q3: Real chart repos are usually plain object storage (S3, GCS) or GitHub Pages, not a laptop running <code>python3 -m http.server</code>. What actually changes?</summary>

Nothing about the chart-authoring side — `helm package` and `helm repo index` produce the exact same files either way. Only the "serving" step changes: instead of a local process, you upload `index.yaml` and every `.tgz` to a bucket or a static site with public (or authenticated) read access, and `--url` points at that public endpoint instead of `localhost`. `helm repo add`/`search`/`install` work identically once there's a real HTTP(S) URL in front of the files.
</details>

---

**Module 2 complete.** Advanced topics (OCI registries, provenance/signing, GitOps, CI/CD, Helmfile) land in [03-advanced](../../03-advanced/) — coming soon.
