#!/bin/bash

set -eu

build_and_push_docker () {
  echo "  - name: \"Building and pushing to docker hub\""
  echo "    command:
      - docker login -u=\\\$DOCKER_USERNAME -p=\\\$DOCKER_PASSWORD
      - docker build -t sadjy/iri-dev:$1 .
      - docker push sadjy/iri-dev:$1
      - target/iri-oracle8-$1.jar"
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"docker\"
        mount-buildkite-agent: true
        volumes:
        - /var/run/docker.sock:/var/run/docker.sock
        - /conf/docker/.docker:$HOME/.docker
        environment:
          - DOCKER_USERNAME
          - DOCKER_PASSWORD"
  echo "    artifact_paths:
      - \"target/iri-oracle8-*\""
  echo "    agents:
      queue: aws-m5large"
}

skip_build () {
  echo "  - name: \"Triggering commit not tagged, skipping build\""
  echo "    command:
      - exit 0" 
  echo "    agents:
      queue: aws-m5large"  
}

trigger_reg_tests () {
  echo "  - trigger: iri-regression-tests"
  echo "    build:
      env: 
        IRI_BUILD_NUMBER: $1
        IRI_GIT_COMMIT: $2
        ARTIFACT_BUILDKITE_BUILD_ID: $BUILDKITE_BUILD_ID"
}

echo "steps:"
TAG=$(git describe --tags --abbrev=0)
IRI_TAGGED_GIT_COMMIT=$(git show-ref -s $TAG)
if [ ! -z "$IRI_TAGGED_GIT_COMMIT" ]
then
  build_and_push_docker "$TAG"
  trigger_reg_tests "$TAG" "$IRI_TAGGED_GIT_COMMIT"
else
  skip_build
fi
