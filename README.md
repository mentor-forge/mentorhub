# Umbrella Project Template

## Quick Start

This repository is a **Stage0 merge template** for an umbrella repo. Use **`make merge`** (see below) with your specifications context to produce a merged umbrella. Provisioning GitHub repos, Docker images, and service automation is **not** part of this template’s Makefile; use **[Stage0 Launch](https://github.com/agile-learning-institute/stage0_launch)** (web UI / API) from a launchpad when you need that workflow.

### Specifications YAML after merge

Umbrella Jinja merge does **not** generate `architecture.yaml`, `product.yaml`, `catalog.yaml`, or other authoritative spec YAML under `Specifications/`. Those files come from **your** specifications directory:

- **`make merge <specs_path>`** — after the runbook merge container finishes, the Makefile copies **every** `*.yaml` from `<specs_path>` into `./Specifications/`, matching [stage0_launch `merge-all`](https://github.com/agile-learning-institute/stage0_launch) (`copy_spec_yaml_files` in `merge_all.py`).
- **`make test`** — does the same copy from [`.stage0_template/specifications/`](./.stage0_template/specifications/) into the temp repo after merge, so tests mirror Launch.

If you run **`stage0_runbook_merge` alone** (Docker or CLI) without that copy step, **`Specifications/` will not contain** those YAMLs until you copy them yourself. Service merges that read the umbrella `Specifications/` tree expect it to be complete, same as after Launch.

## Contributing
See [Template Guide](https://github.com/agile-learning-institute/stage0_runbook_merge/blob/main/TEMPLATE_GUIDE.md) for information about stage0 merge templates. See the [Processing Instructions](./.stage0_template/process.yaml) for details about this template, and [Test Specifications](./.stage0_template/Specifications/) for sample context data required.

Template Commands
```sh
## Test the Template using test_expected output
## Creates ~/tmp folders 
make test
## Successful output looks like
...
Checking output...
Only in /Users/you/tmp/testRepo: .git
Only in /Users/you/tmp/testRepo/configurator: .DS_Store
Done.

## Look at one file diff from testing
make diff README.md

## Copy a generated file to the test_expected folder
make take somefile.json

## Clean up temp files from testing
## Removes tmp folders
make clean

## Process this merge template using the provided context path
## NOTE: Destructive action, will remove .stage0_template 
## Context path typically ends with ``.Specifications``
make merge {context path}
```
