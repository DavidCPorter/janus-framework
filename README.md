## SAPA: a tool for Search Agnostic Performance Analysis


Sapa provides a simple interface for tuning elastic and solr cloud deployments and comparing their performance. 

CLI tooling shows a few options presented inutitively with this simple flow and options. Or you can simply do step one, and configure the test cases manually in their respective yaml files. 
```
$ sapa create <name1> <name2> <name3>
$ sapa config <key:value> <key:value> <names>...
$ sapa workload <key:value> <names>...
$ sapa env <key:value> <names>...
$ sapa plug </path/to/binary> <other_options> <names>   # needs work... load balancers, rate limiters, etc can go here
$ sapa viz <viz_type1> <viz_type2> <names>
$ sapa show states <names>
$ sapa run <names>
```

### HOW IT WORKS

a simple use case:
John wants to know what search application and configuration has the lowest P99 latency given a particular load. 
```
$ cd sapa
$ sapa create <list of names for each configuration> ;  # e.g. solr1 solr2 elastic1 elastic2
$ sapa add RAM:60G all!elastic2 ;
$ sapa add engine:elastic elastic1 elastic2 ; 
$ sapa add loop:open all ;
$ sapa add load_start:1 load_finish:100 all ;
$ sapa add load_balancer:clients ;
$ sapa plug ratelimiter /path/to/ratelimiter/binary all!elastic1 ;
$ sapa viz plug 
$ sapa show states ;

| ****** elastic1 ****** | ******* elastic 2 ******  | 
    ENGINE: elastic         ENGINE: elastic
    RAM:    60G             RAM:    1G #default
    LOOP:   open            LOOP:   open
    ... 

$ sapa run <experiment_name> ;

```




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
