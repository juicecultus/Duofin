//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import SwiftUI

struct PosterHStack<
    Data: Collection
>: View where Data.Element: Poster, Data.Index == Int {

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    let elements: Data
    let displayType: PosterDisplayType
    let size: PosterDisplayType.Size
    let action: (Data.Element, Namespace.ID) -> Void

    private var layout: CollectionHStackLayout {
        #if os(tvOS)
        .grid(
            columns: displayType == .landscape ? 5 : 7,
            rows: 1,
            columnTrailingInset: 0
        )
        #else
        let baseWidth: CGFloat = switch (displayType, size) {
        case (.landscape, .small): 220
        case (.landscape, .medium): 300
        case (_, .small): 120
        default: 200
        }
        return .minimumWidth(
            columnWidth: baseWidth * (dynamicTypeSize.isAccessibilitySize ? 1.3 : 1),
            rows: 1
        )
        #endif
    }

    var body: some View {
        CollectionHStack(
            uniqueElements: elements,
            layout: layout
        ) { item in
            PosterButton(
                item: item,
                displayType: displayType,
                size: size
            ) { namespace in
                action(item, namespace)
            }
        }
        .clipsToBounds(false)
        .insets(horizontal: EdgeInsets.edgePadding)
        .itemSpacing(UIDevice.isTV ? EdgeInsets.itemSpacing : DuoLayoutMetrics.spacing)
        .scrollBehavior(.continuousLeadingEdge)
        .withViewContext(.isThumb)
    }
}
