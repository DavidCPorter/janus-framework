import os
import sys
from datetime import datetime
import time
import gzip

print(os.environ["PROJ_HOME"])
proj_home="/Users/dporter/projects/sapa"

# args = $THREADS $DURATION $CON $QUERY $LOOP $PROCESSES

def main(p, t, d, rf, q, l, shards, solrnum, loadnodes, instances=None):
    print('\n\nRUNNING readresults.py ::: ARGS == proc=%s threads=%s duration=%s' % (p, t, d))
    QPS = []
    median_lat = []
    tail_lat = []
    ninenine = []
    ninezero = []
    fct_total_string = ''
    files = os.popen('ls ' + proj_home + '/benchmark_scripts/tmp/proc_results | grep ' + q).read()
    files = files.split('\n')
    processes = float(len(files))
    print("num output files copied from remote == %s | should == %s (num procs passsed in to this script)" % (
    str(processes * int(t)), p))
    files.pop()
    for file in files:
        f = open(proj_home+"/benchmark_scripts/tmp/proc_results/" + file, 'r')
        #
        result_page = f.readlines()
        # read first line which is the request total
        ninenine.append(result_page[1])
        ninezero.append(result_page[3])
        QPS.append(result_page[5])
        median_lat.append(result_page[7])
        tail_lat.append(result_page[9])
        fct_total_string = fct_total_string + "," + str(result_page[17])

        f.close()

    sum_queries_per_second = 0.0
    for i in QPS:
        sum_queries_per_second += float(i)

    sum_median_lat = 0
    for i in median_lat:
        sum_median_lat += float(i)

    sum_tail_lat = 0
    for i in tail_lat:
        sum_tail_lat += float(i)

    sum_ninenine_lat = 0
    for i in ninenine:
        sum_ninenine_lat += float(i)

    sum_ninezero_lat = 0
    for i in ninezero:
        sum_ninezero_lat += float(i)

    # fct_total_string=fct_total_string.replace(' ','')
    fct_total_string = fct_total_string.replace('\n', '')
    fct_total_string = fct_total_string.replace('[', '')
    fct_total_string = fct_total_string.replace(']', '')
    fct_total_string = fct_total_string.replace(' ', '')

    fct_total_list = fct_total_string.split(",")
    fct_total_list = [float(i) for i in fct_total_list[1:]]

    total_qps = round(sum_queries_per_second, 2)
    total_med_lat = float(sum_median_lat / float(processes))
    total_tail_lat = float(sum_tail_lat / float(processes))
    total_ninenine_lat = float(sum_ninenine_lat / float(processes))
    total_ninezero_lat = float(sum_ninezero_lat / float(processes))

    fct_total_list.sort()
    fct_len = len(fct_total_list)
    incrementer_95 = int(fct_len / 20)
    # incrementer_50=int(fct_len/2)
    # incrementer_90=int(fct_len/10)
    # incrementer_99=int(fct_len/100)
    # gonna make a list [0,5,10,... 100] and save to text file and that will be the data read into the CDF chart

    p_95 = [fct_total_list[incrementer_95 * x] for x in range(0, 20)]
    # p_95=[fct_total_list[incrementer*x] for x in range(0,20)]
    # fct_percentiles_95=[fct_total_list[incrementer*x] for x in range(0,20)]
    # fct_percentiles_95=[fct_total_list[incrementer*x] for x in range(0,20)]

    # simply to denote this is a single node cluster record
    if instances != "0":
        print("SINGLE NODE READRESULTS ")
        solrnum = '9' + str(solrnum)

    try:
        os.makedirs(
            '/Users/dporter/projects/sapa/benchmark_scripts/tmp/exp_results/rf' + rf + '_s' + shards + '__clustersize' + solrnum)
    except FileExistsError:
        print("file exists\n\n\n")
        # directory already exists
        pass

    fp = open(
        proj_home+'/benchmark_scripts/tmp/exp_results/rf' + rf + '_s' + shards + '__clustersize' + solrnum + '/rf' + rf + '_s' + shards + '__clustersize' + solrnum + "::query=" + q + "::proc=" + p + "::threads=" + t + "::dur=" + d + ":::TIME->" + datetime.today().strftime(
            '%Y-%m-%d-%H:%M:%S'), 'w+')
    # for charting
    #  writes -> total outstanding requests, QPS, median LAT, Tail LAT
    # 2*2 is simply compensating for the fact that I don't want to change the driver code to generate the correct number here - so i'm just hardcoding the outstanding requests position with p*2*2 b/c thats the right number.
    fp.write(p + ',' + str(total_qps) + ',' + str(total_med_lat) + ',' + str(total_ninezero_lat) + "," + str(
        total_tail_lat) + "," + str(total_ninenine_lat) + '\n')
    fp.write(str(p_95))
    # fp.write(str(p_90))
    # fp.write(str(p_50))
    # fp.write(str(p_99))

    fp.close()
    print("READRESULTS SCRIPT COMPLETE\n\n\n")


if __name__ == "__main__":
    arg_dict = {}
    # keys = [sys.argv[x*2] for x in range(1,len(sys.argv[1:])/2)]
    # values = [sys.argv[x*2] for x in range(1,len(sys.argv[1:])/2)]
    # print(keys)
    processes = sys.argv[1]
    threads = sys.argv[3]
    duration = sys.argv[5]
    replicas = sys.argv[7]
    query = sys.argv[9]
    loop = sys.argv[11]
    shards = sys.argv[13]
    solrnum = sys.argv[15]
    loadnodes = sys.argv[16]
    instances = sys.argv[18]

    sys.exit(
        main(processes, threads, duration, replicas, query, loop, shards, solrnum, loadnodes, instances)
    )
