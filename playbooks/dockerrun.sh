#!/bin/bash
source /Users/dporter/projects/sapa/benchmark_scripts/utils/utils.sh

solo_party cloud_configure.yml --tags general,pip_installs --extra-vars "@sapa_vars.yml"
solo_party elastic_configure_2.yml --tags setup --extra-vars @sapa_vars.yml
solo_party elastic_configure_2.yml --tags start --extra-vars @sapa_vars.yml
solo_party elastic_configure_2.yml --tags load_json,docker --extra-vars @sapa_vars.yml
solo_party elastic_configure_2.yml --tags run_script --extra-vars @sapa_vars.yml