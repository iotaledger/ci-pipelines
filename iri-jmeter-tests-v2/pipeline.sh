#!/bin/bash

set -eu

wait() {
  echo "  - wait"
}

waitf() {
  echo "  - wait: ~
    continue_on_failure: true"
}

echo "steps:"

echo "  - name: \"[TIAB] Cloning TIAB\"
    command:
      - cd Nightly-Tests/Performance-Tests
      - bash runNode.sh
      - ls -alR
    artifact_paths: 
      - \"RunningOutput/**/*;\"
    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"ubuntu\"
        always-pull: false
        mount-buildkite-agent: false        
    env:
      BUILDKITE_AGENT_NAME: \"$BUILDKITE_AGENT_NAME\"
    agents:
      queue: aws-m5large"
