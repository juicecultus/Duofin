#!/usr/bin/env python3
"""Check an actual default dark welcome screenshot (requires Pillow).

Measures the rendered purple Connect button and message, not SwiftUI's
computed layout. Run against a screenshot taken before connecting a server.
The active display must be captured, not Duo's inactive outer display.
"""
import argparse
import json
from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument('screenshot')
parser.add_argument('--scale', type=float, default=3)
args = parser.parse_args()
im = Image.open(args.screenshot).convert('RGB')
w, h = im.size
pixels = im.load()
button = []
content = []
for y in range(h // 4, 3 * h // 4):
    for x in range(w // 6, 5 * w // 6):
        r, g, b = pixels[x, y]
        if r > 100 and b > 100 and g < r * .8 and g < b * .8:
            button.append((x, y))
        if max(r, g, b) > 70:
            content.append((x, y))
assert button and content, 'Expected the default dark connection screen on the active display'

def midpoint(points):
    xs, ys = zip(*points)
    return ((min(xs) + max(xs) + 1) / 2, (min(ys) + max(ys) + 1) / 2)

logo = [(x, y) for y in range(h // 4) for x in range(w)
        if pixels[x, y][2] > 80 and pixels[x, y][0] < 100
        and pixels[x, y][2] > pixels[x, y][0] * 1.5]
assert logo, 'Expected the welcome logo'
lx, _ = midpoint(logo)
bx, _ = midpoint(button)
cx, cy = midpoint(content)
errors = {'logo_x_error_points': (lx - w / 2) / args.scale,
          'button_x_error_points': (bx - w / 2) / args.scale,
          'content_x_error_points': (cx - w / 2) / args.scale,
          'content_y_error_points': (cy - h / 2) / args.scale}
print(json.dumps(errors, indent=2))
assert abs(errors['logo_x_error_points']) <= 1, 'Logo is not horizontally centred'
assert abs(errors['button_x_error_points']) <= 1, 'Connect button is not horizontally centred'
assert abs(errors['content_x_error_points']) <= 1, 'Welcome content is not horizontally centred'
# Glyph ink bounds differ slightly from typographic layout bounds.
assert abs(errors['content_y_error_points']) <= 4, 'Welcome content is not vertically centred'
print('Rendered welcome centering passed')
