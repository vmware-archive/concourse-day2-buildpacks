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

function fn_update_buildpack {

  bp_version=$(cat $(ls -d *buildpack-release*)/version)
  bp_id=$(fn_get_buildpack_id ${buildpack})
  bp_position=$(cf curl /v2/buildpacks/${bp_id} | jq .entity.position | tr -d '\"')
  bp_fname=$(cf curl /v2/buildpacks/${bp_id} | jq .entity.filename | tr -d '\"')

  cp_cmd="cp $(ls -d *buildpack-release*)/release.tgz ./${buildpack}-${bp_version}.zip"
  (eval $cp_cmd)

  exit 1

}

function fn_trigger {

  declare -a apps
  echo "Will work on ... ${buildpack}"
  fn_auth_cli
  buildpack_id=$(fn_get_buildpack_id "${buildpack}")

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
