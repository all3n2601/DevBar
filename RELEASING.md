# Releasing DevBar

1. Update `VERSION` and `Sources/Core/Version.swift` to the same semantic version.
2. Add changes and known limitations to `CHANGELOG.md`.
3. Run `swift test`, `python3 scripts/smoke-test.py "$(swift build --show-bin-path)/DevBar"`, and `scripts/package-release.sh`.
4. Test the packaged app on macOS: open/close the popover, hotkey, empty states, iOS/Android discovery, boot/shutdown, installation, captures, and failures. Test Intel and Apple Silicon before declaring stable support. Test recording finalization and GPS on disposable virtual devices.
5. Commit and push to `main`; wait for CI to pass.
6. Tag the reviewed commit and push the tag:

   ```sh
   git tag -a "v$(cat VERSION)" -m "DevBar $(cat VERSION)"
   git push origin "v$(cat VERSION)"
   ```

7. Inspect the Release workflow and download its assets. Check the SHA256 manifest, archive contents, version, and launch behavior. Edit the generated release notes with any material limitations.

The release workflow needs only GitHub's built-in token. It builds/tests on macOS, uploads artifacts, then publishes from a separate job with repository write permission. It fails if the tag, VERSION file, and Swift version disagree. Do not retag a published version; fix forward with a new version.

## Signing

Current builds are ad-hoc signed and not notarized. They may require a Gatekeeper override. Do not describe them as notarized or suitable for frictionless installation.

For a future Developer ID release, supply signing credentials through GitHub Actions secrets, import them into a temporary keychain, sign with hardened runtime and a timestamp, submit the app ZIP to Apple's notary service, staple the successful ticket, and verify with `spctl` before creating archives. Add that process only after validating the chosen entitlements and notarization credentials. No Apple signing secrets are currently required or configured.

## Validation boundaries

CI regression tests use command fixtures and protocol checks. They do not boot real devices. Platform availability, MapKit UI, recordings, push delivery, and private app storage require manual testing. Keep releases marked beta until that matrix is verified.
