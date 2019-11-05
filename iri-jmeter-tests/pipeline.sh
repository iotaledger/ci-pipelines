#!/bin/bash

set -eu

wait() {
  echo "  - wait"
}

waitf() {
  echo "  - wait: ~
    continue_on_failure: true"
}

block() {
  echo "  - block: \"Display graphs\""
}

echo "steps:"

echo "  - name: \"[TIAB] Clearing cache\"
    command:
      - rm -rf /cache/*
    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"alpine\"
        always-pull: false
        mount-buildkite-agent: false        
        volumes:
          - /cache-iri-jmeter-tests-$BUILDKITE_BUILD_ID:/cache
    env:
      BUILDKITE_AGENT_NAME: \"$BUILDKITE_AGENT_NAME\"
    agents:
      queue: aws-m5large"

echo "  - name: \"[TIAB] Cloning TIAB\"
    command:
      - apk add git
      - git clone --depth 1 https://github.com/iotaledger/tiab.git /cache/tiab
    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"alpine\"
        always-pull: false
        mount-buildkite-agent: false        
        volumes:
          - /cache-iri-jmeter-tests-$BUILDKITE_BUILD_ID:/cache
    env:
      BUILDKITE_AGENT_NAME: \"$BUILDKITE_AGENT_NAME\"
    agents:
      queue: aws-m5large"

wait

echo "  - name: \"[TIAB] Setting up dependencies\"
    command:
      - |
        cat <<EOF >> /cache/tiab/kube.config 
        apiVersion: v1
        kind: Config
        preferences: {}

        clusters:
        - cluster:
            certificate-authority-data: \\\$TIAB_KUBE_CA  
            server: \\\$TIAB_KUBE_SERVER
          name: my-cluster

        users:
        - name: buildkite-user
          user:
            as-user-extra: {}
            client-key-data: \\\$TIAB_KUBE_CLIENT_KEY 
            token: \\\$TIAB_KUBE_TOKEN 

        contexts:
        - context:
            cluster: my-cluster
            namespace: buildkite
            user: buildkite-user
          name: buildkite-namespace

        current-context: buildkite-namespace
        EOF
      - |
        cat <<EOF >> /cache/tiab/node_config.yml 
        defaults: &config
          db: https://s3.eu-central-1.amazonaws.com/iotaledger-dbfiles/dev/testnet_files.tgz
          db_checksum: 6eaa06d5442416b7b8139e337a1598d2bae6a7f55c2d9d01f8c5dac69c004f75
        nodes:
        EOF
        for testfile in Nightly-Tests/Jmeter-Tests/*.jmx; do
          TESTNAME=\$(basename \\\$testfile .jmx)
          echo \"  node\\\$TESTNAME:
              <<: *config\" >> /cache/tiab/node_config.yml
        done
      - |
        cat <<EOF >> /cache/tiab/nodeaddr.py 
        import yaml
        import argparse
        parser = argparse.ArgumentParser()
        parser.add_argument('-n', '--node', dest='node_name', required=True)
        parser.add_argument('-q', '--host', dest='host', action='store_true')
        parser.add_argument('-p', '--port', dest='port', action='store_true')

        args = parser.parse_args()
        node_name = args.node_name

        with open('output.yml', 'r') as stream:
          yaml_file = yaml.load(stream, Loader = yaml.Loader)

        for key, value in yaml_file['nodes'].items():
            if key == node_name:
              if args.host:
                  print(\"{}\".format(yaml_file['nodes'][node_name]['host']))
              if args.port:
                  print(\"{}\".format(yaml_file['nodes'][node_name]['ports']['api']))
        EOF
      - apk add gcc musl-dev libffi-dev openssl-dev
      - pip install virtualenv
      - cd /cache/tiab
      - virtualenv venv
      - . venv/bin/activate
      - pip install -r requirements.txt
    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"python:alpine\"
        environment:
          - TIAB_KUBE_CA
          - TIAB_KUBE_TOKEN
          - TIAB_KUBE_SERVER
          - TIAB_KUBE_CLIENT_KEY
          - IRI_IMAGE
        always-pull: false
        mount-buildkite-agent: false
        volumes:
          - /cache-iri-jmeter-tests-$BUILDKITE_BUILD_ID:/cache
    env:
      BUILDKITE_AGENT_NAME: \"$BUILDKITE_AGENT_NAME\"
    agents:
      queue: aws-m5large" 

wait

echo "  - name: \"[TIAB] Creating IRI nodes cluster with \${IRI_IMAGE:-iotacafe/iri-dev}\"
    command:
      - cd /cache/tiab
      - . venv/bin/activate 
      - python create_cluster.py -i \${IRI_IMAGE:-iotacafe/iri-dev} -t \$BUILDKITE_BUILD_ID -c node_config.yml -o output.yml -k kube.config -n buildkite -d
    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"python:alpine\"
        always-pull: false
        mount-buildkite-agent: false
        volumes:
          - /cache-iri-jmeter-tests-$BUILDKITE_BUILD_ID:/cache
    env:
      BUILDKITE_AGENT_NAME: \"$BUILDKITE_AGENT_NAME\"
    agents:
      queue: aws-m5large"

wait

echo "  - name: \"[Jmeter] Downloading and extracting binary\"
    command:
      - cd /cache
      - wget http://apache.mirror.cdnetworks.com//jmeter/binaries/apache-jmeter-5.1.1.tgz
      - tar xzf apache-jmeter-5.1.1.tgz 
      - mkdir jmeter-$BUILDKITE_BUILD_ID
    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"alpine\"
        always-pull: false
        mount-buildkite-agent: false
        volumes:
          - /cache-iri-jmeter-tests-$BUILDKITE_BUILD_ID:/cache
    env:
      BUILDKITE_AGENT_NAME: \"$BUILDKITE_AGENT_NAME\"
    agents:
      queue: aws-m5large" 

wait

for testfile in Nightly-Tests/Jmeter-Tests/*.jmx
do
  TESTPATH=$(basename $testfile)
  TESTNAME=${TESTPATH%.jmx}
  echo "  - name: \"[Jmeter] Running $TESTNAME test\"
    command:
      - export PATH=\\\$PATH:/cache/apache-jmeter-5.1.1/bin
      - cd /cache/tiab
      - apk add --quiet --no-progress --update python3 py-pip jq curl
      - pip3 install --quiet --progress-bar off --upgrade pip
      - pip3 install --quiet --progress-bar off -r requirements.txt
      - pip3 install --quiet --progress-bar off argparse
      - hostDest=\\\$(python3 nodeaddr.py -n node$TESTNAME -q)
      - portDest=\\\$(python3 nodeaddr.py -n node$TESTNAME -p)
      - jmeter -n -t /workdir/$testfile -Jhost=\\\$hostDest -Jport=\\\$portDest -j /cache/jmeter-$BUILDKITE_BUILD_ID/$TESTNAME.log -l /cache/jmeter-$BUILDKITE_BUILD_ID/$TESTNAME.jtl -e -o /cache/jmeter-$BUILDKITE_BUILD_ID/$TESTNAME
      - |
        cat << EOF | buildkite-agent annotate --style \"default\" --context '$TESTPATH'
          Read the <a href=\"artifact://jmeter-$BUILDKITE_BUILD_ID/$TESTNAME/index.html\"> $TESTNAME tests results</a>
        EOF
      - jq -n '.metadata .date = \\\$date' --arg date \\\$(date +%Y-%m-%d) > /cache/jmeter-$BUILDKITE_BUILD_ID/$TESTNAME/tmp.json
      - jq '.metadata .appVersion = \\\$appVersion' --arg appVersion \\\$(curl -s http://\\\$hostDest:\\\$portDest -X  POST -H 'Content-Type:application/json' -H 'X-IOTA-API-Version:1' -d '{\"command\":\"getNodeInfo\"}' | jq -r '.appVersion') /cache/jmeter-$BUILDKITE_BUILD_ID/$TESTNAME/tmp.json > /cache/jmeter-$BUILDKITE_BUILD_ID/$TESTNAME/metadata.json && rm /cache/jmeter-$BUILDKITE_BUILD_ID/$TESTNAME/tmp.json
      - echo
      - cp -rf /cache/jmeter-$BUILDKITE_BUILD_ID /workdir 
    artifact_paths: 
      - \"jmeter-$BUILDKITE_BUILD_ID/$TESTNAME/**/*\"
    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"openjdk:8-alpine\"
        always-pull: false
        mount-buildkite-agent: true
        volumes:
          - /cache-iri-jmeter-tests-$BUILDKITE_BUILD_ID:/cache
    env:
      BUILDKITE_AGENT_NAME: \"$BUILDKITE_AGENT_NAME\"
    agents:
      queue: aws-m5large"          

  waitf

  echo "  - name: \"[Jmeter] Checking $TESTNAME results\"
    command:
      - apk add jq ca-certificates
      - exitflag=false
      - |
        case $TESTNAME in
          GetTransactionsToApprove)
            thresResp=456
            thresThru=186
          ;;
          GetTransactionsToApproveLoop)
            thresResp=18
            thresThru=268
          ;;          
        esac
      - cd /cache/jmeter-$BUILDKITE_BUILD_ID/$TESTNAME
      - respTime=\\\$(jq -r \".Total .meanResTime\" statistics.json)
      - throughput=\\\$(jq -r \".Total .throughput\" statistics.json)
      - |
        if [ \\\${respTime%%.*} -gt \\\$thresResp ]; then
          buildkite-agent annotate '$TESTNAME mean Response Time value exceeding threshold value' --style \"error\" --context '$TESTNAME-check1'
          exitflag=true
        fi
      - |
        if [ \\\${throughput%%.*} -gt \\\$thresThru ]; then
          buildkite-agent annotate '$TESTNAME mean Throughput value exceeding threshold value' --style \"error\" --context '$TESTNAME-check2'
          exitflag=true
        fi
      - if [ \"\\\$exitflag\" = true ]; then exit 1; fi
    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"alpine\"
        always-pull: false
        mount-buildkite-agent: true
        volumes:
          - /cache-iri-jmeter-tests-$BUILDKITE_BUILD_ID:/cache
    env:
      BUILDKITE_AGENT_NAME: \"$BUILDKITE_AGENT_NAME\"
    agents:
      queue: aws-m5large"          

waitf

done

echo "  - name: \"[TIAB] Tearing down cluster\"
    command:
      - cd /cache/tiab
      - . venv/bin/activate
      - python teardown_cluster.py -t $BUILDKITE_BUILD_ID -k kube.config -n buildkite
      - ls -al
    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"python:alpine\"
        always-pull: false
        mount-buildkite-agent: false
        volumes:
          - /cache-iri-jmeter-tests-$BUILDKITE_BUILD_ID:/cache
    env:
      BUILDKITE_AGENT_NAME: \"$BUILDKITE_AGENT_NAME\"
    agents:
      queue: aws-m5large"  

waitf
#block 

for testfile in Nightly-Tests/Jmeter-Tests/*.jmx
do
  TESTPATH=$(basename $testfile)
  TESTNAME=${TESTPATH%.jmx}
  echo "  - name: \"[Jmeter] Displaying $TESTNAME graph\"
    command:
      - echo
      - |
        cat <<EOF >> /cache/plot.py 
        import yaml
        import os
        import boto
        from boto.s3.connection import S3Connection
        import requests
        import json
        import csv
        import datetime
        import matplotlib.pyplot as plt
        import matplotlib.dates as mdates

        aws_key = os.environ['AWS_ACCESS_KEY_ID']
        aws_secret = os.environ['AWS_SECRET_ACCESS_KEY']
        region = 's3.eu-central-1.amazonaws.com'
        bucket_name = 'iotaledger-iri-jmeter-tests'
        s3 = S3Connection(aws_key, aws_secret, host=region)
        bucket = s3.get_bucket(bucket_name)
        date_table = []
        metric_table = []
        version_table = []
        with open('$TESTNAME.csv', 'w') as csvfile:
          filewriter = csv.writer(csvfile)
          for o in bucket.list(delimiter='/'):
              stats_url = 'https://{}.{}/{}$TESTNAME/statistics.json'.format(bucket_name, region, o.name)
              mdata_url = 'https://{}.{}/{}$TESTNAME/metadata.json'.format(bucket_name, region, o.name)
              stats_req = requests.get(stats_url)
              mdata_req = requests.get(mdata_url)
              date = mdata_req.json()['metadata']['date']
              metric = stats_req.json()['$TESTNAME']['meanResTime']
              version = mdata_req.json()['metadata']['appVersion']
              date_table.append(datetime.date.fromisoformat(date))
              metric_table.append(metric)
              version_table.append(version) 
              filewriter.writerow([date, metric, version])
        fig, ax = plt.subplots()
        plt.plot_date(date_table, metric_table)
        plt.xlabel('Date')
        plt.ylabel('Mean response time')
        plt.title('$TESTNAME')
        ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
        ax.xaxis.set_tick_params(rotation=30, labelsize=7)
        plt.savefig('$TESTNAME.png')
        EOF
      - python3 /cache/plot.py
      - cp -rf /cache/*.{png,csv} /workdir/jmeter-$BUILDKITE_BUILD_ID/$TESTNAME/
      - ls -al 
    artifact_paths: 
      - \"jmeter-$BUILDKITE_BUILD_ID/$TESTNAME/*.csv;jmeter-$BUILDKITE_BUILD_ID/$TESTNAME/*.png\"
    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"python:alpine\"
        always-pull: false
        mount-buildkite-agent: false
        volumes:
          - /cache-iri-jmeter-tests-$BUILDKITE_BUILD_ID:/cache
        environment:
          - AWS_ACCESS_KEY_ID
          - AWS_SECRET_ACCESS_KEY
    env:
      BUILDKITE_AGENT_NAME: \"$BUILDKITE_AGENT_NAME\"
    agents:
      queue: aws-m5large"
done 


