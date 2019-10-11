import pandas as pd
import plotly.express as px
import os
import sys
from datetime import datetime
import time
import gzip
import plotly


def display_chart(query,clustersize,codename):

    df = pd.read_csv('/Users/dporter/projects/solrcloud/chart/totals/total_'+clustersize+query+'_'+codename+'.csv')
    QPS = px.scatter(df, x = 'parallel_requests', y = 'QPS', color='rfshards', title=clustersize+" solr nodes using loadbalancer_type->"+query)
    tail = px.scatter(df, x = 'parallel_requests', y = 'tail_lat', color='rfshards',title=clustersize+" solr nodes using loadbalancer_type->"+query)
    plotly.offline.plot(QPS, filename=query+clustersize+'QPS.html')
    plotly.offline.plot(tail, filename=query+clustersize+'tail.html')
    return

def display_chart_scaling(query,clustersize,codename):

    df = pd.read_csv('/Users/dporter/projects/solrcloud/chart/totals/total_'+clustersize+query+'_'+codename+'.csv')
    QPS = px.scatter(df, x = 'clustersize', y = 'QPS', color='rfshards', title=clustersize+" solr nodes using loadbalancer_type->"+query)
    tail = px.scatter(df, x = 'clustersize', y = 'tail_lat', color='rfshards',title=clustersize+" solr nodes using loadbalancer_type->"+query)
    plotly.offline.plot(QPS, filename=query+clustersize+'QPS.html')
    plotly.offline.plot(tail, filename=query+clustersize+'tail.html')
	#fig1.show()
    #fig2.show()

    return


if __name__ == "__main__":
    sys.exit(
    display_chart(sys.argv[1],sys.argv[2],sys.argv[3])
    )
