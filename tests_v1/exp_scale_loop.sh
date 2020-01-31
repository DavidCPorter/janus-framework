#!/bin/bash

CLOUDHOME=/users/dporte7
export USER="dporte7"
export PROJ_HOME=$PROJ_HOME

# load sugar
source /Users/dporter/projects/solrcloud/utils/utils.sh
source /Users/dporter/projects/solrcloud/utils/exp_helpers.sh
source /Users/dporter/projects/solrcloud/utils/exp_scale_loop_params.sh

commence_dstat () {
  # remove previous dstatout
  QUERY=$1
  RF=$2
  SHARD=$3
  SOLRNUM=$4
  echo "dstat should not be running but killing just in case"
  pssh -h $PROJ_HOME/ssh_files/pssh_all --user $USER "pkill -f dstat"


  echo "removing prev dstat files"
  pssh -h $PROJ_HOME/ssh_files/pssh_all --user $USER "rm ~/*dstat.csv"
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

LOAD_SCRIPTS="$PROJ_HOME/tests_v1/traffic_gen"
TERMS="$PROJ_HOME/tests_v1/words.txt"
ENV_OUTPUT_FILE="$PROJ_HOME/env_output_file.txt"
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

accepted_nodes=( 2 4 8 16 24 )

####### validate arguments

for SERVERNODE in "$@"; do
  # shellcheck disable=SC2068
  # shellcheck disable=SC2068
  containsElement $SERVERNODE ${accepted_nodes[@]}
  if [ $? -eq 1 ]; then
    echo "nodesizes must be 2,4,8,16, or 32"
    exit
  fi
done

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



# vars for loop for config experiment
box_cores=16
box_threads=1
app_threads=1
echo "SCALE EXP will increase outstanding query requests (LOAD) from $(($load_server_incrementer*$app_threads*$box_cores*$box_threads)) --->> $(($LOAD*$app_threads*$box_cores*$box_threads)) + $(($EXTRA_ITERS*16))"
echo "chartname:"
echo $CHARTNAME
EXP_HOME=/Users/dporter/projects/solrcloud/chart/exp_records
# mov prev record outside project perview (data size too large)
echo "moving previous records to long term data store"
mv $EXP_HOME/* ~/projects/saga_records/

mkdir $EXP_HOME/$CHARTNAME

# ARCHIVE PREVIOUS EXPs (this shouldnt archive anything if done correctly so first wipe dir)
rm -rf $PROJ_HOME/tests_v1/profiling_data/exp_results/*
rm -rf $PROJ_HOME/tests_v1/profiling_data/proc_results/*
mkdir $PROJ_HOME/tests_v1/profiling_data/proc_results

# echo "$LOAD_NODES"
# echo "LOAD_NODES = ${LOAD_NODES[1]}"
if [ $copy_python_scripts == "yes" ]; then
  echo 'Copying python scripts and search terms to load machines'
  play update_loadscripts.yml --extra-vars "scripts_path=$LOAD_SCRIPTS terms_path=$TERMS"
fi

########## PRINT ENV TO ENV OUTPUT FILE ##########

LOAD=$(getLoadNum $LOAD)
printf "getting load machine info"
echo "LOADNODES:::" > $ENV_OUTPUT_FILE
pssh -h $PROJ_HOME/ssh_files/pssh_traffic_node_file_$LOAD -P "lscpu | grep 'CPU(s)\|Thread(s)\|Core(s)\|Arch\|cache\|Socket(s)'" >> $ENV_OUTPUT_FILE
echo "********" >> $ENV_OUTPUT_FILE

echo "SOLR NODES:::" >> $ENV_OUTPUT_FILE
pssh -h $PROJ_HOME/ssh_files/pssh_solr_node_file -P "lscpu | grep 'CPU(s)\|Thread(s)\|Core(s)\|Arch\|cache\|Socket(s)'" >> $ENV_OUTPUT_FILE
echo "********" >> $ENV_OUTPUT_FILE

echo "NETWORK BANDWIDTH::: " >> $ENV_OUTPUT_FILE
pssh -h $PROJ_HOME/ssh_files/pssh_all -P "cat /sys/class/net/eno1d1/speed" >> $ENV_OUTPUT_FILE
echo "********" >> $ENV_OUTPUT_FILE

echo "RAM::: " >> $ENV_OUTPUT_FILE
pssh -h $PROJ_HOME/ssh_files/pssh_all -P "lshw -c memory | grep size" >> $ENV_OUTPUT_FILE
echo "********" >> $ENV_OUTPUT_FILE

#
LOADHOSTS="$PROJ_HOME/ssh_files/pssh_traffic_node_file"

printf "sttarting loop \n\n"
for ENGINE in ${SEARCHENGINES[@]};do

  for QUERY in ${QUERYS[@]}; do

    for SERVERNODE in "$@"; do

      for SHARD in ${SHARDS[@]}; do

        for RF_MULT in ${RF_MULTIPLE[@]}; do

          ######## EXP LOOP = r*s = 2(num of SERVERNODES) ##########

          RF=$(($RF_MULT*$SERVERNODE))
          # RF=$RF_MULT

        # change this to switch statement.
          if [ $ENGINE == "solr" ];then
            # zookeeper loses sight of previous collection node mapping for a single clustersize. chroot mitigates zookeeper failure when clustersize changes for an experiment. Basically, a single instance of Zookeeper can keep track of every config and cluster change for solr without failing if chroot exists to separate each clustersize collection mapping. i.e. we dont need to restart zookeeper ever.
            startSolr $SERVERNODE
          # begin_exp is going to either post to solr a new colleciton or pull down an existing one from aws
            play post_data_$SERVERNODE.yml --tags begin_exp --extra-vars "replicas=$RF shards=$SHARD clustersize=$SERVERNODE"
          #  need to restart since pulling index from aws most likely happened and solr (not zookeeper) needs to restart after that hack
            restartSolr $SERVERNODE

            play post_data_$SERVERNODE.yml --tags update_collection_configs --extra-vars "replicas=$RF shards=$SHARD clustersize=$SERVERNODE"
            sleep 2

            if [ $QUERY == "client" ]; then
              echo "waiting for solr..."
              sleep 3
              echo "restarting solrj.."
              restartSolrJ $SERVERNODE
              sleep 2
            fi
            # else it will be roundrobin

          # start elastic search
          else
            printf "staring elastic \n"
            startElastic $SERVERNODE
            sleep 5
          fi


          #  sfor solrj ... using chroot requires restart of solrj every time :/


          PROCESSES=$SERVERNODE
          SOLRNUM=$SERVERNODE
            # scale each load up to servernode size then add a load node

      # these state loops below do not require any index mods, so they are fast

          for J_MEM in ${JVM_MEM[@]}; do
            for doc_cache in ${DOC_CACHE[@]}; do
              for filter_cache in ${FILTER_CACHE[@]}; do
                for loop in ${CONTROLLOOP[@]}; do

                  STATE_SPACE="
                    \n\n
                    \n ENGINE       = $ENGINE
                    \n LB           = $QUERY
                    \n SERVERNODE   = $SERVERNODE
                    \n SHARD        = $SHARD
                    \n RF_MULT      = $RF_MULT
                    \n JVM_MEM      = $J_MEM
                    \n doc_cache    = $doc_cache
                    \n filter_cache = $filter_cache
                    \n CONTROLLOOP  = $loop
                    \n LOADSIZE     = $LOAD
                    \n CONNSCALE    = $mincon -> $maxcon
                    \n\n
                  "
                  printf "BEGINNING EXP LOOP FOR THIS STATE SPACE: $STATE_SPACE "

                  if [ "$DSTAT_SWITCH" = on ];then
                    commence_dstat "$QUERY" $RF "$SHARD" "$SOLRNUM"
                  fi

                  # vars for loop for config experiment
                  box_cores=$load_cpu_cores
                  load_start=$load_start
                  load_server_incrementer=$load_server_incrementer
                  export SOLRJ_PORT_OVERRIDE=$SOLRJ_PORT_OVERRIDE
                  printf "\n\n********** WARMING CACHE... **************\n\n"

                  if "$WARM_CACHE" == true;then
                    cd ~/projects/solrcloud;pssh -l dporte7 -h $LOADHOSTS "echo ''>traffic_gen/traffic_gen.log"
                    echo "bash runtest.sh traffic_gen words.txt --user dporte7 -rf $RF -s $SHARD -t $app_threads -d 10 -p $maxcon --solrnum $SOLRNUM --query $QUERY --loop $CONTROLLOOP --load $M_LOAD --engine $ENGINE"
                    cd ~/projects/solrcloud/tests_v1/scriptsThatRunLoadServers; bash runtest.sh traffic_gen words.txt --user dporte7 -rf $RF -s $SHARD -t $app_threads -d 10 -p $maxcon --solrnum $SOLRNUM --query $QUERY --loop $CONTROLLOOP --load $MAX_LOAD --engine $ENGINE
                  fi

                  printf "\n\n********** WARMING CACHE COMPLETE **************\n\n"

                  # this loop scales the connections on traffic servers, thus increasing load to search engines
                  for ((l=mincon; l<=maxcon; l=$((l+conincrementer))));do

                    printf "\n\n********   STARTING EXP PRELIM STEPS   ************\n\n"
                    printf "removing previous exp load script output ::: traffic_gen/traffic_gen.log \n\n"
                    cd ~/projects/solrcloud;pssh -l dporte7 -h "${LOADHOSTS}_${LOAD}" "echo ''>traffic_gen/traffic_gen.log"

                    printf "\n\n PARAMETERS TO runscript.sh:::: \n"
                    echo "\$ ./tests_v1/scriptsThatRunLoadServers/runtest.sh traffic_gen words.txt --user dporte7 -rf $RF -s $SHARD -t ${app_threads} -d 10 -p $l --solrnum $SOLRNUM --query $QUERY --loop $CONTROLLOOP --load $l --engine $ENGINE"

                    printf "\n\n\n RUNNING runscript.sh .....  \n"
                    # shellcheck disable=SC2086
                    cd ~/projects/solrcloud/tests_v1/scriptsThatRunLoadServers || exit; bash runtest.sh traffic_gen words.txt --user dporte7 -rf $RF -s $SHARD -t ${app_threads} -d 10 -p $l --solrnum $SOLRNUM --query $QUERY --loop $CONTROLLOOP --load $MAX_LOAD --engine $ENGINE
                    sleep 2

                  done

                  printf "\n\n\n ******* COMPLETED CONNECTION SCALE LOOP for $ ********** "

                  # this is the secondary loop that scales the experiemnt beyond the optimal CPU parallism

                  if [ "$DSTAT_SWITCH" = on ];then
                    for n in $ALL_NODES;do
                      ssh $USER@$n "pkill -f dstat" >/dev/null 2>&1 &
                    done
                    DSTAT_DIR="${PROJ_HOME}/rf_${RF}_s${SHARD}_solrnum${SOLRNUM}_query${QUERY}"
                    mkdir $DSTAT_DIR
                    for n in $ALL_NODES;do
                      scp -r $USER@${n}:~/*dstat.csv $DSTAT_DIR
                    done
                    mv $DSTAT_DIR "/Users/dporter/projects/solrcloud/chart/exp_records/$CHARTNAME"
                  fi

                  # next controlloop
                done
                # next filter cache
              done
              # next doc cache
            done
            # next jvm
          done

          #need to call stopsolr it here since it needs to stop this exp explicitly before running a new one

          stopElastic $SERVERNODE
          stopSolr $SERVERNODE
          play post_data_$SERVERNODE.yml --tags aws_exp_reset --extra-vars "replicas=$RF shards=$SHARD clustersize=$SERVERNODE"
          archivePrev $CHARTNAME $SERVERNODE $QUERY $RF $SHARD

          # next RF
        done
        # next shard
      done
      # next servernode
    done
    python3 /Users/dporter/projects/solrcloud/chart/chart_all_full.py $QUERY $CHARTNAME
    python3 /Users/dporter/projects/solrcloud/chart/chartit_error_bars.py $QUERY $CHARTNAME
    zip -r /Users/dporter/projects/solrcloud/chart/exp_html_out/_$CHARTNAME/exp_zip.zip /Users/dporter/projects/solrcloud/chart/exp_records/$CHARTNAME
    # next query
  done
  # next searchengine
done
