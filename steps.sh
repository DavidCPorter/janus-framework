#!/bin/bash
source /Users/dporter/projects/solrcloud/utils/utils.sh
#play cloud_configure.yml --tags never
play zoo_configure.yml
play solr_configure_all.yml --tags setup
play solr_bench.yml --tags solrj
