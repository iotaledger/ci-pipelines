#!/bin/bash

set -eu

echo "steps:"

api_staging () {
  echo "  - name: \"api-build-and-deploy-staging\""
  echo "    command:
      - apt update && apt install jq -y
      - npm i -g --unsafe-perm now
      - cd api 
      - jq -r '.provider = \\\$provider' --arg provider \\\$IRI_NODE src/data/config.template.json > src/data/config.staging.json
      - jq -r '.mwm = \\\$mwm' --argjson mwm '9' src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.dynamoDbConnection .region = \\\$region' --arg region 'eu-central-1' src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.dynamoDbConnection .accessKeyId = \\\$accessKeyId' --arg accessKeyId \\\$CERT_STAGING_AWS_ACCESS_KEY_ID src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.dynamoDbConnection .secretAccessKey = \\\$secretAccessKey' --arg secretAccessKey \\\$CERT_STAGING_AWS_SECRET_ACCESS_KEY src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.dynamoDbConnection .dbTablePrefix = \\\$dbTablePrefix' --arg dbTablePrefix \\\$DB_TABLE_PREFIX src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.s3Connection .region = \\\$region' --arg region 'eu-central-1' src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.s3Connection .accessKeyId = \\\$accessKeyId' --arg accessKeyId \\\$CERT_STAGING_AWS_ACCESS_KEY_ID src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.s3Connection .secretAccessKey = \\\$secretAccessKey' --arg secretAccessKey \\\$CERT_STAGING_AWS_SECRET_ACCESS_KEY src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.s3Connection .bucketPrefix = \\\$bucketPrefix' --arg bucketPrefix \\\$BUCKET_PREFIX src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.mainBucket = \\\$mainBucket' --arg mainBucket \\\$MAIN_BUCKET src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.authenticateDomain = \\\$authenticateDomain' --arg authenticateDomain \\\$AUTH_DOMAIN src/data/config.staging.json > tmp.json && mv tmp.json src/data/config.staging.json
      - jq -r '.name = \\\$name' --arg name 'certification-api' now.json > tmp.json && mv tmp.json now.json
      - now --token \\\$ZEIT_TOKEN --team iota alias \$(now --regions sfo --token \\\$ZEIT_TOKEN --team iota deploy --docker -e CONFIG_ID=staging --build-env CONFIG_ID=staging -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS"
  echo "    plugin:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v2.0.0:
        image: \"node:8.12-stretch\"
        environment:
          - IRI_NODE=https://altnodes.devnet.iota.org:443
          - CERT_STAGING_AWS_ACCESS_KEY_ID
          - CERT_STAGING_AWS_SECRET_ACCESS_KEY
          - DB_TABLE_PREFIX=certification-staging-
          - BUCKET_PREFIX=certification-staging-
          - MAIN_BUCKET=main
          - AUTH_DOMAIN=https://certification.iota.works
          - ALIAS=certification-api.iota.works
          - ZEIT_TOKEN" 
  echo "    agents:
      queue: aws-nano"
}

api_prod () {
  echo "  - name: \"api-build-and-deploy-prod\""
  echo "    command:
      - apt update && apt install jq -y
      - npm i -g --unsafe-perm now
      - cd api 
      - jq -r '.provider = \\\$provider' --arg provider \\\$IRI_NODE src/data/config.template.json > src/data/config.prod.json
      - jq -r '.dynamoDbConnection .region = \\\$region' --arg region 'eu-central-1' src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.dynamoDbConnection .accessKeyId = \\\$accessKeyId' --arg accessKeyId \\\$CERT_PROD_AWS_ACCESS_KEY_ID src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.dynamoDbConnection .secretAccessKey = \\\$secretAccessKey' --arg secretAccessKey \\\$CERT_PROD_AWS_SECRET_ACCESS_KEY src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.dynamoDbConnection .dbTablePrefix = \\\$dbTablePrefix' --arg dbTablePrefix \\\$DB_TABLE_PREFIX src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.s3Connection .region = \\\$region' --arg region 'eu-central-1' src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.s3Connection .accessKeyId = \\\$accessKeyId' --arg accessKeyId \\\$CERT_PROD_AWS_ACCESS_KEY_ID src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.s3Connection .secretAccessKey = \\\$secretAccessKey' --arg secretAccessKey \\\$CERT_PROD_AWS_SECRET_ACCESS_KEY src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.s3Connection .bucketPrefix = \\\$bucketPrefix' --arg bucketPrefix \\\$BUCKET_PREFIX src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.mainBucket = \\\$mainBucket' --arg mainBucket \\\$MAIN_BUCKET src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.authenticateDomain = \\\$authenticateDomain' --arg authenticateDomain \\\$AUTH_DOMAIN src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.draftCertificates = \\\$draftCertificates' --argjson draftCertificates 'false' src/data/config.prod.json > tmp.json && mv tmp.json src/data/config.prod.json
      - jq -r '.name = \\\$name' --arg name 'certification-api' now.json > tmp.json && mv tmp.json now.json
      - now --token \\\$ZEIT_TOKEN --team iota alias \$(now --regions sfo --token \\\$ZEIT_TOKEN --team iota deploy --docker -e CONFIG_ID=prod --build-env CONFIG_ID=prod -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS" 
  echo "    plugin:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v2.0.0:
        image: \"node:8.12-stretch\"
        environment:
          - IRI_NODE=https://nodes.iota.cafe:443
          - CERT_PROD_AWS_ACCESS_KEY_ID
          - CERT_PROD_AWS_SECRET_ACCESS_KEY
          - DB_TABLE_PREFIX=certification-prod-
          - BUCKET_PREFIX=certification-prod-
          - MAIN_BUCKET=main
          - AUTH_DOMAIN=https://certification.iota.org
          - ALIAS=certification-api.iota.org
          - ZEIT_TOKEN"
  echo "    agents:
      queue: aws-nano"
}

admin_staging () {
  echo "  - name: \"admin-build-and-deploy-staging\""
  echo "    command:
      - apt update && apt install jq -y
      - npm i -g --unsafe-perm now
      - cd admin
      - jq -r '.apiEndpoint = \\\$apiEndpoint' --arg apiEndpoint \\\$API_ENDPOINT public/data/config.template.json > public/data/config.staging.json
      - jq -r '.tangleExplorer .transactions = \\\$transactions' --arg transactions 'https://devnet.thetangle.org/transaction/:transactionHash' public/data/config.staging.json > tmp.json && mv tmp.json public/data/config.staging.json
      - jq -r '.tangleExplorer .bundles = \\\$bundles' --arg bundles 'https://devnet.thetangle.org/bundle/:bundleHash' public/data/config.staging.json > tmp.json && mv tmp.json public/data/config.staging.json
      - jq -r '.name = \\\$name' --arg name 'certification-admin' now.json > tmp.json && mv tmp.json now.json
      - now --token \\\$ZEIT_TOKEN --team iota alias \$(now --regions sfo --token \\\$ZEIT_TOKEN --team iota deploy --docker -e CONFIG_ID=staging --build-env CONFIG_ID=staging --build-env GITHUB_TOKEN=\\\$GIT_TOKEN -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS" 
  echo "    plugin:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v2.0.0:
        image: \"node:8.12-stretch\"
        environment:
          - API_ENDPOINT=https://certification-api.iota.works
          - ALIAS=certification-admin.iota.works
          - ZEIT_TOKEN
          - GIT_TOKEN"
  echo "    agents:
      queue: aws-nano"    
}

admin_prod () {
  echo "  - name: \"admin-build-and-deploy-prod\""
  echo "    command:
              - apt update && apt install jq -y
              - npm i -g --unsafe-perm now
              - cd admin
              - jq -r '.apiEndpoint = \\\$apiEndpoint' --arg apiEndpoint \\\$API_ENDPOINT public/data/config.template.json > public/data/config.prod.json
              - jq -r '.name = \\\$name' --arg name 'certification-admin' now.json > tmp.json && mv tmp.json now.json
              - now --token \\\$ZEIT_TOKEN --team iota alias \$(now --regions sfo --token \\\$ZEIT_TOKEN --team iota deploy --docker -e CONFIG_ID=prod --build-env CONFIG_ID=prod --build-env GITHUB_TOKEN=\\\$GIT_TOKEN -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS" 
  echo "    plugin:
              https://github.com/iotaledger/docker-buildkite-plugin#release-v2.0.0:
                image: \"node:8.12-stretch\"
                environment:
                  - API_ENDPOINT=https://certification-api.iota.org
                  - ALIAS=certification-admin.iota.org
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
              - jq -r '.apiEndpoint = \\\$apiEndpoint' --arg apiEndpoint \\\$API_ENDPOINT public/data/config.template.json > public/data/config.staging.json
              - jq -r '.name = \\\$name' --arg name 'certification-client' now.json > tmp.json && mv tmp.json now.json
              - now --token \\\$ZEIT_TOKEN --team iota alias \$(now --regions sfo --token \\\$ZEIT_TOKEN --team iota deploy --docker -e CONFIG_ID=staging --build-env CONFIG_ID=staging --build-env GITHUB_TOKEN=\\\$GIT_TOKEN -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS"  
  echo "    plugin:
              https://github.com/iotaledger/docker-buildkite-plugin#release-v2.0.0:
                image: \"node:8.12-stretch\"
                environment:
                  - API_ENDPOINT=https://certification-api.iota.works
                  - ALIAS=certification.iota.works
                  - ZEIT_TOKEN
                  - GIT_TOKEN"
  echo "    agents:
            queue: aws-nano"
}

client_prod () {
  echo "  - block: \"Deploy LIVE\""
  echo "    prompt: \"Deploy this build to production?\""

  echo "  - name: \"client-build-and-deploy-prod\""
  echo "    command:
      - apt update && apt install jq -y
      - npm i -g --unsafe-perm now
      - cd client
      - jq -r '.apiEndpoint = \\\$apiEndpoint' --arg apiEndpoint \\\$API_ENDPOINT public/data/config.template.json > public/data/config.prod.json
      - jq -r '.name = \\\$name' --arg name 'certification-client' now.json > tmp.json && mv tmp.json now.json
      - now --token \\\$ZEIT_TOKEN --team iota alias \$(now --regions sfo --token \\\$ZEIT_TOKEN --team iota deploy --docker -e CONFIG_ID=prod --build-env CONFIG_ID=prod --build-env GITHUB_TOKEN=\\\$GIT_TOKEN -m BK_JOB_ID=\$BUILDKITE_JOB_ID) \\\$ALIAS" 
  echo "    plugin:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v2.0.0:
        image: \"node:8.12-stretch\"
        environment:
          - API_ENDPOINT=https://certification-api.iota.org
          - ALIAS=certification.iota.org
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
    'admin api client')
      api_staging
      admin_staging
      client_staging
      block_prod
      api_prod
      admin_prod
      client_prod
      ;;
    'admin api')
      api_staging
      admin_staging
      block_prod
      api_prod
      admin_prod
      ;;
    'admin client')
      admin_staging
      client_staging
      block_prod
      admin_prod
      client_prod
      ;;
    'api client')
      api_staging
      client_staging
      block_prod
      api_prod
      client_prod
      ;;
    'admin')
      admin_staging
      block_prod
      admin_prod
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