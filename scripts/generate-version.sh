#!/usr/bin/env bash
set -euo pipefail

PROJECT_FILE="${1:-ptime.lpi}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="${ROOT_DIR}/${PROJECT_FILE}"

if [ ! -f "${PROJECT_PATH}" ]; then
  echo "Project file not found: ${PROJECT_PATH}" >&2
  exit 1
fi

read_version_field() {
  sed -n "s/.*<$1 Value=\"\([0-9][0-9]*\)\"\/>.*/\1/p" "${PROJECT_PATH}" | head -n 1
}

MAJOR="$(read_version_field MajorVersionNr)"
MINOR="$(read_version_field MinorVersionNr)"
REVISION="$(read_version_field RevisionNr)"

if [ -z "${MAJOR}" ] || [ -z "${MINOR}" ] || [ -z "${REVISION}" ]; then
  echo "Could not read version fields from ${PROJECT_FILE}" >&2
  exit 1
fi

VERSION="${MAJOR}.${MINOR}.${REVISION}"
cat > "${ROOT_DIR}/version.inc" <<EOF
const
  PTIME_VERSION = '${VERSION}';
EOF

printf '%s\n' "${VERSION}"
