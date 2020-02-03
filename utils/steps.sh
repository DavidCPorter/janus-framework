#!/bin/bash
source /Users/dporter/projects/sapa/utils/utils.sh
# play cloud_configure.yml --tags never
# play zoo_configure.yml
# play solr_configure_all.yml --tags setup
# play solr_bench.yml --tags solrj

play elastic_configure_2.yml --skip-tags main --tags load_json
play elastic_configure_2.yml --tags setup
play elastic_configure_2.yml --tags start
