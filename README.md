# Tucker

Native macOS menu bar manager by Quarks. Deployment target: macOS 15.

## Build and run

Open `Tucker.xcodeproj`, select the Tucker scheme, and run in Xcode.

The Run scheme installs the built app to `/Applications/Tucker.app`, registers
that copy with Launch Services, and debugs it there. macOS 27 may fail to match
a DerivedData app to the visibility allow-list, hiding Tucker itself. Hiding is
therefore refused outside that installed path. The install script validates the
bundle identifier before replacing an existing app; it never uses sudo.

For reliable Accessibility permission during development, select an Apple
Development team in Xcode under Signing & Capabilities. A `Sign to Run Locally`
ad-hoc signature changes after every build, so macOS can treat the rebuilt app as
a new Accessibility client even when the old toggle still appears enabled.

Startup leaves icons expanded until the first manual collapse. Reopening Tucker
from Finder restores all icons and suspends auto-hide until a manual collapse.
The configured global shortcut (default Control-Option-T) also restores icons
and suspends auto-hide when collapsed. Xcode Stop terminates Tucker and releases
the process-owned restriction. A rebuild may require reauthorizing Accessibility
for the installed copy.

```sh
xcodebuild -project Tucker.xcodeproj -scheme Tucker -configuration Debug -destination 'platform=macOS,arch=arm64' -derivedDataPath build/DerivedData build
```

## macOS 27 hiding

The overlay implementation has been removed. Tucker now uses a runtime-loaded,
private `MenuBarClientCore` visibility assertion on macOS 27. This exception to
the original public-API-only requirement was explicitly authorized by the user.
The system hides excluded applications' menu bar items and recomputes layout.
No window, panel, bitmap, or mask covers the menu bar.

1. Click Tucker and grant Accessibility in System Settings > Privacy & Security
   > Accessibility. The permission reads the positions of other apps' menu extras.
2. Hold Command and drag the icons to hide to the LEFT of Tucker. In a right-to-left
   menu bar, put them to its right instead. Other app icons stay visible.
3. Click Tucker to collapse; click again to restore. Control-Option-T also toggles.

The read runs off the main thread. Apps with unreadable positions stay allowed.
An application with icons on both sides remains visible: the private service
controls whole applications, not individual icons. Tucker explicitly includes
itself and system item identifiers 0 through 63 in the allow-list.

Repeating the toggle during a pending request cancels it. Stale callbacks release
their assertions. An eight-second timeout restores the unrestricted state.
Quitting or changing display configuration also releases the restriction.
The state changes to collapsed only after the system reports success. Failures
appear in Tucker's tooltip and, for manual requests, its context menu.

This private interface may change after macOS updates and is unsuitable for
App Store distribution. Missing runtime classes/selectors leave icons visible.
The app must remain unsandboxed to read other applications' AX menu extras.
No Screen Recording, Automation, or Full Disk Access permission is requested.
Launch at login uses SMAppService; the shortcut uses Carbon RegisterEventHotKey.

## Distribution

Tucker can be distributed directly in an ad-hoc signed DMG without an Apple
Developer Program membership. It cannot use the Mac App Store because its macOS
27 implementation loads a private framework and the Accessibility inventory must
run without App Sandbox.

Create the free ad-hoc package:

```sh
Tools/build-dmg.sh --adhoc
```

The DMG includes installation instructions. Gatekeeper blocks an ad-hoc build on
first launch, so each recipient must try to open Tucker and then choose Tucker's
Open Anyway action in System Settings > Privacy & Security. The app becomes an
exception on that Mac after confirmation.

Public distribution requires an active Apple Developer Program membership, a
`Developer ID Application` certificate, and notarization credentials. Save the
credentials once in Keychain (the command prompts securely for the app-specific
password):

```sh
xcrun notarytool store-credentials TuckerNotary \
  --apple-id "YOUR_APPLE_ID" \
  --team-id "YOUR_TEAM_ID"
```

Then build the public release:

```sh
TUCKER_SIGNING_IDENTITY="Developer ID Application: YOUR NAME (TEAMID)" \
TUCKER_NOTARY_PROFILE="TuckerNotary" \
Tools/build-dmg.sh
```

The script performs a clean universal Release build, signs Tucker with Hardened
Runtime and a secure timestamp, verifies the signature, creates a DMG containing
Tucker and an Applications shortcut, notarizes it, staples the ticket, runs
Gatekeeper assessment, and prints SHA-256. The final file appears in `dist/`.
The script refuses public mode without both the Developer ID identity and Keychain
notary profile.

`--local` remains an alias for the ad-hoc mode for compatibility with older build
instructions.

```sh
Tools/build-dmg.sh --local
```

Before each release, increment `MARKETING_VERSION` and
`CURRENT_PROJECT_VERSION` in the target build settings and test Accessibility
plus hide/reveal on a clean Mac.

## Older systems

On macOS 15 and 26, Tucker retains the public NSStatusItem spacer approach.
Command-drag the separator between hidden icons and the Tucker control. Expansion
returns it to 20 points while preserving its saved position. Collapsing grows it
to twice the widest attached display, capped at 10,000 points. This compatibility
path depends on system overflow behavior and has not been runtime-tested here.
macOS 27 drops oversized status items, so this path is not used there.

## Verification and limitations

Development environment: macOS 27.0 (26A428), Xcode 27.0 (27A266a).
The Debug build and the standalone hidden-section selection checks are run locally.
The test executable probes private API availability without activating it.
End-to-end hide/reveal testing is left to the user's Xcode session; compilation
and an availability probe do not establish that the system accepts activation.

New applications launched while collapsed are absent from the current allow-list
and may be hidden until expansion. Arrange icons while expanded; positions are
read again on the next collapse. Mirrored menu bars, multiple displays, crashes,
sleep/wake, and future system-item identifiers still need runtime verification.

## Important files

- `Tucker/MenuBar/HiddenItemsController.swift`: AX inventory, selection, timeout,
  restoration, and legacy spacer.
- `Tucker/MenuBar/NativeVisibility.h` and `.m`: runtime private API bridge.
- `Tucker/MenuBar/MenuBarController.swift`: toggle state, hover, timers, and menu.
- `Tests/HiddenItemSelectionTests.swift`: selection regression checks and read-only
  runtime availability probe.

Research reference: [Hidden Bar's macOS 27 engine](https://github.com/dwarvesf/hidden/blob/develop/hidden/Features/StatusBar/Engine/NativeVisibilityEngine.swift).
Tucker's implementation is maintained locally; no dependency on Hidden Bar is added.
