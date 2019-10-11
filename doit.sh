#!/bin/bash

# python3 /Users/dporter/projects/solrcloud/delete_collection.py
sleep 5
source /Users/dporter/projects/solrcloud/utils.sh

shopt -s expand_aliases

# play zoo_configure.yml --tags zoo_stop
# play solr_configure.yml --tags solr_stop
# play zoo_configure.yml --tags zoo_start
# play solr_configure.yml --tags solr_start

#
cd /Users/dporter/projects/solrcloud/tests_v1;cp -rf profiling_data/exp_results ~/exp_results/$(date '+%Y-%m-%d_%H:%M');rm -rf profiling_data/exp_results/*

cd /Users/dporter/projects/solrcloud/tests_v1;cp -rf *.zip ~/exp_results/$(date '+%Y-%m-%d_%H:%M');rm -rf *.zip




cd ~/projects/solrcloud/tests_v1; bash runtest.sh traffic_gen words.txt --user dporte7 -rf 4 -s 16 -t 1 -d 10 -p 32 --solrnum 32 --query solrj --loop open
cd ~/projects/solrcloud;pssh -l dporte7 -h ssh_files/pssh_traffic_node_file "echo ''>traffic_gen/traffic_gen.log"
