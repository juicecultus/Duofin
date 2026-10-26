//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

/// A scene-local adapter, following InkHub's UIKit measurement approach.
/// Observes the fold even when bounds and safe areas have not changed.
struct DuoGeometryReader: UIViewRepresentable {
    let report: (DuoGeometry) -> Void

    func makeUIView(context: Context) -> Probe {
        let view = Probe()
        view.report = report
        return view
    }

    func updateUIView(_ view: Probe, context: Context) {
        view.report = report
        view.read()
    }

    final class Probe: UIView {
        var report: ((DuoGeometry) -> Void)?
        private var last: DuoGeometry?
        private var sceneObservation: NSKeyValueObservation?

        init() {
            super.init(frame: .zero)
            isUserInteractionEnabled = false
            backgroundColor = .clear
            if #available(iOS 27.1, *) {
                addInteraction(UIHingeInteraction { [weak self] _, _ in self?.read() })
            }
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(sceneDidActivate(_:)),
                name: UIScene.didActivateNotification,
                object: nil
            )
            registerForTraitChanges([UITraitHorizontalSizeClass.self, UITraitVerticalSizeClass.self]) {
                (view: Probe, _: UITraitCollection) in view.read()
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) is unavailable")
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            last = nil
            sceneObservation = window?.windowScene?.observe(\.effectiveGeometry, options: [.new]) { [weak self] _, _ in
                DispatchQueue.main.async { self?.read() }
            }
            read()
        }

        @objc
        private func sceneDidActivate(_ notification: Notification) {
            guard let scene = notification.object as? UIWindowScene, scene === window?.windowScene else { return }

            read()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            read()
        }

        override func safeAreaInsetsDidChange() {
            super.safeAreaInsetsDidChange()
            read()
        }

        func read() {
            guard let window, let scene = window.windowScene, bounds.width > 0, bounds.height > 0 else { return }

            // Convert the window's safe rectangle into this view, rather than
            // assuming the probe always fills the window or using UIScreen.main.
            let safe = convert(window.safeAreaLayoutGuide.layoutFrame, from: window).intersection(bounds)
            var value = DuoGeometry()
            value.size = bounds.size
            if !safe.isNull {
                value.safeArea = .init(
                    top: max(0, safe.minY - bounds.minY),
                    left: max(0, safe.minX - bounds.minX),
                    bottom: max(0, bounds.maxY - safe.maxY),
                    right: max(0, bounds.maxX - safe.maxX)
                )
            }
            value.isCompactWidth = traitCollection.horizontalSizeClass != .regular
            value.statusBarHidden = scene.statusBarManager?.isStatusBarHidden ?? false
            if #available(iOS 27.1, *) {
                value.occlusions = reservedRegions(kind: .occlusion, options: .includeInactive).map {
                    .init(frame: $0.frame, isActive: $0.isActive)
                }
                value.divisions = reservedRegions(kind: .division, options: .includeInactive).map {
                    .init(frame: $0.frame, isActive: $0.isActive)
                }
            }
            guard value != last else { return }

            last = value
            // No state mutation inside a SwiftUI layout/update pass. Drop
            // superseded measurements when several passes happen in one turn.
            DispatchQueue.main.async { [weak self] in
                guard let self, self.window != nil, self.last == value else { return }

                self.report?(value)
            }
        }
    }
}

struct DuoGeometryScope: ViewModifier {
    @State
    private var geometry = DuoGeometry()

    func body(content: Content) -> some View {
        content
            .environment(\.duoGeometry, geometry)
            .background {
                DuoGeometryReader { geometry = $0 }
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            }
    }
}
