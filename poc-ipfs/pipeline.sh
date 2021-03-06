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
      - jq -r '.node .mwm = \\\$mwm' --argjson mwm '9' src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.ipfs .provider = \\\$provider' --arg provider \\\$IPFS_NODE src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.ipfs .token = \\\$token' --arg token \\\$AUTH_TOKEN src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.dynamoDbConnection .region = \\\$region' --arg region 'eu-central-1' src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.dynamoDbConnection .accessKeyId = \\\$accessKeyId' --arg accessKeyId \\\$IPFS_STAGING_AWS_ACCESS_KEY_ID src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.dynamoDbConnection .secretAccessKey = \\\$secretAccessKey' --arg secretAccessKey \\\$IPFS_STAGING_AWS_SECRET_ACCESS_KEY src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.dynamoDbConnection .dbTablePrefix = \\\$dbTablePrefix' --arg dbTablePrefix \\\$DB_TABLE_PREFIX src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - now --token \\\$ZEIT_TOKEN --scope iota alias \$(now --regions sfo --token \\\$ZEIT_TOKEN --scope iota deploy --docker -e CONFIG_ID=staging --build-env CONFIG_ID=staging -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS"
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v2.0.0:
        image: \"node:12.16-stretch\"
        environment:
          - IRI_NODE=https://altnodes.devnet.iota.org:443
          - IPFS_NODE=https://ipfs.iota.cafe:443/api/v0/
          - AUTH_TOKEN
          - ALIAS=ipfs-api.iota.works
          - ZEIT_TOKEN
          - IPFS_STAGING_AWS_ACCESS_KEY_ID
          - IPFS_STAGING_AWS_SECRET_ACCESS_KEY
          - DB_TABLE_PREFIX=ipfs-staging-"
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
      - now --token \\\$ZEIT_TOKEN --scope iota alias \$(now --regions sfo --token \\\$ZEIT_TOKEN --scope iota deploy --docker -e CONFIG_ID=staging --build-env CONFIG_ID=staging --build-env GITHUB_TOKEN=\\\$GIT_TOKEN -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS"
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v2.0.0:
        image: \"node:12.16-stretch\"
        environment:
          - API_ENDPOINT=https://ipfs-api.iota.works
          - ALIAS=ipfs.iota.works
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
      - jq -r '.node .mwm = \\\$mwm' --argjson mwm '14' src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.ipfs .provider = \\\$provider' --arg provider \\\$IPFS_NODE src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.ipfs .token = \\\$token' --arg token \\\$AUTH_TOKEN src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.dynamoDbConnection .region = \\\$region' --arg region 'eu-central-1' src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.dynamoDbConnection .accessKeyId = \\\$accessKeyId' --arg accessKeyId \\\$IPFS_PROD_AWS_ACCESS_KEY_ID src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.dynamoDbConnection .secretAccessKey = \\\$secretAccessKey' --arg secretAccessKey \\\$IPFS_PROD_AWS_SECRET_ACCESS_KEY src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.dynamoDbConnection .dbTablePrefix = \\\$dbTablePrefix' --arg dbTablePrefix \\\$DB_TABLE_PREFIX src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - now --token \\\$ZEIT_TOKEN --scope iota alias \$(now --regions sfo --token \\\$ZEIT_TOKEN --scope iota deploy --docker -e CONFIG_ID=prod --build-env CONFIG_ID=prod -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS"
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v2.0.0:
        image: \"node:12.16-stretch\"
        environment:
          - IRI_NODE=https://nodes.iota.cafe:443
          - IPFS_NODE=https://ipfs.iota.cafe:443/api/v0/
          - AUTH_TOKEN
          - ALIAS=ipfs-api.iota.org
          - ZEIT_TOKEN
          - IPFS_PROD_AWS_ACCESS_KEY_ID
          - IPFS_PROD_AWS_SECRET_ACCESS_KEY
          - DB_TABLE_PREFIX=ipfs-prod-"
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
      - jq -r '.tangleExplorer .transactions = \\\$transactions' --arg transactions 'https://thetangle.org/transaction/:transactionHash' public/data/config.prod.json > tmp.json && mv tmp.json public/data/config.prod.json
      - jq -r '.tangleExplorer .bundles = \\\$bundles' --arg bundles 'https://thetangle.org/bundle/:bundleHash' public/data/config.prod.json > tmp.json && mv tmp.json public/data/config.prod.json
      - jq -r '.googleAnalyticsId = \\\$googleAnalyticsId' --arg googleAnalyticsId 'UA-134592666-3' public/data/config.prod.json > tmp.json && mv tmp.json public/data/config.prod.json
      - now --token \\\$ZEIT_TOKEN --scope iota alias \$(now --regions sfo --token \\\$ZEIT_TOKEN --scope iota deploy --docker -e CONFIG_ID=prod --build-env CONFIG_ID=prod --build-env GITHUB_TOKEN=\\\$GIT_TOKEN -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS"
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v2.0.0:
        image: \"node:12.16-stretch\"
        environment:
          - API_ENDPOINT=https://ipfs-api.iota.org
          - ALIAS=ipfs.iota.org
          - ZEIT_TOKEN
          - GIT_TOKEN"
  echo "    agents:
      queue: aws-nano"
}

block_prod () {
  echo "  - block: \"Deploy LIVE\""
  echo "    prompt: \"Deploy this build to production?\""
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

print_block "$(git diff-tree --no-commit-id --name-only -r $BUILDKITE_COMMIT | grep '/' | cut -d / -f 1 | sort | uniq | tr '\n' ' ' | awk '{$1=$1};1')"
