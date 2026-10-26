# Duo first adaptation — validation, 25 October 2026

All builds and compiled checks ran on the Max. Source, package checkout and
build outputs are under `/Volumes/OWCM2RAID1/swiftfin-duo`. The Air was used
for editing and for connection to the physical phone.

- Upstream baseline simulator build: **passed** (arm64 and x86_64).
- Adapted simulator build: **passed** (arm64).
- Signed iPhone development build: **passed** (arm64).
- Geometry/model checks: **52 passed**, using **16** recorded InkHub snapshots.
- Geometry adapter type-check against iOS 27.1 SDK with deployment target
  iOS 18.6: **passed**, including availability guards and scene activation.
- Formatting and `git diff --check`: **passed**.
- Simulator installation and launch: **passed** in a dedicated `Swiftfin Duo`
  simulator on the Max; connection screen visually inspected. Screenshot:
  `evidence/simulator-launch.png`.
- Physical Duo installation and launch from the Air: **passed**. The initial
  connection screen was visually checked on the active inner display in
  landscape (2853 × 2007 pixels); screenshot: `evidence/device-launch.png`.
  The outer display was inactive at capture time.
- Release naming check: normal release remains `org.jellyfin.swiftfin`, display
  name `Swiftfin`; only the local development configuration uses
  `com.ratedcounsel.swiftfin.duo` and `Swiftfin Duo`.

The first baseline invocation stopped at Xcode's macro-trust check. Repeating
with the same `-skipMacroValidation` setting as upstream's Fastlane build
succeeded. SwiftFormat and SwiftLint were installed from upstream's Brewfile
requirements. Xcode emitted non-fatal internal JSON diagnostics in both the
baseline and adapted/device compilation; all listed build invocations above
finished with `BUILD SUCCEEDED`.

## Signed-in centering audit

The physical Duo is now signed in. The Max-built XCTest runner in
`Tests/DuoUIAudit` navigates the installed app from the Air without building
there. `Scripts/duo-ui-audit.py` captures the active CoreDevice display; XCTest
screenshots otherwise capture the inactive primary display and appear black.
Private screenshots and account/media trees remain in ignored `build/`.

The audit found asymmetric margins caused by the visible system control rail.
User selection now centers on the full canvas; library grids, item header
content, filter drawers and playback controls use symmetric live safe-area
insets. Each navigation presentation measures its own geometry, preventing
full-window margins from leaking into sheets. Hidden controls can therefore
release the reserved space without a hard-coded rail width.

Completed before the glass follow-up: open landscape settings navigation and
open portrait setup, user selection, Home, Media, Favorites empty state,
Movies, movie details, Search/no results, Settings, Advanced, Items, Libraries,
Posters and Video Player settings. Open portrait navigation passed. Rendered
user chooser centre error was below 0.2 points in both axes. The initial
landscape movie playback was inspected; video was centered, while asymmetric
progress/control insets were subsequently corrected.

Early audit failures came from selecting an offscreen Back button and trying
to tap Home beneath the search keyboard. The runner now uses the visible back
button and relaunches after search. These runs are not counted as complete
pose passes. Remaining fold/rotation and playback cases must be recorded
explicitly; this is not a claim that every nested editor has been checked.

## Adaptive glass

Native glass effects and buttons use the system regular Liquid Glass style,
allowing iOS to apply its glass appearance and accessibility preferences.
Standard backport glass buttons now explicitly select the native glass button
style on iOS as well. The pre-Liquid-Glass fallback observes
`accessibilityReduceTransparency` and composites tinted fills onto an opaque
system background when enabled. No custom forced transparency is applied to
native glass.

InkHub's repository, builds and simulator were not modified. Only read-only
references and a copied measurement fixture were used.

The final glass/device build (`glass-final-build.log`) and simulator build
(`glass-simulator-build.log`) both succeeded on the Max. The physical device
was updated with that build. Partial portrait passed the same core navigation
sequence before the glass-only follow-up, with chooser and Media grid centre
errors below 0.3 points. Partial landscape uses the system's pane-local sheet
presentation; sheets should be centered within their presented pane rather
than forcibly expanded across the fold.

Reduce Transparency was toggled on and off in Device Hub with the app running.
The native chooser toolbar changed appearance immediately, with text and layout
preserved. The Liquid Glass slider was exercised at 0 and 1; its effect is not
strongly distinguishable over the chooser's black background, so that check
only confirms the control can be exercised, not a visual contrast measurement.
Original preferences were restored: Reduce Transparency off, glass slider 0.5.

The closed-display audit exposed a 32.5-point downward chooser displacement
and overlap with the bottom toolbar in landscape. The grid now accounts for
available height, scales its label allowance with Dynamic Type, and uses a
clipped scroll view that centers content when it fits. This avoids unbounded
avatar growth and scrolling content underneath the toolbar. The video fit
viewport now balances both vertical and horizontal measured insets, including
the compact system-safe-area path. `viewport-build.log` passed on the Max and
the resulting app was installed on the device. Verification follows below.

Final compact-landscape verification (`final-closed-a`): chooser centre error
(+0.05, -0.15) points; Media grid horizontal centre error 0.00 points. The
same movie certificate frame moved from a +33.33-point vertical offset before
the viewport fix to -0.17 points afterwards (outer-edge pixel bounds, 3x scale).
Playback and control-hide screenshots were captured. The run later failed
because its assumed Back navigation after dismissing playback did not exist;
those captures verify the layout, but the entire run is not counted as passing.
The subsequent navigation audit uses independent known starting screens.

`final-closed-portrait` passed navigation through Home, Media, Movies, movie
selection, Settings, user selection, sign-in and server connection sheets.
Chooser centre error was (0.00, -0.50) points; Media grid horizontal centre
error was 0.00 points. One movie-detail checkpoint captured its loading state;
that image alone is not counted as a fully loaded detail inspection.

`final-open-browse` passed chooser, Home, Media, movie detail and TV library
navigation on the open landscape display. Chooser error was (-0.05, -0.55)
points and Media grid horizontal error +0.20 points. The final Max geometry
check again passed all 52 checks against 16 fixtures. Formatting checks passed
for the compact grid and video viewport. The UI runner now directs coordinate
gestures to the largest active window rather than an inactive zero-sized Duo
window; earlier gesture-only checkpoints are not treated as proof of scrolling.

`final-series-scroll` passed with the active-window runner. Loaded series
headers, episode cards/descriptions, genres, studios and lower series sections
were visually inspected on the open landscape display. Episode cards retained
balanced layout and native glass controls over artwork. These audits cover
primary browsing, setup, settings and playback layout families; they do not
constitute exhaustive visual coverage of every server-administration editor.

The final build also passed user-chooser rotation checks in open portrait and
partially folded portrait, each with (+0.05, -0.15)-point centre error. These
checks validate the compact-grid change after the earlier broader pose audits.

Final aggregate: 10 rendered chooser/Media centering checks passed across
closed, open and partial portrait/landscape captures; largest measured error
was 0.55 points. Final partial-landscape navigation passed and the device was
left signed in on Home, open in landscape, with playback stopped. Reduce
Transparency remains off and the Liquid Glass setting remains at its original
0.5. InkHub was not modified.
