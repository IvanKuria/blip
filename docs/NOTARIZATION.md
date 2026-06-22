# Notarizing & Distributing Blip

This guide covers the one-time setup and the repeatable workflow for producing a
notarized, stapled `Blip.dmg` using `scripts/build-dmg.sh`.

Target: macOS 14+ / Xcode 26 with the modern `notarytool` workflow.
(The legacy `altool` notarization path was removed by Apple and is **not** used.)

---

## 1. Prerequisites (one-time)

1. **Xcode + command line tools**

   ```sh
   xcode-select --install        # if not already installed
   sudo xcodebuild -license accept
   ```

2. **xcodegen** (project generation) and optionally **create-dmg** (nicer DMG):

   ```sh
   brew install xcodegen
   brew install create-dmg       # optional; the script falls back to hdiutil
   ```

3. **Developer ID Application certificate** in your **login** keychain.

   You need *"Developer ID Application: Ivan Kuria (347LA37C2B)"* **with its
   private key**. If you created the cert in Xcode or on another Mac, export it
   as a `.p12` (Keychain Access → export, which includes the private key) and
   double-click it on this machine. Verify it is present:

   ```sh
   security find-identity -v -p codesigning
   ```

   You should see a line containing
   `Developer ID Application: Ivan Kuria (347LA37C2B)`.

---

## 2. Store notarization credentials (one-time)

`notarytool` reads credentials from a named **keychain profile**. The build
script uses the profile name **`blip-notary`**. Create it once using **either**
option below.

### Option A - Apple ID + app-specific password (simplest)

1. Create an app-specific password at <https://account.apple.com> →
   *Sign-In and Security* → *App-Specific Passwords*. (This is **not** your
   normal Apple ID password.)
2. Store the profile:

   ```sh
   xcrun notarytool store-credentials "blip-notary" \
     --apple-id "you@example.com" \
     --team-id "347LA37C2B" \
     --password "abcd-efgh-ijkl-mnop"
   ```

   (`--password` is the app-specific password from step 1.)

### Option B - App Store Connect API key (recommended for CI)

1. In App Store Connect → *Users and Access* → *Integrations* → *Keys*,
   create a key with the **Developer** role and download the `.p8` file
   (you can only download it once). Note the **Key ID** and **Issuer ID**.
2. Store the profile:

   ```sh
   xcrun notarytool store-credentials "blip-notary" \
     --key "/path/to/AuthKey_XXXXXXXXXX.p8" \
     --key-id "XXXXXXXXXX" \
     --issuer "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
   ```

Either way, the credentials are stored in the keychain under the profile name
`blip-notary`; the build script references only that name and never sees your
secrets directly.

Verify the profile works:

```sh
xcrun notarytool history --keychain-profile "blip-notary"
```

---

## 3. Build, notarize & staple

From the project root:

```sh
chmod +x scripts/build-dmg.sh      # first time only
scripts/build-dmg.sh               # version read from project.yml
# or pin an explicit version:
scripts/build-dmg.sh 0.1.0
```

The script will:

1. `xcodegen generate`
2. Archive `Release` with hardened runtime + Developer ID signing
3. Export `Blip.app` (`method: developer-id`)
4. Build `build/Blip-<version>.dmg` (with an `/Applications` drag target)
5. Codesign the DMG
6. Submit to notarization (`notarytool submit --wait`)
7. Staple the ticket (`stapler staple`)
8. Verify with `spctl`

Output: **`build/Blip-<version>.dmg`**. The script also prints the DMG's
SHA-256, which you paste into the Homebrew cask (`Casks/blip.rb`).

If notarization is rejected, read the detailed log:

```sh
xcrun notarytool log <submission-id> --keychain-profile "blip-notary"
```

(The submission ID is printed by `notarytool submit`.)

---

## 4. Verify the result manually

```sh
# Gatekeeper assessment of the DMG container:
spctl -a -t open --context context:primary-signature -v build/Blip-0.1.0.dmg

# Confirm the staple ticket is attached:
xcrun stapler validate build/Blip-0.1.0.dmg
```

To test the end-to-end user experience: mount the DMG, drag `Blip.app` to
`/Applications`, then check the **app** itself:

```sh
spctl -a -t exec -vv /Applications/Blip.app
codesign --verify --strict --deep --verbose=2 /Applications/Blip.app
```

A correctly notarized app reports `source=Notarized Developer ID` and
`accepted`.

---

## 5. Publish

1. Create a GitHub release tagged `v<version>` (e.g. `v0.1.0`) on
   <https://github.com/IvanKuria/blip>.
2. Attach `build/Blip-<version>.dmg` as a release asset.
3. Update `Casks/blip.rb`: set `version` and paste the printed `sha256`.
