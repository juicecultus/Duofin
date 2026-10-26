//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreGraphics
import Foundation

var checks = 0
func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    checks += 1
    guard condition() else { fatalError(message) }
}

// Measured widths, plus a narrow split window. Cards must fit their actual
// content area, and expanding a window must reveal more cards, not scale type.
let widths: [CGFloat] = [240, 350, 550, 835]
var previous = 0
for width in widths {
    let count = DuoLayoutMetrics.columns(width: width, minimumWidth: 120)
    check(count >= previous, "Wider windows must not lose columns")
    check(
        (width - CGFloat(count - 1) * DuoLayoutMetrics.spacing) / CGFloat(count) >= 120,
        "Cards must meet the readable minimum width"
    )
    check(
        DuoLayoutMetrics.columns(width: width, minimumWidth: 120, accessibility: true) <= count,
        "Larger text needs fewer columns"
    )
    previous = count
}

check(DuoLayoutMetrics.columns(width: .nan, minimumWidth: 120) == 1, "Invalid transient width")
check(DuoLayoutMetrics.columns(width: 0, minimumWidth: 120) == 1, "First layout pass")
check(DuoLayoutMetrics.listColumns(width: 350, preferred: 3) == 1, "Wide-layout preference must collapse")
check(DuoLayoutMetrics.listColumns(width: 950, preferred: 3) == 3, "Restore wide-layout preference")

struct Fixtures: Decodable {
    struct Snapshot: Decodable {
        struct Region: Decodable { var frame: [CGFloat]
            var isActive: Bool
        }

        var name: String
        var size: [CGFloat]
        var widthClass: String
        var divisions: [Region]
        var occlusions: [Region]
    }

    var snapshots: [Snapshot]
}

let path = CommandLine.arguments[1]
let fixtures = try JSONDecoder().decode(Fixtures.self, from: Data(contentsOf: URL(fileURLWithPath: path)))
func region(_ r: Fixtures.Snapshot.Region) -> DuoGeometry.Region {
    .init(frame: CGRect(x: r.frame[0], y: r.frame[1], width: r.frame[2], height: r.frame[3]), isActive: r.isActive)
}

for snapshot in fixtures.snapshots {
    var geometry = DuoGeometry()
    geometry.size = CGSize(width: snapshot.size[0], height: snapshot.size[1])
    geometry.isCompactWidth = snapshot.widthClass == "compact"
    geometry.occlusions = snapshot.occlusions.map(region)
    geometry.divisions = snapshot.divisions.map(region)
    check(
        geometry.activeOcclusions.count == snapshot.occlusions.filter(\.isActive).count,
        "Do not avoid an inactive inner camera: \(snapshot.name)"
    )
    for division in geometry.activeDivisions {
        check(CGRect(origin: .zero, size: geometry.size).contains(division), "Fold must be in current view")
    }
    if snapshot.divisions.allSatisfy({ !$0.isActive }) {
        check(geometry.activeDivisions.isEmpty, "A flat display must not be split")
    }
}

var geometry = DuoGeometry()
geometry.size = CGSize(width: 466, height: 678)
geometry.divisions = [.init(frame: CGRect(x: 900, y: 0, width: 40, height: 669), isActive: true)]
check(geometry.activeDivisions.isEmpty, "Discard offscreen fold during closing")
geometry.size = CGSize(width: 951, height: 669)
geometry.divisions = [.init(frame: CGRect(x: 455.5, y: 0, width: 40, height: 669), isActive: false)]
let flat = geometry
geometry.divisions[0].isActive = true
check(geometry != flat, "A fold-only change must publish without a bounds change")
check(geometry.activeDivisions.count == 1, "Active vertical fold")
geometry.size = CGSize(width: 669, height: 951)
geometry.divisions = [.init(frame: CGRect(x: 0, y: 455.5, width: 669, height: 40), isActive: true)]
check(geometry.activeDivisions.first?.height == 40, "Active horizontal fold")
check(geometry.laptopDivision?.minY == 455.5, "Laptop video ends above the active horizontal fold")
geometry.divisions[0].isActive = false
check(geometry.laptopDivision == nil, "Unfold restores the full canvas without a size change")
geometry.size = CGSize(width: 951, height: 669)
geometry.divisions = [.init(frame: CGRect(x: 455.5, y: 0, width: 40, height: 669), isActive: true)]
check(geometry.laptopDivision == nil, "A book fold must not enable laptop layout")
print("Passed \(checks) Duo layout checks against \(fixtures.snapshots.count) recorded snapshots")
