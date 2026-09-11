# Changelog

## [0.22.0](https://github.com/GlueOps/docs-argocd/compare/v0.21.0...v0.22.0) (2026-09-11)


### Features

* install the Argo CD OTEL UI extension on every cluster ([#53](https://github.com/GlueOps/docs-argocd/issues/53)) ([45a0911](https://github.com/GlueOps/docs-argocd/commit/45a091110d77ecd01db7eb94c114ad07ec051b33))

## [0.21.0](https://github.com/GlueOps/docs-argocd/compare/v0.20.0...v0.21.0) (2026-09-05)


### Features

* accept the toolbox edge token and route the CLI through bearer-preserving middlewares ([#63](https://github.com/GlueOps/docs-argocd/issues/63)) ([de01b66](https://github.com/GlueOps/docs-argocd/commit/de01b669fdd5a93f65ef5e8fd84580668ccae0dd))

## [0.20.0](https://github.com/GlueOps/docs-argocd/compare/v0.19.1...v0.20.0) (2026-08-26)


### ⚠ BREAKING CHANGES

* on existing clusters the next helm upgrade of the argocd release deletes the live gates.platform.glueops.dev CRD (no Gate resources exist in prod). Run the captain_utils crds step again after the argocd upgrade to recreate it from the bundle.

### Features

* remove the Gate CRD from extraObjects (shipped by platform-crds) ([#62](https://github.com/GlueOps/docs-argocd/issues/62)) ([ba17215](https://github.com/GlueOps/docs-argocd/commit/ba17215b8b94c04c429c30c397af3c061b9cec5e))


### Miscellaneous Chores

* add Apache-2.0 LICENSE ([#59](https://github.com/GlueOps/docs-argocd/issues/59)) ([9127232](https://github.com/GlueOps/docs-argocd/commit/91272326a18f634b2018e8f0698e018848087a17))

## [0.19.1](https://github.com/GlueOps/docs-argocd/compare/v0.19.0...v0.19.1) (2026-07-03)


### Miscellaneous Chores

* delete legacy PRCHECKLIST ([#56](https://github.com/GlueOps/docs-argocd/issues/56)) ([abe5df4](https://github.com/GlueOps/docs-argocd/commit/abe5df4e6ae3aa4a5ea4b03c6d22592e9f573a5f))


### Code Refactoring

* **argocd:** consolidate node pinning into global affinity preset ([d3ed075](https://github.com/GlueOps/docs-argocd/commit/d3ed075629609d5f8d3dd5b2f74708b1350b6239))


### Continuous Integration

* add release-please ([#57](https://github.com/GlueOps/docs-argocd/issues/57)) ([cc517cc](https://github.com/GlueOps/docs-argocd/commit/cc517ccb4b136a81e57e6fee3e3de05204028e38))
