import urllib3
from testmodes import *
from clparsing import *
from benchstats import *

#returns a list passed to the threads to append (name,urls[i],req_start,req_finish,fct) for each request

thread_stats = ThreadStats()

def add_pool(main_args):
    http_pool = urllib3.connectionpool.HTTPConnectionPool( main_args.host,
                                                          port=main_args.port,
                                                          maxsize=(main_args.conns),
                                                          block=False)
    return http_pool

def create_threadargs(main_args,start_flag, stop_flag, gauss_mean, gauss_std, poisson_lam):
    """ returns 5-tuple -> ( test_param, thread_stats, start_flag, stop_flag, return_list ) """

    base_url = "http://%s:%s" % ( main_args.host, main_args.port)
    return_list = queue.Queue()

    # import pdb; pdb.set_trace()

    thread_stats.init_thread_stats(main_args.threads)

    print(main_args.host, main_args.port)
    # header = {'Connection':'Close'}

    if main_args.test_type == "size":
        target = size_based_test
        test_param = TestParam( host=main_args.host, port=main_args.port, threads=main_args.threads,
                                base_url=base_url, conns=main_args.conns, rand_req=main_args.rand_req,
                                max_rand_obj=main_args.max_rand_obj, req_dist=main_args.req_dist,
                                gauss_mean=gauss_mean, gauss_std=gauss_std, poisson_lam=poisson_lam )
    else:
        target = duration_based_test
        test_param = TestParam( host=main_args.host, port=main_args.port, threads=main_args.threads,
                                base_url=base_url, ramp=main_args.ramp, loop=main_args.loop,
                                duration=main_args.duration, conns=main_args.conns, rand_req=main_args.rand_req,
                                max_rand_obj=main_args.max_rand_obj, req_dist=main_args.req_dist,
                                gauss_mean=gauss_mean, gauss_std=gauss_std, poisson_lam=poisson_lam )

    thread_args = [ test_param, thread_stats, start_flag, stop_flag, return_list ]
    return thread_args
