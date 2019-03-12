#!/bin/sh

set -eu

echo "steps:"

for machine_dir in machine1; do
  machine_num=$(echo $machine_dir | sed -r 's/^.+([0-9]+)$/\1/')
  sed "s#NUM#$machine_num#g" run-jmeter-step.yml
done
