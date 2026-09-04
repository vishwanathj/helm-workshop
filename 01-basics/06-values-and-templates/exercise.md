# Exercise 6 · Override Values

Continue in `/tmp/webapp` from Lesson 5, with the `webapp` release still installed.

## Part A — quick override with `--set`

1. Bump the replica count with `--set`:
   ```bash
   helm upgrade webapp . --namespace helm-basics --set replicaCount=3
   ```
2. Confirm:
   ```bash
   kubectl get pods --namespace helm-basics
   ```
   You should now see 3 `webapp` pods.

## Part B — a values file for a "NodePort" environment

Imagine you want to expose this app differently for local testing — via `NodePort` instead of `ClusterIP` — while keeping replicaCount at 3.

1. Create `custom-values.yaml` in `/tmp/webapp` (a working copy is also at [solution/custom-values.yaml](solution/custom-values.yaml)):
   ```yaml
   replicaCount: 3

   service:
     type: NodePort
   ```
   Notice this file only needs the keys you're changing — everything else keeps its default from the chart's `values.yaml` (image repository/tag stay as-is).

2. Preview the change first, without applying it:
   ```bash
   helm upgrade webapp . --namespace helm-basics -f custom-values.yaml --dry-run --debug
   ```
   Look at the printed `COMPUTED VALUES` section — confirm `service.type: NodePort` and `replicaCount: 3` show up, and check the rendered `Service` manifest in the output.

3. Apply it for real:
   ```bash
   helm upgrade webapp . --namespace helm-basics -f custom-values.yaml
   ```

4. Confirm the Service type changed:
   ```bash
   kubectl get svc webapp --namespace helm-basics
   ```
   `TYPE` should now show `NodePort`, with a port in the 30000-32767 range listed under `PORT(S)`.

5. Confirm what values Helm now considers "set" for this release:
   ```bash
   helm get values webapp --namespace helm-basics
   ```

## Part C — bonus: add a ConfigMap (optional)

So far your chart only has a `Deployment` and a `Service`. The third Kubernetes resource nearly every beginner chart needs is a `ConfigMap` — a way to inject configuration or small files into a Pod without baking them into the container image. Here you'll use one to replace nginx's default welcome page with your own message, driven by `values.yaml`.

A complete solution is in [solution/webapp-with-configmap/](solution/webapp-with-configmap/) if you want to check your work — try it yourself first.

1. Add a `html.message` value to `values.yaml`:
   ```yaml
   html:
     message: "Hello from the Helm workshop!"
   ```

2. Create `templates/configmap.yaml`. Notice the `| default "..."` filter — the same pattern `helm create` used for `image.tag` in Lesson 4 — so the chart still works even if `html.message` is left unset:
   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: webapp-html
   data:
     index.html: |
       <html>
         <body>
           <h1>{{ .Values.html.message | default "Hello from the Helm workshop!" }}</h1>
         </body>
       </html>
   ```

3. Mount it into the nginx container in `templates/deployment.yaml`, replacing the default content at `/usr/share/nginx/html`. Add `volumeMounts` under the container, and `volumes` as a sibling of `containers` under `spec.template.spec`:
   ```yaml
           volumeMounts:
             - name: html
               mountPath: /usr/share/nginx/html
   ```
   ```yaml
         volumes:
           - name: html
             configMap:
               name: webapp-html
   ```

4. Preview, then apply:
   ```bash
   helm lint .
   helm upgrade webapp . --namespace helm-basics -f custom-values.yaml --dry-run --debug
   helm upgrade webapp . --namespace helm-basics -f custom-values.yaml
   ```

5. Confirm the ConfigMap was created and the page changed:
   ```bash
   kubectl get configmap --namespace helm-basics
   kubectl port-forward --namespace helm-basics svc/webapp 8080:80 &
   curl localhost:8080
   ```
   You should see your custom `<h1>` message instead of the default "Welcome to nginx!" page.

6. Try changing the message without touching any template — add `html.message` to `custom-values.yaml` and upgrade again. This is the payoff of templating: the same chart, same templates, different content, purely from values.

   **Gotcha to expect**: `curl` right after the upgrade may still show the *old* message for up to a minute. Helm and Kubernetes updated the ConfigMap object immediately, but Kubernetes does **not** restart pods just because a ConfigMap they mount changed — the kubelet only re-syncs a mounted ConfigMap's file contents periodically (roughly every 30-60s), and your existing pods keep running the whole time. Wait a bit and `curl` again — you'll see it flip to the new message without any pod restart. This is a well-known Kubernetes rough edge and is exactly why production charts often add a checksum annotation (e.g. `checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}`) on the pod template, so a config change forces a real rollout — a technique for Module 2.

## Questions

<details>
<summary>Q1: Why didn't <code>custom-values.yaml</code> need to repeat <code>image.repository</code> and <code>image.tag</code>?</summary>

Values files are merged on top of the chart's default `values.yaml`, not used as a full replacement. Any key you don't mention keeps its default. This is why you only put the fields you actually want to change in an override file.
</details>

<details>
<summary>Q2: What's the risk of skipping <code>--dry-run</code> before an upgrade on a real (non-workshop) release?</summary>

Without previewing, a typo or wrong value (e.g., accidentally setting `replicaCount: 0`, or the wrong `image.tag`) gets applied directly to a live release, potentially causing an outage. `--dry-run --debug` lets you catch mistakes by reading the rendered manifests and computed values before anything changes in the cluster.
</details>

<details>
<summary>Q3 (bonus): Why put the HTML content in a ConfigMap and mount it, instead of just building a custom nginx image with the file baked in?</summary>

Baking it into the image means rebuilding, re-pushing, and re-pulling a container image for every content change — slow, and it couples your "config" to your "code artifact." A ConfigMap is a Kubernetes-native object you can edit and roll out independently of the image (via `helm upgrade` with new values), it's visible/diffable with plain `kubectl`, and the same generic nginx image can be reused across many different deployments that each mount their own ConfigMap. It's the same principle as the rest of this lesson: separate what changes often (config) from what doesn't (the image).
</details>

Next: [Lesson 7 · Upgrade, Rollback & Uninstall](../07-upgrade-rollback-uninstall/)
