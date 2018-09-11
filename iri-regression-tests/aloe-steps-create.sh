#!/bin/sh

set -eu

echo "steps:"

for machine_dir in /workdir/PythonRegression/tests/features/machine?; do
  machine_num=$(echo $machine_dir | sed -r 's/^.+([0-9]+)$/\1/')
  sed "s#NUM#$machine_num#g" run-aloe-step.yml
done
