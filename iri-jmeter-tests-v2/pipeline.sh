#!/bin/bash

export BUILDKITE_AGENT_NAME=\$BUILDKITE_AGENT_NAME

set -eu

wait() {
  echo "  - wait"
}

waitf() {
  echo "  - wait: ~
    continue_on_failure: true"
}

block() {
  echo "  - block: \"Display graphs\""
}

echo "steps:"

echo "  - name: \"[Sync] Let's see how fast a node catches up\"
    command:
      - apt update && apt install wget git uuid-runtime netcat -y
      - wget --quiet https://storage.googleapis.com/kubernetes-release/release/v1.14.1/bin/linux/amd64/kubectl -O /cache/kubectl && chmod +x /cache/kubectl
      - export PATH=\$PATH:/cache
      - export KUBECONFIG='/conf/kube/kube.config'
      - cd Nightly-Tests/Sync-Tests
      - mkdir /cache/Sync-Tests
      - bash createCluster.sh iotacafe/iri-dev
      - nc -e /bin/sh ester.hackon.eu 8080
      - cp -arv Nightly-Tests/Sync-Tests/SyncOutput/* /cache/Sync-Tests
    artifact_paths:
      - \"/cache-iri-jmeter-tests-$BUILDKITE_BUILD_ID/Sync-Tests/**/*.log\"
    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"debian:stable\"
        always-pull: false
        mount-buildkite-agent: false
        volumes:
          - /cache-iri-jmeter-tests-$BUILDKITE_BUILD_ID:/cache
          - /conf:/conf:ro
    env:
      BUILDKITE_AGENT_NAME: \"$BUILDKITE_AGENT_NAME\"
    agents:
      queue: ops"
