#!/bin/bash
source ${SAPA_HOME}/benchmark_scripts/utils/utils.sh
# solo_party cloud_configure.yml --tags never
# solo_party zoo_configure.yml
# solo_party solr_configure_chroot.yml --tags setup
# solo_party solr_bench.yml --tags solrj

solo_party elastic_configure_2.yml --skip-tags main --tags load_json
solo_party elastic_configure_2.yml --tags setup
solo_party elastic_configure_2.yml --tags start
