#! /bin/bash

RSCRIPTS=$PROJECT_HOME/benchmark_scripts/remotescripts

source ${SAPA_HOME}/benchmark_scripts/utils/utils.sh
source ${SAPA_HOME}/benchmark_scripts/utils/exp_helpers.sh
source ${SAPA_HOME}/benchmark_scripts/utils/exp_scale_loop_params.sh



function start_experiment() {
  export DOCKER=$DOCKER

  export SAPA_HOME=$SAPA_HOME
  if [ "$#" -lt 3 ]; then
      echo "Usage: start_experiment <username> <python scripts dir> <term list textfile>"
  	exit
  fi
  USER=$1
	PY_SCRIPT=$2
  TERMS=$3
  THREADS="$4 $5"
  PROCESSES="$7"
  DURATION="$8 $9"
  REPLICAS="${10} ${11}"
  SHARDS="${12} ${13}"
  QUERY="${14} ${15}"
  LOOP="${16} ${17}"
  SOLRNUM="${18} ${19}"
  LOAD=${21}
  INSTANCES="${22} ${23}"
  ENGINE="${24} ${25}"
  SOLR_SIZE=${19}
  # loadsize = num of load servers
  LOADSIZE=$LOAD
  # proper array for this var
  LOAD_NODES=($(setLoadArray $LOADSIZE))
  ALL_LOAD_NODES=($(setLoadArray $LOAD))
  # LOAD_NODES is the array of IPs for the specified loadsize
  echo "THESE ARE THE LOAD NODES FOR THIS ITERATION OF EXP::"
  for i in "${LOAD_NODES[@]}";do
    echo $i
  done

  INSTANCES_BOOL=false
  STANDALONE=false
  echo "solrsize=$SOLR_SIZE"

  if [ $SOLR_SIZE -eq 1 ];then
    INSTANCES_BOOL=true
  fi

  if [ $SOLR_SIZE -eq 0 ];then
    STANDALONE=true
    SOLR_SIZE=1
  fi


  SINGLE_PAR=none
  PAR=none
  PARAMS=""

  # if we have instances > 0 then we are in single node cluster mode
  if [ "$INSTANCES_BOOL" = true ];then
    # need to add port (instance) later
    SINGLE_PAR="$DURATION $REPLICAS $SHARDS $QUERY $LOOP $SOLRNUM $ENGINE $INSTANCES --connections 1 --output-dir ./"
  else
    PAR="$DURATION $REPLICAS $SHARDS $QUERY $LOOP $SOLRNUM $ENGINE --connections 1 --output-dir ./"
  fi

  printf "\n\n\n removing previous output from remote sources and local host copies \n\n\n"
  pssh -h $PROJECT_HOME/utils/ssh_files/pssh_traffic_node_file --user $USER "rm ~/traffic_gen/http_benchmark_*"
  rm $PROJECT_HOME/benchmark_scripts/tmp/proc_results/*
# THIS MIGHT HAVE BEEN THE PROBLEM

########## UPDATE LOAD SERVER SCRIPTS #################
#DOCKER exported for this
  update_rscripts $LOAD $RSCRIPTS $PROCESSES $SOLR_SIZE $SOLRJ_PORT_OVERRIDE "$SINGLE_PAR" "$PAR" $INSTANCES_BOOL $STANDALONE "$THREADS" $USER

  printf "\n\n\n ******** EXP PRELIM STEPS COMPLETE!! ************ \n\n\n"
  printf "********* STARTING EXPERIMENT *********\n\n\n"

  echo "RUNNING THESE SHELL SCRIPTS ON LOAD NODES"
  show_remote_scripts $LOAD $RSCRIPTS

  printf "\n nohup output to loadoutput.out\n\n\n"
  # BACKGROUND LOAD GEN NODES
  # ideally kafka would take care of output here. but for now we are just reading a single con output

  # THIS RUNS THE EXPERIMENT
  echo "pssh -l $USER -h $PROJECT_HOME/utils/ssh_files/pssh_traffic_node_file_$LOAD cd $(basename $PY_SCRIPT); bash remotescript.sh "
  pssh -l $USER -h $PROJECT_HOME/utils/ssh_files/pssh_traffic_node_file_$LOAD -P "cd traffic_gen; bash remotescript.sh"
  wait $!

  echo "************* FINISHED EXP ****************"
#### FINISHED #####

  printf "\n\n\n\n ************* STARTING POST EXP STEPS ****************\n\n\n"
  echo "copying exp results to proc_results/  ... "

  # wait for slow processes to complete
  sleep 3
  mycounter=1

  for i in "${ALL_LOAD_NODES[@]}"; do
    if [ $mycounter -eq $LOADSIZE ];then
      echo "$mycounter == $LOADSIZE"
      scp -q $USER@$i:~/traffic_gen/http_benchmark_${15}* $SAPA_HOME/benchmark_scripts/tmp/proc_results
    else
      scp -q $USER@$i:~/traffic_gen/http_benchmark_${15}* $SAPA_HOME/benhmark_scripts/tmp/proc_results &
      mycounter=$(($mycounter+1))
    fi
  done
  wait $!
  sleep 3

  # data transfer can take a few seconds


  printf "\n\n\n RUNNING READ RESULTS SCRIPT"
  printf "$PROJECT_HOME/benchmark_scripts/readresults.py $PROCESSES $THREADS $DURATION $REPLICAS $QUERY $LOOP $SHARDS $SOLRNUM $LOADSIZE $INSTANCES $ENGINE"

  python3 $PROJECT_HOME/benchmark_scripts/readresults.py $PROCESSES $THREADS $DURATION $REPLICAS $QUERY $LOOP $SHARDS $SOLRNUM $LOADSIZE $INSTANCES $ENGINE
  wait $!

  #stores the comnnection output for each load server... this is a lot of data, prolly want to get rid of this.
  DATE=$(date '+%Y-%m-%d_%H:%M:%S')
  conn_result_store=$PROJECT_HOME/benchmark_scripts/${DATE}:::FCTS__query${15}_rf${11}_s${13}_clustersize${19}_threads${5}_proc${7}

  mkdir $conn_result_store
  cp -rf $PROJECT_HOME/benchmark_scripts/tmp/proc_results $conn_result_store

  touch $PROJECT_HOME/benchmark_scripts/tmp/proc_results/javaServer.log

  printf "\n\n\n****** COMPLETED POST EXP STEPS *******\n\n\n"

}


if [ "$#" -lt 3 ]; then
    echo "Usage: runtest.sh <python scripts dir> <search term list> [ -u | --user ] [ -p | --processes ] [ -t | ---threads ] [ -d | --duration ] [ -c | --REPLICASnections ]"
	exit
fi
# initialize to ensure absent params don't mess the local var order up.
PARAMS=""
USER="x"
PY_SCRIPT="x"
TERMS="x"
THREADS="x x"
PROCESSES="x x"
DURATION="x x"
REPLICAS="x x"
SHARDS="x x"
QUERY="x x"
LOOP="x x"
SOLRNUM="x x"
# this default remains when distributed sapa is run
INSTANCES="--instances 0"
LOAD="x x"
ENGINE="x x"

while (( "$#" )); do
  case "$1" in
    -t|--threads)
      THREADS="--threads $2"
      shift 2
      ;;
    -p|--processes)
      PROCESSES="--processes $2"
      shift 2
      ;;
    -d|--duration)
      DURATION="--duration $2"
      shift 2
      ;;
    -rf|--replicas)
      REPLICAS="--replicas $2"
      REPLICA_PARAM=$2
      shift 2
      ;;
    -s|--shards)
      SHARDS="--shards $2"
      SHARD_PARAM=$2
      shift 2
      ;;
    -u|--user)
      USER="$2"
      shift 2
      ;;
    --query)
      QUERY="--query $2"
      shift 2
      ;;

    --loop)
      LOOP="--loop $2"
      shift 2
      ;;

    --solrnum)
      SOLRNUM="--solrnum $2"
      SOLRNUM_PARAM=$2
      shift 2
      ;;

    --load)
      LOAD="--load $2"
      shift 2
      ;;

    --instances)
      INSTANCES="--instances $2"
      shift 2
      ;;
    --engine)
      ENGINE="--engine $2"
      shift 2
      ;;

    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done


PY_SCRIPT="traffic_gen"
TERMS="words.txt"

#PARAMETERS=$3
# this should be done in the exp loop script after loop finishes, not for each exp.
  # echo "checking if cores exist for reviews_ $SHARDS $REPLICAS"
  # cd ~/projects/sapa; ansible-playbook -i inventory post_data.yml --tags exp_mode --extra-vars "replicas=${REPLICA_PARAM} shards=${SHARD_PARAM} clustersize=${SOLRNUM_PARAM}"
  # wait $!

cd ~/projects/sapa/benchmark_scripts;
# start_experiment $USER $PY_SCRIPT
export procs=$procs
export SOLRJ_PORT_OVERRIDE=$SOLRJ_PORT_OVERRIDE
export DOCKER=$DOCKER
export SAPA_HOME=$SAPA_HOME
export -f setLoadArray
start_experiment $USER $PY_SCRIPT $TERMS $THREADS $PROCESSES $DURATION $REPLICAS $SHARDS $QUERY $LOOP $SOLRNUM $LOAD $INSTANCES $ENGINE

#start_experiment $USER $PY_SCRIPT "\"$PARAMETERS\""

exit
