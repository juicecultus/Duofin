#!/bin/bash
# Isolated Swiftfin build/test on the Max. Does not touch InkHub or install apps.
set -euo pipefail
cd "$(dirname "$0")/.."
remote=max-lan
root=/Volumes/OWCM2RAID1/swiftfin-duo
mode=${1:-build}
case "$mode" in build|test) ;; *) echo 'Usage: Scripts/duo-max.sh [build|test]' >&2; exit 2 ;; esac
ssh "$remote" "mkdir -p '$root/source'"
rsync -az --exclude .git --exclude build --exclude .build ./ "$remote:$root/source/"
if [[ "$mode" == test ]]; then
    ssh "$remote" "set -e; cd '$root/source'; xcrun swiftc Shared/Components/DuoLayoutMetrics.swift Tests/Duo/main.swift -o '$root/duo-layout-tests'; '$root/duo-layout-tests' Tests/Duo/Fixtures/duo-geometries.json"
else
    ssh "$remote" "cd '$root/source'; xcodebuild -project Swiftfin.xcodeproj -scheme Swiftfin -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath '$root/DerivedData' -clonedSourcePackagesDirPath '$root/SourcePackages' -skipMacroValidation ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO > '$root/build.log' 2>&1; result=\$?; tail -45 '$root/build.log'; exit \$result"
fi
