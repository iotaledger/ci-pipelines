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
      - apt -qq update && apt -qq install curl -y
      - IRI_VERSION=\$(echo $1 | tr -d 'v')
      - IRI_VERSION_NUMBER=\$(echo \\\$IRI_VERSION | awk -F- '{print \\\$1}')
      - curl https://iotaledger-iri-release.s3.eu-central-1.amazonaws.com/\\\$IRI_VERSION_NUMBER/iri-\\\$IRI_VERSION.jar --output target/iri-\\\$IRI_VERSION.jar
      - curl https://iotaledger-iri-release.s3.eu-central-1.amazonaws.com/\\\$IRI_VERSION_NUMBER/SHA256SUM-\\\$IRI_VERSION --output target/SHA256SUM-\\\$IRI_VERSION
      - if [[ \\\$(sha256sum target/iri-\\\$IRI_VERSION.jar | cut -d \" \" -f 1) == \\\$(cat target/SHA256SUM-\\\$IRI_VERSION) ]]; then echo 'CHECKSUM OK'; else exit 1; fi
      - curl -L https://github.com/buildkite/github-release/releases/download/v1.0/github-release-linux-amd64 -o github-release
      - chmod +x github-release
      #- gpg --armor --detach-sign --clearsign --default-key email@iota.org target/SHA256SUM
      - ./github-release \\\$GITHUB_RELEASE_TAG target/*"
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"debian\"
        always-pull: true
        mount-buildkite-agent: false
        shell: [\"/bin/bash\", \"-e\", \"-c\"]
        environment:
          - GITHUB_RELEASE_TAG=$1
          - GITHUB_RELEASE_ACCESS_TOKEN
          - GITHUB_RELEASE_REPOSITORY=iotaledger/iri
          - GITHUB_RELEASE_COMMIT"
  echo "    agents:
      queue: aws-m5large"
}

docker_push () {
  echo "  - label: \"Pushing to docker hub\""
  echo "    commands:
      - IRI_VERSION=\$(echo $1 | tr -d 'v')
      - IRI_VERSION_NUMBER=\$(echo \\\$IRI_VERSION | awk -F- '{print \\\$1}')
      - docker login -u=\\\$DOCKER_USERNAME -p=\\\$DOCKER_PASSWORD
      - docker pull iotacafe:iri-\\\$IRI_VERSION
      - docker tag iotacafe:iri-\\\$IRI_VERSION iotaledger:iri-\\\$IRI_VERSION
      - docker push iotaledger:iri-\\\$IRI_VERSION"
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"docker\"
        always-pull: true
        mount-buildkite-agent: false
        environment:
          - DOCKER_USERNAME
          - DOCKER_PASSWORD"
  echo "    agents:
      queue: aws-m5large"
}

echo "steps:"
GIT_TAG=$(git describe --exact-match --tags HEAD || true)
if [[ "$GIT_TAG" == *"RELEASE" ]]; then
  release "$GIT_TAG"
  docker_push "$GIT_TAG"
else
  skip_build
fi
