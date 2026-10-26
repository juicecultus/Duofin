#!/usr/bin/env python3
"""Check user-chooser centres from real XCTest element frames and device images."""
import pathlib
import re
import struct
import sys

label = sys.argv[1]
frame = r"\{\{([\d.-]+), ([\d.-]+)\}, \{([\d.-]+), ([\d.-]+)\}\}"
checks = 0
for arg in sys.argv[2:]:
    log = pathlib.Path(arg)
    screenshots = log.with_name(log.stem + '-screens')
    for block in log.read_text().split('DUO_SCREEN ')[1:]:
        name = block.splitlines()[0]
        is_chooser = name.endswith('capture-users') or name.endswith('tap-Switch user')
        is_media = name.endswith('tap-Media')
        if not (is_chooser or is_media):
            continue
        filename = re.sub(r'[^A-Za-z0-9_-]', '_', name) + '.png'
        png = (screenshots / filename).read_bytes()
        width, height = struct.unpack('>II', png[16:24])
        if is_media:
            cards = re.findall(r'Button,[^\n]*?' + frame + r", label: '(?:Favorites|Movies|TV Shows|Collections|Family Memories)'", block)
            assert len(cards) >= 2, 'Missing media cards'
            bounds = [tuple(map(float, card)) for card in cards]
            dx = (min(c[0] for c in bounds) + max(c[0] + c[2] for c in bounds)) / 2 - width / 6
            print(f'{log.stem}/{name}: media grid horizontal centre error {dx:+.2f} pt')
            assert abs(dx) <= 1, 'Media grid is off centre'
            checks += 1
            continue
        match = re.search(r'Button,[^\n]*?' + frame + r", label: '" + re.escape(label) + "'", block)
        if not match:
            raise SystemExit(f'{log.name}: missing chooser button {label}')
        x, y, w, h = map(float, match.groups())
        # The attached physical Duo reports a 3x scale on both built-in displays.
        dx, dy = x + w / 2 - width / 6, y + h / 2 - height / 6
        print(f'{log.stem}/{name}: centre error {dx:+.2f}, {dy:+.2f} pt')
        assert abs(dx) <= 1 and abs(dy) <= 1, 'User chooser is off centre'
        checks += 1
assert checks, 'No chooser captures found'
print(f'Passed {checks} rendered centring checks')
