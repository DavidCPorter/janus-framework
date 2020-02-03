#!/bin/bash

CLOUDHOME="/users/dporte7"
USER="dporte7"


function show_remote_scripts() {
  M_LOAD=$1
  ALL_LOAD_NODES=($(setLoadArray $M_LOAD))
  RSCRIPTS=$2
  easyreadcount=0
  for i in "${ALL_LOAD_NODES[@]}";do
    if [ "$easyreadcount" -eq 0 ];then
      echo "${i}::"
      cat $RSCRIPTS/${i}/remotescript.sh
      printf "\n"

    else
      echo "${i}::"
      # head -n 5 $RSCRIPTS/${i}/remotescript.sh
      cat $RSCRIPTS/${i}/remotescript.sh
      printf "......\n"
    fi

    ((easyreadcount+=1))

  done
}

function update_rscripts() {
  args=("$@")
# get number of elements
  ELEMENTS=${#args[@]}

  # echo each element in array
  # for loop
  for (( i=0;i<$ELEMENTS;i++)); do
      echo ${args[${i}]}
  done
  M_LOAD=$1
  ALL_LOAD_NODES=($(setLoadArray $M_LOAD))
  RSCRIPTS=$2
  procs=$3
  SOLR_SIZE=$4
  SOLRJ_PORT_OVERRIDE=$5
  SINGLE_PAR=$6
  PAR=$7
  INSTANCES_BOOL=$8
  STANDALONE=${9}
  THREADS=${10}
  USER=${11}
  printf "\n\n PARS = $PAR"

  printf "making dirs for copying remote scripts\n\n"
  for i in "${ALL_LOAD_NODES[@]}";do
    mkdir $RSCRIPTS/${i}
    touch $RSCRIPTS/${i}/remotescript.sh
    echo "#!/bin/bash" > $RSCRIPTS/${i}/remotescript.sh
  done

# single_instance_port_arr =  so we can load balance accross local cores
  single_instance_port_arr=( "8983" "9911" "9922" "9933" )

  ####### round robin the requested connections over all servers' remote scripts

  for ((i=1; i<=procs; i++)); do

    LUCKY_LOAD=${ALL_LOAD_NODES[$(($i % $M_LOAD))]}

    # if more than 1 node, then the nodes subsequent to the first always have the max three threads for optimal parallelism
    node_subnet_suffix=$(($(($i % $SOLR_SIZE))+1))

    # this port suffix thing is really just for solrj requests since solrj has multiple ports to serve requests
    port_num_suffix=$((($i % 4)+1))
    if [ "$SOLRJ_PORT_OVERRIDE" = true ];then
      port_num_suffix=4
    fi

    if [ "$INSTANCES_BOOL" = true ];then
      PARAMS="$SINGLE_PAR  --host 10.10.1.$node_subnet_suffix --port ${single_instance_port_arr[$(($i % 4))]}"
    else
      PARAMS="$PAR --host 10.10.1.$node_subnet_suffix --port 9$port_num_suffix$port_num_suffix$port_num_suffix"
    fi
    if [ "$STANDALONE" = true ];then
      PARAMS="$PAR  --host 10.10.1.5 --port 8983"
    fi
    #foreground if procs equals i
    # shellcheck disable=SC1050
    if [ $procs -eq $i ]; then
      echo "python3 traffic_gen.py $THREADS $PARAMS" >> $RSCRIPTS/${LUCKY_LOAD}/remotescript.sh
      break
    fi
    echo "python3 traffic_gen.py $THREADS $PARAMS >/dev/null 2>&1 &" >> $RSCRIPTS/${LUCKY_LOAD}/remotescript.sh
  done
  # copy to respective load nodes
  for noder in "${ALL_LOAD_NODES[@]}";do
    scp ${RSCRIPTS}/${noder}/remotescript.sh $USER@${noder}:/users/${USER}/traffic_gen/remotescript.sh &
  done
  printf "\n\n waiting for scp of remote files ***"
  wait $!
  printf "\n\n\n done waiting \n\n\n"

}


restartSolr () {
  printf "\n\n"
  # zoo needs to be restarted in case clutersize changed
  echo "restarting solr and zookeeper "
  play solr_configure_$1.yml --tags solr_restart

}


resetExperiment () {
  printf "\n\n"
  echo "resetting experiment..."
  delete_collections 8983
  sleep 5

}

getZnode (){
  case $1 in
    1)
      echo "/singleNode"
      ;;
      
    2)
      echo "/twoNode"
      ;;

    4)
      echo "/fourNode"
      ;;

    8)
      echo "/eightNode"
      ;;
    16)
      echo "/sixteenNode"
      ;;
    24)
      echo "/twentyfourNode"
      ;;
    *)
      echo "ERROR: Failed to parse znode $1. Please recheck the variables"
      ;;
  esac
}

restartSolrJ () {
  echo "restarting SOLRJ"
  printf "\n\n"
  echo "stopping SOLRJ"
  killsolrj
  sleep 6

  printf "\n\n"

  # echo "starting SOLRJ $((getZnode $1))"
  printf "\n\n"
  runsolrj $(getZnode $1)
  wait $!
  sleep 4

}




containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

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

