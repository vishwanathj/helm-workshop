# Lesson 4 · Custom Helm Plugins

You've been running `helm uninstall <release> --namespace <ns>` followed by `kubectl delete namespace <ns>` at the end of nearly every lesson's cleanup step in this workshop. A **Helm plugin** lets you turn a repeated multi-command routine like that into a single new `helm` subcommand — `helm nuke <release> <namespace>`, say — installed and invoked exactly like any built-in Helm command.

## What a plugin actually is

Nothing exotic: a directory containing a `plugin.yaml` manifest plus whatever executable it points at (a shell script, a Python script, a compiled binary — Helm doesn't care what language, it just runs it as a subprocess). At minimum, `plugin.yaml` needs:

```yaml
name: "nuke"
version: "0.1.0"
usage: "Uninstall a release and delete its namespace in one step"
description: |
  A convenience command for workshop-style cleanup...
command: "$HELM_PLUGIN_DIR/nuke.sh"
```

- `name` becomes the subcommand: `helm nuke ...`.
- `command` is what Helm actually executes, with whatever arguments you passed after the subcommand appended (`helm nuke foo bar` runs `nuke.sh foo bar`). `$HELM_PLUGIN_DIR` is an environment variable Helm sets to the plugin's own install directory, so the manifest doesn't need to hardcode an absolute path.

## Installing a plugin

```bash
helm plugin install <path-or-git-url>
helm plugin list
helm plugin uninstall <name>
```

Real-world plugins (well-known examples: `helm-diff`, `helm-secrets`, `helm-unittest`) are typically installed straight from a Git repository URL, e.g. `helm plugin install https://github.com/databus23/helm-diff`, rather than a local directory. `helm plugin install` recognizes a local path (like this lesson's exercise uses) purely for development/testing, exactly the way you might `pip install -e .` a Python package you're actively editing.

## A limitation worth knowing before you rely on this pattern

Helm treats a plugin as an opaque external process: it runs your command and reports whether it exited zero or non-zero. There's no special handling for `--help`, no built-in argument parsing, no access to Helm's internal Go APIs from a shell-script plugin — you get argv and your own wits. That's fine for something like `nuke`, but it's why more sophisticated plugins (`helm-diff`, for instance) are written as full Go programs using Helm's SDK internally, not shell scripts.

## Exercise

Go to [exercise.md](exercise.md). You'll build, install, and use the `nuke` plugin described above, then remove it.
