#!/bin/bash

set -e

# install latest cf cli
sudo wget -O /tmp/cfcli.deb "https://cli.run.pivotal.io/stable?release=debian64&version=6.22.2&source=github-rel"
sudo dpkg -i /tmp/cfcli.deb && apt-get install -f

# log into CF
cf api ${cf_api} --skip-ssl-validation
cf login -u ${cf_user} -p ${cf_password} -o system -s system

# list buildpacks
cf buildpacks

# Functions

# Main Login
case ${buildpack} in
    java)
      echo "Will work on java_buildpack_offline"
      exit 1
      ;;
    *)
      echo "BuildPack Not Instrumented!!!"
      exit 1
      ;;
esac
