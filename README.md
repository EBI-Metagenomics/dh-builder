# dh-builder

Standalone Docker image + Python executor for on-demand rebuilds of a
DataHarmonizer (DH) web bundle from a LinkML schema supplied at runtime.

There is a single shared image, tagged `dh-builder`, built once and used by
both consumers below — they differ only in which `TEMPLATE` they pass at
`docker run` time, not in image content.

Used by:
- [mimicc-ena-submission-assistant](https://github.com/timrozday-mgnify/mimicc-ena-submission-assistant)'s
  admin-only `POST /api/dh/build` endpoint (`server/dh_builder_runner.py`),
  which spawns the `dh-builder` image as a sibling container (default
  `TEMPLATE=mimicc`) the same way that app's `read-helper` spawns
  `enasequence/webin-cli`. Also consumes `scripts/dh_build_steps.sh` directly
  (as a sibling-checkout build context) for its own embedded DH-bundle build
  stage and host-dev script.
- [dataharmonizer-template-builder](https://github.com/timrozday-mgnify/dataharmonizer-template-builder),
  which runs the same `dh-builder` image with `TEMPLATE=template_builder_preview`.

## Layout

- `dh_builder_lib/__init__.py` — `iter_dh_builder_logs()` / `run_dh_builder()`,
  pure-stdlib helpers that shell out to `docker run <image>` and stream its
  log output. Accepts `template` (default `"mimicc"`) and `image` (default
  `"dh-builder"`) keyword args so other consumers can build a different
  template / use a different image tag without forking anything.
- `Dockerfile` — builds the DH-builder image (Node + Yarn + DataHarmonizer;
  entrypoint rebuilds the bundle from `/schema/mimicc.yaml` into `/output`).
- `scripts/dh_build_steps.sh` — the actual LinkML→bundle build steps. This is
  the single canonical copy; consumer repos pull it in via a build context
  rather than forking it (see mimicc-ena-submission-assistant's
  `dh-builder-src` build context for an example).
- `scripts/dh_builder_entrypoint.sh` — the image's entrypoint. Reads
  `TEMPLATE` from the environment (default `"mimicc"`).

## Build

```bash
docker build \
  --build-context dataharmonizer-src=../DataHarmonizer \
  -t dh-builder .
```

## Run

```bash
docker run --rm \
  -v <schema-dir>:/schema:ro \
  -v <output-dir>:/output \
  -e TEMPLATE=mimicc \
  dh-builder
```

Expects `/schema/mimicc.yaml`; writes the built bundle to `/output`. `TEMPLATE`
defaults to `"mimicc"` if unset.
