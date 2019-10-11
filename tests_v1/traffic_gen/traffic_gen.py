#!/usr/bin/python
# from __future__ import with_statement
import os
import sys
import time
import random
import logging
import argparse
import threading
import numpy as np
import queue
import copy
from testmodes import *
from clparsing import *
from benchstats import *
from threadargs import *

def get_args(ta):
    x = copy.copy(ta)
    return x

def main( ):
    """ Main function """
    # get args
    print(sys.argv[1:])
    main_args = parse_commandline(sys.argv[1:])
    if main_args.query == 'direct':
        if int(main_args.clustersize) > 1:
            main_args.port = 8983
        elif (int(main_args.port) == 0 ):
            main_args.port = 8983
        else:
            main_args.port = 9990


    elif main_args.query == 'direct' and int(main_args.clustersize) > 1:
        main_args.port = 8983

    elif main_args.query == 'solrj':
        main_args.host = '127.0.0.1'

    else:
        # for single server mode host and ports are good
        pass

# config for closed loop -> throughput
    if main_args.loop == 'closed':
        main_args.threads = 1
        main_args.conns = 1


    # Setup logging
    logging.basicConfig( level=logging.DEBUG,
                         format="[%(threadName)s]: [%(asctime)-15s] - %(message)s",
                         filename="traffic_gen.log" )
    logging.getLogger( "urllib3" ).setLevel( logging.WARNING )

    print("HOST=%s\nPORT=%s\nQUERY=%s\nThreads = %s\n" % (main_args.host, main_args.port, main_args.query, main_args.threads))

    # objects to sync start time for threads
    start_flag = threading.Event()
    stop_flag = threading.Event()

    # randomized traffic params
    gauss_mean = 1.0 / 16384.0
    gauss_std = 0.5
    poisson_lam = gauss_mean

    # returns tuple with thread args
    # """ returns a list -> [ test_param, thread_stats] """
    # return_list and the flags are main_thread lock-enabled so cannot be copied so have been removed
    thread_args = create_threadargs(main_args, start_flag, stop_flag, gauss_mean, gauss_std, poisson_lam)

    # ******* START TEST ********
    # set test function
    target = size_based_test if main_args.test_type == "size" else duration_based_test

    terms = get_terms()
    fct_list_main = []

    # Spawn threads
    for i in range( main_args.threads ):
        next_name = "%03d" % ( i )

        # makes copy of thread_args
        ta = get_args(thread_args)
        # preload queries into list
        urls = get_urls(ta[0], terms, main_args.shards, main_args.replicas, main_args.clustersize)
        # create http for each thread
        conn = add_conn(main_args)
        # combine arguments
        ta.append(conn)
        ta.append(urls)
        ta.append(start_flag)
        ta.append(stop_flag)
        ta.append(next_name)
        ta.append(fct_list_main)
        next_thread = threading.Thread( name=next_name,
                                        target=target,
                                        args=tuple(ta)
                                      )
        next_thread.start()


    init_interval = 5
    logging.debug( "Waiting %d s for %d threads to initialize" % (init_interval, main_args.threads) )
    time.sleep( init_interval )
    logging.debug( "Signaling threads to start test" )

    # start threads
    start_flag.set()

    # Add ramp time

    # Wait for test completion
    start = time.time()
    if main_args.test_type == "duration":
        sleep_time = main_args.ramp + main_args.duration
        logging.debug( "Waiting %d s for test to complete" % (sleep_time) )
        time.sleep ( sleep_time )
    else:
        logging.debug( "Waiting for %d B to be requested for test to complete" % (main_args.transfer_size) )
        sleep_time = gauss_mean * 10.0
        if main_args.req_dist == "poisson":
            sleep_time = poisson_lam * 10.0
        while np.sum(thread_stats.byte_count) < main_args.transfer_size:
            time.sleep( sleep_time )
    stop_flag.set()
    # global thread_stats
    thread_stats.duration = time.time() - start
    logging.debug( "Test completed" )

    # wait for slow requests to finish
    time.sleep(5)

    # Join on threads
    main_thread = threading.current_thread()
    for next_thread in threading.enumerate():
        if next_thread is not main_thread:
            next_thread.join( )

    # Calculate statistics
    print(thread_stats.responses)
    web_stats = calc_web_stats( main_args, thread_stats )
    # print(web_stats)
    web_stats = convert_units( web_stats )

    # Save statistics to CSV file
    if main_args.query == 'direct':
        csv_file = os.path.join( main_args.output_dir, "http_benchmark_direct"+str(random.randint(0,99999999))+"_"+str(main_args.host)+".csv" )
    else:
        csv_file = os.path.join( main_args.output_dir, "http_benchmark_solrj"+str(random.randint(0,999999))+"_"+str(main_args.port)+".csv" )
# threadargs[4] = return_list
    write_csv( csv_file, web_stats, main_args, fct_list_main)
    logging.debug( "Wrote %s" % (csv_file) )


    return 0

if __name__ == "__main__":
    sys.exit( main() )
