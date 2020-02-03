import os
import sys
from datetime import datetime
import time
import gzip

# args = $THREADS $DURATION $CON $QUERY $LOOP $PROCESSES

def main(query, codename):
    proj_home = "~/projects/sapa"
    print('RUNNING compile totals')
    QPS = []
    median_lat = []
    tail_lat = []
    dirs = os.popen('ls '+proj_home+'/chart/totals | grep '+codename).read()
    print(dirs)
    dirs = dirs.split('\n')
    dirs.pop()
    final_resting_place='/Users/dporter/projects/sapa/chart/totals/cluster_totals'
    try:
        os.makedirs(final_resting_place)
    except FileExistsError:
        print("file exists\n\n\n")
     # directory already exists
        pass

# this is for total file
    fm = open(final_resting_place'/all_cluster_'+query+'_'+codename+'.csv', "w+")
    fm.write('parallel_requests,QPS,median_lat,P95(ms),clustersize,query,rfshards\n')

    for d in dirs:
        print(d)
        with open('/Users/dporter/projects/sapa/chart/totals/'+d, "r") as f_in:
            # flush first line
            f_in.readline()
            for line in f_in:
                fm.write(line)

    fm.close()


if __name__ == "__main__":
    arg_dict = {}
    # keys = [sys.argv[x*2] for x in range(1,len(sys.argv[1:])/2)]
    # values = [sys.argv[x*2] for x in range(1,len(sys.argv[1:])/2)]
    # print(keys)
    # c = sys.argv[1]
    # q = sys.argv[2]
    # duration = sys.argv[5]
    # replicas = sys.argv[7]
    # query = sys.argv[9]
    # loop = sys.argv[11]
    # shards = sys.argv[13]
    # solrnum = sys.argv[15]
    sys.exit(
    main(sys.argv[1],sys.argv[2])
    )
