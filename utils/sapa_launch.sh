#!/bin/bash
source $SAPA_HOME/benchmark_scripts/utils/utils.sh
#play cloud_configure.yml --tags general,pip_installs,utils --extra-vars @ui_sapa_vars.yml
#play zoo_configure.yml --extra-vars @ui_sapa_vars.yml
play solr_configure_$1.yml --tags setup --extra-vars @ui_sapa_vars.yml
play solr_configure_$1.yml --tags solr_start --extra-vars @ui_sapa_vars.yml
#play solr_configure_chroot.yml --extra-vars @ui_sapa_vars.yml
play solr_configure_$1.yml --tags load_json,docker --extra-vars @ui_sapa_vars.yml

play elastic_configure_$1.yml --tags setup --extra-vars @ui_sapa_vars.yml
play elastic_configure_$1.yml --tags start --extra-vars @ui_sapa_vars.yml
play elastic_configure_$1.yml --tags load_json,docker --extra-vars @ui_sapa_vars.yml
#play elastic_configure_$1.yml --tags run_script --extra-vars @ui_sapa_vars.yml
