#!/bin/bash

set -eu

echo "steps:"

api_staging () {
  echo "  - name: \"api-build-and-deploy-staging\""
  echo "    command:
      - apt update && apt install jq -y
      - npm i -g --unsafe-perm now
      - cd api 
      - jq -r '.cmcApiKey = \\\$cmcApiKey' --arg cmcApiKey \\\$CMC_API_KEY src/data/config.template.json > src/data/config.staging.json
      - jq -r '.fixerApiKey = \\\$fixerApiKey' --arg fixerApiKey \\\$FIXER_API_KEY src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.dynamoDbConnection .region = \\\$region' --arg region 'eu-central-1' src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.dynamoDbConnection .accessKeyId = \\\$accessKeyId' --arg accessKeyId \\\$TANGLE_UTILS_STAGING_AWS_ACCESS_KEY_ID src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.dynamoDbConnection .secretAccessKey = \\\$secretAccessKey' --arg secretAccessKey \\\$TANGLE_UTILS_STAGING_AWS_SECRET_ACCESS_KEY src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.dynamoDbConnection .dbTablePrefix = \\\$dbTablePrefix' --arg dbTablePrefix \\\$DB_TABLE_PREFIX src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.zmqMainNet .endpoint = \\\$endpoint' --arg endpoint 'tcp://zmq.iota.org:5556' src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.zmqDevNet .endpoint = \\\$endpoint' --arg endpoint 'tcp://zmq.devnet.iota.org:5556' src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - now --token \\\$ZEIT_TOKEN --scope iota alias \$(now --token \\\$ZEIT_TOKEN --scope iota deploy --docker -e CONFIG_ID=staging --build-env CONFIG_ID=staging -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS"
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"node:8.12-stretch\"
        environment:
          - CMC_API_KEY
          - FIXER_API_KEY
          - ALIAS=utils-api.iota.works
          - ZEIT_TOKEN
          - TANGLE_UTILS_STAGING_AWS_ACCESS_KEY_ID
          - TANGLE_UTILS_STAGING_AWS_SECRET_ACCESS_KEY
          - DB_TABLE_PREFIX=tangle-utils-staging-" 
  echo "    agents:
      queue: aws-nano"
}

api_prod () {
  echo "  - name: \"api-build-and-deploy-prod\""
  echo "    command:
      - apt update && apt install jq -y
      - npm i -g --unsafe-perm now
      - cd api 
      - jq -r '.cmcApiKey = \\\$cmcApiKey' --arg cmcApiKey \\\$CMC_API_KEY src/data/config.template.json > src/data/config.prod.json
      - jq -r '.fixerApiKey = \\\$fixerApiKey' --arg fixerApiKey \\\$FIXER_API_KEY src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.dynamoDbConnection .region = \\\$region' --arg region 'eu-central-1' src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.dynamoDbConnection .accessKeyId = \\\$accessKeyId' --arg accessKeyId \\\$TANGLE_UTILS_PROD_AWS_ACCESS_KEY_ID src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.dynamoDbConnection .secretAccessKey = \\\$secretAccessKey' --arg secretAccessKey \\\$TANGLE_UTILS_PROD_AWS_SECRET_ACCESS_KEY src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.dynamoDbConnection .dbTablePrefix = \\\$dbTablePrefix' --arg dbTablePrefix \\\$DB_TABLE_PREFIX src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.zmqMainNet .endpoint = \\\$endpoint' --arg endpoint 'tcp://zmq.iota.org:5556' src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.zmqDevNet .endpoint = \\\$endpoint' --arg endpoint 'tcp://zmq.devnet.iota.org:5556' src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - now --token \\\$ZEIT_TOKEN --scope iota alias \$(now --token \\\$ZEIT_TOKEN --scope iota deploy --docker -e CONFIG_ID=prod --build-env CONFIG_ID=prod -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS"
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"node:8.12-stretch\"
        environment:
          - CMC_API_KEY
          - FIXER_API_KEY
          - ALIAS=utils-api.iota.org
          - ZEIT_TOKEN
          - TANGLE_UTILS_PROD_AWS_ACCESS_KEY_ID
          - TANGLE_UTILS_PROD_AWS_SECRET_ACCESS_KEY
          - DB_TABLE_PREFIX=tangle-utils-prod-" 
  echo "    agents:
      queue: aws-nano"
}

client_staging () {
  echo "  - name: \"client-build-and-deploy-staging\""
  echo "    command:
      - apt update && apt install jq -y
      - npm i -g --unsafe-perm now
      - cd client
      - jq -r '.apiEndpoint = \\\$apiEndpoint' --arg apiEndpoint \\\$API_ENDPOINT public/data/config.template.json > public/data/config.staging.json
      - jq -r '.nodesMainnet[0] .provider = \\\$provider' --arg provider 'https://nodes.iota.cafe:443' public/data/config.staging.json > tmp.json && mv tmp.json public/data/config.staging.json
      - jq -r '.nodesMainnet[1] .provider = \\\$provider' --arg provider 'https://nodes.thetangle.org:443' public/data/config.staging.json > tmp.json && mv tmp.json public/data/config.staging.json
      - jq -r '.nodesDevnet[0] .provider = \\\$provider' --arg provider 'https://altnodes.devnet.iota.cafe:443' public/data/config.staging.json > tmp.json && mv tmp.json public/data/config.staging.json
      - jq -r '.nodesDevnet[1] .provider = \\\$provider' --arg provider 'https://nodes.devnet.iota.cafe:443' public/data/config.staging.json > tmp.json && mv tmp.json public/data/config.staging.json
      - now --token \\\$ZEIT_TOKEN --scope iota alias \$(now --token \\\$ZEIT_TOKEN --scope iota deploy --docker -e CONFIG_ID=staging --build-env CONFIG_ID=staging --build-env GITHUB_TOKEN=\\\$GIT_TOKEN -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS"  
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"node:8.12-stretch\"
        environment:
          - API_ENDPOINT=https://utils-api.iota.works
          - ALIAS=utils.iota.works
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
      - jq -r '.apiEndpoint = \\\$apiEndpoint' --arg apiEndpoint \\\$API_ENDPOINT public/data/config.template.json > public/data/config.prod.json
      - jq -r '.nodesMainnet[0] .provider = \\\$provider' --arg provider 'https://nodes.iota.cafe:443' public/data/config.prod.json > tmp.json && mv tmp.json public/data/config.prod.json
      - jq -r '.nodesMainnet[1] .provider = \\\$provider' --arg provider 'https://nodes.thetangle.org:443' public/data/config.prod.json > tmp.json && mv tmp.json public/data/config.prod.json
      - jq -r '.nodesDevnet[0] .provider = \\\$provider' --arg provider 'https://altnodes.devnet.iota.cafe:443' public/data/config.prod.json > tmp.json && mv tmp.json public/data/config.prod.json
      - jq -r '.nodesDevnet[1] .provider = \\\$provider' --arg provider 'https://nodes.devnet.iota.cafe:443' public/data/config.prod.json > tmp.json && mv tmp.json public/data/config.prod.json
      - jq -r '.googleAnalyticsId = \\\$googleAnalyticsId' --arg googleAnalyticsId 'UA-134592666-12' public/data/config.prod.json > tmp.json && mv tmp.json public/data/config.prod.json
      - now --token \\\$ZEIT_TOKEN --scope iota alias \$(now --token \\\$ZEIT_TOKEN --scope iota deploy --docker -e CONFIG_ID=prod --build-env CONFIG_ID=prod --build-env GITHUB_TOKEN=\\\$GIT_TOKEN -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS"  
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"node:8.12-stretch\"
        environment:
          - API_ENDPOINT=https://utils-api.iota.org
          - ALIAS=utils.iota.org
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

FOLDERS=$(git diff-tree --no-commit-id --name-only -r $BUILDKITE_COMMIT | grep '/' | cut -d / -f 1 | sort | uniq | tr '\n' ' ' | awk '{$1=$1};1')

if [ -z "$FOLDERS" ]
then
  skip_build
else
  print_block "$FOLDERS"  
fi
