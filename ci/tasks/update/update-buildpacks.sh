#!/bin/bash

set -e

# Log Into CF

cf api https://${cf_api} --skip-ssl-validation
cf login -u ${cf_user} -p ${cf_password} -o system -s system

cf buildpacks

exit 1
