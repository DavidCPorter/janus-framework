#!/bin/bash

CLOUDHOME=/users/dporte7
USER="dporte7"


# load sugar
source ${SAPA_HOME}/benchmark_scripts/utils/utils.sh
source ${SAPA_HOME}/utils/exp_helpers.sh
source ${SAPA_HOME}/utils/exp_scale_loop_params.sh

LOAD_SCRIPTS="$SAPA_HOME/benchmark_scripts/traffic_gen"
TERMS="$SAPA_HOME/benchmark_scripts/words.txt"
ENV_OUTPUT_FILE="$SAPA_HOME/env_output_file.txt"
touch $ENV_OUTPUT_FILE


if [ "$#" -gt 5 ]; then
    echo "Usage: scale.sh [ nodesize1 nodesize2 ... nodesize5 ] (default/max 32)"
    echo " ERROR : TOO MANY ARGUMENTS"
    echo " Example -> bash scale.sh 2 4 8"
	exit
fi
if [ "$#" -eq 0 ]; then
    echo "Usage: scale.sh [ size1 size2 ... size5 ] (default/max 32)"
    echo " this program requires at least 1 argument "
	exit
fi

accepted_nodes=( 1 2 4 8 16 24 )

####### validate arguments

for SERVERNODE in "$@"; do
  containsElement $SERVERNODE ${accepted_nodes[@]}
  if [ $? -eq 1 ]; then
    echo "nodesizes must be 2,4,8,16, or 32"
    exit
  fi
done


createInstances () {
  printf "\n\n"
  echo "running createInstances()"
  printf "\n\n"

    INSTANCES=$1

    for i in `seq $(($INSTANCES-1))`;do

      if [ $INSTANCES = "1" ];then
        echo "not creating additional instances"
        break
      fi

      echo "creating new dir for instance -> $CLOUDHOME/node__$i"
      pssh -h ~/projects/sapa/ssh_files/solr_single_node -l dporte7 -P "mkdir $CLOUDHOME/node__$i"
    done
    wait $!

    for i in `seq $(($INSTANCES-1))`;do
      if [ $INSTANCES = '1' ];then
        break
      fi
      # better way to do this:::: use ansible to copy files local to remote
      echo "removing any old indexes from default single cluster"
      pssh -h ~/projects/sapa/ssh_files/solr_single_node -l dporte7 -P "rm -rf $CLOUDHOME/solr-8_3/solr/server/solr/reviews*"
      echo "copying config files to $CLOUDHOME/node__$i/"
      pssh -h ~/projects/sapa/ssh_files/solr_single_node -l dporte7 -P "cp -rf $CLOUDHOME/solr-8_3/solr/server/solr $CLOUDHOME/node__$i/"
    done
    wait $!

    for i in `seq $(($INSTANCES-1))`;do
      if [ $INSTANCES = '1' ];then
        break
      fi
      printf "\n launching:"
      echo "node__$i/solr -p 99$i$i"
      # already have the zk config in the solr.in.sh so dont need to override it
      pssh -h ~/projects/sapa/ssh_files/solr_single_node -l dporte7 -P "bash ~/solr-8_3/solr/bin/solr start -cloud -q -s ~/node__$i/solr -p 99$i$i -Dhost=10.10.1.1"
      printf "\n done \n"
    done

    # runsolrj
    wait $!
    sleep 5
}

freshRestart () {
  SERVERNODE=$1
  RF=$2
  SHARD=$3

  startSolr $SERVERNODE

  if [ "$SERVERNODE" -eq 1 ];then
    createInstances $instances
  fi

  # begin_exp is going to either post to solr a new colleciton or pull down an existing one from aws
  play post_data_$SERVERNODE.yml --tags begin_exp --extra-vars "replicas=$RF shards=$SHARD clustersize=9$SERVERNODE"
  #  need to restart since pulling index from aws most likely happened and solr (not zookeeper) needs to restart after that hack
  restartSolr $SERVERNODE
  play post_data_$SERVERNODE.yml --tags update_collection_configs --extra-vars "replicas=$RF shards=$SHARD clustersize=9$SERVERNODE"
  sleep 2
}

# START OF SCRIPT



PREFIXER=""
printf "\n\n\n\n"
echo "******** STARTING FULL SCALING EXPERIEMENT **********"
printf "\n"
echo " SCALE EXP loop will measure performance of solrcloud with these cluster sizes:"
for SERVERNODE in "$@"; do
  PREFIXER="${PREFIXER}${SERVERNODE}_"
  echo $SERVERNODE
done
CHARTNAME=$(LC_ALL=C tr -dc 'a-z' </dev/urandom | head -c 7; echo)
CHARTNAME="$(date +"%m-%d")::${PREFIXER}${CHARTNAME}"
######## VALIDATION COMPLETE
printf "\n\n\n"

# workload vars for loop for config experiment
box_cores=16
box_threads=1
app_threads=1
load_server_incrementer=1
echo "SCALE EXP will increase outstanding query requests (LOAD) from $(($load_server_incrementer*$app_threads*$box_cores*$box_threads)) --->> $(($LOAD*$app_threads*$box_cores*$box_threads))"
echo "chartname:"
echo $CHARTNAME
EXP_HOME=${SAPA_HOME}/chart/exp_records
mkdir $EXP_HOME/$CHARTNAME
# ARCHIVE PREVIOUS EXPs (this shouldnt archive anything if done correctly so first wipe dir)
rm -rf $SAPA_HOME/benchmark_scripts/tmp/tmp/*
rm -rf $SAPA_HOME/benchmark_scripts/tmp/proc_results/*

# echo "$LOAD_NODES"
# echo "LOAD_NODES = ${LOAD_NODES[1]}"
if [ $copy_python_scripts == "yes" ]; then
  echo 'Copying python scripts and search terms to load machines'
  play update_loadscripts.yml --extra-vars "scripts_path=$LOAD_SCRIPTS terms_path=$TERMS"
fi

########## PRINT ENV TO ENV OUTPUT FILE ##########

LOAD=$(getLoadNum $LOAD)

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


        # startSolr $SERVERNODE
        #
        # if [ "$SERVERNODE" -eq 1 ];then
        #   createInstances $instances
        # fi
        #
        # # begin_exp is going to either post to solr a new colleciton or pull down an existing one from aws
        # play post_data_$SERVERNODE.yml --tags begin_exp --extra-vars "replicas=$RF shards=$SHARD clustersize=9$SERVERNODE"
        # #  need to restart since pulling index from aws most likely happened and solr (not zookeeper) needs to restart after that hack
        # restartSolr $SERVERNODE
        #
        # play post_data_$SERVERNODE.yml --tags update_collection_configs --extra-vars "replicas=$RF shards=$SHARD clustersize=9$SERVERNODE"
        # sleep 2


for QUERY in ${QUERYS[@]}; do

  for SERVERNODE in "$@"; do
    # maybe restart zoo




    LOADHOSTS="$SAPA_HOME/utils/ssh_files/pssh_traffic_node_file"

    for SHARD in ${SHARDS[@]}; do

      for RF_MULT in ${RF_MULTIPLE[@]}; do


        ######## EXP LOOP = r*s = 2(num of SERVERNODES) ##########

        RF=$(($RF_MULT*$SERVERNODE))
        # RF=$RF_MULT

        freshRestart $SERVERNODE $RF $SHARD


        #  sfor solrj ... using chroot requires restart of solrj every time :/
        if [ $QUERY == "solrj" ]; then
          echo "waiting for solr..."
          sleep 3
          echo "restarting solrj.."

          restartSolrJ $SERVERNODE
          sleep 2
        fi

        PROCESSES=$SERVERNODE
        SOLRNUM=$SERVERNODE
          # scale each load up to servernode size then add a load node
        # remove previous dstatout
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
          nohup ssh $USER@$n "dstat -t --cpu --mem --disk --io --net --int --sys --swap --tcp --output node${node_counter}_${n}_${QUERY}::rf${RF}_s${SHARD}_cluster9${SERVERNODE}_dstat.csv &" >/dev/null 2>&1 &
          node_counter=$(($node_counter+1))
        done
        printf "\n"
        echo "DSTAT LIVE"
        printf "\n"

        # vars for loop for config experiment
        box_cores=16
        box_threads=1
        app_threads=1
        load_server_incrementer=1
        export procs=$(($box_cores*$box_threads))
        export SOLRJ_PORT_OVERRIDE=$SOLRJ_PORT_OVERRIDE
        for ((l=$load_server_incrementer; l<=$LOAD; l=$((l+$load_server_incrementer))));do

          # keep last log
          printf "\n"
          printf "\n"
          printf "\n"

          echo "********   STARTING EXP PRELIM STEPS   ************"
          printf "\n"

          echo "removing previous exp load script output ::: traffic_gen/traffic_gen.log"
          cd ~/projects/sapa;pssh -l dporte7 -h "${LOADHOSTS}_${LOAD}" "echo ''>traffic_gen/traffic_gen.log"
          printf "\n\n\n\n"
          echo " PARAMETERS TO runscript.sh:::: "
          echo "\$ ./benchmark_scripts/scriptsThatRunLoadServers/runtest.sh traffic_gen words.txt --user dporte7 -rf $RF -s $SHARD -t ${app_threads} -d 10 -p $(($procs*$l*$app_threads)) --solrnum $SERVERNODE --query $QUERY --loop open --load $l --instances $instances"
          printf "\n\n"
          cd ~/projects/sapa/benchmark_scripts/scriptsThatRunLoadServers; bash runtest.sh traffic_gen words.txt --user dporte7 -rf $RF -s $SHARD -t ${app_threads} -d 10 -p $(($procs*$l*$app_threads)) --solrnum $SERVERNODE --query $QUERY --loop open --load $l --instances $instances
          sleep 2
        done

        for n in $ALL_NODES;do
          ssh $USER@$n "pkill -f dstat" >/dev/null 2>&1 &
        done

        DSTAT_DIR="${SAPA_HOME}/rf_${RF}_s${SHARD}_solrnum${SERVERNODE}_query${QUERY}"
        mkdir $DSTAT_DIR

        for n in $ALL_NODES;do
          scp -r $USER@${n}:~/*dstat.csv $DSTAT_DIR
        done

        mv $DSTAT_DIR "/Users/dporter/projects/solrcloud/chart/exp_records/$CHARTNAME"


    # need to call stopsolr it here since it needs to stop this exp explicitly before running a new one

        stopSolr $SERVERNODE
# need to add new var herre if we want to change the default 4 node single cluster
        play post_data_$SERVERNODE.yml --tags aws_exp_reset --extra-vars "replicas=$RF shards=$SHARD clustersize=9$SERVERNODE"

        # next RF
      done
      # next shard
    done
    # next servernode
    archivePrev $CHARTNAME $SERVERNODE $QUERY
  done
  # next query
  python3 ${SAPA_HOME}/chart/generate_exp_csvs.py $QUERY $CHARTNAME
  python3 ${SAPA_HOME}/chart/generate_figures.py $QUERY $CHARTNAME
  zip -r ${SAPA_HOME}/chart/exp_html_out/_$CHARTNAME/exp_zip.zip ${SAPA_HOME}/chart/exp_records/$CHARTNAME
done
