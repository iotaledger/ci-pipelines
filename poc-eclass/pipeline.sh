#!/bin/bash

set -eu

echo "steps:"

api_staging () {
  echo "  - name: \"api-build-and-deploy-staging\""
  echo "    command:
      - apt update && apt install jq -y
      - npm i -g --unsafe-perm now
      - cd api
      - jq -r '.node .provider = \\\$provider' --arg provider \\\$IRI_NODE src/data/config.template.json > src/data/config.staging.json
      - now --token \\\$ZEIT_TOKEN --scope iota alias \$(now --token \\\$ZEIT_TOKEN --scope iota deploy --docker -e CONFIG_ID=staging --build-env CONFIG_ID=staging --build-env GITHUB_TOKEN=\\\$GIT_TOKEN -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS"
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"node:12.16-stretch\"
        environment:
          - IRI_NODE=https://altnodes.devnet.iota.org:443
          - ALIAS=eclass-api.iota.works
          - ZEIT_TOKEN
          - GIT_TOKEN"
  echo "    agents:
      queue: aws-nano"
}

api_prod () {
  echo "  - name: \"api-build-and-deploy-prod\""
  echo "    command:
      - apt update && apt install jq -y
      - npm i -g --unsafe-perm now
      - cd api
      - jq -r '.node .provider = \\\$provider' --arg provider \\\$IRI_NODE src/data/config.template.json > src/data/config.prod.json
      - now --token \\\$ZEIT_TOKEN --scope iota alias \$(now --token \\\$ZEIT_TOKEN --scope iota deploy --docker -e CONFIG_ID=prod --build-env CONFIG_ID=prod --build-env GITHUB_TOKEN=\\\$GIT_TOKEN -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS"
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"node:12.16-stretch\"
        environment:
          - IRI_NODE=https://altnodes.devnet.iota.org:443
          - ALIAS=eclass-api.iota.org
          - ZEIT_TOKEN
          - GIT_TOKEN"
  echo "    agents:
      queue: aws-nano"
}

client_staging () {
  echo "  - name: \"client-build-and-deploy-staging\""
  echo "    command:
      - apt update && apt install jq -y
      - npm i -g --unsafe-perm now
      - cd client
      - jq -r '.node .provider = \\\$provider' --arg provider \\\$IRI_NODE public/data/config.template.json > public/data/config.staging.json
      - jq -r '.apiEndpoint = \\\$apiEndpoint' --arg apiEndpoint \\\$API_ENDPOINT public/data/config.staging.json > tmp.json && mv tmp.json public/data/config.staging.json
      - now --token \\\$ZEIT_TOKEN --scope iota alias \$(now --token \\\$ZEIT_TOKEN --scope iota deploy --docker -e CONFIG_ID=staging --build-env CONFIG_ID=staging --build-env GITHUB_TOKEN=\\\$GIT_TOKEN -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS"
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"node:12.16-stretch\"
        environment:
          - IRI_NODE=https://altnodes.devnet.iota.org:443
          - API_ENDPOINT=https://eclass-api.iota.works
          - ALIAS=eclass.iota.works
          - ZEIT_TOKEN
          - GIT_TOKEN"
  echo "    agents:
      queue: aws-nano"
}

client_prod () {
  echo "  - name: \"client-build-and-deploy-prod\""
  echo "    command:
      - apt update && apt install jq -y
      - npm i -g --unsafe-perm now
      - cd client
      - jq -r '.node .provider = \\\$provider' --arg provider \\\$IRI_NODE public/data/config.template.json > public/data/config.prod.json
      - jq -r '.apiEndpoint = \\\$apiEndpoint' --arg apiEndpoint \\\$API_ENDPOINT public/data/config.prod.json > tmp.json && mv tmp.json public/data/config.prod.json
      - now --token \\\$ZEIT_TOKEN --scope iota alias \$(now --token \\\$ZEIT_TOKEN --scope iota deploy --docker -e CONFIG_ID=prod --build-env CONFIG_ID=prod --build-env GITHUB_TOKEN=\\\$GIT_TOKEN -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS"
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"node:12.16-stretch\"
        environment:
          - IRI_NODE=https://altnodes.devnet.iota.org:443
          - API_ENDPOINT=https://eclass-api.iota.org
          - ALIAS=eclass.iota.org
          - ZEIT_TOKEN
          - GIT_TOKEN"
  echo "    agents:
      queue: aws-nano"
}

block_prod () {
  echo "  - block: \"Deploy LIVE\""
  echo "    prompt: \"Deploy this build to production?\""
}

skip_build () {
  echo "  - name: \"No folder modified, skipping build\""
  echo "    command:
      - exit 0"
  echo "    agents:
      queue: aws-nano"
}

print_block () {
  case $1 in
    'api client')
      api_staging
      client_staging
      block_prod
      api_prod
      client_prod
      ;;
    'api')
      api_staging
      block_prod
      api_prod
      ;;
    'client')
      client_staging
      block_prod
      client_prod
      ;;
  esac
}

FOLDERS=$(git diff-tree --no-commit-id --name-only -r $BUILDKITE_COMMIT | grep '/' | cut -d / -f 1 | sort | uniq | grep "api\|client" | tr '\n' ' ' | awk '{$1=$1};1')

if [ -z "$FOLDERS" ]
then
  skip_build
else
  print_block "$FOLDERS"
fi
