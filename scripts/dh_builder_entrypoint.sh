#!/usr/bin/env bash
# Entrypoint for the dh-builder image: rebuild the DataHarmonizer bundle
# from a schema supplied at /schema/mimicc.yaml, write the bundle to
# /output. Used by dh_builder_lib (server-triggered on-demand rebuild) and
# can also be run manually:
#   docker run --rm -v <schema-dir>:/schema:ro -v <output-dir>:/output mimicc-dh-builder
#
# TEMPLATE defaults to "mimicc"; pass -e TEMPLATE=<name> on `docker run` to
# build a different template (e.g. dataharmonizer-template-builder uses
# "template_builder_preview").
set -euo pipefail

SCHEMA="${1:-/schema/mimicc.yaml}"
OUT="${2:-/output}"
TEMPLATE="${TEMPLATE:-mimicc}"

bash /opt/dh_build_steps.sh /dh-src "$SCHEMA" "$TEMPLATE"

echo ">> Copying bundle into $OUT"
mkdir -p "$OUT"
rm -rf "${OUT:?}"/*
cp -R /dh-src/web/dist/. "$OUT/"
echo "Done."
