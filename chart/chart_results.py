import os
import sys
from datetime import datetime
import time
import gzip

# args = $THREADS $DURATION $CON $QUERY $LOOP $PROCESSES

def main(query,clustersize,codename):
    proj_home = "~/projects/sapa"
    print('RUNNING chart results')
    QPS = []
    median_lat = []
    tail_lat = []
    dirs = os.popen('ls '+proj_home+'/benchmark_scripts/tmp/tmp | grep clustersize'+clustersize).read()
    dirs = dirs.split('\n')
    dirs.pop()

    try:
        os.makedirs('//chart/totals')
    except FileExistsError:
        print("file exists\n\n\n")
     # directory already exists
        pass

# this is for total file
    fm = open('/Users/dporter/projects/sapa/chart/totals/total_'+clustersize+query+'_'+codename+'.csv', "w+")
    fm.write('parallel_requests,QPS,median_lat,tail_lat,clustersize,query,rfshards\n')

    for d in dirs:
        print(d)
        files = os.popen('ls '+proj_home+'/benchmark_scripts/tmp/tmp/'+d+' | grep '+query+ '| grep clustersize'+clustersize ).read()
        print(files)
        files = files.split('\n')
        files.pop()
        print(files)
        try:
            os.makedirs('/Users/dporter/projects/sapa/chart/'+d+'/query'+query)
        except FileExistsError:
            print("file exists\n\n\n")
            # directory already exists
            pass


        # add table headers
        fp = open('/Users/dporter/projects/sapa/chart/'+d+'/query'+query+'/'+d+'query'+query+'_chartdata_'+codename+'.csv', "a+")
        fp.write('parallel_requests,QPS,median_lat,tail_lat,clustersize,query,rfshards\n')
        fp.close()


        fm = open('/Users/dporter/projects/sapa/chart/totals/total_'+clustersize+query+'_'+codename+'.csv', "a+")

        
        for exp_output in files:
            f = open("/Users/dporter/projects/sapa/benchmark_scripts/tmp/tmp/"+d+'/'+exp_output, 'r')
            data = f.readline()
            f.close()
            # dont need to write this file anymore
            # fp = open('/Users/dporter/projects/sapa/chart/'+d+'/query'+query+'/'+d+'query'+query+'_chartdata_'+codename+'.csv', "a+")
            # fp.write(data+','+clustersize+','+query+','+d[:8]+'\n')
            # fp.close()
            fm.write(data+','+clustersize+','+query+','+d[:8]+'\n')

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
    main(sys.argv[1],sys.argv[2],sys.argv[3])
    )
