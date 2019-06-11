#!/bin/bash

set -eu

build_and_push_docker () {
  echo "  - name: \"Building and pushing to docker hub\""
  echo "    command:
      - docker login -u=\\\$DOCKER_USERNAME -p=\\\$DOCKER_PASSWORD
      - docker build -t sadjy/iri-dev:$1 .
      - docker push sadjy/iri-dev:$1"
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
 echo "    agents:
      queue: aws-m5large"
}

echo "steps:"
TAG=$(git describe --tags)
if [ ! -z "$(git show-ref -s $TAG)" ]
then
  build_and_push_docker "$TAG"
else
  echo
  exit 0
fi
