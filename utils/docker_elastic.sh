#!/bin/bash
source $SAPA_HOME/benchmark_scripts/utils/utils.sh

#solo_party cloud_configure.yml --tags general,pip_installs --extra-vars "@example_variables.yml"
solo_party elastic_configure_2.yml --tags setup --extra-vars @example_variables.yml
solo_party elastic_configure_2.yml --tags start --extra-vars @example_variables.yml
solo_party elastic_configure_2.yml --tags load_json,docker --extra-vars @example_variables.yml
solo_party elastic_configure_2.yml --tags run_script --extra-vars @example_variables.yml