#!/bin/bash


# load sugar
source ${SAPA_HOME}/benchmark_scripts/utils/exp_scale_loop_params.sh
source ${SAPA_HOME}/benchmark_scripts/utils/utils.sh
source ${SAPA_HOME}/benchmark_scripts/utils/exp_helpers.sh

#set -e
#if [ $DOCKER = yes ];then
#fi
#set -x
export DOCKER=$DOCKER

if [ $DOCKER = yes ];then
  echo "wooooo"
  alias play=solo_party
fi




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
EXP_HOME=${SAPA_HOME}/chart/exp_records
# mov prev record outside project perview (data size too large)
echo "moving previous records to long term data store"
mv $EXP_HOME/* ~/projects/saga_records/
mkdir $EXP_HOME/$CHARTNAME

# ARCHIVE PREVIOUS EXPs (this shouldnt archive anything if done correctly so first wipe dir)

mkdir -p $SAPA_HOME/benchmark_scripts/tmp/proc_results
rm -rf $SAPA_HOME/benchmark_scripts/tmp/proc_results/*
rm -rf $SAPA_HOME/benchmark_scripts/tmp/exp_results/*


if [ $copy_python_scripts == "yes" ]; then
  echo 'Copying python scripts and search terms to load machines'
  play update_loadscripts.yml --extra-vars "scripts_path=$LOAD_SCRIPTS terms_path=$TERMS"
fi

LOADHOSTS="$SAPA_HOME/utils/ssh_files/pssh_traffic_node_file"

printf "\n\n starting loop \n\n"
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
            if [ $keep_solr_state = false ]
              then
                play post_data_$SERVERNODE.yml --tags begin_exp --extra-vars "replicas=$RF shards=$SHARD clustersize=$SERVERNODE"
          #  need to restart since pulling index from aws most likely happened and solr (not zookeeper) needs to restart after that hack
                restartSolr $SERVERNODE
            fi

            play post_data_$SERVERNODE.yml --tags update_collection_configs --extra-vars "replicas=$RF shards=$SHARD clustersize=$SERVERNODE"
            sleep 2

          #  for solrj ... using chroot requires restart of solrj every time :/
#            if [ $QUERY == "client" ]; then
#              sleep 3
#              restartSolrJ $SERVERNODE
#              sleep 2
#            fi
            # else it will be roundrobin
          else
            startElastic $SERVERNODE
            sleep 5
          fi



          PROCESSES=$SERVERNODE
          SOLRNUM=$SERVERNODE

          for J_MEM in ${JVM_MEM[@]}; do
            for doc_cache in ${DOC_CACHE[@]}; do
              for filter_cache in ${FILTER_CACHE[@]}; do
                for loop in ${CONTROLLOOP[@]}; do

                  STATE_SPACE="
                    \n\n
                     ENGINE       = $ENGINE
                     LB           = $QUERY
                     SERVERNODE   = $SERVERNODE
                     SHARD        = $SHARD
                     RF_MULT      = $RF_MULT
                     JVM_MEM      = $J_MEM
                     doc_cache    = $doc_cache
                     filter_cache = $filter_cache
                     CONTROLLOOP  = $loop
                     LOADSIZE     = $LOAD
                     CONNSCALE    = $mincon -> $maxcon
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
                    cd ~/projects/sapa;pssh -l $USER -h $LOADHOSTS "echo ''>traffic_gen/traffic_gen.log"
                    echo "bash runtest.sh traffic_gen words.txt --user $USER -rf $RF -s $SHARD -t $app_threads -d 10 -p $maxcon --solrnum $SOLRNUM --query $QUERY --loop $CONTROLLOOP --load $M_LOAD --engine $ENGINE"
                    cd ~/projects/sapa/benchmark_scripts/scriptsThatRunLoadServers; bash runtest.sh traffic_gen words.txt --user $USER -rf $RF -s $SHARD -t $app_threads -d 10 -p $maxcon --solrnum $SOLRNUM --query $QUERY --loop $CONTROLLOOP --load $MAX_LOAD --engine $ENGINE
                  fi

                  printf "\n\n********** WARMING CACHE COMPLETE **************\n\n"

                  # this loop scales the connections on traffic servers, thus increasing load to search engines
                  for ((l=mincon; l<=maxcon; l=$((l+conincrementer))));do

                    printf "\n\n********   STARTING EXP PRELIM STEPS   ************\n\n"
                    printf "removing previous exp load script output ::: traffic_gen/traffic_gen.log \n\n"
                    cd ~/projects/sapa;pssh -l $USER -h "${LOADHOSTS}_${LOAD}" "echo ''>traffic_gen/traffic_gen.log"

                    printf "\n\n PARAMETERS TO runscript.sh:::: \n"
                    echo "\$ ./benchmark_scripts/scriptsThatRunLoadServers/runtest.sh traffic_gen words.txt --user $USER -rf $RF -s $SHARD -t ${app_threads} -d 10 -p $l --solrnum $SOLRNUM --query $QUERY --loop $CONTROLLOOP --load $l --engine $ENGINE"

                    printf "\n\n\n RUNNING runscript.sh .....  \n"
                    # shellcheck disable=SC2086
                    cd ~/projects/sapa/benchmark_scripts/scriptsThatRunLoadServers || exit; bash runtest.sh traffic_gen words.txt --user $USER -rf $RF -s $SHARD -t ${app_threads} -d 10 -p $l --solrnum $SOLRNUM --query $QUERY --loop $CONTROLLOOP --load $MAX_LOAD --engine $ENGINE
                    sleep 2

                  done

                  printf "\n\n\n ******* COMPLETED CONNECTION SCALE LOOP for $ ********** "

                  # this is the secondary loop that scales the experiemnt beyond the optimal CPU parallism

                  if [ "$DSTAT_SWITCH" = on ];then
                    for n in $ALL_NODES;do
                      ssh $USER@$n "pkill -f dstat" >/dev/null 2>&1 &
                    done
                    DSTAT_DIR="${SAPA_HOME}/rf_${RF}_s${SHARD}_solrnum${SOLRNUM}_query${QUERY}"
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

          if [ $ENGINE = "solr" ]
          then
            stopSolr $SERVERNODE
          else
            stopElastic $SERVERNODE
          fi

#          play post_data_$SERVERNODE.yml --tags aws_exp_reset --extra-vars "replicas=$RF shards=$SHARD clustersize=$SERVERNODE"
          archivePrev $CHARTNAME $SERVERNODE $QUERY $RF $SHARD

          # next RF
        done
        # next shard
      done
      # next servernode
    done

    # next query
  done
  # next searchengine
done
export SAPA_HOME=$SAPA_HOME
python3 ${SAPA_HOME}/chart/chart_all_full.py $CHARTNAME
python3 ${SAPA_HOME}/chart/chartit_error_bars.py $CHARTNAME
zip -r ${SAPA_HOME}/chart/exp_html_out/_$CHARTNAME/exp_zip.zip ${SAPA_HOME}/chart/exp_records/$CHARTNAME
