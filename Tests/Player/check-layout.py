#!/usr/bin/env python3
"""Compile the production layout and zoom math on the Max without a simulator."""
from pathlib import Path
import subprocess
import tempfile
root = Path(__file__).resolve().parents[2]
layout = (root / 'Shared/Views/VideoPlayer/Container/VideoPlayer+VideoLayout.swift').read_text().split('    struct VideoViewport')[0] + '}\n'
size = (root / 'Shared/Extensions/CGSize.swift').read_text().replace('import UIKit', 'import CoreGraphics')
zoom = (root / 'Shared/Objects/VideoZoom.swift').read_text()
tests = '''
let sizes = [CGSize(width: 951, height: 669), CGSize(width: 669, height: 951), CGSize(width: 669, height: 455.5), CGSize(width: 678, height: 466)]
for viewport in sizes {
    for video in [CGSize(width: 2400, height: 1000), CGSize(width: 1920, height: 1080), CGSize(width: 1080, height: 1920)] {
        let bounds = CGRect(origin: .zero, size: viewport)
        let fit = VideoPlayer.VideoLayout(videoSize: video, viewportSize: viewport, behavior: .fit).videoFrame(in: bounds)
        precondition(fit.width <= viewport.width + 0.001 && fit.height <= viewport.height + 0.001)
        let fill = VideoPlayer.VideoLayout(videoSize: video, viewportSize: viewport, behavior: .fill).videoFrame(in: bounds)
        precondition(fill.width >= viewport.width - 0.001 && fill.height >= viewport.height - 0.001)
        var zoom = VideoZoom(geometry: VideoZoom.Geometry(videoSize: video, viewportSize: viewport, fitViewport: bounds))
        precondition(zoom.beginPinch(input: 1, location: CGPoint(x: bounds.midX, y: bounds.midY), fillsViewport: true))
        let pinched = VideoPlayer.VideoLayout(videoSize: video, viewportSize: viewport, behavior: .fill, zoom: zoom).videoFrame(in: bounds)
        precondition(abs(pinched.width - fill.width) < 0.001, "Pinch must start at the displayed fill")
    }
}
print("Passed fit/fill and pinch continuity for 12 Duo/video combinations")
'''
with tempfile.TemporaryDirectory() as tmp:
    source = Path(tmp) / 'main.swift'
    source.write_text('import SwiftUI\nenum VideoPlayer { enum ViewState { enum AspectFillBehavior { case fit, fill } } }\n' + size + zoom + layout + tests)
    binary = Path(tmp) / 'checks'
    subprocess.run(['xcrun', 'swiftc', str(source), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
