#!/usr/bin/env bash
set -euo pipefail

mh down
mh pull all
mh up all
