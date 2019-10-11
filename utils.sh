#!/bin/bash
alias wipetraffic='cd ~/projects/solrcloud;pssh -l dporte7 -h ssh_files/pssh_traffic_node_file "echo ''>traffic_gen/traffic_gen.log"'
alias viewtraffic='cd ~/projects/solrcloud;pssh -l dporte7 -h ssh_files/pssh_traffic_node_file -P "tail -n 2000 traffic_gen/traffic_gen.log"'
alias viewsolrj='cd ~/projects/solrcloud;pssh -l dporte7 -h ssh_files/pssh_traffic_node_file -P "tail -n 2000 solrclientserver/solrjoutput.txt"'
alias search='cd ~/projects/solrcloud;pssh -l dporte7 -h ssh_files/pssh_zoo_node_file -P "tail -n 500 /var/solr/logs/solr.log"'
alias test='cd ~/projects/solrcloud/tests_v1; bash testingloop.sh'
alias play='cd ~/projects/solrcloud; ansible-playbook -i inventory'
alias closedloop='cd ~/projects/solrcloud/tests_v1; bash runtest.sh traffic_gen words.txt -t 1 -p 1 -c 1 -d 20 --query solrj --loop closed --user dporte7'
alias testlocal='cd ~/projects/solrcloud/tests_v1; bash runtest.sh traffic_gen words.txt --user dporte7'
alias runit='test -t 2 -p 32 -c 1 -d 20 --query direct --loop open'
alias runsolrj='cd ~/projects/solrcloud;nohup pssh -P -i -h ssh_files/pssh_traffic_node_file -l dporte7 "cd solrclientserver;java -cp target/solrclientserver-1.0-SNAPSHOT.jar com.dporte7.solrclientserver.DistributedWebServer > solrjoutput.txt" &'
alias killsolrj='cd ~/projects/solrcloud;pssh -i -h ssh_files/pssh_traffic_node_file -l dporte7 $KILLARGS'
export KILLARGS="ps aux | grep -i solrclientserver | awk -F' ' '{print \$2}' | xargs kill -9"
alias clearout="cd ~/projects/solrcloud/tests_v1; echo ''> nohup.out"
alias viewout="cd ~/projects/solrcloud/tests_v1; tail -n 1000 nohup.out"
alias checksolrj='cd ~/projects/solrcloud;pssh -P -i -h ssh_files/pssh_traffic_node_file -l dporte7 $CHECKARGS'
export CHECKARGS="ps aux | grep -i solrclientserver"
alias prime="cd /Users/dporter/projects/solrcloud/tests_v1;cp -rf profiling_data/exp_results ~/exp_results/$(date '+%Y-%m-%d_%H:%M');rm -rf profiling_data/exp_results/*;cd /Users/dporter/projects/solrcloud/tests_v1;cp -rf *.zip ~/exp_results/$(date '+%Y-%m-%d_%H:%M');rm -rf *.zip"
