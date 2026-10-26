# Swiftfin adaptation for iPhone Duo

Inspected 25 October 2026. Swiftfin upstream main: `2e354062e0d510fac40cce6d4bb2ad423f7431d0`. Reference: `/Users/justin/projects/inkhub-ios`, HEAD `2cd8734b0666f94e06b2d5b5534cf46552697521` plus its active working changes. InkHub is being edited concurrently; this is a point-in-time assessment, not a claim that its current layout implementation is final.

## Conclusion

Swiftfin is a viable base. Keep its Jellyfin integration and media-session architecture. Adapt the presentation layer and validate both native and MPV playback through display changes. This is a meaningful UI adaptation, not merely enabling iPad layouts and not a player rewrite.

This inspection cloned Swiftfin and read source, InkHub device geometry documentation/tests, and the installed iOS 27.1 SDK headers. No application code was changed, no builds or playback tests were run, and no Duo compatibility is certified yet.

## Concrete changes

| Priority | Evidence in Swiftfin | Required change |
|---|---|---|
| First | `Swiftfin/App/SwiftfinApp.swift:33` restricts non-iPad browsing to portrait. Playback separately allows all orientations except upside down. | Permit intended Duo browsing orientations; test both outer landscape directions and inner portrait/landscape. |
| First | `Shared/Components/LibraryElement.swift:78` fixes phone grids to two landscape or three portrait posters. `PosterHStack.swift`, user selection, episode collections, EPG sizing and library settings also branch on device idiom. | Pass actual container geometry and traits into layout decisions. Choose columns by usable width, including split-window widths. Keep cards clear of an active division; do not globally redefine `isPad`. |
| First | `Shared/Views/VideoPlayer/Container/VideoPlayer+Container.swift:622`, `:688`, `:774` classify compact playback by phone idiom plus portrait aspect ratio. Its layout refresh guard watches size and safe areas. | Replace this with explicit playback layout modes. Observe division/occlusion changes as well as size/safe area: partially folding can change regions without changing bounds. |
| First | No reserved-region, hinge-interaction or arrangement-view use was found in Swiftfin Swift sources. | Add one scene-local geometry adapter for bounds, traits, physical safe areas, active occlusions, active divisions and status visibility. Use SDK availability guards if retaining older OS support. |
| First | `Swiftfin/Components/NotchReader.swift` dynamically invokes private cutout/corner-radius selectors and assumes a single cutout rectangle. | Use public reserved-region data on Duo. Retain a safe-area fallback where unavailable. Audit consumers for assumptions that one edge inset represents every obstruction. |
| First | `Swiftfin/Views/VideoPlayer/PlaybackControls/PlaybackControls.swift` lays controls in a top toolbar, bottom progress and central button overlay. | Define control, subtitle and gesture regions for each playback mode. Avoid camera/status occlusions and active folds. Showing controls must not unintentionally resize video. |
| Next | `Shared/Coordinators/Tabs/MainTabView.swift` uses the iOS tab presentation; sidebar-adaptable style appears only in its tvOS branch. | Evaluate adaptive navigation for wide layouts while preserving the existing tab coordinator and navigation paths. A sidebar is a product choice, not a compatibility prerequisite. |

## Playback continuity: preserve the useful architecture

`VideoPlayer.swift` receives a `MediaSession` and only attaches a player if one is absent. `Container.dismantleUIViewController` detaches its surface rather than stopping the session. `viewDidDisappear` stops only through actual dismissal handling, with PiP checks. These are good foundations for resizing.

Keep session ownership stable above layout branches. Prefer rearranging the same player/controller to constructing a new player per pose. Confirm continuity rather than assuming it: time, pause state, selected audio/subtitles, queue, buffering, casting and PiP must survive folding and rotation. Ensure posture changes never look like user dismissal.

## InkHub foundations to reuse

- `App/Reader/ReaderGeometryProbe.swift`: UIKit window measurements; layout, safe-area and trait change observation; division and occlusion reads; hinge interaction as an update trigger. Separate this from InkHub theme, reader logging and page-colour dependencies.
- `docs/design/duo-layout-topology.md`: device-observed geometry and the distinction between content, overlays and system obstructions.
- `AppTests/Fixtures/duo-geometries.json`: measured outer portrait, both outer landscape directions, inner portrait/landscape and folded variants; use as test inputs, not production constants.
- `App/Topology/LayoutRules.swift`, `App/Topology/LayoutAudit.swift`, `AppUITests/LayoutTopologyUITests.swift`: check actual rendered frames rather than only a layout calculation. Define video-specific rules.

Do not copy the reader's pagination, comic cropping policy, fixed rail dimensions or exact furniture placement into a video app. Do not make hinge angle the source of layout geometry. Treat width class as a layout trait rather than universal hardware identification, especially in split windows. InkHub's document and current rail rule implementation contain evolving placement details; reconcile them before extracting a reusable component.

The installed SDK includes public arrangement view-controller APIs, so a system arrangement for video plus controls is worth prototyping. The reference app targets iOS 27.1; retaining Swiftfin's broader support versus making a Duo-focused target is an implementation decision to settle before adding these APIs.

## Proposed video behavior

- Closed: compact browsing; normal full-screen playback with controls clear of the physical obstructions.
- Open flat: wider browsing grids and optional sidebar; one continuous video surface with explicit fit/fill behavior.
- Partially folded with horizontal division: prototype video above the division and playback controls/chapters/queue below it.
- Partially folded with vertical division: keep actionable controls and subtitles out of the crease; evaluate one-pane video with adjacent details versus continuous video. Do not automatically apply InkHub's two-page layout to a film.

These are proposed product behaviors, not features verified in the current app.

## Suggested delivery sequence

1. Establish a baseline build and playback on Duo; record failures and make a separate app identifier for development.
2. Add a small geometry adapter, fixtures and video-specific layout rules. Keep InkHub untouched while its current work finishes.
3. Fix browsing orientation and idiom-dependent layouts. Preserve selection, scroll positions, filters and navigation across resizing.
4. Adapt player constraints/controls for flat and folded layouts without replacing the media session.
5. Exercise native and MPV playback on hardware, then refine appearance.

## Acceptance checks

Test closed portrait; outer landscape both ways; inner portrait and landscape; horizontal and vertical active divisions; narrow split windows; light/dark; larger text and RTL. Include camera/status changes, controls hidden/shown, keyboard and sheets, and transitions during scrubbing.

For native and MPV playback: open/close while playing and paused; change orientation; background/foreground; PiP and return; subtitles and audio selection; next episode; direct play and server-transcoded media. Assert no duplicate sessions, accidental stop, lost playback position, inaccessible controls or subtitle collision. Inspect actual render frames and real-device recordings; InkHub explicitly documents simulator/device geometry discrepancies.

No effort estimate is committed before a baseline build and a player-layout prototype. Browsing is relatively contained; player geometry and device transition validation are the main uncertainty.
