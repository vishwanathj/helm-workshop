# Exercise 4 · Explore a Generated Chart

Helm can scaffold a starter chart for you — a great way to see a working example of every file described in the lesson.

## Tasks

1. Generate a demo chart (do this somewhere scratch, e.g. `/tmp`, not inside this repo):
   ```bash
   cd /tmp
   helm create demo
   cd demo
   ```

2. Open `Chart.yaml`. Answer: what are the values of `name`, `version`, and `appVersion`?

3. Open `values.yaml`. Find the `replicaCount` and `image` sections.

4. Open `templates/deployment.yaml`. Find the line that sets the container image, and match it back to `values.yaml`. It should look like:
   ```yaml
   image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
   ```

5. Without installing anything, render the templates locally to see the final YAML Helm *would* apply:
   ```bash
   helm template demo .
   ```
   Scroll through the output — this is plain Kubernetes YAML, no more `{{ }}` placeholders.

6. Now render it again, but override the replica count from the command line, and diff mentally against the previous output:
   ```bash
   helm template demo . --set replicaCount=3
   ```
   Find `replicas:` in the output — it should now say `3`.

## Questions

<details>
<summary>Q1: In <code>templates/deployment.yaml</code>, what value does <code>.Values.image.tag</code> fall back to if it's not set in <code>values.yaml</code>?</summary>

`.Chart.AppVersion` — the `| default .Chart.AppVersion` part of the template means "use `.Values.image.tag` if set, otherwise use the chart's `appVersion` from `Chart.yaml`."
</details>

<details>
<summary>Q2: What's the practical difference between <code>helm template</code> and <code>helm install</code>?</summary>

`helm template` renders the final YAML locally and prints it — it never talks to your cluster and creates nothing. `helm install` renders the same YAML and then applies it to the cluster, creating a tracked release. `helm template` is the safe way to preview exactly what would be deployed before you commit to installing it.
</details>

Next: [Lesson 5 · Your First Chart](../05-your-first-chart/)
