#!/bin/bash

set -eu

echo "steps:"

api_staging () {
  echo "  - name: \"api-build-and-deploy-staging\""
  echo "    command:
      - apt update && apt install jq -y
      - npm i -g --unsafe-perm now
      - cd demo/api 
      - jq -r '.nodes[0] .provider = \\\$provider' --arg provider 'https://altnodes.devnet.iota.org:443' src/data/config.template.json > src/data/config.staging.json
      - jq -r '.nodes[1] .provider = \\\$provider' --arg provider 'https://nodes.devnet.iota.org:443' src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.dynamoDbConnection .region = \\\$region' --arg region 'eu-central-1' src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.dynamoDbConnection .accessKeyId = \\\$accessKeyId' --arg accessKeyId \\\$P2P_NRG_STAGING_AWS_ACCESS_KEY_ID src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.dynamoDbConnection .secretAccessKey = \\\$secretAccessKey' --arg secretAccessKey \\\$P2P_NRG_STAGING_AWS_SECRET_ACCESS_KEY src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.dynamoDbConnection .dbTablePrefix = \\\$dbTablePrefix' --arg dbTablePrefix \\\$DB_TABLE_PREFIX src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.s3Connection .region = \\\$region' --arg region 'eu-central-1' src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.s3Connection .accessKeyId = \\\$accessKeyId' --arg accessKeyId \\\$P2P_NRG_STAGING_AWS_ACCESS_KEY_ID src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.s3Connection .secretAccessKey = \\\$secretAccessKey' --arg secretAccessKey \\\$P2P_NRG_STAGING_AWS_SECRET_ACCESS_KEY src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.s3Connection .bucketPrefix = \\\$bucketPrefix' --arg bucketPrefix \\\$BUCKET_PREFIX src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.walletSeed = \\\$walletSeed' --arg walletSeed \\\$WALLET_SEED src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - now --token \\\$ZEIT_TOKEN --scope iota alias \$(now --token \\\$ZEIT_TOKEN --scope iota deploy --docker -e CONFIG_ID=staging --build-env CONFIG_ID=staging --build-env GITHUB_TOKEN=\\\$GIT_TOKEN -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS"
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"node:8.12-stretch\"
        environment:
          - ALIAS=p2p-energy-api.iota.works
          - ZEIT_TOKEN
          - GIT_TOKEN          
          - P2P_NRG_STAGING_AWS_ACCESS_KEY_ID
          - P2P_NRG_STAGING_AWS_SECRET_ACCESS_KEY
          - DB_TABLE_PREFIX=p2p-energy-demo-staging-
          - BUCKET_PREFIX=p2p-energy-demo-staging-
          - WALLET_SEED_STAGING" 
  echo "    agents:
      queue: aws-nano"
}

api_prod () {
  echo "  - name: \"api-build-and-deploy-prod\""
  echo "    command:
      - apt update && apt install jq -y
      - npm i -g --unsafe-perm now
      - cd demo/api 
      - jq -r '.nodes[0] .provider = \\\$provider' --arg provider 'https://altnodes.devnet.iota.org:443' src/data/config.template.json > src/data/config.prod.json
      - jq -r '.nodes[1] .provider = \\\$provider' --arg provider 'https://nodes.devnet.iota.org:443' src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.dynamoDbConnection .region = \\\$region' --arg region 'eu-central-1' src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.dynamoDbConnection .accessKeyId = \\\$accessKeyId' --arg accessKeyId \\\$P2P_NRG_PROD_AWS_ACCESS_KEY_ID src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.dynamoDbConnection .secretAccessKey = \\\$secretAccessKey' --arg secretAccessKey \\\$P2P_NRG_PROD_AWS_SECRET_ACCESS_KEY src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.dynamoDbConnection .dbTablePrefix = \\\$dbTablePrefix' --arg dbTablePrefix \\\$DB_TABLE_PREFIX src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.s3Connection .region = \\\$region' --arg region 'eu-central-1' src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.s3Connection .accessKeyId = \\\$accessKeyId' --arg accessKeyId \\\$P2P_NRG_PROD_AWS_ACCESS_KEY_ID src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.s3Connection .secretAccessKey = \\\$secretAccessKey' --arg secretAccessKey \\\$P2P_NRG_PROD_AWS_SECRET_ACCESS_KEY src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.s3Connection .bucketPrefix = \\\$bucketPrefix' --arg bucketPrefix \\\$BUCKET_PREFIX src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.walletSeed = \\\$walletSeed' --arg walletSeed \\\$WALLET_SEED src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - now --token \\\$ZEIT_TOKEN --scope iota alias \$(now --token \\\$ZEIT_TOKEN --scope iota deploy --docker -e CONFIG_ID=prod --build-env CONFIG_ID=prod --build-env GITHUB_TOKEN=\\\$GIT_TOKEN -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS"
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"node:8.12-stretch\"
        environment:
          - ALIAS=p2p-energy-api.iota.org
          - ZEIT_TOKEN
          - GIT_TOKEN
          - P2P_NRG_PROD_AWS_ACCESS_KEY_ID
          - P2P_NRG_PROD_AWS_SECRET_ACCESS_KEY
          - DB_TABLE_PREFIX=p2p-energy-demo-prod-
          - BUCKET_PREFIX=p2p-energy-demo-prod-
          - WALLET_SEED_PROD" 
  echo "    agents:
      queue: aws-nano"
}

client_staging () {
  echo "  - name: \"client-build-and-deploy-staging\""
  echo "    command:
      - apt update && apt install jq -y
      - npm i -g --unsafe-perm now
      - cd demo/client
      - jq -r '.apiEndpoint = \\\$apiEndpoint' --arg apiEndpoint \\\$API_ENDPOINT public/data/config.template.json > public/data/config.staging.json
      - jq -r '.nodes[0] .provider = \\\$provider' --arg provider 'https://altnodes.devnet.iota.org:443' public/data/config.staging.json > tmp.json && mv tmp.json public/data/config.staging.json
      - jq -r '.nodes[1] .provider = \\\$provider' --arg provider 'https://nodes.devnet.iota.org:443' public/data/config.staging.json > tmp.json && mv tmp.json public/data/config.staging.json
      - jq -r '.googleAnalyticsId = \\\$googleAnalyticsId' --arg googleAnalyticsId 'UA-134592666-9' public/data/config.staging.json > tmp.json && mv tmp.json public/data/config.staging.json
      - now --token \\\$ZEIT_TOKEN --scope iota alias \$(now --token \\\$ZEIT_TOKEN --scope iota deploy --docker -e CONFIG_ID=staging --build-env CONFIG_ID=staging --build-env GITHUB_TOKEN=\\\$GIT_TOKEN -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS"  
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"node:8.12-stretch\"
        environment:
          - API_ENDPOINT=https://p2p-energy-api.iota.works
          - ALIAS=p2p-energy.iota.works
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
      - cd demo/client
      - jq -r '.apiEndpoint = \\\$apiEndpoint' --arg apiEndpoint \\\$API_ENDPOINT public/data/config.template.json > public/data/config.prod.json
      - jq -r '.nodes[0] .provider = \\\$provider' --arg provider 'https://nodes.iota.cafe:443' public/data/config.prod.json > tmp.json && mv tmp.json public/data/config.prod.json
      - jq -r '.nodes[1] .provider = \\\$provider' --arg provider 'https://nodes.devnet.iota.org:443' public/data/config.prod.json > tmp.json && mv tmp.json public/data/config.prod.json
      - jq -r '.googleAnalyticsId = \\\$googleAnalyticsId' --arg googleAnalyticsId 'UA-134592666-9' public/data/config.prod.json > tmp.json && mv tmp.json public/data/config.prod.json
      - now --token \\\$ZEIT_TOKEN --scope iota alias \$(now --token \\\$ZEIT_TOKEN --scope iota deploy --docker -e CONFIG_ID=prod --build-env CONFIG_ID=prod --build-env GITHUB_TOKEN=\\\$GIT_TOKEN -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS"  
  echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"node:8.12-stretch\"
        environment:
          - API_ENDPOINT=https://p2p-energy-api.iota.org
          - ALIAS=p2p-energy.iota.org
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

FOLDERS=$(git diff-tree --no-commit-id --name-only -r $BUILDKITE_COMMIT | grep 'demo/' | cut -d / -f 2 | sort | uniq | tr '\n' ' ' | awk '{$1=$1};1')

if [ -z "$FOLDERS" ]
then
  skip_build
else
  print_block "$FOLDERS"  
fi
