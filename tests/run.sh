#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

logfile="$(mktemp)"

ansible-playbook -i inventory playbook.yml --syntax-check

ansible-playbook -i inventory playbook.yml --connection=local

ansible-playbook -i inventory playbook.yml --connection=local \
  | tee $logfile \
  | grep 'changed=0.*failed=0' > /dev/null \
  && (echo 'Idempotence test: pass' && exit 0) \
  || (cat $logfile && echo 'Idempotence test: fail' && exit 1)

curl -s -k https://localhost/ \
  | tee $logfile \
  | grep 'Welcome' > /dev/null \
  && (echo 'Mutalyzer website test: pass' && exit 0) \
  || (cat $logfile && echo 'Mutalyzer website test: fail' && exit 1)

curl -s -k https://localhost/json/info \
  | tee $logfile \
  | grep 'version' > /dev/null \
  && (echo 'Mutalyzer JSON service test: pass' && exit 0) \
  || (cat $logfile && echo 'Mutalyzer JSON service test: fail' && exit 1)

curl -s -k https://localhost/services/?wsdl \
  | tee $logfile \
  | grep 'targetNamespace' > /dev/null \
  && (echo 'Mutalyzer SOAP service test: pass' && exit 0) \
  || (cat $logfile && echo 'Mutalyzer SOAP service test: fail' && exit 1)
