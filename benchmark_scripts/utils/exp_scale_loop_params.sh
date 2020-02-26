#########  EXP PARAMS
configure_engines=false
keep_solr_state=false
keep_elastic_state=false
# constraint -> shards are 1, 2, or 4
SEARCHENGINES=(  "solr" )
DSTAT_SWITCH=off
copy_python_scripts="no"
SHARDS=( 1 2 )
# client == solrj, or elastic client api
QUERYS=( "roundrobin" )
# RF_MULTIPLE e.g. if == 1, then replicas == clustersize
RF_MULTIPLE=( 1 2 )
load_start=1
LOAD=8
export MAX_LOAD=8
instances=0
export SOLRJ_PORT_OVERRIDE=true
load_server_incrementer=1
EXTRA_ITERS=0
CONTROLLOOP=( "closed" )
JVM_MEM=( 9 )
DOC_CACHE=( 1 )
FILTER_CACHE=( 1 )
mincon=1
maxcon=341
conincrementer=20
WARM_CACHE=true
DOCKER=no
export USER=dporte7

#########  PARAMS END

setLoadArray (){

	load_seq=($( seq 1 $MAX_LOAD ))
	# shellcheck disable=SC2199
	# shellcheck disable=SC2076
	if [[ ! " ${load_seq[@]} " =~ " $1 " ]]; then
			echo "NOT VALID LOAD PARAMETER LOAD ARRAY"
			return
	else
		case "$1" in
		*)
			tmp=($(echo $ALL_LOAD))
			echo ${tmp[@]:0:$1}
			;;
		esac
	fi
}


export -f setLoadArray

# this function is stupid now but whatever

getLoadNum (){
	load_seq=($( seq 1 $MAX_LOAD ))
	# shellcheck disable=SC2199
	# shellcheck disable=SC2076
	if [[ ! " ${load_seq[@]} " =~ " $1 " ]]; then
	    # whatever you want to do when arr contains value
			echo "NOT VALID LOAD PARAMETER LOAD NUM"
			return
	else
		case "$1" in
		*)
			echo "$1"
			;;
		esac

	fi

}
export -f getLoadNum
