# Standalone image that rebuilds the DataHarmonizer (DH) web bundle from a
# LinkML schema supplied at runtime, rather than baked in at image-build
# time. This lets a future "edit template" UI feature request a rebuild
# without rebuilding the whole app image. Used by both
# mimicc-ena-submission-assistant (server/dh_builder_runner.py) and
# dataharmonizer-template-builder, each spawning this image as a sibling
# container, the same way mimicc-ena-submission-assistant's read-helper
# spawns enasequence/webin-cli.
#
# The template name is configurable via the TEMPLATE env var (see
# scripts/dh_builder_entrypoint.sh), default "mimicc". Pass -e TEMPLATE=...
# on `docker run` for other consumers (e.g. dataharmonizer-template-builder
# uses "template_builder_preview").
#
# Build:
#   docker build \
#     --build-context dataharmonizer-src=../DataHarmonizer \
#     -t mimicc-dh-builder .
#
# Run:
#   docker run --rm -v <schema-dir>:/schema:ro -v <output-dir>:/output mimicc-dh-builder
#   (expects /schema/mimicc.yaml; writes the built bundle to /output)
FROM node:20-slim
RUN apt-get update && apt-get install -y python3 python3-pip && rm -rf /var/lib/apt/lists/*

COPY --from=dataharmonizer-src . /dh-src
RUN pip install --no-cache-dir --break-system-packages -r /dh-src/requirements.txt

# Pre-fetch yarn deps at image-build time so a rebuild only re-runs the
# schema compile + webpack steps, not a full `yarn install`.
RUN cd /dh-src && yarn install --frozen-lockfile

COPY scripts/dh_build_steps.sh /opt/dh_build_steps.sh
COPY scripts/dh_builder_entrypoint.sh /opt/dh_builder_entrypoint.sh
RUN chmod +x /opt/dh_builder_entrypoint.sh

ENTRYPOINT ["/opt/dh_builder_entrypoint.sh"]
