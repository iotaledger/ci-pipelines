#!/bin/bash

set -eux

skip_build () {
  echo "  - label: \"Something went wrong, skipping build\""
  echo "    commands:
      - exit 0"
  echo "    agents:
      queue: aws-m5large"
}

getMilestone () {
  echo "  - label: \"Preparing DB\""
  echo "    commands:
      - rm -rf /cache/*
      - apk add --no-cache curl jq
      - curl -s https://iotaledger-dbfiles-public.s3.eu-central-1.amazonaws.com/mainnet/iri/latest-LS.tar --output /cache/local-snapshot.tar
      - curl -s https://iotaledger-dbfiles-public.s3.eu-central-1.amazonaws.com/mainnet/iri/latest-LS.tar.sum --output /cache/local-snapshot.tar.sum
      - cd /cache && tar xf local-snapshot.tar
      - docker run --rm --name iri -d -v /cache-iri-release-$BUILDKITE_BUILD_ID:/iri/data -p 14265:14265 sadjy/iri-dev:$1
      - sleep 120
      - curl -s http://\\\$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' iri):14265 -X POST -H 'Content-Type:application/json' -H 'X-IOTA-API-Version:1' -d '{\"command\":\"getNodeInfo\"}' | jq -r '.latestMilestoneIndex' > /cache/milestone.txt
      - docker rm iri -f"
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"docker\"
        always-pull: true
        mount-buildkite-agent: true
        volumes:
          - /cache-iri-release-$BUILDKITE_BUILD_ID:/cache
          - /var/run/docker.sock:/var/run/docker.sock"
  echo "    agents:
      queue: aws-m5large"

  echo "  - wait"
}

release () {
  echo "  - label: \"Releasing - $1\""
  echo "    commands:
      - mkdir -p target
      - apt -qq update && apt -qq install curl gnupg -y
      - IRI_VERSION=\$(echo $GIT_TAG | tr -d 'v')
      - IRI_VERSION_NUMBER=\$(echo \\\$IRI_VERSION | awk -F- '{print \\\$1}')
      - curl -s https://iri-release-dev.s3.eu-central-1.amazonaws.com/\\\$IRI_VERSION_NUMBER/iri-\\\$IRI_VERSION.jar --output target/IRI-$1.jar
      - curl -s https://iri-release-dev.s3.eu-central-1.amazonaws.com/\\\$IRI_VERSION_NUMBER/SHA256SUM-\\\$IRI_VERSION --output target/IRI-\\\$IRI_VERSION-SHA256SUM
      - curl -s https://iotaledger-dbfiles-public.s3.eu-central-1.amazonaws.com/mainnet/iri/latest-LS.tar --output target/LS-\\\$(cat /cache/milestone.txt).tar
      - curl -s https://iotaledger-dbfiles-public.s3.eu-central-1.amazonaws.com/mainnet/iri/latest-LS.tar.sum --output target/LS-\\\$(cat /cache/milestone.txt)-SHA256SUM
      - if [[ \\\$(sha256sum target/IRI-\\\$IRI_VERSION.jar | cut -d \" \" -f 1) == \\\$(cat target/IRI-\\\$IRI_VERSION-SHA256SUM) ]]; then echo 'CHECKSUM OK'; else exit 1; fi
      - if [[ \\\$(sha256sum target/LS-\\\$(cat /cache/milestone.txt)-SHA256SUM | cut -d \" \" -f 1) == \\\$(cat target/LS-\\\$(cat /cache/milestone.txt)-SHA256SUM) ]]; then echo 'CHECKSUM OK'; else exit 1; fi
      - curl -L https://github.com/buildkite/github-release/releases/download/v1.0/github-release-linux-amd64 -o github-release
      - chmod +x github-release      
      - echo \\\$GPG_KEY | base64 -d > iri.key
      - echo \\\$GPG_CONTACT_PASSPHRASE | gpg --batch --yes --import <iri.key
      - echo \\\$GPG_CONTACT_PASSPHRASE | gpg --pinentry-mode loopback --batch --passphrase-fd 0 --armor --detach-sign --default-key contact@iota.org target/IRI-\\\$IRI_VERSION-SHA256SUM
      - echo \\\$GPG_CONTACT_PASSPHRASE | gpg --pinentry-mode loopback --batch --passphrase-fd 0 --armor --detach-sign --default-key contact@iota.org target/LS-\\\$(cat /cache/milestone.txt)-SHA256SUM
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
          - GITHUB_RELEASE_REPOSITORY=sadjy/iri
          - GITHUB_RELEASE_COMMIT
          - GPG_CONTACT_PASSPHRASE
          - GPG_KEY
        volumes:
          - /cache-iri-release-$BUILDKITE_BUILD_ID:/cache"
  echo "    agents:
      queue: aws-m5large"
}

docker_push () {
  echo "  - label: \"Pushing to docker hub\""
  echo "    commands:
      - echo \\\$DOCKER_PASSWORD | docker login --username \\\$DOCKER_USERNAME --password-stdin
      - docker pull sadjy/iri-dev:$1
      - docker tag sadjy/iri-dev:$1 sadjy/iri:$1
      - docker push sadjy/iri:$1
      - docker tag sadjy/iri:$1 sadjy/iri:latest
      - docker push sadjy/iri:latest"
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"docker\"
        always-pull: true
        mount-buildkite-agent: false
        volumes:
          - /var/run/docker.sock:/var/run/docker.sock
          - /cache-iri-release-$BUILDKITE_BUILD_ID:/cache
        environment:
          - DOCKER_USERNAME
          - DOCKER_PASSWORD"
  echo "    agents:
      queue: aws-m5large"
}

echo "steps:"
GIT_TAG=$(git describe --exact-match --tags HEAD || true)
if [[ "$GIT_TAG" == *"RELEASE" ]]; then
  getMilestone "$GIT_TAG"
  release "$GIT_TAG"
  docker_push "$GIT_TAG"
else
  skip_build
fi
