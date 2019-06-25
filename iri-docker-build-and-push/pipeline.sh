#!/bin/bash

set -eu


build_docker () {
  echo "  - label: \"Building jar - $1\""
  echo "    commands:
      - mvn clean package
      - mv target/iri*.jar target/iri-oracle8-$1.jar
      - cp target/iri-oracle8-$1.jar /cache"
  echo "    env:
      BUILDKITE_CLEAN_CHECKOUT: \"true\""
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"iotacafe/maven:3.5.4.oracle8u181.1.webupd8.1.1-1\"
        always-pull: true
        mount-buildkite-agent: false
        volumes:
        - /cache-iri-docker-build-and-push-$BUILDKITE_BUILD_ID:/cache"
  echo "    artifact_paths:
      - \"target/iri-oracle8-*\""
  echo "    agents:
      queue: aws-m5large"
}


push_docker () {
  echo "  - label: \"Pushing to docker hub - $1\""
  echo "    commands:
      - mkdir target
      - cp /cache/iri-oracle8-$1.jar target
      - sed -i '/# execution image/d' Dockerfile     
      - sed -i 's#--from=local_stage_build /iri/##g' Dockerfile
      - docker login -u=\\\$DOCKER_USERNAME -p=\\\$DOCKER_PASSWORD
      - docker build -t sadjy/iri-dev:$1 .
      - docker push sadjy/iri-dev:$1"
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"docker\"
        always-pull: true
        mount-buildkite-agent: true
        volumes:
        - /var/run/docker.sock:/var/run/docker.sock
        - /conf/docker/.docker:$HOME/.docker
        - /cache-iri-docker-build-and-push-$BUILDKITE_BUILD_ID:/cache
        environment:
          - DOCKER_USERNAME
          - DOCKER_PASSWORD"
  echo "    agents:
      queue: aws-m5large"
}

wait () {
  echo "  - wait"
}

skip_build () {
  echo "  - label: \"Triggering commit not tagged, skipping build\""
  echo "    command:
      - exit 0" 
  echo "    agents:
      queue: aws-m5large"  
}

trigger_reg_tests () {
  echo "  - trigger: iri-regression-tests-dev"
  echo "    build:
      env: 
        IRI_BUILD_NUMBER: $1
        IRI_GIT_COMMIT: $2
        ARTIFACT_BUILDKITE_BUILD_ID: $BUILDKITE_BUILD_ID"
}

echo "steps:"
TAG=$(git describe --exact-match --tags HEAD)
IRI_TAGGED_GIT_COMMIT=$(git show-ref -s $TAG)
IRI_BUILD_NUMBER=${GIT_COMMIT:0:7}-${BUILDKITE_BUILD_ID:0:8}
if [ ! -z "$IRI_TAGGED_GIT_COMMIT" ]
then
  build_docker "$TAG"
  wait
  push_docker "$TAG"
  wait
  trigger_reg_tests "$TAG" "$IRI_TAGGED_GIT_COMMIT"
else
  skip_build
#  build_docker "$IRI_BUILD_NUMBER"
#  wait
#  push_docker "$IRI_BUILD_NUMBER"
#  wait
#  trigger_reg_tests "$IRI_BUILD_NUMBER" "$GIT_COMMIT"
fi
