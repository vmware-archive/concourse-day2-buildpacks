#!/bin/bash
function fn_check_app_health {

  local app_id=${1}
  let 'timeout = 300'
  sleep 3

  for (( x=0; x < $timeout; x++ )); do

        #app_instance_state_cmd="cf curl /v2/apps/${app_id}/stats | jq .[].state | tr -d '\"'"
        app_instance_state_cmd="cf curl /v2/apps/${app_id}/stats | jq -r 'keys[] as \$k | [\$k,(.[\$k].state)] | @csv' | tr -d '\"'"
        echo $app_instance_state_cmd
        let 'ai_count = 0'
        for y in $(eval ${app_instance_state_cmd}); do
                (( ai_count++ ))
        done
        let 'healthy_count = 0'

        for x in $(eval ${app_instance_state_cmd}); do
            app_instance_id=$(echo $x | awk -F "," '{print$1}')
            app_instance_state=$(echo $x | awk -F "," '{print$2}')
            if [[ ${app_instance_state} == "RUNNING" ]]; then
              echo ${app_id}":instance[${app_instance_id}]-state:"${app_instance_state}
              (( healthy_count++ ))
            else
              echo ${app_id}":instance[${app_instance_id}]-state:"${app_instance_state}
              echo "Not Healthy Yet...."
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

fn_check_app_health ${1}
