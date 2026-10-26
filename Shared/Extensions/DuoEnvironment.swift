//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension EnvironmentValues {
    @Entry var duoGeometry: DuoGeometry = DuoGeometry()
}

/// Full-width empty states follow the same horizontal centre as the media
/// canvas. This remains local to each navigation pane, including sheets.
private struct DuoCenteredState: ViewModifier {
    @Environment(\.duoGeometry) private var geometry

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, max(geometry.safeArea.left, geometry.safeArea.right))
            .ignoresSafeArea(.container, edges: .horizontal)
    }
}

extension View {
    @ViewBuilder
    func duoCenteredState() -> some View {
        #if os(iOS)
        modifier(DuoCenteredState())
        #else
        self
        #endif
    }
}
