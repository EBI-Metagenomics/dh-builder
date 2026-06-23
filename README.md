# dh-builder

Standalone Docker image + Python executor for on-demand rebuilds of a
DataHarmonizer (DH) web bundle from a LinkML schema supplied at runtime.

Used by [mimicc-ena-submission-assistant](https://github.com/timrozday-mgnify/mimicc-ena-submission-assistant)'s
admin-only `POST /api/dh/build` endpoint (`server/dh_builder_runner.py`),
which spawns the `mimicc-dh-builder` image as a sibling container the same
way that app's `read-helper` spawns `enasequence/webin-cli`.

## Layout

- `dh_builder_lib/__init__.py` — `iter_dh_builder_logs()` / `run_dh_builder()`,
  pure-stdlib helpers that shell out to `docker run mimicc-dh-builder` and
  stream its log output. Vendored by mimicc-ena-submission-assistant's
  `scripts/vendor.sh` (`DH_BUILDER` sibling checkout, default `../dh-builder`).
- `Dockerfile` — builds the `mimicc-dh-builder` image (Node + Yarn +
  DataHarmonizer, entrypoint rebuilds the bundle from `/schema/mimicc.yaml`
  into `/output`).
- `scripts/dh_builder_entrypoint.sh` — the image's entrypoint.

## Build

`scripts/dh_build_steps.sh`, the actual LinkML→bundle build steps, is **not**
vendored into this repo — it's shared with mimicc-ena-submission-assistant's
embedded DH-bundle Dockerfile stage and its host-dev
`scripts/build_dh_template.sh`, so it's pulled in here via an additional
build context pointing at that repo's `scripts/` directory. This keeps a
single source of truth across the three build paths.

```bash
docker build \
  --build-context dataharmonizer-src=../DataHarmonizer \
  --build-context mimicc-scripts=../mimicc-ena-submission-assistant/scripts \
  -t mimicc-dh-builder .
```

## Run

```bash
docker run --rm \
  -v <schema-dir>:/schema:ro \
  -v <output-dir>:/output \
  mimicc-dh-builder
```

Expects `/schema/mimicc.yaml`; writes the built bundle to `/output`.
