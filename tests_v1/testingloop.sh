#!/bin/bash

# python3 /Users/dporter/projects/solrcloud/delete_collection.py
sleep 5
source /Users/dporter/projects/solrcloud/utils.sh

shopt -s expand_aliases

# play zoo_configure.yml --tags zoo_stop
# play solr_configure.yml --tags solr_stop

#
cd /Users/dporter/projects/solrcloud/tests_v1;cp -rf profiling_data/exp_results ~/exp_results/$(date '+%Y-%m-%d_%H:%M');rm -rf profiling_data/exp_results/*

cd /Users/dporter/projects/solrcloud/tests_v1;cp -rf *.zip ~/exp_results/$(date '+%Y-%m-%d_%H:%M');rm -rf *.zip




for j in `seq 3 5`; do
  # killsolrj
  # wait $1
  # sleep 2
  # play zoo_configure.yml --tags zoo_start
  # wait $!
  # sleep 5
  # play solr_configure_$((2**$j)).yml --tags solr_start
  # wait $!
  # sleep 5
  # runsolrj
  # sleep 5

  # for i in `seq 1 5 30`; do
  #   cd ~/projects/solrcloud/tests_v1; bash runtest.sh traffic_gen words.txt --user dporte7 -rf 4 -s 16 -t ${i} -d 10 -p $((2**$j)) --solrnum $((2**$j)) --query direct --loop open
  #   wait $!
  #   cd ~/projects/solrcloud;pssh -l dporte7 -h ssh_files/pssh_traffic_node_file "echo ''>traffic_gen/traffic_gen.log"
  #   sleep 2
  # done
  # cd ~/projects/solrcloud;pssh -l dporte7 -h ssh_files/pssh_traffic_node_file "echo ''>/users/dporte7/solrclientserver/solrjoutput.txt"
  #
  # sleep 8

  for i in `seq 1 5 30`; do
    cd ~/projects/solrcloud/tests_v1; bash runtest.sh traffic_gen words.txt --user dporte7 -rf 4 -s 16 -t ${i} -d 10 -p $((2**$j)) --solrnum $((2**$j)) --query solrj --loop open
    wait $!
    # cd ~/projects/solrcloud;pssh -l dporte7 -h ssh_files/pssh_traffic_node_file "echo ''>traffic_gen/traffic_gen.log"
    sleep 2
  done
  sleep 100
  # cd ~/projects/solrcloud;pssh -l dporte7 -h ssh_files/pssh_traffic_node_file "echo ''>/users/dporte7/solrclientserver/solrjoutput.txt"


  # for i in `seq 1 5 30`; do
  #   cd ~/projects/solrcloud/tests_v1; bash runtest.sh traffic_gen words.txt --user dporte7 -rf 2 -s 16 -t ${i} -d 10 -p $((2**$j)) --solrnum $((2**$j)) --query direct --loop open
  #   wait $!
  #   cd ~/projects/solrcloud;pssh -l dporte7 -h ssh_files/pssh_traffic_node_file "echo ''>traffic_gen/traffic_gen.log"
  #   sleep 2
  # done
  # sleep 8
  # cd ~/projects/solrcloud;pssh -l dporte7 -h ssh_files/pssh_traffic_node_file "echo ''>/users/dporte7/solrclientserver/solrjoutput.txt"


  # for i in `seq 1 5 30`; do
  #   cd ~/projects/solrcloud/tests_v1; bash runtest.sh traffic_gen words.txt --user dporte7 -rf 2 -s 16 -t ${i} -d 10 -p $((2**$j)) --solrnum $((2**$j)) --query solrj --loop open
  #   wait $!
  #   cd ~/projects/solrcloud;pssh -l dporte7 -h ssh_files/pssh_traffic_node_file "echo ''>traffic_gen/traffic_gen.log"
  #   sleep 2
  # done
  # # cd ~/projects/solrcloud;pssh -l dporte7 -h ssh_files/pssh_traffic_node_file "echo ''>/users/dporte7/solrclientserver/solrjoutput.txt"
  #
  # python3 /Users/dporter/projects/solrcloud/delete_collection.py
  # wait $!
  # sleep 8



  # for i in `seq 1 5 30`; do
  #   cd ~/projects/solrcloud/tests_v1; bash runtest.sh traffic_gen words.txt --user dporte7 -rf $((2**$j)) -s 1 -t ${i} -d 10 -p $((2**$j)) --solrnum $((2**$j)) --query direct --loop open
  #   wait $!
  #   cd ~/projects/solrcloud;pssh -l dporte7 -h ssh_files/pssh_traffic_node_file "echo ''>traffic_gen/traffic_gen.log"
  #   sleep 2
  # done
  # sleep 8
  # cd ~/projects/solrcloud;pssh -l dporte7 -h ssh_files/pssh_traffic_node_file "echo ''>/users/dporte7/solrclientserver/solrjoutput.txt"

  # for i in `seq 1 5 30`; do
  #   cd ~/projects/solrcloud/tests_v1; bash runtest.sh traffic_gen words.txt --user dporte7 -rf $((2**$j)) -s 1 -t ${i} -d 10 -p $((2**$j)) --solrnum $((2**$j)) --query solrj --loop open
  #   wait $!
  #   cd ~/projects/solrcloud;pssh -l dporte7 -h ssh_files/pssh_traffic_node_file "echo ''>traffic_gen/traffic_gen.log"
  #   sleep 2
  # done
  # sleep 8
  # # cd ~/projects/solrcloud;pssh -l dporte7 -h ssh_files/pssh_traffic_node_file "echo ''>/users/dporte7/solrclientserver/solrjoutput.txt"
  #
  # python3 /Users/dporter/projects/solrcloud/delete_collection.py
  # wait $!
  # sleep 8

  # for i in `seq 1 5 30`; do
  #   cd ~/projects/solrcloud/tests_v1; bash runtest.sh traffic_gen words.txt --user dporte7 -rf $((2**($j-1))) -s 2 -t ${i} -d 10 -p $((2**$j)) --solrnum $((2**$j)) --query direct --loop open
  #   wait $!
  #   cd ~/projects/solrcloud;pssh -l dporte7 -h ssh_files/pssh_traffic_node_file "echo ''>traffic_gen/traffic_gen.log"
  #   sleep 2
  # done
  # sleep 8
  # cd ~/projects/solrcloud;pssh -l dporte7 -h ssh_files/pssh_traffic_node_file "echo ''>/users/dporte7/solrclientserver/solrjoutput.txt"


  # for i in `seq 1 5 30`; do
  #   cd ~/projects/solrcloud/tests_v1; bash runtest.sh traffic_gen words.txt --user dporte7 -rf $((2**($j-1))) -s 2 -t ${i} -d 10 -p $((2**$j)) --solrnum $((2**$j)) --query solrj --loop open
  #   wait $!
  #   cd ~/projects/solrcloud;pssh -l dporte7 -h ssh_files/pssh_traffic_node_file "echo ''>traffic_gen/traffic_gen.log"
  #   sleep 2
  # done
  # # cd ~/projects/solrcloud;pssh -l dporte7 -h ssh_files/pssh_traffic_node_file "echo ''>/users/dporte7/solrclientserver/solrjoutput.txt"
  #
  #
  #
  # python3 /Users/dporter/projects/solrcloud/delete_collection.py
  # wait $!
  # sleep 10
  # play solr_configure_$((2**$j)).yml --tags solr_stop
  # wait $!
  # sleep 5
  # play zoo_configure.yml --tags zoo_stop
  # wait $!
  # sleep 5


done
