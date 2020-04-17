#!/bin/bash
source $SAPA_HOME/benchmark_scripts/utils/utils.sh
#play cloud_configure.yml --tags general,pip_installs,utils --extra-vars @example_variables.yml
#play zoo_configure.yml --extra-vars @example_variables.yml
play solr_configure_$1.yml --tags setup --extra-vars @example_variables.yml
play solr_configure_$1.yml --tags solr_start --extra-vars @example_variables.yml
#play solr_configure_chroot.yml --extra-vars @example_variables.yml
play solr_configure_$1.yml --tags load_json,docker --extra-vars @example_variables.yml

play elastic_configure_$1.yml --tags setup --extra-vars @example_variables.yml
play elastic_configure_$1.yml --tags start --extra-vars @example_variables.yml
play elastic_configure_$1.yml --tags load_json,docker --extra-vars @example_variables.yml
#play elastic_configure_$1.yml --tags run_script --extra-vars @example_variables.yml
