#!/bin/bash


function fn_auth_cli {

  cf api ${cf_api} --skip-ssl-validation
  cf login -u ${cf_user} -p ${cf_password} -o system -s system

}

function fn_check_app_health {

  local app_id=${1}
  let 'timeout = 120'
  sleep 30

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
              echo ${app_id}":instance-state:"${x}
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

fn_auth_cli
fn_check_app_health ${1}
