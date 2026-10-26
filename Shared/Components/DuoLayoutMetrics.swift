//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreGraphics
import Foundation

/// InkHub's useful browsing rules: 16-point gutters, stable card sizes,
/// and fewer columns at accessibility text sizes. No device model checks.
enum DuoLayoutMetrics {
    static let gutter: CGFloat = 16
    static let spacing: CGFloat = 12
    static let minimumTarget: CGFloat = 44

    static func columns(width: CGFloat, minimumWidth: CGFloat, accessibility: Bool = false) -> Int {
        guard width.isFinite, width > 0, minimumWidth.isFinite, minimumWidth > 0 else { return 1 }

        let count = max(1, Int((width + spacing) / (minimumWidth + spacing)))
        return accessibility ? max(1, count - 1) : count
    }

    static func listColumns(width: CGFloat, preferred: Int, accessibility: Bool = false) -> Int {
        min(max(1, preferred), columns(width: width, minimumWidth: 300, accessibility: accessibility))
    }
}

/// All frames use the probe's coordinate space; left/right are physical,
/// never semantic leading/trailing. Size classes describe space, not hardware.
struct DuoGeometry: Equatable {
    struct Insets: Equatable {
        var top: CGFloat = 0
        var left: CGFloat = 0
        var bottom: CGFloat = 0
        var right: CGFloat = 0
    }

    struct Region: Equatable {
        var frame: CGRect
        var isActive: Bool
    }

    var size: CGSize = .zero
    var safeArea = Insets()
    var isCompactWidth = true
    var occlusions: [Region] = []
    var divisions: [Region] = []
    var statusBarHidden = false

    var activeOcclusions: [CGRect] {
        occlusions.filter(\.isActive).map(\.frame)
    }

    var activeDivisions: [CGRect] {
        // Ignore stale/offscreen regions during display transitions.
        let bounds = CGRect(origin: .zero, size: size)
        return divisions.filter(\.isActive)
            .map { $0.frame.intersection(bounds) }
            .filter { !$0.isNull && $0.width > 0 && $0.height > 0 }
    }
}

// A horizontal active division separates the laptop screen from its controls.
// Vertical book folds and inactive (flat) divisions leave playback full-screen.
extension DuoGeometry {
    var laptopDivision: CGRect? {
        activeDivisions.first {
            $0.width >= size.width * 0.8 && $0.width > $0.height &&
                $0.minY > size.height * 0.15 && $0.maxY < size.height * 0.85
        }
    }
}
