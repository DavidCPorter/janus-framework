#!/bin/bash
PROJ_HOME=/Users/dporter/projects/sapa
CL_USER=dporte7
CHECKSOLRARGS='ps aux | grep solr'
CHECKPORTSARGS='lsof -i | grep LISTEN'
KILLARGS="ps aux | grep -i solrclientserver | awk -F' ' '{print \$2}' | xargs kill -9"
CHECKARGS='ps aux | grep -i solrclientserver'
alias utilsview="cat $PROJ_HOME/utils/utils.sh"
alias grepmal="cd $PROJ_HOME/; pssh -l $CL_USER -h ssh_files/pssh_solr_node_file -P 'ps aux | grep kdevtmpfsi > tmpout.txt;head -n 1 tmpout.txt'"
alias whatsgood="cd $PROJ_HOME/tests_v1/profiling_data/exp_results; ls -t; cat * */*;cd $PROJ_HOME"
alias mechart="python3 $PROJ_HOME/chart/chartit_error_bars.py"
alias killallbyname="cd /Users/dporter/projects/solrcloud;pssh -i -h ssh_files/pssh_all -l dporte7 -P sudo pkill -f"
alias fullog="cd $PROJ_HOME/; pssh -l $CL_USER -h ssh_files/pssh_solr_node_file -P 'tail -n 100 /var/solr/logs/solr.log | grep ERROR'"
alias grepnodeprocs="cd $PROJ_HOME/; pssh -l $CL_USER -h ssh_files/pssh_solr_node_file -P 'ps aux | grep'"
alias callingnodes="cd $PROJ_HOME/; pssh -l $CL_USER -h ssh_files/pssh_all -P"
alias wipetraffic="cd $PROJ_HOME;pssh -l $CL_USER -h ssh_files/pssh_traffic_node_file 'echo hey >traffic_gen/traffic_gen.log'"
alias viewtraffic="cd $PROJ_HOME;pssh -l $CL_USER -h ssh_files/pssh_traffic_node_file -P 'tail -n 2000 traffic_gen/traffic_gen.log'"
alias viewsolrj="cd $PROJ_HOME;pssh -l $CL_USER -h ssh_files/pssh_traffic_node_file -P 'tail -n 2000 solrclientserver/solrjoutput.txt'"
alias play="cd $PROJ_HOME/playbooks; ansible-playbook -i ../inventory"
alias play_solo="cd $PROJ_HOME/playbooks; ansible-playbook -i ../inventory_local"
alias killsolrj='cd $PROJ_HOME;pssh -i -h ssh_files/pssh_traffic_node_file -l $CL_USER $KILLARGS'
alias clearout="cd $PROJ_HOME/tests_v1; echo ''> nohup.out"
alias viewout="cd $PROJ_HOME/tests_v1; tail -n 1000 nohup.out"
alias checksolrj="cd $PROJ_HOME;pssh -i -h ssh_files/pssh_traffic_node_file -l $CL_USER $CHECKARGS"
alias checksolr="cd $PROJ_HOME;pssh -i -h ssh_files/pssh_solr_node_file -l $CL_USER $CHECKSOLRARGS"
alias checkports="cd $PROJ_HOME;pssh -i -h ssh_files/solr_single_node -l $CL_USER $CHECKPORTSARGS"
alias checkcpu="cd $PROJ_HOME/; pssh -l $CL_USER -h ssh_files/pssh_all -P 'top -bn1 > cpu.txt;head -10 cpu.txt | grep dporte7'"
# alias delete_collections="python3 $PROJ_HOME/utils/delete_collection.py"
alias singlelogs="cd $PROJ_HOME/; pssh -l $CL_USER -h ssh_files/solr_single_node -P 'tail -n 1000 /var/solr/logs/solr.log'"

# alias archive_fcts="cd $PROJ_HOME/benchmark_scripts;cp -rf *.zip ~/exp_results_fct_zips/$(date '+%Y-%m-%d_%H:%M');rm -rf *.zip"
alias singletest="cd $PROJ_HOME/tests_v1; bash exp_scale_loop_single.sh"
alias fulltest="cd $PROJ_HOME/tests_v1; bash exp_scale_loop.sh"
alias listcores="cd $PROJ_HOME/; pssh -l $CL_USER -i -h ssh_files/pssh_solr_node_file 'ls /users/$CL_USER/solr-8_3/solr/server/solr'"
alias deldown="cd $PROJ_HOME/; pssh -l $CL_USER -i -h ssh_files/solr_single_node 'bash ~/solr-8_3/solr/bin/solr delete -c'"
alias checkdisk="cd $PROJ_HOME/; pssh -h ssh_files/pssh_solr_node_file -l $CL_USER -P 'df | grep /dev/nvme0n1p1'"

alias checkconfig="cd $PROJ_HOME/; pssh -l $CL_USER -i -h ssh_files/solr_single_node 'cat ~/solr-8_3/solr/server/solr/configsets/_default/conf/solrconfig.xml'"
alias collectionconfig="curl http://128.110.153.162:8983/solr/reviews_rf4_s1_clustersize94/config"
alias collectionconfigfull="curl http://128.110.153.162:8983/solr/reviews_rf32_s1_clustersize16/config"
alias daparams="vim $PROJ_HOME/utils/exp_scale_loop_params.sh"

export CORE_HOME=/users/dporte7/solr-8_3/solr/server/solr

export node0='128.110.153.77'
export node1='128.110.153.87'
export node2='128.110.153.78'
export node3='128.110.153.76'
export node4='128.110.153.90'
export node5='128.110.153.82'
export node6='128.110.153.71'
export node7='128.110.153.106'
export node8='128.110.153.80'
export node9='128.110.153.66'
export node10='128.110.153.103'
export node11='128.110.153.84'
export node12='128.110.153.83'
export node13='128.110.153.108'
export node14='128.110.153.95'
export node15='128.110.153.73'

# cannot export ARRAYS in bash : ) so we do this instead
export ALL_NODES=" $node0 $node1 $node2 $node3 $node4 $node5 $node6 $node7 $node8 $node9 $node10 $node11 $node12 $node13 $node14 $node15 "

export ALL_SOLR=" $node0 $node1 $node2 $node3 $node4 $node5 $node6 $node7 "
export ALL_LOAD=" $node8 $node9 $node10 $node11 $node12 $node13 $node14 $node15 "

alias ssher="ssh -l $CL_USER"
shopt -s expand_aliases

wipecores () {
  pssh -h $PROJ_HOME/ssh_files/pssh_solr_node_file -l $CL_USER rm -rf $CORE_HOME/reviews*
}

wipecores_backup () {
  for i in $ALL_SOLR; do
    ssh $CL_USER@$i rm -rf $CORE_HOME/reviews*
  done
}

EXP_HOME=$PROJ_HOME/chart/exp_records
# just deal with it... find and replace snafu. they are the same
export PROJECT_HOME=/Users/dporter/projects/sapa

runsolrj (){
  pssh -h $PROJ_HOME/ssh_files/pssh_traffic_node_file -l $CL_USER "cd solrclientserver;java -cp target/solrclientserver-1.0-SNAPSHOT.jar com.dporte7.solrclientserver.DistributedWebServer $1  > javaServer.log 2>&1 &"&
}

archivePrev (){
  reps=$4
  shards=$5
  cd $PROJ_HOME/benchmark_scripts
  mkdir $EXP_HOME/$1
  cp -rf tmp/tmp/* $EXP_HOME/$1
  rm -rf tmp/tmp/*
  mkdir -p $EXP_HOME/$1/FCTS/$2/$3/r$reps:s$shards
  cp -rf 2020* $EXP_HOME/$1/FCTS/$2/$3/r$reps:s$shards
  rm -rf 2020*
}

stopsingle (){
  for i in `seq 3`;do
    printf "\n STOPPING SOLR INSTANCES:"
    echo "node__$i/solr -p 99$i$i"
    pssh -h $PROJ_HOME/ssh_files/solr_single_node -l $CL_USER -P "bash ~/solr-8_3/solr/bin/solr stop -cloud -q -s ~/node__$i/solr -p 99$i$i -Dhost=10.10.1.1"
  done
}


wipeInstances (){

  stopsingle

  sleep 8
  echo "removing old node_ dirs on server1"
  pssh -h $PROJ_HOME/ssh_files/solr_single_node -l $CL_USER -P "rm -rf ~/node_*"
  sleep 2
}


stopSolr () {
  printf "\n\n"
  echo "stopping solr "
  printf "\n\n"

  play solr_configure_$1.yml --tags solr_stop
  # sleep 5
  if [ $1 -eq 1 ];then
	stopsingle
  fi


  #   wipeInstances
  # else
  #   wipecores
  # fi
  # play zoo_configure.yml --tags zoo_stop
  # wait $!
  # sleep 3

}

resetState () {
  stopSolr $1
  wipecores
  play zoo_configure.yml --tags zoo_stop
  play zoo_configure.yml --tags zoo_start
}

startSolr () {
  printf "\n\n"
  echo "starting zookeeper and solr "
  printf "\n\n"
  play solr_configure_$1.yml --tags solr_start
  sleep 3
}

startElastic () {
  printf "\n\n"
  echo "starting elastic "
  printf "\n\n"
  play elastic_configure_$1.yml --tags start
}

#to kill malware
#pssh -l dporte7 -h ssh_files/pssh_solr_node_file -P sudo rm -rf /tmp/.ICEd* /tmp/kdevtmpfsi;pssh -l dporte7 -h ssh_files/pssh_solr_node_file -P sudo pkill -f .ICEd;pssh -l dporte7 -h ssh_files/pssh_solr_node_file -P sudo pkill -f kdevtmpfsi
