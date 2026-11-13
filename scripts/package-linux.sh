#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?Usage: package-linux.sh VERSION}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
STAGE_DIR="${DIST_DIR}/pTime-${VERSION}-linux-x86_64"
APP_DIR="${DIST_DIR}/AppDir"

rm -rf "${STAGE_DIR}" "${APP_DIR}"
mkdir -p "${STAGE_DIR}" "${APP_DIR}/usr/bin" "${APP_DIR}/usr/share/applications" \
  "${APP_DIR}/usr/share/icons/hicolor/256x256/apps" \
  "${APP_DIR}/usr/share/metainfo"

cp "${ROOT_DIR}/ptime" "${STAGE_DIR}/ptime"
cp "${ROOT_DIR}/libsqlite3.so" "${STAGE_DIR}/libsqlite3.so"
cp "${ROOT_DIR}/readme.md" "${ROOT_DIR}/LICENSE" "${ROOT_DIR}/EULA.md" "${STAGE_DIR}/"
tar -C "${DIST_DIR}" -czf "${DIST_DIR}/pTime-${VERSION}-linux-x86_64.tar.gz" \
  "pTime-${VERSION}-linux-x86_64"

cp "${ROOT_DIR}/ptime" "${APP_DIR}/usr/bin/ptime"
cp "${ROOT_DIR}/libsqlite3.so" "${APP_DIR}/usr/bin/libsqlite3.so"
cp "${ROOT_DIR}/readme.md" "${ROOT_DIR}/LICENSE" "${ROOT_DIR}/EULA.md" "${APP_DIR}/"

cat > "${APP_DIR}/AppRun" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_ROOT="${XDG_DATA_HOME:-${HOME}/.local/share}/pTime"
mkdir -p "${DATA_ROOT}"
cp "${APP_DIR}/usr/bin/ptime" "${DATA_ROOT}/ptime"
cp "${APP_DIR}/usr/bin/libsqlite3.so" "${DATA_ROOT}/libsqlite3.so"
chmod +x "${DATA_ROOT}/ptime"
exec "${DATA_ROOT}/ptime" "$@"
EOF
chmod +x "${APP_DIR}/AppRun" "${APP_DIR}/usr/bin/ptime"

cat > "${APP_DIR}/ptime.desktop" <<EOF
[Desktop Entry]
Name=pTime
Comment=Portable project time tracker
Exec=ptime
Icon=ptime
Type=Application
Categories=Office;
Terminal=false
EOF
cp "${APP_DIR}/ptime.desktop" "${APP_DIR}/usr/share/applications/ptime.desktop"

cat > "${APP_DIR}/usr/share/metainfo/io.github.pablissimo77.ptime.metainfo.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>io.github.pablissimo77.ptime</id>
  <name>pTime</name>
  <summary>Portable project time tracker</summary>
  <metadata_license>CC0-1.0</metadata_license>
  <project_license>MIT</project_license>
  <url type="homepage">https://github.com/pablissimo77/pTime</url>
  <launchable type="desktop-id">ptime.desktop</launchable>
  <categories>
    <category>Office</category>
  </categories>
</component>
EOF

if command -v convert >/dev/null 2>&1; then
  convert "${ROOT_DIR}/ptime.ico[0]" "${APP_DIR}/ptime.png"
  cp "${APP_DIR}/ptime.png" "${APP_DIR}/usr/share/icons/hicolor/256x256/apps/ptime.png"
fi

APPIMAGE_TOOL="${RUNNER_TEMP:-/tmp}/appimagetool-x86_64.AppImage"
APPIMAGE_PATH="${DIST_DIR}/pTime-${VERSION}-linux-x86_64.AppImage"
if [ ! -x "${APPIMAGE_TOOL}" ]; then
  curl -L --fail --retry 3 \
    -o "${APPIMAGE_TOOL}" \
    https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
  chmod +x "${APPIMAGE_TOOL}"
fi

RUNTIME_FILE="${RUNNER_TEMP:-/tmp}/runtime-x86_64"
if [ ! -f "${RUNTIME_FILE}" ]; then
  curl -L --fail --retry 3 \
    -o "${RUNTIME_FILE}" \
    https://github.com/AppImage/type2-runtime/releases/download/continuous/runtime-x86_64
fi

(cd "${DIST_DIR}" && ARCH=x86_64 "${APPIMAGE_TOOL}" --appimage-extract-and-run \
  --runtime-file "${RUNTIME_FILE}" \
  --updateinformation "gh-releases-zsync|pablissimo77|pTime|latest|pTime-*-linux-x86_64.AppImage.zsync" \
  "${APP_DIR}" \
  "${APPIMAGE_PATH}")

if ! command -v zsyncmake >/dev/null 2>&1; then
  echo "ERROR: zsyncmake is required to create the AppImage update file." >&2
  echo "Install it with: sudo apt install zsync" >&2
  exit 1
fi

RELEASE_URL="https://github.com/pablissimo77/pTime/releases/download/v${VERSION}/pTime-${VERSION}-linux-x86_64.AppImage"
zsyncmake -C -e -u "${RELEASE_URL}" \
  -o "${DIST_DIR}/pTime-${VERSION}-linux-x86_64.AppImage.zsync" \
  "${APPIMAGE_PATH}"

rm -rf "${STAGE_DIR}" "${APP_DIR}"
