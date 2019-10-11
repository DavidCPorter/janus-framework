#!/bin/bash
shopt -s expand_aliases
source /Users/dporter/projects/solrcloud/utils.sh


play solr_bench.yml --tags local
