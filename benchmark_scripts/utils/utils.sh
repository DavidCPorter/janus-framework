#!/bin/bash
export SAPA_HOME=/Users/dporter/projects/sapa
CL_USER=dporte7
CHECKSOLRARGS='ps aux | grep solr'
CHECKPORTSARGS='lsof -i | grep LISTEN'
KILLARGS="ps aux | grep -i solrclientserver | awk -F' ' '{print \$2}' | xargs kill -9"
CHECKARGS='ps aux | grep -i solrclientserver'
alias utilsview="cat $SAPA_HOME/utils/utils.sh"
alias grepmal="cd $SAPA_HOME/; pssh -l $CL_USER -h ssh_files/pssh_solr_node_file -P 'ps aux | grep kdevtmpfsi > tmpout.txt;head -n 1 tmpout.txt'"
alias whatsgood="cd $SAPA_HOME/benchmark_scripts/profiling_data/exp_results; ls -t; cat * */*;cd $SAPA_HOME"
alias mechart="python3 $SAPA_HOME/chart/chartit_error_bars.py"
alias killallbyname="cd /Users/dporter/projects/solrcloud;pssh -i -h ssh_files/pssh_all -l dporte7 -P sudo pkill -f"
alias fullog="cd $SAPA_HOME/; pssh -l $CL_USER -h ssh_files/pssh_solr_node_file -P 'tail -n 100 /var/solr/logs/solr.log | grep ERROR'"
alias grepnodeprocs="cd $SAPA_HOME/; pssh -l $CL_USER -h ssh_files/pssh_solr_node_file -P 'ps aux | grep'"
alias callingnodes="cd $SAPA_HOME/; pssh -l $CL_USER -h ssh_files/pssh_all -P"
alias wipetraffic="cd $SAPA_HOME;pssh -l $CL_USER -h ssh_files/pssh_traffic_node_file 'echo hey >traffic_gen/traffic_gen.log'"
alias viewtraffic="cd $SAPA_HOME;pssh -l $CL_USER -h ssh_files/pssh_traffic_node_file -P 'tail -n 2000 traffic_gen/traffic_gen.log'"
alias viewsolrj="cd $SAPA_HOME;pssh -l $CL_USER -h ssh_files/pssh_traffic_node_file -P 'tail -n 2000 solrclientserver/solrjoutput.txt'"
alias play="cd $SAPA_HOME/playbooks; ansible-playbook -i ../inventory"
alias solo_party="cd $SAPA_HOME/playbooks; ansible-playbook -i ../inventory_local"
alias killsolrj='cd $SAPA_HOME;pssh -i -h ssh_files/pssh_traffic_node_file -l $CL_USER $KILLARGS'
alias clearout="cd $SAPA_HOME/benchmark_scripts; echo ''> nohup.out"
alias viewout="cd $SAPA_HOME/benchmark_scripts; tail -n 1000 nohup.out"
alias checksolrj="cd $SAPA_HOME;pssh -i -h ssh_files/pssh_traffic_node_file -l $CL_USER $CHECKARGS"
alias checksolr="cd $SAPA_HOME;pssh -i -h ssh_files/pssh_solr_node_file -l $CL_USER $CHECKSOLRARGS"
alias checkports="cd $SAPA_HOME;pssh -i -h ssh_files/solr_single_node -l $CL_USER $CHECKPORTSARGS"
alias checkcpu="cd $SAPA_HOME/; pssh -l $CL_USER -h ssh_files/pssh_all -P 'top -bn1 > cpu.txt;head -10 cpu.txt | grep dporte7'"
# alias delete_collections="python3 $SAPA_HOME/utils/delete_collection.py"
alias singlelogs="cd $SAPA_HOME/; pssh -l $CL_USER -h ssh_files/solr_single_node -P 'tail -n 1000 /var/solr/logs/solr.log'"

# alias archive_fcts="cd $SAPA_HOME/benchmark_scripts;cp -rf *.zip ~/exp_results_fct_zips/$(date '+%Y-%m-%d_%H:%M');rm -rf *.zip"
alias singletest="cd $SAPA_HOME/benchmark_scripts; bash exp_scale_loop_single.sh"
alias fulltest="cd $SAPA_HOME/benchmark_scripts; bash exp_scale_loop.sh"
alias dockertest="cd $SAPA_HOME/benchmark_scripts; bash exp_scale_loop_docker.sh"
alias listcores="cd $SAPA_HOME/; pssh -l $CL_USER -i -h ssh_files/pssh_solr_node_file 'ls /users/$CL_USER/solr-8_3/solr/server/solr'"
alias deldown="cd $SAPA_HOME/; pssh -l $CL_USER -i -h ssh_files/solr_single_node 'bash ~/solr-8_3/solr/bin/solr delete -c'"
alias checkdisk="cd $SAPA_HOME/; pssh -h ssh_files/pssh_solr_node_file -l $CL_USER -P 'df | grep /dev/nvme0n1p1'"

alias checkconfig="cd $SAPA_HOME/; pssh -l $CL_USER -i -h ssh_files/solr_single_node 'cat ~/solr-8_3/solr/server/solr/configsets/_default/conf/solrconfig.xml'"
alias collectionconfig="curl http://128.110.153.162:8983/solr/reviews_rf4_s1_clustersize94/config"
alias collectionconfigfull="curl http://128.110.153.162:8983/solr/reviews_rf32_s1_clustersize16/config"
alias daparams="vim $SAPA_HOME/benchmark_scripts/utils/exp_scale_loop_params.sh"
alias davars="vim $SAPA_HOME/playbooks/sapa_vars.yml"

export CORE_HOME=/users/dporte7/solr-8_3/solr/server/solr

export node0='sapa0'
export node1='sapa1'
export node2='sapa2'
export node3='sapa3'
# # cannot export ARRAYS in bash : ) so we do this instead
export ALL_NODES=" $node0 $node1 $node2 $node3 "
export ALL_SOLR=" $node0 $node1 $node2 "
export ALL_LOAD=" $node3 "

alias ssher="ssh -l $CL_USER"
source $SAPA_HOME/benchmark_scripts/utils/exp_helpers.sh
shopt -s expand_aliases

