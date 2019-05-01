#!/bin/bash

# TODO
# Generate kube.config with Vault
# Manage errors on config.yml files when running TIAB or just upload every output as artifacts 

set -eu

echo "steps:"

#echo "defaults: &conFig
#  db: https://s3.eu-central-1.amazonaws.com/iotaledger-dbfiles/dev/testnet_files.tgz
#  db_checksum: 6eaa06d5442416b7b8139e337a1598d2bae6a7f55c2d9d01f8c5dac69c004f75
#  iri_args: ['--testnet-coordinator',
#  'BTCAAFIH9CJIVIMWFMIHKFNWRTLJRKSTMRCVRE9CIP9AEDTOULVFRHQZT9QAQBZXXAZGBNMVOOKTKAXTB',
#  '--milestone-start', 
#  '0',
#  '--snapshot', 
#  './snapshot.txt',
#  '--testnet-no-coo-validation',
#  'true',
#  '--testnet',
#  'true'
#  ]" > node_config.yml

echo "  - name: \"Running jmeter tests\""
echo "    command:
    - echo \"[TIAB] Cloning github repository\"
    - git clone --depth 1 https://github.com/iotaledger/tiab.git
    - |
      cat <<EOF >> tiab/kube.config 
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
      cat <<EOF >> tiab/node_config.yml 
      defaults: &config
        db: https://s3.eu-central-1.amazonaws.com/iotaledger-dbfiles/dev/testnet_files.tgz
        db_checksum: 6eaa06d5442416b7b8139e337a1598d2bae6a7f55c2d9d01f8c5dac69c004f75
      nodes:
      EOF
      for testfile in Nightly-Tests/Jmeter-Tests/*.jmx; do
        TESTNAME=\$(basename \\\$testfile .jmx)
        echo \"  node\\\$TESTNAME:
            <<: *config\" >> tiab/node_config.yml
      done
    - |
      cat <<EOF >> tiab/nodeaddr.py 
      from yaml import load, Loader
      import argparse
      parser = argparse.ArgumentParser()
      parser.add_argument('-n', '--node', dest='node_name', required=True)
      parser.add_argument('-q', '--host', dest='host', action='store_true')
      parser.add_argument('-p', '--port', dest='port', action='store_true')

      args = parser.parse_args()
      node_name = args.node_name

      yaml_path = './output.yml'
      stream = open(yaml_path,'r')
      yaml_file = load(stream,Loader=Loader)

      for key, value in yaml_file['nodes'].items():
          if key == node_name:
            if args.host:
                print(\"{}\".format(yaml_file['nodes'][node_name]['host']))
            if args.port:
                print(\"{}\".format(yaml_file['nodes'][node_name]['ports']['api']))
      EOF
    - apt update && apt install python-pip -y
    - echo \"[TIAB] Installing dependencies\"
    - cd tiab
    - virtualenv venv
    - . venv/bin/activate
    - pip install -r requirements.txt
    - echo \"[TIAB] Creating IRI nodes cluster\"
    - cat node_config.yml
    - python create_cluster.py -i iotacafe/iri-dev:latest -t $BUILDKITE_BUILD_ID -c node_config.yml -o output.yml -k kube.config -n buildkite -d
    - echo [Jmeter] Downloading and extracting binary
    - wget http://apache.mirror.cdnetworks.com//jmeter/binaries/apache-jmeter-5.1.1.tgz
    - tar xzf apache-jmeter-5.1.1.tgz && export PATH=\\\$PATH:\$(pwd)/apache-jmeter-5.1.1/bin"
for testfile in Nightly-Tests/Jmeter-Tests/*.jmx
do
  TESTPATH=$(basename $testfile)
  TESTNAME=${TESTPATH%.jmx}
  echo "    - echo \"[Jmeter] Running $TESTNAME test\"
      - python nodeaddr.py -n node\\\$TESTNAME -q
      - python nodeaddr.py -n node\\\$TESTNAME -p
      - jmeter -n -t $testfile Jhost=\\\$(python nodeaddr.py -n node$TESTNAME -q) Jport=\\\$(python nodeaddr.py -n node$TESTNAME -p) -l results-$TESTNAME.jtl -j jmeter-$TESTNAME.log"
done
echo "    - python teardown_cluster.py -t $BUILDKITE_BUILD_ID -k kube.config -n buildkite
    - pwd && ls -al
    - sleep 600"

echo "    artifact_paths: 
      - \"tiab/*.jtl\"
      - \"tiab/*.log\""
echo "    plugins:
      https://github.com/iotaledger/docker-buildkite-plugin#release-v2.0.0:
        image: \"openjdk:8\"
        environment:
          - TIAB_KUBE_CA
          - TIAB_KUBE_TOKEN
          - TIAB_KUBE_SERVER
          - TIAB_KUBE_CLIENT_KEY" 
echo "    agents:
      queue: aws-m5large"  