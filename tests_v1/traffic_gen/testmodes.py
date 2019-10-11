#!/usr/bin/python
# from __future__ import with_statement
import os
import sys
import time
import random
import logging
import threading
import numpy as np



def duration_based_test( test_param, thread_stats, conn, urls, start_flag, stop_flag, name, fct_list ):
    """ Duration-based test to be carried out by each thread """
    sys.stdout.flush()
    j = int( name )
    # np.random.seed( j )

    # Pre-stage requests and wait times
    # sleep_times = [test_param.gauss_mean]
    # if test_param.req_dist == "gauss":
    #     sleep_times = np.abs( np.random.normal(loc=test_param.gauss_mean,
    #                                            scale=test_param.gauss_std, size=test_param.max_iters) )
    # elif test_param.req_dist == "poisson":
    #     sleep_times = np.random.poisson( lam=test_param.poisson_lam, size=test_param.max_iters )

    # [(fct, timestamp), ...]
    # fct_stamps = []
    lat = 0
    responses = 0
    fct_return = []

    # Wait for start signal
    logging.debug( "Waiting for start event %s" % name )
    event_start = start_flag.wait()
    logging.debug( "Event %s: Starting" , event_start )
    start = time.time()

    # wait ramp time
    # while (time.time() - start < test_param.ramp):
    #     route = urls[random.randint(1,4990)]
    #     print(route)
    #     conn.request( "GET", route , headers = {'Connection':'keep-alive'})
    #     resp = conn.getresponse()
    #     r = resp.read()
    #     continue
    # i = 0
    while not stop_flag.is_set():

        req_start = time.time()
        route = urls[random.randint(1,4990)]
        try:
            conn.request( "GET", route , headers = {'Connection':'keep-alive'})
            resp = conn.getresponse()
            print(res)

            r = resp.read()
            print(r)
            req_finish = time.time()
            fct = req_finish - req_start
            # log 20% of queries
            # if responses%5 == 0:
            fct_return.append(fct)
            responses += 1
            j+=1

        except Exception as e:
            logging.debug( "Error while requesting: %s - %s - %s" % (str(j%test_param.max_iters), route, str(e)) )
            # if dt > test_param.ramp:
            #     thread_stats.errors[j] += 1
    if test_param.port != 8983:
        conn.send(b'bye\n')
    conn.close()
    fct_return.sort()
    length = len(fct_return)
    # get index for 90% tail latency
    tail_nine_index = int(length/10)
    # get 95% tail_index
    tail_nine_five_index = int(length/20)

    median_index = int(length/2)

    # log median latency
    median = fct_return[median_index]
    # log 90->100% latency numbers
    tail_nine_list = fct_return[-tail_nine_index:]
    # log 95% tail latency
    tail = fct_return[-tail_nine_five_index]


    # throughput in qps
    thread_stats.responses[int(name)] = responses/test_param.duration
    thread_stats.requests[int(name)] = tail
    thread_stats.avg_lat[int(name)] = median
    fct_list.append((median,tail,tail_nine_list))
    logging.debug( "Exiting" )

    return

def size_based_test( test_param, thread_stats, start_flag, stop_flag ):
    """ Size-based test to be carried out by each thread """
    # terms = ["good","bad","5","stars","best","horrible","incredible","terrific","garbage"]
    # indexed_fields = ["reviewerName","reviewText","overall ","summary"]
    # name = threading.currentThread().getName()
    # j = int( name )
    # prefix_url = "%s/" % (test_param.base_url)
    # np.random.seed( j )
    # http_pool = test_param.http_pool
    #
    # # Pre-stage requests and wait times
    # sleep_times = [test_param.gauss_mean]
    # if test_param.req_dist == "gauss":
    #     sleep_times = np.abs( np.random.normal(loc=test_param.gauss_mean,
    #                                            scale=test_param.gauss_std, size=test_param.max_iters) )
    # elif test_param.req_dist == "poisson":
    #     sleep_times = np.random.poisson( lam=test_param.poisson_lam, size=test_param.max_iters )
    # urls = []
    #
    # if test_param.rand_req:
    #     for i in range( test_param.max_iters ):
    #         #add random query here
    #         term = terms[i%len(terms)]
    #         field = indexed_fields[i%len(indexed_fields)]
    #         q = 'solr/reviews_rf2q/select?q='+field+'%3A'+term+'&rows=10'
    #         urls.append( "%s%s" % (prefix_url, q))
    # else:
    #     for i in range( test_param.max_iters ):
    #         term = terms[i%len(terms)]
    #         field = indexed_fields[i%len(indexed_fields)]
    #         q = 'solr/reviews_rf2q/select?q='+field+'%3A'+term+'&rows=10'
    #         urls.append( "%s%s" % (prefix_url, q))
    # # Wait for start signal
    # with start_flag:
    #     start_flag.wait()
    #     logging.debug( "Starting" )
    #
    # i = 0
    # while not stop_flag.isSet():
    #     # Wait before making next request
    #     time.sleep( sleep_times[i] )
    #     req_start = time.time()
    #     try:
    #         # rsp = http_pool.request( "GET", urls[i%test_param.max_iters] )
    #         rsp = http_pool.request( "GET", "/good/" )
    #
    #         thread_stats.avg_lat[j] += time.time() - req_start
    #         thread_stats.responses[j] += 1
    #         thread_stats.byte_count[j] += len( rsp.data )
    #     except Exception as e:
    #         logging.debug( "Error while requesting: %s - %s" % (urls[i], str(e)) )
    #         thread_stats.errors[j] += 1
    #     i += 1
    # thread_stats.requests[j] = http_pool.num_requests
    # if thread_stats.requests[j] > 0:
    #     thread_stats.avg_lat[j] = thread_stats.avg_lat[j] / float( thread_stats.requests[j] )
    # logging.debug( "Exiting" )

    return
