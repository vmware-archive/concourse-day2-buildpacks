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
function fn_get_buildpack_id {

   local buildpack=${1}

   my_cmd="cf curl /v2/buildpacks | jq '.resources[] | select(.entity.name==\"${buildpack}\") | .' | jq .metadata.guid | tr -d '\"'"
   eval $my_cmd


}

function fn_restage_apps_with_buildpack {

  local buildpack_id=${1}
  declare -a apps
  my_cmd="cf curl /v2/apps | jq '.resources[] | select(.entity.detected_buildpack_guid==\"${buildpack_id}\") | .metadata.guid' | tr -d '\"'"
  apps=$(eval $my_cmd)
  for x in ${apps[@]}; do
      echo "Restaging App GUID="$x" ..."
      cf curl -X POST /v2/apps/$x/restage
  done

}

function fn_trigger {

  declare -a apps
  echo "Will work on ... ${buildpack}"
  buildpack_id=$(fn_get_buildpack_id "${buildpack}")
  fn_restage_apps_with_buildpack "${buildpack_id}"
}


# Main Logic
case ${buildpack} in
    java_buildpack_offline)
      declare -a apps
      fn_trigger
      ;;
    go_buildpack)
      fn_trigger
      ;;
    nodejs_buildpack)
      fn_trigger
      ;;
    *)
      echo "BuildPack Not Instrumented!!!"
      exit 1
      ;;
esac
