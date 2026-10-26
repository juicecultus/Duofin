//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SettingsBarButton: View {

    let server: ServerState
    let user: UserState
    let action: () -> Void
    @State private var showingSupport = false

    var body: some View {
        Menu {
            Button(action: action) { Label(L10n.settings, systemImage: "gearshape") }
            Button { showingSupport = true } label: {
                Label("Support Duofin", systemImage: "heart")
            }
            .accessibilityIdentifier("navigation.more.support")
        } label: {
            Image(systemName: "ellipsis")
        }
        .accessibilityLabel("More")
        .accessibilityIdentifier("navigation.more")
        .sheet(isPresented: $showingSupport) { SupportDevelopmentView() }
    }
}
