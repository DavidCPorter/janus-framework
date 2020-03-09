## RECKON: test/benchmark any cloud-native architectures

- 


There is a maxim in software engineering so commonly used that it is now borderline cliche: "the right tool for the job". IMO, the saying comes off as a cheeky oversimplification of a process that can be extremely complex. In some cases, this maxim could provide a false sense of security in decision making in lieu of proper due dilligence. This quote presumes tacit experience/knowledge of every eligible tool and the features to satify the job requirements. In reality, this is almost impossible for many scenarios, especially when the job has a fuzzy or complex or changing requirements. Moreover, there are so many tools out there, it's completely overwhelming. Is it reasonable to compare an implementation of each of these tools before making a decision? I think a better maxim would be... "the more you know the better, grind hard, consider and evaluate everything" ¯\_(ツ)_/¯ . Another maxim I hear in Software engineering is that the industry is "99% persperation annd 1% inspiration". This is self explanatory and, in my opinion, very true. However, the 1% is very important. This project is rooted in these perspectives and applies them to cloud-native architecture design and development. This project attempts to make "the right tool for the job" possible while minimizing the 99% persperation. 

 After doing some market research, I was unable to find any framework which standardizes and implements a process for benchmarking and testing various cloud system deployments. RECKON approaches the complexity of this responsibility by first defining the parts of a benchmarking framework:
 - `features` (e.g. data store, file system, transaction service, etc) are the core services a cloudsystem provides. 
 - `components` are the applications that enable features (e.g. MongoDB, ElasticSearch, SolrCloud, Memcached, Hadoop, Spanner, S3 )
 - `workloads` are the applications which apply pressure to the system and track performance. 
 - `pipeline` this component drives the results from the many workloads into a format that can be projected in the next step.
 - `viz` projects the data into html charts for analysis of SLOs and performance characteristics.   
 
 
The architect will have to make a decision on what components to use. They could use abc or bcf or xyz to implement the components that enable the features.

**about handlers**
- Notify handlers are always run in the same order they are defined, not in the order listed in the notify-statement. This is also the case for handlers using listen.
- Handler names and listen topics live in a global namespace.
- Handler names are templatable and listen topics are not.
- Use unique handler names. If you trigger more than one handler with the same name, the first one(s) get overwritten. Only the last one defined will run.
- You cannot notify a handler that is defined inside of an include. As of Ansible 2.1, this does work, however the include must be static.

 
System design is divided into modules with subcomponetns. modules are anssible roles and represent a component of deployment architecture. The ssubcomponents comprise the module with each representing a step in it's deployment process. For example: 
  Module: 
    Solr
    subcompoenents:
        - install
        - state_config
        - run
        - dynamic_config
        - Index
 
 The dependency graph is calcuateed and will branch at any point in the treee where variables defined in dependencies in thee meta dir in the role is different than the variables defined in the dependencies of the otherr roles. 
 
 So LOAD module for example may list these in dependencies:  
 - ubuntu:
    vars:
        - version: value
        - apt: value
 - docker
    vars:
        - RAM: 40
    listening_ports:
        - 
 -  solr:
    vars:
        clustersize: 4
        replication: 2
        shards: 2
        solr_home: /users/butter/solr
        source: http://url_for_source.com
    
  
  
[allNodes]
128.110.153.216   globalIP=128.110.153.216   ansible_subnet=10.10.1.1  zoo_id=1
128.110.153.228   globalIP=128.110.153.228   ansible_subnet=10.10.1.2  zoo_id=2
128.110.153.230   globalIP=128.110.153.230   ansible_subnet=10.10.1.3  zoo_id=3
128.110.153.238   globalIP=128.110.153.238   ansible_subnet=10.10.1.4
128.110.153.212   globalIP=128.110.153.212   ansible_subnet=10.10.1.5
128.110.153.204   globalIP=128.110.153.204   ansible_subnet=10.10.1.6
128.110.153.217   globalIP=128.110.153.217   ansible_subnet=10.10.1.7
128.110.153.235   globalIP=128.110.153.235   ansible_subnet=10.10.1.8
128.110.153.218   globalIP=128.110.153.218   ansible_subnet=10.10.1.9
128.110.153.226   globalIP=128.110.153.226   ansible_subnet=10.10.1.10
128.110.153.243   globalIP=128.110.153.243   ansible_subnet=10.10.1.11
128.110.153.223   globalIP=128.110.153.223   ansible_subnet=10.10.1.12
128.110.153.225   globalIP=128.110.153.225   ansible_subnet=10.10.1.13
128.110.153.213   globalIP=128.110.153.213   ansible_subnet=10.10.1.14
128.110.153.199   globalIP=128.110.153.199   ansible_subnet=10.10.1.15
128.110.153.214   globalIP=128.110.153.214   ansible_subnet=10.10.1.16

[masterNodes]
128.110.153.216   globalIP=128.110.153.216   ansible_subnet=10.10.1.1  zoo_id=1
128.110.153.228   globalIP=128.110.153.228   ansible_subnet=10.10.1.2  zoo_id=2
128.110.153.230   globalIP=128.110.153.230   ansible_subnet=10.10.1.3  zoo_id=3

[thirdMaster]
128.110.153.230   globalIP=128.110.153.230   ansible_subnet=10.10.1.3  zoo_id=3

[zookeeperNodes]
128.110.153.216   globalIP=128.110.153.216   ansible_subnet=10.10.1.1  zoo_id=1
128.110.153.228   globalIP=128.110.153.228   ansible_subnet=10.10.1.2  zoo_id=2
128.110.153.230   globalIP=128.110.153.230   ansible_subnet=10.10.1.3  zoo_id=3


[twoNode]
128.110.153.216   globalIP=128.110.153.216   ansible_subnet=10.10.1.1  zoo_id=1
128.110.153.228   globalIP=128.110.153.228   ansible_subnet=10.10.1.2  zoo_id=2


[fourNode]
128.110.153.216   globalIP=128.110.153.216   ansible_subnet=10.10.1.1  zoo_id=1
128.110.153.228   globalIP=128.110.153.228   ansible_subnet=10.10.1.2  zoo_id=2
128.110.153.230   globalIP=128.110.153.230   ansible_subnet=10.10.1.3  zoo_id=3
128.110.153.238   globalIP=128.110.153.238   ansible_subnet=10.10.1.4
[fourNode:vars]
clustersize=4

[eightNode]
128.110.153.216   globalIP=128.110.153.216   ansible_subnet=10.10.1.1  zoo_id=1
128.110.153.228   globalIP=128.110.153.228   ansible_subnet=10.10.1.2  zoo_id=2
128.110.153.230   globalIP=128.110.153.230   ansible_subnet=10.10.1.3  zoo_id=3
128.110.153.238   globalIP=128.110.153.238   ansible_subnet=10.10.1.4
128.110.153.212   globalIP=128.110.153.212   ansible_subnet=10.10.1.5
128.110.153.204   globalIP=128.110.153.204   ansible_subnet=10.10.1.6
128.110.153.217   globalIP=128.110.153.217   ansible_subnet=10.10.1.7
128.110.153.235   globalIP=128.110.153.235   ansible_subnet=10.10.1.8


[allSearchNodes]
128.110.153.216   globalIP=128.110.153.216   ansible_subnet=10.10.1.1  zoo_id=1
128.110.153.228   globalIP=128.110.153.228   ansible_subnet=10.10.1.2  zoo_id=2
128.110.153.230   globalIP=128.110.153.230   ansible_subnet=10.10.1.3  zoo_id=3
128.110.153.238   globalIP=128.110.153.238   ansible_subnet=10.10.1.4
128.110.153.212   globalIP=128.110.153.212   ansible_subnet=10.10.1.5
128.110.153.204   globalIP=128.110.153.204   ansible_subnet=10.10.1.6
128.110.153.217   globalIP=128.110.153.217   ansible_subnet=10.10.1.7
128.110.153.235   globalIP=128.110.153.235   ansible_subnet=10.10.1.8



[sixteenNode]
128.110.153.216   globalIP=128.110.153.216   ansible_subnet=10.10.1.1  zoo_id=1
128.110.153.228   globalIP=128.110.153.228   ansible_subnet=10.10.1.2  zoo_id=2
128.110.153.230   globalIP=128.110.153.230   ansible_subnet=10.10.1.3  zoo_id=3
128.110.153.238   globalIP=128.110.153.238   ansible_subnet=10.10.1.4
128.110.153.212   globalIP=128.110.153.212   ansible_subnet=10.10.1.5
128.110.153.204   globalIP=128.110.153.204   ansible_subnet=10.10.1.6
128.110.153.217   globalIP=128.110.153.217   ansible_subnet=10.10.1.7
128.110.153.235   globalIP=128.110.153.235   ansible_subnet=10.10.1.8
128.110.153.218   globalIP=128.110.153.218   ansible_subnet=10.10.1.9
128.110.153.226   globalIP=128.110.153.226   ansible_subnet=10.10.1.10
128.110.153.243   globalIP=128.110.153.243   ansible_subnet=10.10.1.11
128.110.153.223   globalIP=128.110.153.223   ansible_subnet=10.10.1.12
128.110.153.225   globalIP=128.110.153.225   ansible_subnet=10.10.1.13
128.110.153.213   globalIP=128.110.153.213   ansible_subnet=10.10.1.14
128.110.153.199   globalIP=128.110.153.199   ansible_subnet=10.10.1.15
128.110.153.214   globalIP=128.110.153.214   ansible_subnet=10.10.1.16


[twentyfourNode]
128.110.153.216   globalIP=128.110.153.216   ansible_subnet=10.10.1.1  zoo_id=1
128.110.153.228   globalIP=128.110.153.228   ansible_subnet=10.10.1.2  zoo_id=2
128.110.153.230   globalIP=128.110.153.230   ansible_subnet=10.10.1.3  zoo_id=3
128.110.153.238   globalIP=128.110.153.238   ansible_subnet=10.10.1.4
128.110.153.212   globalIP=128.110.153.212   ansible_subnet=10.10.1.5
128.110.153.204   globalIP=128.110.153.204   ansible_subnet=10.10.1.6
128.110.153.217   globalIP=128.110.153.217   ansible_subnet=10.10.1.7
128.110.153.235   globalIP=128.110.153.235   ansible_subnet=10.10.1.8
128.110.153.218   globalIP=128.110.153.218   ansible_subnet=10.10.1.9
128.110.153.226   globalIP=128.110.153.226   ansible_subnet=10.10.1.10
128.110.153.243   globalIP=128.110.153.243   ansible_subnet=10.10.1.11
128.110.153.223   globalIP=128.110.153.223   ansible_subnet=10.10.1.12
128.110.153.225   globalIP=128.110.153.225   ansible_subnet=10.10.1.13
128.110.153.213   globalIP=128.110.153.213   ansible_subnet=10.10.1.14
128.110.153.199   globalIP=128.110.153.199   ansible_subnet=10.10.1.15
128.110.153.214   globalIP=128.110.153.214   ansible_subnet=10.10.1.16


[singleNode]
128.110.153.216   globalIP=128.110.153.216   ansible_subnet=10.10.1.1  zoo_id=1


[singleGenerator]
128.110.153.218   globalIP=128.110.153.218   ansible_subnet=10.10.1.9

[generatorNode]
128.110.153.218   globalIP=128.110.153.218   ansible_subnet=10.10.1.9
128.110.153.226   globalIP=128.110.153.226   ansible_subnet=10.10.1.10
128.110.153.243   globalIP=128.110.153.243   ansible_subnet=10.10.1.11
128.110.153.223   globalIP=128.110.153.223   ansible_subnet=10.10.1.12
128.110.153.225   globalIP=128.110.153.225   ansible_subnet=10.10.1.13
128.110.153.213   globalIP=128.110.153.213   ansible_subnet=10.10.1.14
128.110.153.199   globalIP=128.110.153.199   ansible_subnet=10.10.1.15
128.110.153.214   globalIP=128.110.153.214   ansible_subnet=10.10.1.16



[dataServer]
128.110.153.238   globalIP=128.110.153.238   ansible_subnet=10.10.1.4


[mylocal]
localhost ansible_connection=local


[all:vars]
node0_subnet=10.10.1.1
ansible_connection=ssh
ansible_user=dporte7
node0=128.110.153.216
node1=128.110.153.228
node2=128.110.153.230
node3=128.110.153.238
node4=128.110.153.212
node5=128.110.153.204
node6=128.110.153.217
node7=128.110.153.235
node8=128.110.153.218
node9=128.110.153.226
node10=128.110.153.243
node11=128.110.153.223
node12=128.110.153.225
node13=128.110.153.213
node14=128.110.153.199
node15=128.110.153.214
cloudnodes=16
searchnodecount=8
loadnodecount=8

root_path=/Users/dporter/projects/sapa
SAPA_HOME=/Users/dporter/projects/sapa
main_class=com.dporte7.solrclientserver.DistributedWebServer
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
git_branch_name=dporter_8_3
solr_bin_exec=/users/dporte7/solr-8_3/solr/bin/solr
s3_bucket_name=solr-8-3-dporter
home=/users/dporte7
gather_facts=no





why not do this instead:

```

DFS_dict = { 
            host:all,play:install, vars:xyz.yml, next:{
                hosts:twoNode, play:env-install.yml, vars:abc.yml, next: {
                    hosts:twoNode, play:env-install.yml, vars:abc.yml, next: {
                    }, branches: [ {
                        hosts:twoNode, play:env-install.yml, vars:abc.yml, next: {
                        }]
            
                }, branches: [
                    hosts:twoNode, play:env-install.yml, vars:abc.yml, next: {

                }
}
            

recurse_helper (dfs_dict){

    HOSTS=dfs_dict['hosts']
    PLAY=dfs_dict['play']
    VARS=dfs_dict['vars']
    
    ansible-playbook -i inventory hosts=$HOSTS vars=$VARS $PLAY
    
    if next != null:
        recurse_helper(dfs_dict['next'])
    for branch in branches:
        recurse_helper(dfs_dict['branch'])

    ansible-playbook -i inventory $PLAY --tags revert
    return
}

main (){
    
    DFS_dict= toolUIgenerator() #this generates a dict like the one at the top
    recurse_helper(DFS_dict)
    execute_visualizations()
    exit()

}

```
  
  