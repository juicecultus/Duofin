# Duo regression checks

Run `Scripts/duo-max.sh test` from the repository root. It compiles the actual
layout/geometry model and runs the checks on the Max, with outputs under
`/Volumes/OWCM2RAID1/swiftfin-duo`.

The fixture is a read-only snapshot of InkHub's
`AppTests/Fixtures/duo-geometries.json` captured on 25 October 2026. InkHub's
working tree was still being updated. Do not treat these values as runtime
layout constants: production geometry comes from UIKit.

Checks cover real geometry fixtures, inactive camera/fold regions, fold-only
updates, offscreen transition regions, narrow windows, accessibility density,
and restoring the preferred list column count after resizing.

These model checks do not replace simulator and physical Duo testing of the
rendered UI, scroll preservation, playback or PiP.
