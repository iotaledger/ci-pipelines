#!/bin/bash

export BUILDKITE_AGENT_NAME=\$BUILDKITE_AGENT_NAME

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

echo "  - name: \"[IRI] Clearing cache\"
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
      queue: nightly-tests"

echo "  - name: \"[IRI] Downloading and unpacking DBs\"
    command:
      - apk add curl
      - mkdir -p /cache/iri01/data
      - curl -s https://s3.eu-central-1.amazonaws.com/iotaledger-dbfiles/dev/SyncTestSynced.tar.gz | tar xzf - -C /cache/iri01/data
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
      queue: nightly-tests"

echo "  - name: \"[IRI] Starting nodes\"
    command:
      - docker network create iri || true
      - |
        docker run \
        -d --rm\
        --name iri01 \
        -v /cache/iri01/data:/iri/data \
        -p 15600:15600 \
        -p 14600:14600/udp  \
        -p 14265:14265 \
        --net=iri \
        iotaledger/iri \
        -p 14265 \
        -t 15600 \
        -u 14600 \
        --testnet-coordinator EFPNKGPCBXXXLIBYFGIGYBYTFFPIOQVNNVVWTTIYZO9NFREQGVGDQQHUUQ9CLWAEMXVDFSSMOTGAHVIBH \
        --mwm 1 \
        --milestone-start 0 \
        --testnet-no-coo-validation true \
        --testnet true \
        --snapshot ./snapshot.txt \
        --zmq-enabled true
    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
        image: \"docker\"
        always-pull: false
        mount-buildkite-agent: true        
        volumes:
          - /cache-iri-jmeter-tests-$BUILDKITE_BUILD_ID:/cache
          - /var/run/docker.sock:/var/run/docker.sock
    env:
      BUILDKITE_AGENT_NAME: \"$BUILDKITE_AGENT_NAME\"
    agents:
      queue: nightly-tests"

wait

echo "  - name: \"[Jmeter] Downloading and extracting binary\"
    command:
      - cd /cache
      - wget http://apache.mirror.cdnetworks.com//jmeter/binaries/apache-jmeter-5.2.1.tgz
      - tar xzf apache-jmeter-5.2.1.tgz 
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
      queue: nightly-tests" 

wait

for testfile in Nightly-Tests/Jmeter-Tests/*.jmx
do
  TESTPATH=$(basename $testfile)
  TESTNAME=${TESTPATH%.jmx}
  echo "  - name: \"[Jmeter] Running $TESTNAME test\"
    command:
      - export PATH=\\\$PATH:/cache/apache-jmeter-5.2.1/bin
      - apk add --quiet --no-progress --update jq curl
      - jmeter -n -t /workdir/$testfile -Jhost=localhost -Jport=14265 -j /cache/jmeter-$BUILDKITE_BUILD_ID/$TESTNAME.log -l /cache/jmeter-$BUILDKITE_BUILD_ID/$TESTNAME.jtl -e -o /cache/jmeter-$BUILDKITE_BUILD_ID/$TESTNAME
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
      queue: nightly-tests"          

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
      queue: nightly-tests"          

waitf

done

#block 

#for testfile in Nightly-Tests/Jmeter-Tests/*.jmx
#do
#  TESTPATH=$(basename $testfile)
#  TESTNAME=${TESTPATH%.jmx}
#  echo "  - name: \"[Jmeter] Displaying $TESTNAME graph\"
#    command:
#      - apk --no-cache --update-cache add gcc gfortran python3 python3-dev py3-pip build-base freetype-dev libpng-dev openblas-dev
#      - pip3 install boto requests matplotlib
#      - |
#        cat <<EOF >> /cache/plot.py
#        import os
#        import boto
#        from boto.s3.connection import S3Connection
#        import requests
#        import json
#        import csv
#        import datetime
#        import matplotlib.pyplot as plt
#        import matplotlib.dates as mdates
#
#        aws_key = os.environ['AWS_ACCESS_KEY_ID']
#        aws_secret = os.environ['AWS_SECRET_ACCESS_KEY']
#        region = 's3.eu-central-1.amazonaws.com'
#        bucket_name = 'iotaledger-iri-jmeter-tests'
#        s3 = S3Connection(aws_key, aws_secret, host=region)
#        bucket = s3.get_bucket(bucket_name)
#        date_table = []
#        metric_table = []
#        version_table = []
#        with open('$TESTNAME.csv', 'w') as csvfile:
#          filewriter = csv.writer(csvfile)
#          for o in bucket.list(delimiter='/'):
#              stats_url = 'https://{}.{}/{}$TESTNAME/statistics.json'.format(bucket_name, region, o.name)
#              mdata_url = 'https://{}.{}/{}$TESTNAME/metadata.json'.format(bucket_name, region, o.name)
#              stats_req = requests.get(stats_url)
#              mdata_req = requests.get(mdata_url)
#              date = mdata_req.json()['metadata']['date']
#              metric = stats_req.json()['GetTransactionsToApprove']['meanResTime']
#              version = mdata_req.json()['metadata']['appVersion']
#              date_table.append(datetime.date.fromisoformat(date))
#              metric_table.append(metric)
#              version_table.append(version) 
#              filewriter.writerow([date, metric, version])
#        fig, ax = plt.subplots()
#        plt.plot_date(date_table, metric_table)
#        plt.xlabel('Date')
#        plt.ylabel('Mean response time')
#        plt.title('$TESTNAME')
#        ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
#        ax.xaxis.set_tick_params(rotation=30, labelsize=7)
#        plt.savefig('$TESTNAME.png')
#        EOF
#      - python3 /cache/plot.py
#      - ls -al && pwd
#      - cp -rf *.{png,csv} /workdir/jmeter-$BUILDKITE_BUILD_ID/$TESTNAME/
#    artifact_paths: 
#      - \"jmeter-$BUILDKITE_BUILD_ID/$TESTNAME/*.csv;jmeter-$BUILDKITE_BUILD_ID/$TESTNAME/*.png\"
#    plugins:
#      https://github.com/iotaledger/docker-buildkite-plugin#release-v3.2.0:
#        image: \"python:alpine\"
#        always-pull: false
#        mount-buildkite-agent: false
#        volumes:
#          - /cache-iri-jmeter-tests-$BUILDKITE_BUILD_ID:/cache
#        environment:
#          - AWS_ACCESS_KEY_ID
#          - AWS_SECRET_ACCESS_KEY
#    env:
#      BUILDKITE_AGENT_NAME: \"$BUILDKITE_AGENT_NAME\"
#    agents:
#      queue: nightly-tests"
#done 


