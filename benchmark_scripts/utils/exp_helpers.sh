#!/bin/bash


CLOUDHOME="/users/dporte7"
export USER=$USER
DOCKER=no


if [ "$DOCKER" = yes ];then
  echo "wooooo"
  alias play=solo_party
fi


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
  typeset args=("$@")
# get number of elements
  ELEMENTS=${#args[@]}
  offset=1
  subnet24=10.10.1.
  home_dir=/users/$USER
  printf "\n\n\n\n $DOCKER \n\n\n"
  if [ $DOCKER = yes ];then
    offset=2
    subnet24=172.21.0.
    home_dir=/home/$USER
  fi
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
    node_subnet_suffix=$(($(($i % $SOLR_SIZE))+$offset))

    # this port suffix thing is really just for solrj requests since solrj has multiple ports to serve requests
    port_num_suffix=$((($i % 4)+1))
    hostinfo="--host ${subnet24}${node_subnet_suffix}"

    if [ "$SOLRJ_PORT_OVERRIDE" = true ];then
      port_num_suffix=4
    fi

    if [ "$INSTANCES_BOOL" = true ];then
      PARAMS="$SINGLE_PAR $hostinfo --port ${single_instance_port_arr[$(($i % 4))]}"
    else
      PARAMS="$PAR $hostinfo --port 9$port_num_suffix$port_num_suffix$port_num_suffix"
    fi
    if [ "$STANDALONE" = true ];then
      PARAMS="$PAR  $hostinfo --port 8983"
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
    scp ${RSCRIPTS}/${noder}/remotescript.sh $USER@${noder}:$home_dir/traffic_gen/remotescript.sh &
  done
  printf "\n\n waiting for scp of remote files ***"
  wait $!
  printf "\n\n\n done waiting \n\n\n"

}


restartSolr () {
  printf "\n\n"
  # zoo needs to be restarted in case clutersize changed
  echo "restarting solr and zookeeper "
  play solr_configure_$1.yml --tags solr_restart --extra-vars "@sapa_vars.yml"

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
  printf "\n\n"
  echo "stopping SOLRJ"
  killsolrj
  sleep 6

  printf "\n\n"

  echo "restarting SOLRJ"
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
  pssh -h $SAPA_HOME/utils/ssh_files/pssh_solr_node_file -l $CL_USER rm -rf $CORE_HOME/reviews*
}

wipecores_backup () {
  for i in $ALL_SOLR; do
    ssh $CL_USER@$i rm -rf $CORE_HOME/reviews*
  done
}

EXP_HOME=$SAPA_HOME/chart/exp_records
# just deal with it... find and replace snafu. they are the same
export PROJECT_HOME=${SAPA_HOME}

runsolrj (){
  pssh -h $SAPA_HOME/utils/ssh_files/pssh_traffic_node_file -l $CL_USER "cd solrclientserver;java -cp target/solrclientserver-1.0-SNAPSHOT.jar com.dporte7.solrclientserver.DistributedWebServer $1  > javaServer.log 2>&1 &"&
}

archivePrev (){
  printf "\n\n archiving exp_results \n\n"
  chartname=$1
  servernode=$2
  query=$3
  reps=$4
  shards=$5
  mkdir $EXP_HOME/$chartname
  cd $SAPA_HOME/benchmark_scripts
  cp -rf tmp/exp_result/* $EXP_HOME/$chartname
  rm -rf tmp/exp_result/*
  mkdir -p $EXP_HOME/$chartname/FCTS/$servernode/$query/r$reps:s$shards
  cp -rf 2020* $EXP_HOME/$chartname/FCTS/$servernode/$query/r$reps:s$shards
  rm -rf 2020*
}

stopsingle (){
  for i in `seq 3`;do
    printf "\n STOPPING SOLR INSTANCES:"
    echo "node__$i/solr -p 99$i$i"
    pssh -h $SAPA_HOME/utils/ssh_files/solr_single_node -l $CL_USER -P "bash ~/solr-8_3/solr/bin/solr stop -cloud -q -s ~/node__$i/solr -p 99$i$i -Dhost=10.10.1.1"
  done
}


wipeInstances (){

  stopsingle

  sleep 8
  echo "removing old node_ dirs on server1"
  pssh -h $SAPA_HOME/utils/ssh_files/solr_single_node -l $CL_USER -P "rm -rf ~/node_*"
  sleep 2
}


stopSolr () {
  printf "\n\n"
  echo "stopping solr "
  printf "\n\n"

  play solr_configure_$1.yml --tags solr_stop --extra-vars "@sapa_vars.yml"
  # sleep 5
  if [ $1 -eq 1 ];then
	stopsingle
  fi

}

resetState () {
  stopSolr $1
  wipecores
  play zoo_configure.yml --tags zoo_stop --extra-vars "@sapa_vars.yml"
  play zoo_configure.yml --tags zoo_start --extra-vars "@sapa_vars.yml"
}

startSolr () {
  printf "\n\n"
  echo "starting solr "
  printf "\n\n"
  play solr_configure_$1.yml --tags solr_start --extra-vars "@sapa_vars.yml"
  sleep 3
}

stopZookeeper (){
  play zoo_configure.yml --tags zoo_stop --extra-vars "@sapa_vars.yml"
}

startZookeeper (){
  play zoo_configure.yml --tags zoo_start --extra-vars "@sapa_vars.yml"
}
startElastic () {
  printf "\n\n"
  echo "starting elastic "
  printf "$DOCKER \n\n"
  if [ $DOCKER = yes ];then
    solo_party elastic_configure_$1.yml --tags start --extra-vars "@sapa_vars.yml"
  else
    play elastic_configure_$1.yml --tags start --extra-vars "@sapa_vars.yml"
  fi

}

stopElastic (){
  if [ $DOCKER = yes ];then
    solo_party elastic_configure_$1.yml --tags stop --extra-vars "@sapa_vars.yml"
  else
    play elastic_configure_$1.yml --tags stop --extra-vars "@sapa_vars.yml"
  fi
}
getHostResourceInfo (){

  echo $LOAD
  LOAD=$(getLoadNum $LOAD)
  echo $LOAD
  printf "getting load machine info"
  echo "LOADNODES:::" > $ENV_OUTPUT_FILE
  pssh -h $SAPA_HOME/utils/ssh_files/pssh_traffic_node_file_$LOAD -P "lscpu | grep 'CPU(s)\|Thread(s)\|Core(s)\|Arch\|cache\|Socket(s)'" >> $ENV_OUTPUT_FILE
  echo "********" >> $ENV_OUTPUT_FILE

  echo "SOLR NODES:::" >> $ENV_OUTPUT_FILE
  pssh -h $SAPA_HOME/utils/ssh_files/pssh_solr_node_file -P "lscpu | grep 'CPU(s)\|Thread(s)\|Core(s)\|Arch\|cache\|Socket(s)'" >> $ENV_OUTPUT_FILE
  echo "********" >> $ENV_OUTPUT_FILE

  echo "NETWORK BANDWIDTH::: " >> $ENV_OUTPUT_FILE
  pssh -h $SAPA_HOME/utils/ssh_files/pssh_all -P "cat /sys/class/net/eno1d1/speed" >> $ENV_OUTPUT_FILE
  echo "********" >> $ENV_OUTPUT_FILE

  echo "RAM::: " >> $ENV_OUTPUT_FILE
  pssh -h $SAPA_HOME/utils/ssh_files/pssh_all -P "lshw -c memory | grep size" >> $ENV_OUTPUT_FILE
  echo "********" >> $ENV_OUTPUT_FILE

}

commence_dstat () {
  # remove previous dstatout
  QUERY=$1
  RF=$2
  SHARD=$3
  SOLRNUM=$4
  echo "dstat should not be running but killing just in case"
  pssh -h $SAPA_HOME/utils/ssh_files/pssh_all --user $USER "pkill -f dstat"


  echo "removing prev dstat files"
  pssh -h $SAPA_HOME/utils/ssh_files/pssh_all --user $USER "rm ~/*dstat.csv"
  # dstat on each node
  # nodecounter just makes it easier to know which node dstat file was
  node_counter=0


  echo "COMMENCE DSTAT ON ALL MACHINES..."
  printf "\n"


  ssh $USER@$n "pkill -f dstat" >/dev/null 2>&1 &

  for n in $ALL_NODES;do
    nohup ssh $USER@$n "dstat -t --cpu --mem --disk --io --net --int --sys --swap --tcp --output node${node_counter}_${n}_${QUERY}::rf${RF}_s${SHARD}_cluster${SOLRNUM}_dstat.csv &" >/dev/null 2>&1 &
    node_counter=$(($node_counter+1))
  done
  printf "\n"
  echo "DSTAT LIVE"
  printf "\n"
}

