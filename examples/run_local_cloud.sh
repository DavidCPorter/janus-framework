#!/bin/bash

# this example case runs a docker cloud locally, then performms a performance analysis of elastic search with a cloud of 2 elastic servers and a single workoad server.
# new users still need to make some changes to the ssh files /sapa/utils/ssh_files. You can run the ssh scrupt to generate. will elaborate later

#also users need to make sure  they add hostnames to their .ssh/configs file and put their id_rsa.pub file in the docker servers.

docker-compose --compatibility build
docker-compose --compatibility up -d

solo_party cloud_configure.yml --tags general,pip_installs --extra-vars @sapa_vars.yml
solo_party elastic_configure_2.yml --tags setup --extra-vars @sapa_vars.yml
solo_party elastic_configure_2.yml --tags start --extra-vars @sapa_vars.yml 
solo_party elastic_configure_2.yml --tags load_json --extra-vars @sapa_vars.yml
solo_party elastic_configure_2.yml --tags run_script --extra-vars @sapa_vars.yml

source /Users/dporter/projects/sapa/benchmark_scripts/utils/exp_scale_loop_params.sh
source /Users/dporter/projects/sapa/benchmark_scripts/utils/utils.sh
source /Users/dporter/projects/sapa/benchmark_scripts/utils/exp_helpers.sh

cd $PROJ_HOME/benchmark_scripts; bash exp_scale_loop_docker.sh
