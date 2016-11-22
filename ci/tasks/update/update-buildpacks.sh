#!/bin/bash
set -e

# install cf cli
sudo wget -O /tmp/cfcli.deb "https://cli.run.pivotal.io/stable?release=debian64&version=6.22.2&source=github-rel"  > /dev/null 2>&1
sudo dpkg -i /tmp/cfcli.deb && apt-get install -f  > /dev/null 2>&1

###############################
# Functions   #################
###############################
function fn_auth_cli {

  cf api ${sandbox_cf_api} --skip-ssl-validation > /dev/null 2>&1
  cf login -u ${sandbox_cf_user} -p ${sandbox_cf_password} -o system -s system > /dev/null 2>&1

}

function fn_get_buildpack_id {

   local buildpack=${1}

   my_cmd="cf curl /v2/buildpacks | jq '.resources[] | select(.entity.name==\"${buildpack}\") | .' | jq .metadata.guid | tr -d '\"'"
   eval $my_cmd

}

function fn_get_pivent_buildpack {

  echo "Getting ${buildpack} version:${bp_version} from pivnet"

  local PIVNET_EULA_URL=$(echo ${1} | sed 's/\/product_files//g')
  local PIVNET_DOWNLOAD_URL=${2}
  local BP_VERSION=${3}
  local PIVNET_TOKEN=${pivnet_api_token}


  curl -H "Authorization: Token ${PIVNET_TOKEN}" \
  -X POST ${PIVNET_EULA_URL}/eula_acceptance

  wget -O ./${buildpack}-v${BP_VERSION}.zip --post-data="" \
  --header="Authorization: Token ${PIVNET_TOKEN}" \
  ${PIVNET_DOWNLOAD_URL}

}

function fn_update_buildpack {



  bp_release_string=$(echo $(ls -d *buildpack-release*) | sed 's/-release//g')
  bp_version=$(cat $(ls -d *buildpack-release*)/version)
  bp_id=$(fn_get_buildpack_id ${buildpack})
  bp_position=$(cf curl /v2/buildpacks/${bp_id} | jq .entity.position | tr -d '\"')

  pivnet_q_cmd="curl -s https://network.pivotal.io/api/v2/products/buildpacks/releases | jq .releases[] | jq '. | select(contains({release_notes_url: \"${bp_release_string}\"})) | select(contains({release_notes_url: \"${bp_version}\"})) | ._links.product_files.href'"

  for pivent_api_response in $(eval ${pivnet_q_cmd}); do
      pivnet_prod_files=$(echo $pivent_api_response | tr -d '"')
      echo $pivnet_prod_files
  done

  pivnet_download_url_cmd="curl -s ${pivnet_prod_files} | jq .product_files[] | jq '. | select(contains({aws_object_key: \"$(echo ${buildpack} | tr "_" "-")\"})) | ._links.download.href'"
  pivnet_download_url=$(eval ${pivnet_download_url_cmd} | tr -d '"')

  if [[ $pivnet_download_url != *"network.pivotal.io/api/v2/products/buildpacks/releases"* ]]; then
    echo "Couldnt find buildpack with string $(echo ${buildpack} | tr "_" "-"), will attempt ${buildpack} ..."
    pivnet_download_url_cmd="curl -s ${pivnet_prod_files} | jq .product_files[] | jq '. | select(contains({aws_object_key: \"$(echo ${buildpack})\"})) | ._links.download.href'"
    pivnet_download_url=$(eval ${pivnet_download_url_cmd} | tr -d '"')
  fi

  if [[ $pivnet_download_url == "" ]]; then
    echo "Cant find URL to download buildpack fro pivnet API!!!!!"
    exit 1
  fi

  fn_get_pivent_buildpack "${pivnet_prod_files}" "${pivnet_download_url}" "${bp_version}"

    if [[ $(cf buildpacks | grep "${buildpack}_venerable" | wc -l) -gt 0 ]]; then
      cf delete-buildpack "${buildpack}_venerable" -f
    fi

  set +e
  cf rename-buildpack ${buildpack} "${buildpack}_venerable" || echo "Buildpack Missing ... will skip rename and insert at highest avail order"
  cf update-buildpack "${buildpack}_venerable" --disable || echo "..."
  set -e

  if [[ ${bp_position} == "" ]]; then
    let "bp_position=$(cf buildpacks | grep zip | awk '{print$2}' | sort | tail -1) + 1"
  fi

  cf create-buildpack ${buildpack} ${buildpack}-v${bp_version}.zip ${bp_position} --enable


}

function fn_trigger {

  declare -a apps
  echo "Will Blue-Green deploy a new buildpack for ... ${buildpack}"
  fn_auth_cli
  buildpack_id=$(fn_get_buildpack_id "${buildpack}")
  fn_update_buildpack

  run_id=$(cat pipeline-run-id/version)
  echo "${buildpack}" > run-info/buildpack-${run_id}.id

}


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
