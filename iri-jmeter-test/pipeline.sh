#!/bin/bash

# TODO
# Generate kube.config with Vault
# Manage errors on config.yml files when running TIAB or just upload every output as artifacts 

# NOTES
# iri/python-regression/tests/features/machineXX/config.yml should be copied to iri/jmeter/testXX/

set -eu

echo "steps:"

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

current-context: buildkite-namespace
" >> kube.config

echo "  - name: \"Running jmeter tests\""
echo "    command:
    - echo \"Cloning TIAB\"
    - git clone --depth 1 https://github.com/iotaledger/tiab.git
    - cp kube.config tiab/
    - echo \"Installing TIAB dependencies\"
    - cd tiab
    - virtualenv venv
    - source venv/bin/activate
    - pip install -r requirements.txt
    - echo \"Running TIAB against config.yml files\""
for test_dir in jmeter/test*/
  TEST_ID=$(test_dir | grep -o '[0-9]\+')
  cp python-regression/tests/features/machine$TEST_ID $test_dir
  echo "      - 
      - python create_cluster.py -i iotacafe/iri-dev:latest -t $BUILDKITE_BUILD_ID -c $test_dir/config.yml -o $test_dir/output.yml -k kube.config -n buildkite -d
      - jmeter -n -t test.jmx -l results-$TEST_ID.jtl "
done
echo "     - python teardown_cluster.py -t $BUILDKITE_BUILD_ID -k /conf/kube/kube.config -n buildkite"
echo "    plugins:
    https://github.com/iotaledger/docker-buildkite-plugin#release-v2.0.0:
      image: \"python:2\"
      environment:
        - " 
echo "    agents:
    queue: aws-m5large"  