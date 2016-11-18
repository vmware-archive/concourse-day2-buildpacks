#!/bin/bash


function fn_auth_cli {

  cf api ${cf_api} --skip-ssl-validation
  cf login -u ${cf_user} -p ${cf_password} -o system -s system

}

function fn_check_app_health {

  local app_id=${1}
  let 'timeout = 300'
  sleep 3

  for (( x=0; x < $timeout; x++ )); do

        declare -a app_instances
        app_stage_state_cmd="cf curl /v2/apps/${app_id} | jq .entity.package_state | tr -d '\"'"
        app_stage_state=$(eval $app_state_cmd)
        app_instance_state_cmd="cf curl /v2/apps/${app_id}/stats | jq .[].state | tr -d '\"'"
        let 'ai_count = 0'
        for y in $(eval ${app_instance_state_cmd}); do
                (( ai_count++ ))
        done
        let 'healthy_count = 0'

        for x in $(eval ${app_instance_state_cmd}); do
            if [[ ${x} == "RUNNING" ]]; then
              echo ${app_id}":instance-state:"${x}
              (( healthy_count++ ))
            fi
        done

        if [[ ${healthy_count} -eq ${ai_count} ]]; then
          return 0
        fi
        sleep 1
  done

  if [[ ! ${healthy_count} -eq ${ai_count} ]]; then
    echo "AppID:${1} Not Running" 1>&2
    exit 1
  else
    echo "AppID:${1} Running :) "
    exit 0
  fi
}

fn_auth_cli
fn_check_app_health ${1}
