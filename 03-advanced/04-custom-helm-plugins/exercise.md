# Exercise 4 · Build the `nuke` Plugin

## Part A — write the plugin

1. Create a scratch directory for the plugin:
   ```bash
   mkdir /tmp/helm-nuke-plugin
   ```

2. `/tmp/helm-nuke-plugin/nuke.sh` — the actual logic. Two positional arguments: release name, namespace.
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail

   if [ "$#" -ne 2 ]; then
     echo "Usage: helm nuke <release> <namespace>" >&2
     exit 1
   fi

   RELEASE="$1"
   NAMESPACE="$2"

   echo "Uninstalling release '$RELEASE' in namespace '$NAMESPACE'..."
   helm uninstall "$RELEASE" --namespace "$NAMESPACE"

   echo "Deleting namespace '$NAMESPACE'..."
   kubectl delete namespace "$NAMESPACE"

   echo "Done."
   ```
   Make it executable:
   ```bash
   chmod +x /tmp/helm-nuke-plugin/nuke.sh
   ```

3. `/tmp/helm-nuke-plugin/plugin.yaml` — the manifest that tells Helm this directory is a plugin:
   ```yaml
   name: "nuke"
   version: "0.1.0"
   usage: "Uninstall a release and delete its namespace in one step"
   description: |
     A convenience command for workshop-style cleanup: uninstalls a Helm
     release, then deletes the Kubernetes namespace it lived in.
   command: "$HELM_PLUGIN_DIR/nuke.sh"
   ```

## Part B — install and inspect it

```bash
helm plugin install /tmp/helm-nuke-plugin
helm plugin list
```
You should see `nuke` listed. Try it with no arguments to confirm your usage-error path works:
```bash
helm nuke
```
Expect your `Usage: helm nuke <release> <namespace>` message on stderr, and a non-zero exit reported by Helm as `Error: plugin "nuke" exited with error`.

## Part C — use it for real

1. Install a throwaway release to clean up:
   ```bash
   cd /tmp/webapp-m2-ex1   # or any chart directory from earlier lessons
   helm install nuke-test . --namespace helm-nuke-test --create-namespace
   kubectl get pods -n helm-nuke-test
   ```

2. Nuke it in one command instead of two:
   ```bash
   helm nuke nuke-test helm-nuke-test
   ```

3. Confirm it's actually gone:
   ```bash
   helm list -n helm-nuke-test
   kubectl get namespace helm-nuke-test
   ```
   The `kubectl get namespace` should report `NotFound` — proof the plugin did both steps.

## Part D — remove the plugin

```bash
helm plugin uninstall nuke
helm plugin list
```

## Questions

<details>
<summary>Q1: What does <code>$HELM_PLUGIN_DIR</code> resolve to, and why use it instead of a hardcoded path?</summary>

It's an environment variable Helm sets before invoking a plugin's command, pointing at the plugin's own install directory (e.g. wherever `helm plugin install` copied `/tmp/helm-nuke-plugin` to internally). Hardcoding `/tmp/helm-nuke-plugin/nuke.sh` in `plugin.yaml` would only work for your one local copy — `$HELM_PLUGIN_DIR` makes the manifest portable to wherever the plugin actually ends up installed on any machine, including everyone else's.
</details>

<details>
<summary>Q2: Why did <code>helm nuke</code> with no arguments print your usage message but still show Helm's own <code>"plugin ... exited with error"</code> wrapper?</summary>

Helm doesn't parse or understand a plugin's arguments or output at all — it just runs the command as a subprocess and checks the exit code. Your script's `exit 1` (from `set -euo pipefail` plus the explicit `exit 1` in the argument check) is what Helm sees; it has no way to know *why* the plugin failed, so it reports a generic wrapper message. This is the "opaque external process" limitation from the lesson's README — a more polished plugin would need its own dedicated `--help` handling, since Helm won't provide any of that for you.
</details>

<details>
<summary>Q3: Could you rewrite <code>nuke</code> to accept the Module 1-style <code>--namespace</code> flag (<code>helm nuke webapp --namespace helm-basics</code>) instead of two bare positional arguments?</summary>

Yes — Helm passes every argument after the plugin name through to your script completely unprocessed (`$@` in bash), so you could add your own flag-parsing logic (a `while`/`case` loop over `$@`, or a tool like `getopts`) inside `nuke.sh` exactly as you would in any standalone shell script. Helm's plugin mechanism doesn't provide flag-parsing for you — whatever argument conventions your plugin honors are entirely up to what you implement in the script itself.
</details>

Next: [Lesson 5 · Helmfile](../05-helmfile/)
