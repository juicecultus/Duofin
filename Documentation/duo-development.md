# Duo development

## Build location

Build on the Max (`max-lan`), under `/Volumes/OWCM2RAID1/swiftfin-duo`.
The local repository is the editing checkout. InkHub is a read-only reference;
there is no linked package or build dependency on its working tree.

- `Scripts/duo-max.sh build`: sync source, build the iOS simulator app.
- `Scripts/duo-max.sh test`: sync source, compile/run the geometry regression checks.
- Remote logs: `baseline.log` (unmodified upstream) and `build.log` (adaptation).
- Remote outputs: `DerivedData`, `SourcePackages`, and `duo-layout-tests`.

The build uses Swiftfin’s own CI macro setting (`-skipMacroValidation`) and
builds arm64 for the Max’s simulator.

The script does not delete remote files, sign for a device, install an app or
publish anything. Do not run concurrent sync/build commands against this same
remote source directory.

## First adaptation

The geometry adapter reads the current view/window, physical safe-area edges,
size class, status visibility, active and inactive occlusion/division regions.
It observes trait, layout, safe-area, scene-geometry and hinge updates. Hinge
angle is not used to infer layout. Updates are deduplicated and delivered
outside SwiftUI's layout pass. Public Duo APIs are guarded at iOS 27.1; the
existing iOS 18.6 deployment floor is retained.

The snapshot is available as `EnvironmentValues.duoGeometry`; its rectangles
are in the root probe's coordinate space. A nested player or other consumer
must convert coordinates before applying those rectangles to local content.
Browsing grids use their own measured width, not this scene width, so a sidebar
or narrow window does not produce too many columns.

Library grids and lists adapt to actual usable width. List preferences remain
stored when a narrow view temporarily limits columns. Poster/episode shelves
use minimum widths rather than the device's iPhone/iPad identity. User grids
resize, and regular-width navigation uses the system's adaptable sidebar.
Browsing allows landscape as playback already did. The full-screen-only opt-out
is removed so the browser can resize in a shared window; the iPad orientation
declaration now includes all four orientations for multitasking.

## InkHub design-system references

Adopted: 16-point outer gutters for user selection, 12-point card spacing,
stable poster sizes across displays, fewer columns for accessibility sizes,
and up to four title lines at accessibility sizes. System navigation keeps
Liquid Glass where supported, with Swiftfin's existing media artwork and
semantic text styling. InkHub's reader-specific paper treatment, fonts, rails,
and pagination are not imported into the media browser.

## Remaining work

This is the geometry and responsive-browsing stage. Player constraints,
fold-separated video/controls, subtitle avoidance and replacement of the
player's legacy notch reader remain a later stage. The current browser does
not yet route individual custom collection cells around an active crease;
even column counts alone would not guarantee that alignment.

Physical Duo acceptance still needs a Jellyfin account: unfold/fold and rotate
while browsing; check selection, scroll position and filter preservation;
check both outer landscape orientations, inner portrait/landscape, narrow
windows, accessibility text, RTL, search keyboard and sheets. Then test native
and MPV playback, including PiP. Model checks are not rendered-device proof.

## Development device identity

The local ignored `XcodeConfig/DevelopmentTeam.xcconfig` supplies the signing
team and separate `com.ratedcounsel.swiftfin.duo` bundle identifier. It also
sets `SWIFTFIN_DISPLAY_NAME = Swiftfin Duo`; upstream defaults remain Swiftfin.
The Max uses its existing development identity and provisioning API key;
private keys and passwords are never copied into this repository.

Device builds use the same Max source/packages/DerivedData paths with
`-destination 'generic/platform=iOS'`, automatic development provisioning,
and the CI macro setting. The resulting `Debug-iphoneos/Swiftfin.app` is
transferred to the Air and installed with `devicectl` on the connected Duo.
