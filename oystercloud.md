
## OYSTACLOUD { * } 
deploy and compare performance of cloud-native systems with ease
```
                                              the cloud is your oysta 
```


**optional read**

*There is a maxim in software engineering so commonly used that it is now borderline cliche: "the right tool for the job". IMO, the saying comes off as a cheeky oversimplification of a process that can be extremely complex. This quote presumes tacit experience/knowledge of every eligible tool and the features to satify the job requirements. In reality, this is almost impossible for many scenarios, especially when the job has a fuzzy or complex or changing requirements. Moreover, there are so many tools out there, it's completely overwhelming.*

*Is it reasonable to compare an implementation of each of these tools before making a decision? I think a better maxim would be... "the more you know the better, grind hard, consider and evaluate everything" ¯\_(ツ)_/¯ . Another maxim I hear in Software engineering is that the industry is "99% persperation annd 1% inspiration". This is self explanatory and, in my opinion, very true. However, the 1% is very important. This project is rooted in these perspectives and applies them to cloud-native architecture design and development. This project aims to make "the right tool for the job" a feasible endeavor while minimizing 99% persperation and maximizing 1% inspiration.*


 After doing some market research, I was unable to find any framework which standardizes and implements a process for benchmarking and testing various cloud system deployments. OYSTACLOUD approaches the complexity of this responsibility by first defining the parts of a benchmarking framework:
 
 - `features` (e.g. data store, file system, transaction service, etc) are the core services a cloudsystem provides. 
 - `deployment` is a fully functional cloud-native system. (i.e. set of components)
 - `components` are systems that enable features for cloud-native systems (e.g. MongoDB, ElasticSearch, SolrCloud, Memcached, Hadoop, Spanner, S3 )
 - `workloads` are the applications which apply pressure to the system and track performance. 
 - `pipeline` this component drives the results from the many workloads into a format that can be projected in the next step.
 - `viz` projects the data into html charts for analysis of SLOs and performance characteristics.   
 
 


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
  

### REQUIREMENTS / INSTALLATION

##### LOCAL ENV:
Create a python3 virtual env:  
`pyenv activate your_env`

install packages:  
`pip install ansible paramiko Jinja2 numpy`

##### CLOUD INFRASTRUCTURE:  

###### cloudlab setup 
(OYSTA provides an optional cloudlab profile creation script oysta/utils/cloudlab_profiles)
If you are using cloudlab reasources, the cloud infrastructure creation is supported by OYSTA. 
*first, place the domain names of your nodes in oysta/utils/cloudlabDNS; then run:*
```
oysta create inventory [max_component_nodes] [max_load_nodes]

```
this will create sapa/inventory file

###### other setup
Most notably, you will need globally addressible nodes and a subnet connecting them.
Please emulate the inventory example with your own IPs. 
[add more]

###### emulating cloud infrastructure with local docker env
OYSTA provides benchmarking even if you don't have cloud resources but emulating them with Docker locally. So, if you choose this route, please_:
- add 0.0.0.0 as hostname for config file in ~/.ssh/config for all servers used in docker-compose.yml (see config-host.example)
- make sure docker desktop configuration allocates enough CPU cores and RAM (50% of your machine is good)
- run `$ bash container_rsa.yml` to load ssh keyss into your containers. 


### RUNNING WITH LOCAL


### required variables 
when a deploy is run, oysta will load the UI variables, which override any defaults for that module (module/defaults/main.yml). Defaults will use jinja syntax to set var value to {{ui_var | 'default_string'}}. Since oysta has a predetermined variables, branch variables are also set for next branch in branch_vars/



next:

- load should save the results to default location on remote load machines. These results might include data from multiple iterations. 
- pipeline should retrieve remote results, filter results, and save locally
- viz should run once for entire oysta experiment at the end. 
