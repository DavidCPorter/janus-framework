#########  EXP PARAMS

# constraint -> shards are 1, 2, or 4
SEARCHENGINES="elastic"
DSTAT_SWITCH=off
copy_python_scripts="no"
SHARDS=( 1 )
# client == solrj, or elastic client api
QUERYS=( "client" )
RF_MULTIPLE=( 1 )
load_start=1
LOAD=1
export MAX_LOAD=1
instances=0
export SOLRJ_PORT_OVERRIDE=true
load_server_incrementer=1
EXTRA_ITERS=0
CONTROLLOOP=( "closed" )
JVM_MEM=( 1 )
DOC_CACHE=( 1 )
FILTER_CACHE=( 1 )
mincon=1
maxcon=10
conincrementer=2
WARM_CACHE=false
DOCKER=yes
export USER=sapauser


#########  PARAMS END

setLoadArray (){
	load_seq=($( seq 1 $MAX_LOAD ))
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
