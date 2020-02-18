## SAPA: a tool for Search Agnostic Performance Analysis

### OVERVIEW

Sapa provides an automation tool for deploying and benchmarking SolrCloud and Elastic search engines. The overarching purpose of this project is to provide a framework for quickly discovering optimal deployment strategies given organizational constraints. Search engine config state space is incredibly large (fig1). Consequentially, tuning these apps for performance requires a lot of guesswork since there is no silver bullet when it comes to the best configuration. If you ask 10 domain experts what the best settings are for optimal performance of x, you will be hammered with 10 "it depends", which can be frustrating. Sapa takes the guesswork out of performance tuning by providing a tight feedback loop on your deployment strategies out of the box. If you have been diagnosed with "search engine configuration fatigue", or suspect there are performance bottlenecks and want to efficiently explore all your options?... SAPA is the tool for you.
 
 fig 1 | notes 
 ---- | ----
 ![fig_1](./utils/state_explosion.png) | The single line traversing this state space represents a single deployment. This graph illustrates a simple example of a deployment state space definition; each color represents a config category, and each dot represents a configured value. Many production systems will choose to compare many more verticals.  
 



Key Terminology:
- `sapa_bench` = sapa_bench is the term to descibe a sapa run from end to end. Put simply, it's the core use case for sapa. It's defined as a experiment to benchmark N number of search engine deployments and compare the results.
- `statespace` = the statespace is the particular settings for a single deployment. 
- `deployment` = a particular instance of elastic or solrcloud with a defined statespace 

Importantly, statespace is composed of three sub spaces, and each has an impact on search performance.

- `config`: these are the knobs provided to users for tuning the instance of the search engine. _e.g. solrconfig.xml, elasticsearch.yml, replicas, shards, etc._
- `workload`: these settings generally define the interactions with search engines during the experiment, most notably the workload settings. _e.g. search term dictionary, documents, load balancers, client apis, etc_
- `env`: defines things such as JVM settings, clustersize scaling, local, remote configs.
**e.g. clustersizes, cluster replications, JVM settings, docker,  network configs, etc**

other sapa_bench options: 
- `viz`: declare visualizations to generate with the performance data. _e.g. cdfs, latecy->throughput, 
- `plug`: experimental integrations to plug into the enviornment. The goal with this is to inject a binary into the experimental flow to enhance performance. e.g. rate limiters, service proxies, multitenenant, etc.  

Sapa's CLI makes configuring the statespace for multiple deployments simple. The CLI sole purposes is to populate sapa_.yml files for each deployment. The best practice is to generate the .yml files using for example `sapa create e_1:elastic e_2:elastic s_1:solr s_2:solr`. This will generate the template files which you can manually reconfigure, or do so with the CLI commands. A savvy user may choose to use the cli in a bash script that can be saved and perhaps replayed or archived. 

Importantly, the last paramater for each cli command is a comma separated list of deployment names given in the create step. Optionally, all and ! are tokens that represent *all* deployments, and *sans* deployment. So you can for instance use `all,!elastic1` which will apply those settings to all but the elastic1 deployment. 

```
$ sapa create <key:name1> <key:name2> <key:name3> 
$ sapa config <key:value> <key:value> <deployments>
$ sapa workload <key:value> <deployments>
$ sapa env <key:value> <deployments>
$ sapa plug </path/to/binary> <other_options> <deployments> 
$ sapa viz <viz_type1> <viz_type2> <deployments>
$ sapa show states <deployments>
$ sapa run <deployments>
```
 
 
### SIMPLE EXAMPLE

a simple use case:
John wants to know what search application and configuration has the lowest P99 latency given a particular load. 
```
$ cd sapa
$ sapa create solr:solr1 solr:solr2 elastic:elastic1 elastic:elasic2
$ sapa env RAM:20G all,!elastic2 ;
$ sapa configconfig queryCache:9999 documentCache:9999 all,!elastic1,!elastic2 ;
$ sapa workload loop:open all ;
$ sapa workload load_start:1 load_finish:100 solr1,solr2;
$ sapa workload load_balancer:clients all,!elastic2;
$ sapa plug ratelimiter /path/to/ratelimiter/binary all,!elastic1 ;
$ sapa viz cdf_91 total_throughput all
$ sapa show states all ;

| ****** elastic1 ****** | ******* elastic 2 ******  | 
    ENGINE: elastic         ENGINE: elastic
    RAM:    60G             RAM:    1G #default
    LOOP:   open            LOOP:   open
    ... 

$ sapa run <experiment_name> all ;

```

__need to tell a story here, basically a placeholder for now__

 fig 2: CDF 91 connections | fig 3: Total Throughput
 ---- | ----
 ![fig_2](./utils/cdf_example_fig.png) |  ![fig_3](./utils/total_throughput.png)




### INSTALLATION

Requirements:
To deploy you need to set up a local and remote env:

LOCAL:  
Create a python3 virtual env:  
`pyenv activate your_env`

install packages:  
`pip install ansible paramiko Jinja2 numpy`

add 127.0.0.1 as hostname for config file in ~/.ssh/config for all servers used in ansible inventory_local 
make sure docker desktop configuration allocates enough CPU cores and RAM 

put rsa keys in the local machines .ssh/authorized_keys file

this example case runs a docker cloud locally, then performms a performance analysis of elastic search with a cloud of 2 elastic servers and a single workoad server.
 new users still need to make some changes to the ssh files /sapa/utils/ssh_files. You can run the ssh script to generate. 

also users need to make sure  they add hostnames to their .ssh/configs file and put their id_rsa.pub file in the docker servers. 


REMOTE:  
1. to set up your remote env, put the four Cloudlab domains in a file ./cloudlabDNS e.g
```
ms1312.utah.cloudlab.us
ms1019.utah.cloudlab.us
ms1311.utah.cloudlab.us
ms1341.utah.cloudlab.us
ms0819.utah.cloudlab.us
...
```


*before running this script, make sure your id_rsa public key is on cloudlab and your id_rsa private key starts with -----BEGIN RSA PRIVATE KEY----- since this paramiko version requires this.*
**also make sure all whitespace is removed from this file otherwise paramiko may throw a curious error**
**be sure the list of dns names are in order of the cloudlab listview**

2. run $python3 getips.py <cloudlab username> <cloudlabDNS filename> <path_to_private_rsa_key>
this will generate >> `inventory_gen.txt` file. swap this file with `./inventory`

### before you run the ansible scripts:
*these steps fork the solr repo, check out a specific branch, and duplicate that branch to your own dev branch.*
- fork the lucene-solr repo https://github.com/DavidCPorter/lucene-solr.git
- add ssh keys from solr nodes to github account (temp solution so ansible can easily update repos remotely)
- locally clone repo
- checkout branch_8_3 (or whatever solr version you want)
- create new branch <name> e.g. `git checkout -b <name>`
- push <name> branch to origin
- replace git_branch_name=dporter_8_3 in inventory to git_branch_name=<name>
- replace `dporte7` in ansible role "vars" and "defaults" files with your username in cloudlab

##### LOAD env helpers utils.sh and be sure to replace SAPA_HOME and CL_USER var with your path for this app.

#### set up shell envs
1. update all files in utils folder with your current cluster and user-specific info **especially the node strings with the IPS**
2. then, run `ssh_files/produce_ssh_files.sh` to create files for pssh tasks dependencies in runtest.sh

#### run ansible scripts
3. to install the cloud env, run:  
`play cloud_configure.yml --tags never`
4. to install and run zookeeper, run:  
`play zoo_configure.yml`
5. to install and run solrcloud, run:  
`play solr_configure_all.yml --tags setup --extra-vars "solr_bin_exec=/users/dporte7/solr-8_3/solr/bin/solr"`
6. to install solrj-enabled client application (cloudaware solr client). There is a tag you can use to enable remote monitoring via jmx if you would like to see that. Also requires REMOTE_JMX setting mod (see below)
`play solr_bench.yml --tags solrj`




#### run experiment
*before you run any experiment you want to make sure solr is not running `checksolr` and that there is no indicies on the cores `listcores`*
*make sure the utils are updated  loaded first*
*make sure to edit params file*
fulltest < list of solr clusters >
e.g. if i wanted to run scaling experiment on 2 4 8 and 16 clusters and compare the performance, I would run this:
`fulltest 2 4 8 16`

**IF YOU EVER EXIT an experiment or it fails... make sure to remember run `stopSolr <clustersize>` and `wipecores` and `killallbyname dstat` `callingnodes rm *.csv` before you continue**
*FURTHERMORE, if the exp posted_data (indexed) for the first time, you might want to consider deleting that collection via solr admin and redoing the experiemnt becuase the final step in the exp is to save to aws and that would not have happened in a failed exp... you can either run the ansible script to post to aws, or just redo it after deleting*

**It's important to remember that the disk space on the cluster is small ~10GB so any more that 4 replicas will prolly fail due to disk size failure. This is why there is the posting the index to aws (if prev nott there ) and removing it after each exp so you dont hit the limit.**


### NOTES
#### Notes on Solr Config
*This is completed automatically during the solr config step with the ansible playbooks.*

I found the easiest way to connect with the remote JMX is to modify this line in the ~/solr-8_0/solr/bin/solr executable

`REMOTE_JMX_OPTS+=("-Djava.rmi.server.hostname=$SOLR_HOST")`  
to  
`REMOTE_JMX_OPTS+=("-Djava.rmi.server.hostname=$GLOBALIP")`


#### Notes on Ansible Roles:
There are five roles in this repo `cloudenv, solr, zookeeper, upload_data, benchmark` located in the /playbooks/roles dir. You can take a look at the procedures for setting up the envs in ./roles/<role_name>/tasks/main.yml

#### Notes on Ansible Variables
when you run ansible playbooks, the process will generate sys variables, and to view these you can run `ansible -i inventory -m setup`
`hostvars`
`VARIABLE PRECEDENCE`
If multiple variables of the same name are defined in different places, they win in a certain order, which is:
- extra vars (-e in the command line) always win
- then comes connection variables defined in inventory (ansible_ssh_user, etc)
- then comes "most everything else" (command line switches, vars in play, included vars, role vars, etc)
- then comes the rest of the variables defined in inventory
- then comes facts discovered about a system
- then "role defaults", which are the most "defaulty" and lose in priority to everything.



### upgrading solr:
http://lucene.apache.org/solr/guide/8_3/solr-upgrade-notes.html#solr-upgrade-notes

**feature changes 8->8.1**
*Collections API*
- The CREATE command will now return the appropriate status code (4xx, 5xx, etc.) when the command has failed. Previously, it always returned 0, even in failure.


*Logging*
- (we turn logging off... but goood to know) The default Log4j2 logging mode has been changed from synchronous to asynchronous. This will improve logging throughput and reduce system contention at the cost of a slight chance that some logging messages may be missed in the event of abnormal Solr termination.

**feature changes 8.1->8.2**
*Zookeeper*
- ZooKeeper 3.5.5
- This ZooKeeper release includes many new security features. In order for Solr’s Admin UI to work with 3.5.5, the zoo.cfg file must allow access to ZooKeeper’s "four-letter commands". At a minimum, ruok, conf, and mntr must be enabled, but other commands can optionally be enabled if you choose. See the section Configuration for a ZooKeeper Ensemble for details.
- add this to zoo.cfg::: 4lw.commands.whitelist=mntr,conf,ruok

*Distributed Tracing Support*
- woo! This release adds support for tracing requests in Solr. Please review the section Distributed Solr Tracing for details on how to configure this feature.

*Caches*

- Solr has a new cache implementation, CaffeineCache, which is now recommended over other caches. This cache is expected to generally provide most users lower memory footprint, higher hit ratio, and better multi-threaded performance.Since caching has a direct impact on the performance of your Solr implementation, before switching to any new cache implementation in production, take care to test for your environment and traffic patterns so you fully understand the ramifications of the change.
- A new parameter, maxIdleTime, allows automatic eviction of cache items that have not been used in the defined amount of time. This allows the cache to release some memory and should aid those who want or need to fine-tune their caches.



**UPGRADING SOLR STEPS**
- run play zoo_configure.yml --tags burn_zoo
- stop solr
- change solr install dir
- change solr git branch name in inventory
- change aws bucket name to new dir for this verison
- delete solr dir and data dirs with `play solr_configure_all.yml --tags burn_solr`
- run `play solr_configure_all.yml --tags setup --extra-vars "solr_bin_exec=/users/dporte7/solr-8_3/solr/bin/solr"`
- change defaults in zoo role for new version download link
- add this to zoo.cfg: 4lw.commands.whitelist=mntr,conf,ruok
- run `play zoo_configure.yml`

i.e. these commands should work in sequence as long as the directory names are changed
```
play zoo_configure.yml --tags burn_zoo
play solr_configure_all.yml --tags burn_solr
play zoo_configure.yml
play solr_configure_all.yml --tags setup --extra-vars "solr_bin_exec=/users/dporte7/solr-8_3/solr/bin/solr"
```
