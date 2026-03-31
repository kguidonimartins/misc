#!/usr/bin/env bash
# Regenerate inst/extdata/misc_example.gdb from GDAL autotest data (read-only mirror).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DST="$ROOT/inst/extdata/misc_example.gdb"
BASE="https://raw.githubusercontent.com/OSGeo/gdal/master/autotest/ogr/data/openfilegdb/polygon_golden.gdb"
FILES="
a00000001.gdbtable a00000001.gdbtablx
a00000002.gdbtable a00000002.gdbtablx
a00000003.gdbtable a00000003.gdbtablx
a00000004.gdbtable a00000004.gdbtablx
a00000005.gdbtable a00000005.gdbtablx
a00000006.gdbtable a00000006.gdbtablx
a00000007.gdbtable a00000007.gdbtablx
a00000009.gdbindexes a00000009.gdbtable a00000009.gdbtablx a00000009.spx
gdb timestamps
"
rm -rf "$DST"
mkdir -p "$DST"
for f in $FILES; do
  curl -fsSL "$BASE/$f" -o "$DST/$f"
done
echo "Wrote $DST"
ogrinfo -so "$DST" || true
