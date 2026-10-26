# Physical Duo UI audit

Compile this standalone XCTest bundle with XcodeGen and `build-for-testing` on
the Max, under `/Volumes/OWCM2RAID1/swiftfin-duo/AuditDerivedData`. Copy its
`Build/Products` directory to `build/audit-products` on the Air. Do not compile
on the Air and do not use InkHub's builds or simulator.

From the repository root on the Air:

```sh
python3 Scripts/duo-ui-audit.py unique-run-name 'capture:users|tap:jelly|tap:Media'
python3 Scripts/check-duo-audit.py jelly build/unique-run-name.log
```

The runner executes against the already installed development app. It can
change navigation, search text and playback state. Use test accounts/content
where appropriate. Do not include passwords in actions. The argument syntax
is `command:value`, separated by `|`; see `Audit.swift` for supported commands.
Use a new run name because Xcode does not overwrite result bundles.

Set a pose using Device Hub before each run, and keep it fixed until the run
finishes. The host discovers the active display and captures it after each
checkpoint; XCTest's default screenshot may target the inactive Duo display.
The log and result bundle contain accessibility frames and screen attachments.
The host screenshots are in `build/<run>-screens` and are private ignored files.

A successful test run proves navigation completed, not that every screen is
visually correct. Inspect the screenshots too. The centering checker separately
checks user chooser and Media grid bounds using actual rendered frames. It is
specific to the attached Duo's 3x display scale and current media library names.

After a no-results search, `launch:` returns to Home without relying on a tab
button obscured by the keyboard. `back:` selects the Duo back button or the
navigation bar fallback. Back/Close transitions are not screenshot checkpoints;
add `capture:name` after one when a post-dismissal image is needed.
