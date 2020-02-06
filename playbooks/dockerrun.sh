#!/bin/bash
source /Users/dporter/projects/sapa/benchmark_scripts/utils/utils.sh

play_solo cloud_configure.yml --tags general,pip_installs --extra-vars "@sapa_vars.yml"
play_solo elastic_configure_2.yml --tags setup --extra-vars @sapa_vars.yml
play_solo elastic_configure_2.yml --tags start --extra-vars @sapa_vars.yml
play_solo elastic_configure_2.yml --tags load_json --extra-vars @sapa_vars.yml
play_solo elastic_configure_2.yml --tags run_script --extra-vars @sapa_vars.yml