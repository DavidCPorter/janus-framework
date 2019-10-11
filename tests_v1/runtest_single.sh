#!/bin/bash

PROJECT_HOME='/Users/dporter/projects/solrcloud'

function start_experiment() {

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
    INSTANCES="${21}"

    LOAD_NODES=("128.110.153.246" "128.110.154.32" "128.110.154.35" "128.110.153.247")
    echo $PROJECT_HOME
    echo 'Copying python scripts to remote machine'
    pscp -l $USER -r -h $PROJECT_HOME/ssh_files/pssh_traffic_node_file $PY_SCRIPT /users/dporte7
    pscp -l $USER -h $PROJECT_HOME/ssh_files/pssh_traffic_node_file $TERMS /users/dporte7

    # each process in the python script will make #THREAD num of REPLICASnections to a SINGLE solr instance "--host" (for --query direct)
    # parameters for py script running on nodes 32, 33, 34, 35
    # hosts here will either be this local for solrj since solj is running on same node, or a subnet address
    # different ports reflect the number of solrj processes on each node running solrj
    #  otherwise ports will be changed to 8983 since solrcloud httpserver runs there on the network
    PAR_0="$THREADS $DURATION $REPLICAS $SHARDS $QUERY $LOOP $SOLRNUM --connections 1 --output-dir ./ --port 9111" #host appended below
    PAR_1="$THREADS $DURATION $REPLICAS $SHARDS $QUERY $LOOP $SOLRNUM --connections 1 --output-dir ./ --port 9222" #host appended below
    PAR_2="$THREADS $DURATION $REPLICAS $SHARDS $QUERY $LOOP $SOLRNUM --connections 1 --output-dir ./ --port 9333" #host appended below
    PAR_3="$THREADS $DURATION $REPLICAS $SHARDS $QUERY $LOOP $SOLRNUM --connections 1 --output-dir ./ --port 9444" #host appended below

    SINGLE_PAR="$THREADS $DURATION $REPLICAS $SHARDS $QUERY $LOOP $SOLRNUM --connections 1 --output-dir ./ --host 10.10.1.1"

    echo "removing previous output from remote and local host"
    pssh -h $PROJECT_HOME/ssh_files/pssh_traffic_node_file --user $USER "rm ~/traffic_gen/http_benchmark_*"
    rm $PROJECT_HOME/tests_v1/profiling_data/proc_results/http_benchmark_*
    MINUS1="$((PROCESSES - 1))"


########## EXPERIMENT LOOPS #################

    if [ ${19} = '1' ]; then
      echo "running on single solr server"
      echo "#!/bin/bash" > ./remotescript.sh
      echo "#!/bin/bash" > ./remotescript_foreground.sh
      echo "# this file is used to run processes remotely since cloudlab blacklists aggressive ssh" >> ./remotescript.sh
      # this will allocate the processes connections accross the ports open for each solr instance on server 1
      for i in $(seq $MINUS1); do
        echo "$i"
        # take care of the port in traffic_gen.py
        echo "python3 traffic_gen.py $SINGLE_PAR --port $(($i % $INSTANCES)) >/dev/null 2>&1 &" >> ./remotescript.sh
        echo "python3 traffic_gen.py $SINGLE_PAR --port $(($i % $INSTANCES)) &" >> ./remotescript_foreground.sh
      done
      echo "python3 traffic_gen.py $SINGLE_PAR --port $(($PROCESSES % $INSTANCES)) >/dev/null 2>&1 &" >> ./remotescript.sh
      echo "python3 traffic_gen.py $SINGLE_PAR --port $(($PROCESSES % $INSTANCES)) " >> ./remotescript_foreground.sh
      # run remotescripts on all background nodes
      pscp -l $USER -h $PROJECT_HOME/ssh_files/pssh_traffic_node_file_3 ./remotescript.sh /users/$USER/traffic_gen
      pscp -l $USER -h $PROJECT_HOME/ssh_files/pssh_traffic_node_file_single ./remotescript_foreground.sh /users/$USER/traffic_gen
      nohup pssh -l $USER -h $PROJECT_HOME/ssh_files/pssh_traffic_node_file_3 "cd $(basename $PY_SCRIPT); bash remotescript.sh"&
      # run foreground processes on foreground node
      nohup ssh $USER@128.110.153.246 "cd $(basename $PY_SCRIPT); bash remotescript_foreground.sh"
      wait $!
      echo "finished"

  # wait for slow processes to complete (prolly not effective)
      sleep 5
      for i in "${LOAD_NODES[@]}"; do
          scp $USER@$i:~/traffic_gen/http_benchmark_${15}* profiling_data/proc_results &
      done
      wait $!
      sleep 5
      python3 $PROJECT_HOME/tests_v1/traffic_gen/readresults.py $PROCESSES $THREADS $DURATION $REPLICAS $QUERY $LOOP $SHARDS $SOLRNUM
      DATE=$(date '+%Y-%m-%d_%H:%M:%S')
      # for reference
      zip -r ${DATE}_query${15}_rf${11}_s${13}_clustersize${19}_threads${5}_proc${7}.zip profiling_data/proc_results


# SINGLE PROCESS
    else
        if [ $PROCESSES = '1' ]; then
          echo "starting a single process experiment"
          pssh -h $PROJECT_HOME/ssh_files/pssh_traffic_node_file_single --user $USER "cd $(basename $PY_SCRIPT); python3 traffic_gen.py $PAR_0"
          wait $!
          echo "finished"
          # do something better later cuz pscp is terrible
          # for i in "${LOAD_NODES[@]}"; do
          #     scp $USER@$i:"~/${15}_node${i}_dstat_$PY_NAME.csv" profiling_data/
          # done


# LOCAL EXPERIMENT
# dont use this anymore
      # if [ ${15} = 'local' ]; then
      #   echo "***running local experiment****"
      #   for i in $(seq $MINUS1); do
      #     # PARMS will not be used in this case
      #     PARAMS=$(eval 'echo $PAR_'"$(($i % 4))")
      #   	python3 $PROJECT_HOME/tests_v1/traffic_gen/traffic_gen.py $PARAMS --host >/dev/null 2>&1 &
      #   done
      #   echo "starting"
      #   python3 $PROJECT_HOME/tests_v1/traffic_gen/traffic_gen.py $PARAMS  --host
      #   echo "finished"

  # REMOTE EXPERIMENT WITH X PROCESSES
  # have to DIVIDE the num or processes over 4 load nodes each REPLICASnecting to one of 32 servers for direct 32 exp
        else

          echo "*** running remote experiment ****"
          # clear script to run python processes
          echo "#!/bin/bash" > ./remotescript.sh
          echo "#!/bin/bash" > ./remotescript_foreground.sh
          echo "# this file is used to run processes remotely since cloudlab blacklists aggressive ssh" >> ./remotescript.sh

          # each server will run X processes communicating to all X nodes in cluster
          for i in $(seq $MINUS1); do
            echo "$i"
            PARAMS=$(eval 'echo $PAR_'"$(($i % 4))")
            echo "$PARAMS"
          	echo "python3 traffic_gen.py $PARAMS --host 10.10.1.$(($i % (${19})+1)) >/dev/null 2>&1 &" >> ./remotescript.sh
          	echo "python3 traffic_gen.py $PARAMS --host 10.10.1.$(($i % (${19})+1)) &" >> ./remotescript_foreground.sh
          done
          #  for foreground the final processes in shell scipt must be synchornized for experiment timing purposes (or we could just have this whole thing wait, but it's better to get output back for a single synch process)
    # ${19}+1 the plus one is because arg 19 is num of nodes, and the nodes start at 1
          echo "python3 traffic_gen.py $PARAMS --host 10.10.1.$(($PROCESSES % (${19})+1)) >/dev/null 2>&1 &" >> ./remotescript.sh
          echo "python3 traffic_gen.py $PARAMS --host 10.10.1.$(($PROCESSES % (${19})+1))" >> ./remotescript_foreground.sh

          # run remotescripts on all background nodes
          pscp -l $USER -h $PROJECT_HOME/ssh_files/pssh_traffic_node_file_3 ./remotescript.sh /users/$USER/traffic_gen
          pscp -l $USER -h $PROJECT_HOME/ssh_files/pssh_traffic_node_file_single ./remotescript_foreground.sh /users/$USER/traffic_gen
          nohup pssh -l $USER -h $PROJECT_HOME/ssh_files/pssh_traffic_node_file_3 "cd $(basename $PY_SCRIPT); bash remotescript.sh"&
          # run foreground processes on foreground node
          nohup ssh $USER@128.110.153.246 "cd $(basename $PY_SCRIPT); bash remotescript_foreground.sh"
          wait $!
          echo "finished"

    # wait for slow processes to complete (prolly not effective)
        sleep 5
        for i in "${LOAD_NODES[@]}"; do
            scp $USER@$i:~/traffic_gen/http_benchmark_${15}* profiling_data/proc_results &
        done
        wait $!
        sleep 5
        python3 $PROJECT_HOME/tests_v1/traffic_gen/readresults.py $PROCESSES $THREADS $DURATION $REPLICAS $QUERY $LOOP $SHARDS $SOLRNUM
        DATE=$(date '+%Y-%m-%d_%H:%M:%S')
        # for reference
        zip -r ${DATE}_query${15}_rf${11}_s${13}_clustersize${19}_threads${5}_proc${7}.zip profiling_data/proc_results
        fi
  fi
}

function profile_experiment_dstat() {

    if [ "$#" -lt 3 ]; then
        echo "Usage: profile_experiment_dstat <username> <python scripts dir> <search term list>"
    	exit
    fi
    USER=$1
  	PY_SCRIPT=$2
    TERMS=$3
    THREADS="$4 $5"
    PROCESSES="$6 $7"
    DURATION="$8 $9"
    REPLICAS="${10} ${11}"
    SHARDS="${12} ${13}"
    QUERY="${14} ${15}"
	  #PARAMETERS=$3

    LOOP="${16} ${17}"
    SOLRNUM="${18} ${19}"
    INSTANCES="${20} ${21}"


    DPARAMS='-t --cpu --mem --disk --io --net --int --sys --swap --tcp'

    PY_NAME=$(basename $PY_SCRIPT | cut -d '.' -f1)

    # echo 'deleting node dstat remote files'
    DATE=$(date '+%Y-%m-%d_%H:%M:%S')
    # nohup pssh -i -l $USER -h $PROJECT_HOME/ssh_files/pssh_solr_node_file "rm ~/${DATE}_rf${11}_s${13}_clustersize${19}_threads${5}_proc${7}_dstat_$PY_NAME.csv" &
    # sleep 1
  	# echo 'Starting the dstat'
    # nohup pssh -i -l $USER -h $PROJECT_HOME/ssh_files/pssh_solr_node_file "dstat $DPARAMS --output ${15}_node_dstat_$PY_NAME.csv >/dev/null 2>&1" &
    # nohup pssh -i -l $USER -h $PROJECT_HOME/ssh_files/pssh_traffic_node_file "cd solrclientserver;java -cp target/solrclientserver-1.0-SNAPSHOT.jar com.dporte7.solrclientserver.DistributedWebServer" &
  	echo 'Starting the experiment'
  	 start_experiment $USER $PY_SCRIPT $TERMS $THREADS $PROCESSES $DURATION $REPLICAS $SHARDS $QUERY $LOOP $SOLRNUM $INSTANCES

    # start_experiment returns after requests


    # echo 'Stopping dstat'
    #   nohup pssh -l $USER -i -h $PROJECT_HOME/ssh_files/pssh_solr_node_file "ps aux | grep -i 'dstat*' | awk -F' ' '{print \$2}' | xargs kill -9 >/dev/null 2>&1" &

    echo 'Copying the remote dstat data to local -> /profiling_data'
    echo 'TO DO'

    # pscp $USER@node$i:"~/${15}_node${i}_dstat_$PY_NAME.csv" profiling_data/

    echo 'Done'

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
INSTANCES="x x"

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
    --instances)
      INSTANCES="--instances $2"
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

echo "checking if cores exist for reviews_ $SHARDS $REPLICAS"
cd ~/projects/solrcloud; ansible-playbook -i inventory post_data.yml --tags exp_mode --extra-vars "replicas=${REPLICA_PARAM} shards=${SHARD_PARAM} clustersize=${SOLRNUM_PARAM}"
wait $!

cd ~/projects/solrcloud/tests_v1;
echo 'Starting the experiment'
# start_experiment $USER $PY_SCRIPT

profile_experiment_dstat $USER $PY_SCRIPT $TERMS $THREADS $PROCESSES $DURATION $REPLICAS $SHARDS $QUERY $LOOP $SOLRNUM $INSTANCES

#start_experiment $USER $PY_SCRIPT "\"$PARAMETERS\""

exit
