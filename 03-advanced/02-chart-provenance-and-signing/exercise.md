# Exercise 2 · Sign, Verify, and Detect Tampering

Install GnuPG first if you haven't: `brew install gnupg`. (On this workshop's own test machine, this build took an unusually long time from source — there's no prebuilt binary for every macOS/CPU combination, so budget extra time if `brew install` seems to hang.)

## Part A — generate a throwaway signing key

Real keys need a passphrase and careful handling; this one is just for practicing the mechanism, so we'll skip both for convenience. **Never do this for a key that signs anything real.**

1. Create a batch key-generation config:
   ```bash
   cat > /tmp/gpg-batch.txt <<EOF
   %no-protection
   Key-Type: RSA
   Key-Length: 2048
   Name-Real: Helm Workshop
   Name-Email: workshop@example.com
   Expire-Date: 0
   %commit
   EOF
   ```

2. Generate it:
   ```bash
   gpg --batch --gen-key /tmp/gpg-batch.txt
   gpg --list-keys
   ```
   You should see a `uid` line for `Helm Workshop <workshop@example.com>`.

3. Export into the classic keyring format Helm's `--keyring`/`--key` flags expect (see the README's "keyring gotcha" section for why this step exists):
   ```bash
   gpg --export-secret-keys > ~/.gnupg/secring.gpg
   gpg --export > ~/.gnupg/pubring.gpg
   ```

## Part B — sign your chart

```bash
cd /tmp/webapp-oci   # or a fresh copy of any webapp chart from earlier lessons
helm package --sign --key 'Helm Workshop' --keyring ~/.gnupg/secring.gpg .
ls webapp-0.1.0.tgz*
```
You should see both `webapp-0.1.0.tgz` and a new `webapp-0.1.0.tgz.prov` sitting next to it — the provenance file.

Peek inside the `.prov` file (it's plain text, not binary):
```bash
cat webapp-0.1.0.tgz.prov
```
You'll see a YAML block describing the chart, a `sha256` hash, wrapped in a PGP signature block (`-----BEGIN PGP SIGNED MESSAGE-----` ... `-----BEGIN PGP SIGNATURE-----`).

## Part C — verify it

```bash
helm verify webapp-0.1.0.tgz
```
This should succeed, confirming both the checksum and the signature against your public key in `~/.gnupg/pubring.gpg`.

## Part D — detect tampering

1. Change something in the chart — e.g., edit `values.yaml`'s `html.message`.
2. Re-package **without** `--sign`, overwriting the `.tgz` but leaving the original `.prov` file from Part B untouched:
   ```bash
   helm package .
   ls webapp-0.1.0.tgz*
   ```
3. Verify again:
   ```bash
   helm verify webapp-0.1.0.tgz
   ```
   This time it should **fail**. The `.prov` file still contains the checksum of the *original* archive contents from Part B; the `.tgz` sitting next to it now is different content entirely. `helm verify` recomputes the checksum of what's actually on disk and finds it doesn't match what was signed — exactly the scenario a provenance file exists to catch: someone (or something) replaced the artifact after it was signed.
4. Re-sign it properly to restore a consistent, verifiable pair:
   ```bash
   helm package --sign --key 'Helm Workshop' --keyring ~/.gnupg/secring.gpg .
   helm verify webapp-0.1.0.tgz
   ```

## Questions

<details>
<summary>Q1: In Part D, what specifically did <code>helm verify</code> detect — a broken signature, or something else?</summary>

A checksum mismatch, not a broken signature. The signature itself is still perfectly valid — it was never touched, and it correctly proves *the `.prov` file* wasn't tampered with and really was produced by your key. What's wrong is that the `.tgz` sitting next to it no longer matches the checksum that signature vouches for. This is an important distinction: provenance doesn't mean "this file has an attached signature that checks out" — it means "this exact byte-for-byte content is what got signed."
</details>

<details>
<summary>Q2: If someone else wanted to verify a chart you signed, what would they need from you — your private key, your passphrase, or something else?</summary>

Only your public key (the contents of `~/.gnupg/pubring.gpg`, or more precisely just your key's public portion, shareable freely — e.g. via `gpg --export --armor 'Helm Workshop' > workshop-public-key.asc`). That's the entire point of public-key cryptography: anyone can verify a signature with the public key, but only the private key (which never leaves your machine) can produce one. Never share `secring.gpg` or a private key with anyone who only needs to verify your charts.
</details>

<details>
<summary>Q3: Does <code>helm install --verify</code> stop you from installing an unsigned chart?</summary>

No — `--verify` only changes behavior when a `.tgz.prov` file is present and asked for; it doesn't forbid installing charts that were never signed at all (most charts, including everything else in this workshop, have no provenance file and install completely normally without `--verify`). Provenance is opt-in trust infrastructure: it lets a chart consumer who *chooses* to check catch tampering or an unexpected publisher, but Helm never requires every chart in the ecosystem to be signed.
</details>

Next: [Lesson 3 · Library Charts](../03-library-charts/)
