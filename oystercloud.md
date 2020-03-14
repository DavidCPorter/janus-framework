
## OYSTERCLOUD { * } 
deploy and compare performance of cloud-native systems with ease
```
                                              the cloud is your oyster 
```


**optional read**

*There is a maxim in software engineering so commonly used that it is now borderline cliche: "the right tool for the job". IMO, the saying comes off as a cheeky oversimplification of a process that can be extremely complex. In some cases, this maxim could provide a false sense of security in decision making in lieu of proper due dilligence. This quote presumes tacit experience/knowledge of every eligible tool and the features to satify the job requirements. In reality, this is almost impossible for many scenarios, especially when the job has a fuzzy or complex or changing requirements. Moreover, there are so many tools out there, it's completely overwhelming. Is it reasonable to compare an implementation of each of these tools before making a decision? I think a better maxim would be... "the more you know the better, grind hard, consider and evaluate everything" ¯\_(ツ)_/¯ . Another maxim I hear in Software engineering is that the industry is "99% persperation annd 1% inspiration". This is self explanatory and, in my opinion, very true. However, the 1% is very important. This project is rooted in these perspectives and applies them to cloud-native architecture design and development. This project aims to make "the right tool for the job" a feasible endeavor while minimizing 99% persperation and maximizing 1% inspiration.*


 After doing some market research, I was unable to find any framework which standardizes and implements a process for benchmarking and testing various cloud system deployments. OYSTERCLOUD approaches the complexity of this responsibility by first defining the parts of a benchmarking framework:
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
  
  