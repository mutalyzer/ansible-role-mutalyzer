#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

ansible-playbook -i inventory.yml playbook.yml --syntax-check

ansible-playbook -i inventory.yml playbook.yml --connection=local

ansible-playbook -i inventory.yml playbook.yml --connection=local \
  | grep 'changed=0.*failed=0' > /dev/null \
  && (echo 'Idempotence test: pass' && exit 0) \
  || (echo 'Idempotence test: fail' && exit 1)

curl -s -k https://localhost/ \
  | grep 'Welcome' > /dev/null \
  && (echo 'Mutalyzer website test: pass' && exit 0) \
  || (echo 'Mutalyzer website test: fail' && exit 1)

curl -s -k https://localhost/json/info \
  | grep 'version' > /dev/null \
  && (echo 'Mutalyzer JSON service test: pass' && exit 0) \
  || (echo 'Mutalyzer JSON service test: fail' && exit 1)

curl -s -k https://localhost/services/?wsdl \
  | grep 'targetNamespace' > /dev/null \
  && (echo 'Mutalyzer SOAP service test: pass' && exit 0) \
  || (echo 'Mutalyzer SOAP service test: fail' && exit 1)
