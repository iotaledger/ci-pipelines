#!/bin/bash

set -eu

skip_build () {
  echo "  - label: \"Something went wrong, skipping build\""
  echo "    commands:
      - exit 0"
  echo "    agents:
      queue: aws-m5large"
}

release () {
  echo "  - label: \"Releasing - $1\""
  echo "    commands:
      - mkdir -p target
      - apt update && apt install curl -y
      - curl https://iotaledger-iri-release.s3.eu-central-1.amazonaws.com/target/iri-$1.jar --output target/iri-$1.jar
      - curl https://iotaledger-iri-release.s3.eu-central-1.amazonaws.com/target/SHA256SUM-$1 --output target/SHA256SUM-$1
      - if [ \\\$(sha256sum target/iri-$1.jar) != \\\$(cat target/SHA256SUM-$1)]; then exit 1; fi
      - curl -L https://github.com/buildkite/github-release/releases/download/v1.0/github-release-linux-amd64 -o github-release
      - chmod +x github-release
      #- gpg --armor --detach-sign --clearsign --default-key email@iota.org target/SHA256SUM
      - ./github-release \\\$GITHUB_RELEASE_TAG target/*"
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"debian\"
        always-pull: true
        mount-buildkite-agent: true
        volumes:
        - /cache-iri-docker-build-and-push-$BUILDKITE_BUILD_ID:/cache
        environment:
          - GITHUB_RELEASE_TAG=$1
          - GITHUB_RELEASE_ACCESS_TOKEN
          - GITHUB_RELEASE_REPOSITORY=GalRogozinski/iri
          - GITHUB_RELEASE_COMMIT"
  echo "    agents:
      queue: aws-m5large"
}

echo "steps:"
GIT_TAG=$(git describe --exact-match --tags HEAD || true)
if [[ "$GIT_TAG" == *"RELEASE" ]]; then
  release "$GIT_TAG"
else
  skip_build
fi
