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
      #app_name=$(cf curl /v2/apps/$x : jq .entity.name)
      cf curl -X POST /v2/apps/$x/restage
  done

}

function fn_check_app_health {

  local app_id=${1}
  let 'timeout = 120'
  sleep 3

  for (( x=0; x < $timeout; x++ )); do

        declare -a app_instances
        app_stage_state_cmd="cf curl /v2/apps/${app_id} | jq .entity.package_state | tr -d '\"'"
        app_stage_state=$(eval $app_state_cmd)
        app_instance_state_cmd="cf curl /v2/apps/${app_id}/stats | jq .[].state | tr -d '\"'"
        app_instances=$(eval ${app_instance_state_cmd})
        let "ai_count = ${#app_instances[@]}"
        let 'healthy_count = 0'

        for x in ${app_instances[@]}; do
            if [[ ${x} == "RUNNING" ]]; then
              let 'healthy_count++'
            fi
        done

        if [[ ${healthy_count} -eq ${ai_count} ]]; then
          return 0
        fi
        sleep 1
  done

  if [[ ! ${healthy_count} -eq ${ai_count} ]]; then
    echo "App Not Running" 1>&2
    exit 1
  fi
}

function fn_trigger {

  declare -a apps
  echo "Will work on ... ${buildpack}"
  buildpack_id=$(fn_get_buildpack_id "${buildpack}")
  fn_restage_apps_with_buildpack "${buildpack_id}"
  exit 1
}


# Main Logic
case ${buildpack} in
    java_buildpack_offline)
      fn_trigger
      ;;
    go_buildpack)
      fn_trigger
      ;;
    nodejs_buildpack)
      fn_trigger
      ;;
    *)
      echo "BuildPack ${buildpack} Not Yet Instrumented!!!"
      exit 1
      ;;
esac
