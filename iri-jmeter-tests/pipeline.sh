#!/bin/bash

# TODO
# Generate kube.config with Vault
# Manage errors on config.yml files when running TIAB or just upload every output as artifacts 

set -eu

echo "steps:"

echo "  - block: \"Just printing\""

echo "apiVersion: v1
kind: Config
preferences: {}

clusters:
- cluster:
    certificate-authority-data: $TIAB_KUBE_CA  
    server: $TIAB_KUBE_SERVER
  name: my-cluster

users:
- name: buildkite-user
  user:
    as-user-extra: {}
    client-key-data: $TIAB_KUBE_CLIENT_KEY 
    token: $TIAB_KUBE_TOKEN 

contexts:
- context:
    cluster: my-cluster
    namespace: buildkite
    user: buildkite-user
  name: buildkite-namespace

current-context: buildkite-namespace" > kube.config

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

echo "defaults: &config
  db: https://s3.eu-central-1.amazonaws.com/iotaledger-dbfiles/dev/testnet_files.tgz
  db_checksum: 6eaa06d5442416b7b8139e337a1598d2bae6a7f55c2d9d01f8c5dac69c004f75" > node_config.yml

echo "from yaml import load, Loader
import argparse
parser = argparse.ArgumentParser()
parser.add_argument(\"node\")
args = parser.parse_args()
node_name = args.node

yaml_path = './output.yml'
stream = open(yaml_path,'r')
yaml_file = load(stream,Loader=Loader)

for key, value in yaml_file['nodes'].items():
    if key == node_name:
        print(\"{}{}:{}\".format(\"https://\", yaml_file['nodes'][node_name]['host'], yaml_file['nodes'][node_name]['ports']['api']))" > nodeaddr.py


echo "  - name: \"Running jmeter tests\""
echo "    command:
    - echo \"[TIAB] Cloning github repository\"
    - git clone --depth 1 https://github.com/iotaledger/tiab.git
    - cp kube.config tiab/
    - cp node_config.yml tiab/
    - echo \"[TIAB] Installing dependencies\"
    - cd tiab
    - virtualenv venv
    - source venv/bin/activate
    - pip install -r requirements.txt
    - echo \"[TIAB] Creating IRI nodes cluster\"
    - python create_cluster.py -i iotacafe/iri-dev:latest -t $BUILDKITE_BUILD_ID -c node_config.yml -o output.yml -k kube.config -n buildkite -d"
for testfile in ../Nightly-Tests/Jmeter-Tests/*.jmx
do
  TESTNAME=${testfile%.jmx}
  echo "nodes:
    node$TESTNAME:
      <<: *config" >> node_config.yml
  echo "      - echo \"[Jmeter] Running $TESTNAME test\"
      - jmeter -n -t $testfile host=$(python nodeaddr.py node$TESTNAME) -l results-$TESTNAME.jtl -j jmeter-$TESTNAME.log"
done
echo "     - python teardown_cluster.py -t $BUILDKITE_BUILD_ID -k /conf/kube/kube.config -n buildkite"
echo "    plugins:
    https://github.com/iotaledger/docker-buildkite-plugin#release-v2.0.0:
      image: \"python:2\"
      environment:
        - " 
echo "    agents:
    queue: aws-m5large"  