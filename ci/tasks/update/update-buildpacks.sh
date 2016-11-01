#!/bin/bash

set -e

# install cf cli
sudo wget -O /tmp/cfcli.deb "https://cli.run.pivotal.io/stable?release=debian64&version=6.22.2&source=github-rel"
sudo dpkg -i /tmp/cfcli.deb && apt-get install -f

# log into CF
cf api https://${cf_api} --skip-ssl-validation
cf login -u ${cf_user} -p ${cf_password} -o system -s system

# list buildpacks
cf buildpacks

exit 1
