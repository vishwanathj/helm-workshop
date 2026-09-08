# Lesson 2 · Chart Provenance & Signing

Every install in this workshop so far has trusted that a chart is exactly what it claims to be — nothing has verified that a `.tgz` wasn't tampered with in transit, or that it actually came from whoever you think published it. Helm's answer is a **provenance file**: a cryptographic signature (using PGP/GnuPG, the same technology behind signed Linux packages and signed git commits) that travels alongside a packaged chart.

## The two pieces

- **`helm package --sign`** produces the usual `<chart>-<version>.tgz`, plus a second file: `<chart>-<version>.tgz.prov`. The `.prov` file contains a SHA-256 digest of the chart archive, signed with your private PGP key.
- **`helm verify`** (or `--verify` on `helm install`/`helm pull`) checks a `.tgz` against its `.tgz.prov`: it recomputes the digest, confirms it matches what's in the provenance file, and confirms the signature was made by a key it recognizes as trusted (a public key already in your keyring).

This is the same trust model as `apt`/`dpkg` signature checking or verifying a GPG-signed git tag — the signature proves *who* produced the artifact and that it's *unmodified* since; it says nothing about whether the chart's contents are good practice or safe to run.

## The commands

```bash
helm package --sign --key <key-name> --keyring <path-to-secret-keyring> ./mychart
helm verify mychart-0.1.0.tgz
helm install myrelease mychart-0.1.0.tgz --verify
```

`--key` names which key in your keyring to sign with (by the identity string GPG shows for it, e.g. an email address), and `--keyring` points at the keyring file holding your private key. `helm verify`'s default `--keyring` is `~/.gnupg/pubring.gpg` — it only needs your *public* key to check a signature, exactly like anyone else who wants to verify a chart you signed only needs your public key, never your private one.

## The GPG keyring gotcha

Modern GnuPG (2.1+, which is what `brew install gnupg` gives you today) stores keys in a newer format (a "keybox," `.kbx` files) by default — but Helm's `--keyring`/`--key` flags expect the older, classic OpenPGP keyring file format (`.gpg` files) that GnuPG used before 2.1. This means after generating a key with a current `gpg`, you typically need one extra step to export it into the format Helm expects:

```bash
gpg --export-secret-keys > ~/.gnupg/secring.gpg
gpg --export > ~/.gnupg/pubring.gpg
```

This is a long-standing, widely-documented friction point between Helm's provenance tooling (written against the classic GnuPG keyring format) and every GnuPG release since 2.1 — not something specific to this workshop's setup. If `helm package --sign` or `helm verify` complains it can't find a key that `gpg --list-keys` clearly shows exists, this mismatch is almost always why.

## Exercise

Go to [exercise.md](exercise.md). You'll generate a throwaway signing key, sign your `webapp` chart, verify it, and then see verification correctly fail against a tampered copy.
