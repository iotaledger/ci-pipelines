#!/bin/bash

set -eu

wait() {
  echo "  - wait"
}

waitf() {
  echo "  - wait: ~
    continue_on_failure: true"
}

echo "steps:"

echo "  - name: \"[TIAB] Cloning TIAB\"
    command:
      - apk add git
      - git clone --depth 1 https://github.com/sadjy/tiab.git /cache/tiab
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
        from yaml import load, Loader
        import argparse
        parser = argparse.ArgumentParser()
        parser.add_argument('-n', '--node', dest='node_name', required=True)
        parser.add_argument('-q', '--host', dest='host', action='store_true')
        parser.add_argument('-p', '--port', dest='port', action='store_true')

        args = parser.parse_args()
        node_name = args.node_name

        yaml_path = 'output.yml'
        stream = open(yaml_path,'r')
        yaml_file = load(stream,Loader=Loader)

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
      - tar xzf apache-jmeter-5.1.1.tgz && export PATH=\\\$PATH:\$(pwd)/apache-jmeter-5.1.1/bin
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
      - cd /cache/tiab
      - apk add python3
      - python3 --version
      - . venv/bin/activate
      - mkdir jmeter-$BUILDKITE_BUILD_ID
      - python nodeaddr.py -n node\\\$TESTNAME -q
      - jmeter -n -t $testfile -Jhost=\\\$(python nodeaddr.py -n node$TESTNAME -q) -Jport=\\\$(python nodeaddr.py -n node$TESTNAME -p) -j jmeter-$BUILDKITE_BUILD_ID/$TESTNAME.log -l jmeter-$BUILDKITE_BUILD_ID/$TESTNAME.jtl -e -o jmeter-$BUILDKITE_BUILD_ID/$TESTNAME
      - |
        cat << EOF | buildkite-agent annotate --style \"info\"
          Read the <a href=\"artifact://jmeter-$BUILDKITE_BUILD_ID/$TESTNAME/index.html\"> $TESTNAME tests results</a>
        EOF
    artifact_paths: 
        - \"jmeter-$BUILDKITE_BUILD_ID/**/*\"
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
done

waitf

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