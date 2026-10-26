#!/usr/bin/env python3
"""Execute the Max-built runner on the Air; no compilation or signing here."""
import pathlib
import plistlib
import subprocess
import sys
import json
import re
import os
import atexit

root = pathlib.Path(__file__).resolve().parents[1]
name, actions = sys.argv[1:3]
products = root / 'build/audit-products'
source = products / 'DuoUIAudit_iphoneos27.1-arm64.xctestrun'
config = plistlib.loads(source.read_bytes())
config['DuoUIAudit']['EnvironmentVariables']['DUO_ACTIONS'] = actions
if os.environ.get('DUOFIN_REVIEW_PASSWORD'):
    config['DuoUIAudit']['EnvironmentVariables']['DUOFIN_REVIEW_PASSWORD'] = os.environ['DUOFIN_REVIEW_PASSWORD']
config['DuoUIAudit']['UserAttachmentLifetime'] = 'keepAlways'
run = products / (name + '.xctestrun')
run.write_bytes(plistlib.dumps(config))
run.chmod(0o600)
atexit.register(lambda: run.unlink(missing_ok=True))
result = root / 'build' / (name + '.xcresult')
screens = root / 'build' / (name + '-screens')
screens.mkdir(parents=True, exist_ok=True)
device = '00008160-000870981EA80036'
displays = subprocess.check_output(['xcrun', 'devicectl', 'device', 'info', 'displays', '--device', device, '--json-output', '-'], stderr=subprocess.DEVNULL)
(screens / 'display.json').write_bytes(displays)
display = next(d['uniqueId'] for d in json.loads(displays)['result']['displays'] if d['active'])
with (root / 'build' / (name + '.log')).open('w') as log:
    proc = subprocess.Popen(['xcodebuild', 'test-without-building', '-xctestrun', str(run),
        '-destination', 'platform=iOS,id=' + device,
        '-resultBundlePath', str(result)], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
    for line in proc.stdout:
        log.write(line.replace(os.environ["DUOFIN_REVIEW_PASSWORD"], "[redacted]") if os.environ.get("DUOFIN_REVIEW_PASSWORD") else line)
        log.flush()
        if line.startswith('DUO_READY '):
            label = re.sub(r'[^A-Za-z0-9_-]', '_', line.strip().removeprefix('DUO_READY '))
            subprocess.run(['xcrun', 'devicectl', 'device', 'capture', 'screenshot', '--device', device,
                '--display-unique-id', display, '--destination', str(screens / (label + '.png'))],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
            print(label, flush=True)
    status = proc.wait()
print(f'{name}: exit {status}')
sys.exit(status)
