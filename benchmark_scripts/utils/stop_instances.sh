#!/bin/bash

containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}


if [ "$#" -gt 1 ]; then
  echo "Usage: stop_instances.sh [ instance size]"
  echo " ERROR : TOO MANY ARGUMENTS"
  echo " Example -> bash scale.sh 2 4 8"
	exit
fi

if [ "$#" -eq 0 ]; then
  echo " running stop instacnes for 8 instances by default "
  INSTANCES=8
else
  INSTANCES=$1
fi

accepted_instances=( 2 4 8 )


# load sugar
source ${SAPA_HOME}/benchmark_scripts/utils/utils.sh
shopt -s expand_aliases

SHARDS=( 1 2 4 )
T1=1
STEP=1
TN=10
CLOUDHOME="/users/dporte7"


##### restart zoo and solr ######

echo "deleting previous collections"
delete_collections 9911
wait $!
sleep 5


for i in `seq $INSTANCES`;do
  printf "\n STOPPING SOLR INSTANCES:"
  echo "node__$i/solr -p 99$i$i"
  nohup pssh -h ~/projects/sapa/ssh_files/solr_single_node -l dporte7 -P "bash ~/solr-8_3/solr/bin/solr stop -cloud -q -s ~/node__$i/solr -p 99$i$i -Dhost=10.10.1.1" &
done
sleep 5
echo "STOPPED THE ANCILLARY INSTANCES"

echo "removing old node_ dirs on server1"
pssh -h ~/projects/sapa/ssh_files/solr_single_node -l dporte7 -P "rm -rf $CLOUDHOME/node_*"
######## END ##########
