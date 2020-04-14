#!/bin/bash

set -eux

block () {
  echo "  - block: \"Unlock build\""
}

build () {
  echo "  - label: \"Building jar\""
  echo "    commands:
      - mvn versions:set -DnewVersion=PR-\${BUILDKITE_COMMIT:0:7}-\${BUILDKITE_BUILD_ID:0:8}
      - mvn clean package | tee build-iri.log
      - if grep -q \"\[ERROR\]\" build-iri.log && grep -q \"BUILD FAILURE\" build-iri.log; then exit 1; fi"
  echo "    env:
      BUILDKITE_CLEAN_CHECKOUT: true"
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"iotacafe/maven:3.5.4.oracle8u181.1.webupd8.1.1-1\"
        always-pull: true
        mount-buildkite-agent: false
        shell: [\"/bin/bash\", \"-e\", \"-c\"]
    artifact_paths:
      - \"target/iri-*.jar\"
      - \"target/SHA256SUM-*\"
      - \"build-iri.log\""
  echo "    agents:
      queue: dev"
}

wait() {
  echo "  - wait"
}

trigger_docker_push () {
  echo "  - trigger: iri-push-docker-trusted
    build:
      env:
        ARTIFACT_BUILDKITE_BUILD_ID: \$BUILDKITE_BUILD_ID
        IRI_BUILD_NUMBER: PR-\${GIT_COMMIT:0:7}-\${BUILDKITE_BUILD_ID:0:8}
        IRI_GIT_COMMIT: \$GIT_COMMIT
        IRI_BUILDKITE_PULL_REQUEST_REPO: \$BUILDKITE_PULL_REQUEST_REPO"
}

echo "steps:"
if [[ "$BUILDKITE_BUILD_CREATOR_TEAMS" == *"iri"* ]]; then
  block
fi
build
wait
trigger_docker_push