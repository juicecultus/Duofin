# Duofin

A free, open-source Jellyfin client designed for iPhone Duo. Duofin is an independent fork of [Swiftfin](https://github.com/jellyfin/Swiftfin), not an official Jellyfin release.

- Adaptive browsing across the outer and inner displays.
- Playback uses the available display area and keeps video above the fold in laptop pose.
- Original and Fill playback modes, with glass controls that respect system accessibility settings.
- Your own Jellyfin server, your media, your choice.

## Availability

App Store release preparation is in progress. No public Duofin download is available yet.

## Source and licence

Duofin is distributed under the [Mozilla Public License 2.0](LICENSE.md). Copyright and attribution for Jellyfin and Swiftfin contributors are retained. Modified covered source files are available in this repository. Dependency licences remain applicable to their respective components.

Duofin’s original icon uses two offset swept fins in copper and gold, composed as native glass layers in Icon Composer. It does not use the Jellyfin logo.

Duofin changes are maintained by Justinian. Please report fork-specific issues here, rather than to upstream Swiftfin.

## Build

Open `Swiftfin.xcodeproj` in Xcode 27.1. The internal target and scheme retain the name Swiftfin. Set your own signing team in the ignored `XcodeConfig/DevelopmentTeam.xcconfig`; the installed application is named Duofin.

See [Duo development](Documentation/duo-development.md), [validation](Documentation/duo-validation.md), and [upstream documentation](Documentation/upstream-readme.md).
