import urllib3
import http.client
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

def add_conn(main_args):
    conn = http.client.HTTPConnection(main_args.host,main_args.port,timeout=20)

    return conn

def get_urls(test_param, terms, shards, replicas, clustersize):
    indexed_fields = ["reviewText","summary"]
    prefix_url = "%s" % (test_param.base_url)
    urls = []
    # port 8983 is a benchamrk using direct solr instance queries
    if test_param.port == 8983:
        r = random.randint(1,len(terms))
        for i in range( test_param.max_iters ):
            i+=r
            term1 = terms[i%len(terms)].rstrip()
            term2 = terms[(i+r)%len(terms)].rstrip()
            field = indexed_fields[i%len(indexed_fields)]
            q = '/solr/reviews_rf'+str(replicas)+'_s'+str(shards)+'_clustersize'+str(clustersize)+'/select?q='+field+'%3A'+term1+'%20'+term2+'&rows=10'
            urls.append("%s%s" % (prefix_url, q))

    else:
        # port 9111 flow -> via solrJ
        # introduce randomness for each thread
        r = random.randint(1,len(terms))
        for i in range( test_param.max_iters ):
            i+=r
            term1 = terms[i%len(terms)].rstrip()
            term2 = terms[(i+r)%len(terms)].rstrip()
            field = indexed_fields[i%len(indexed_fields)]
            # q = 'solr/reviews_rf2q/select?q='+field+'%3A'+term+'&rows=10'
            urls.append( "/%s/%s/%s/%s" % (field, term1, term2, 'reviews_rf'+str(replicas)+'_s'+str(shards)+'_clustersize'+str(clustersize)))

    return urls

def get_terms():
    f = open('../words.txt', 'r')
    terms = f.readlines()
    random.shuffle(terms)
    f.close()
    return terms


def create_threadargs(main_args,start_flag, stop_flag, gauss_mean, gauss_std, poisson_lam):
    """ returns  [ test_param, thread_stats]"""

    base_url = "http://%s:%s" % ( main_args.host, main_args.port)
    # return_list = queue.Queue()
    # return_list = ''
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

    thread_args = [ test_param, thread_stats]
    return thread_args
