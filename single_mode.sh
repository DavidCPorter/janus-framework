#!/bin/bash
# this file spins up new solr instances on a sinlge server
# pssh -l dporte7 -h ~/projects/solrcloud/ssh_files/solr_single_node "cp ~/solr-8_0/solr/server/solr/solr.xml nodeTwo; cp ~/solr-8_0/solr/server/solr/solr.xml nodeThree;"
# any parameters passed into the start here will append to the solr.in.sh script so effectively override the variables which is what we want in this case i.e. we only need to add home and port params.
pssh -h ~/projects/solrcloud/ssh_files/solr_single_node -l dporte7 -P "bash ~/solr-8_0/solr/bin/solr stop -cloud -q -s ~/nodeTwo/solr -p 9990 -Dhost=10.10.1.1 "
# pssh -h ~/projects/solrcloud/ssh_files/solr_single_node -l dporte7 -P "bash ~/solr-8_0/solr/bin/solr start -cloud -q -s ~/nodeThree/solr -p 9991 -Dhost=10.10.1.1 -Dcom.sun.management.jmxremote.rmi.port=19991 -Dcom.sun.management.jmxremote.port=19991"
# pssh -h ~/projects/solrcloud/ssh_files/solr_single_node -l dporte7 -P "bash ~/solr-8_0/solr/bin/solr start -cloud -q -s ~/nodeThree/solr -p 9991 -Dhost=10.10.1.1 -Dcom.sun.management.jmxremote.rmi.port=19991 -Dcom.sun.management.jmxremote.port=19991"
